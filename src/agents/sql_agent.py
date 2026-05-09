"""SQL Agent - Text-to-SQL pipeline with Pinecone schema retrieval.

Flow: Complexity Detection -> Ambiguity (with history) -> Cache L2 -> Schema Retrieval ->
      SQL Generation (heavy model) -> Validation -> Approval -> Execution -> Response
"""

import json
import re
import time
from decimal import Decimal
from langchain_core.messages import SystemMessage, HumanMessage
from langchain_groq import ChatGroq
from src.core import get_settings
from src.core.state import AgentState
from src.core.prompts import get_prompt, get_prompt_with_meta
from src.core.database import sql_execute_query, sql_get_full_schema_ddl, save_conversation, sql_log_query
from src.core.tracing import trace_agent_node
from src.core.resilience import resilient_call, llm_circuit, llm_rate_limiter
from src.services.guardrails_service import validate_input, validate_sql, validate_output, parse_json_output
from src.services.retrieval_service import sql_schema_search
from src.services.cache_service import semantic_cache_set
import structlog

log = structlog.get_logger()
settings = get_settings()


def _get_fast_llm():
    return ChatGroq(api_key=settings.groq_api_key, model=settings.groq_fast_model, temperature=0)


def _get_heavy_llm():
    return ChatGroq(api_key=settings.groq_api_key, model=settings.groq_chat_model, temperature=0)


@trace_agent_node("sql_complexity_detector")
def sql_complexity_node(state: AgentState) -> dict:
    """Classify query complexity using fast model + prompt registry."""
    query = state.get("original_query", "")
    messages = state.get("messages", [])

    try:
        prompt_meta = get_prompt_with_meta("complexity_detection")
        system_content = prompt_meta["template"]

        llm = _get_fast_llm()
        response = resilient_call(
            llm.invoke,
            [SystemMessage(content=system_content), HumanMessage(content=query)],
            circuit=llm_circuit, rate_limiter=llm_rate_limiter,
        )
        data = parse_json_output(response.content, ["complexity"])
        complexity = data.get("complexity", "moderate")
        if complexity not in ("simple", "moderate", "complex"):
            complexity = "moderate"
    except Exception:
        complexity = "moderate"

    log.info("sql_complexity_detected", complexity=complexity, model=settings.groq_fast_model)
    return {"messages": messages, "query_complexity": complexity}


@trace_agent_node("sql_ambiguity_agent")
def sql_ambiguity_node(state: AgentState) -> dict:
    """Detect and resolve ambiguity using conversation history.

    Uses fast model. If ambiguous + history exists: infer intent and suggest interpretations.
    If ambiguous + no history: ask for clarification directly.
    """
    query = state.get("original_query", "")
    messages = state.get("messages", [])
    history = state.get("conversation_history", [])
    summary = state.get("conversation_summary", "")

    is_safe, issues = validate_input(query)
    if not is_safe:
        return {"messages": messages, "status": "failed",
                "error": f"Query blocked: {'; '.join(issues)}", "is_ambiguous": False}

    from langchain_core.tools import tool as lc_tool

    @lc_tool
    def resolve_ambiguity(is_ambiguous: bool, rewritten_query: str = "",
                          clarification_message: str = "", clarification_options: list = [],
                          ambiguity_score: float = 0.0, rewrite_confidence: float = 0.8) -> str:
        """Resolve query ambiguity."""
        return json.dumps({
            "is_ambiguous": is_ambiguous, "rewritten_query": rewritten_query,
            "clarification_message": clarification_message,
            "clarification_options": clarification_options,
            "ambiguity_score": ambiguity_score, "rewrite_confidence": rewrite_confidence,
        })

    llm = _get_fast_llm().bind_tools([resolve_ambiguity], tool_choice="auto")

    # Build history context for ambiguity resolution
    context_parts = []
    if summary:
        context_parts.append(f"Conversation summary: {summary}")
    if history:
        context_parts.append("Recent conversation:")
        for h in history[-5:]:
            context_parts.append(f"  {h['role']}: {h['content']}")
    history_context = "\n".join(context_parts) if context_parts else "No prior context available."

    try:
        prompt_meta = get_prompt_with_meta("ambiguity_resolution")
        system_prompt = prompt_meta["template"].format(history_context=history_context)
    except Exception:
        return {"messages": messages, "is_ambiguous": False, "rewritten_query": query}

    try:
        response = resilient_call(
            llm.invoke,
            [SystemMessage(content=system_prompt),
             HumanMessage(content=f"User query: {query}")],
            circuit=llm_circuit, rate_limiter=llm_rate_limiter,
        )

        if response.tool_calls:
            tc = response.tool_calls[0]["args"]
            is_ambiguous = tc.get("is_ambiguous", False)

            if is_ambiguous:
                options = tc.get("clarification_options", [])
                formatted = []
                for i, opt in enumerate(options):
                    if isinstance(opt, str):
                        formatted.append({"index": i + 1, "query": opt, "reason": ""})
                    elif isinstance(opt, dict):
                        formatted.append({
                            "index": opt.get("index", i + 1),
                            "query": opt.get("query", str(opt)),
                            "reason": opt.get("reason", ""),
                        })

                # If history exists, provide context-aware suggestions
                clarification_msg = tc.get("clarification_message", "Could you clarify?")
                if history:
                    clarification_msg = f"Based on our conversation, I have a few interpretations. {clarification_msg}"

                return {
                    "messages": messages, "is_ambiguous": True, "rewritten_query": "",
                    "clarification_message": clarification_msg,
                    "clarification_options": formatted,
                    "status": "awaiting_clarification",
                    "ambiguity_score": tc.get("ambiguity_score", 0.8),
                }
            else:
                return {
                    "messages": messages, "is_ambiguous": False,
                    "rewritten_query": tc.get("rewritten_query", query),
                    "ambiguity_score": tc.get("ambiguity_score", 0.1),
                    "rewrite_confidence": tc.get("rewrite_confidence", 0.8),
                }
        return {"messages": messages, "is_ambiguous": False, "rewritten_query": query}
    except Exception as e:
        log.warning("sql_ambiguity_failed", error=str(e)[:200])
        return {"messages": messages, "is_ambiguous": False, "rewritten_query": query}


@trace_agent_node("sql_schema_retriever")
def sql_schema_node(state: AgentState) -> dict:
    """Retrieve relevant schema context using Pinecone + keyword hybrid search."""
    query = state.get("rewritten_query", "") or state.get("original_query", "")
    embedding = state.get("query_embedding", [])
    messages = state.get("messages", [])

    try:
        schema_results = sql_schema_search(query, embedding=embedding, top_k=settings.schema_top_k)

        seen_tables = set()
        lines = []
        for r in schema_results:
            tbl = r.get("table_name", "")
            col = r.get("column_name", "")
            desc = r.get("description", "")
            dtype = r.get("data_type", "")
            seen_tables.add(tbl)
            lines.append(f"  {tbl}.{col} ({dtype}): {desc}")

        try:
            ddl = sql_get_full_schema_ddl()
        except Exception:
            ddl = ""

        schema_context = f"Relevant columns:\n" + "\n".join(lines)
        if ddl:
            schema_context += f"\n\nFull DDL:\n{ddl}"

        tables_used = list(seen_tables)
        log.info("sql_schema_retrieved", tables=len(tables_used), columns=len(schema_results))

        return {
            "messages": messages,
            "schema_context": schema_context,
            "tables_used": tables_used,
        }
    except Exception as e:
        log.error("sql_schema_retrieval_failed", error=str(e))
        try:
            ddl = sql_get_full_schema_ddl()
            return {"messages": messages, "schema_context": ddl, "tables_used": []}
        except Exception:
            return {"messages": messages, "schema_context": "", "tables_used": [],
                    "error": "Schema retrieval failed", "status": "failed"}


@trace_agent_node("sql_generator")
def sql_generator_node(state: AgentState) -> dict:
    """Generate SQL using heavy model with function calling + prompt registry."""
    query = state.get("rewritten_query", "") or state.get("original_query", "")
    schema = state.get("schema_context", "")
    messages = state.get("messages", [])
    retry_count = state.get("retry_count", 0)
    prev_errors = state.get("validation_errors", [])
    history = state.get("conversation_history", [])
    start_time = time.time()

    from langchain_core.tools import tool as lc_tool

    @lc_tool
    def generate_sql(sql: str, confidence: float = 0.8,
                     tables_used: list = [], reasoning: str = "") -> str:
        """Generate SQL query for the user's question."""
        return json.dumps({"sql": sql, "confidence": confidence,
                           "tables_used": tables_used, "reasoning": reasoning})

    llm = _get_heavy_llm().bind_tools([generate_sql], tool_choice="auto")

    context_parts = []
    if retry_count > 0 and prev_errors:
        context_parts.append(f"PREVIOUS ATTEMPT FAILED. Errors: {'; '.join(prev_errors)}")
        context_parts.append("Fix the SQL based on these errors.")
    if history:
        for h in history[-3:]:
            context_parts.append(f"{h['role']}: {h['content']}")

    context = "\n".join(context_parts) if context_parts else ""

    try:
        prompt_meta = get_prompt_with_meta("sql_generation")
        prompt_template = prompt_meta["template"]
        prompt_version = prompt_meta["version"]
        model_name = settings.groq_chat_model

        formatted = prompt_template.format(schema=schema, query=query, context=context)

        response = resilient_call(
            llm.invoke,
            [HumanMessage(content=formatted)],
            circuit=llm_circuit, rate_limiter=llm_rate_limiter,
        )

        if response.tool_calls:
            tc = response.tool_calls[0]["args"]
            sql = tc.get("sql", "")
            confidence = float(tc.get("confidence", 0.7))
            tables = tc.get("tables_used", [])

            # Self-consistency check (fast model)
            try:
                sc_prompt = get_prompt("sql_self_consistency")
                sc_llm = _get_fast_llm()
                sc_response = resilient_call(
                    sc_llm.invoke,
                    [SystemMessage(content=sc_prompt),
                     HumanMessage(content=f"Question: {query}\nSQL: {sql}")],
                    circuit=llm_circuit, rate_limiter=llm_rate_limiter,
                )
                sc_data = parse_json_output(sc_response.content, ["aligned"])
                if not sc_data.get("aligned", True):
                    penalty = float(sc_data.get("penalty", 0.15))
                    confidence = max(0.0, confidence - penalty)
            except Exception:
                pass

            latency_ms = (time.time() - start_time) * 1000
            log.info("sql_generated", confidence=confidence, tables=tables,
                     prompt_version=prompt_version, model=model_name,
                     latency_ms=round(latency_ms, 1))
            return {
                "messages": messages, "generated_sql": sql,
                "sql_confidence": confidence, "tables_used": tables,
                "retry_count": retry_count,
            }

        return {"messages": messages, "error": "No SQL generated", "status": "failed"}

    except Exception as e:
        error_str = str(e)
        sql_match = re.search(r'"sql":\s*"((?:[^"\\]|\\.)*)"', error_str)
        if sql_match:
            extracted_sql = sql_match.group(1).replace('\\"', '"').replace('\\n', '\n')
            return {
                "messages": messages, "generated_sql": extracted_sql,
                "sql_confidence": 0.5, "retry_count": retry_count,
            }
        return {"messages": messages, "error": f"SQL generation failed: {str(e)}",
                "status": "failed"}


@trace_agent_node("sql_validator")
def sql_validator_node(state: AgentState) -> dict:
    """5-layer SQL validation."""
    sql = state.get("generated_sql", "")
    messages = state.get("messages", [])
    retry_count = state.get("retry_count", 0)
    schema_context = state.get("schema_context", "")
    errors = []

    if not sql:
        return {"messages": messages, "validation_errors": ["No SQL to validate"],
                "sql_validated": False, "retry_count": retry_count + 1}

    is_safe, safety_issues = validate_sql(sql)
    if not is_safe:
        errors.extend(safety_issues)

    sql_upper = sql.upper()
    from_match = re.findall(r'\bFROM\s+(\w+)', sql_upper)
    join_match = re.findall(r'\bJOIN\s+(\w+)', sql_upper)
    referenced_tables = set(t.lower() for t in from_match + join_match)

    if schema_context and referenced_tables:
        schema_tables = set(re.findall(r'TABLE\s+(\w+)', schema_context))
        for tbl in referenced_tables:
            if schema_tables and tbl not in schema_tables:
                errors.append(f"Table '{tbl}' not found in schema")

    if "SELECT *" in sql_upper:
        errors.append("SELECT * is not recommended - specify columns")

    if "GROUP BY" in sql_upper:
        agg_funcs = re.findall(r'\b(COUNT|SUM|AVG|MIN|MAX)\s*\(', sql_upper)
        if not agg_funcs:
            errors.append("GROUP BY without aggregate functions")

    join_count = len(join_match)
    has_limit = "LIMIT" in sql_upper
    estimated_cost = "low"
    if join_count >= 3 and not has_limit:
        estimated_cost = "high"
        errors.append("Complex query without LIMIT - add LIMIT clause")
    elif join_count >= 2:
        estimated_cost = "medium"

    if not has_limit:
        errors.append("Missing LIMIT clause")

    sql_validated = len(errors) == 0

    if errors:
        log.warning("sql_validation_errors", errors=errors, retry=retry_count)

    return {
        "messages": messages,
        "validation_errors": errors,
        "sql_validated": sql_validated,
        "estimated_cost": estimated_cost,
        "retry_count": retry_count + 1 if errors else retry_count,
    }


@trace_agent_node("sql_approval")
def sql_approval_node(state: AgentState) -> dict:
    """HITL approval gate for SQL execution."""
    from langgraph.types import interrupt

    messages = state.get("messages", [])
    sql = state.get("generated_sql", "")
    require_approval = state.get("require_approval", False)

    if not require_approval:
        return {"messages": messages, "approved": True,
                "approval_explanation": "Auto-approved (dev mode)"}

    explanation = f"Execute SQL: {sql[:200]}"
    user_decision = interrupt({
        "query": state.get("original_query", ""),
        "sql": sql,
        "confidence": state.get("sql_confidence", 0),
        "explanation": explanation,
    })

    approved = user_decision.get("approved", False) if isinstance(user_decision, dict) else False
    return {"messages": messages, "approved": approved,
            "approval_explanation": "Approved by user" if approved else "Rejected by user",
            "status": "processing" if approved else "failed"}


@trace_agent_node("sql_executor")
def sql_executor_node(state: AgentState) -> dict:
    """Execute validated SQL against the warehouse database."""
    sql = state.get("generated_sql", "")
    messages = state.get("messages", [])

    if not sql:
        return {"messages": messages, "error": "No SQL to execute", "status": "failed"}

    is_safe, issues = validate_sql(sql)
    if not is_safe:
        return {"messages": messages, "error": f"SQL blocked: {'; '.join(issues)}", "status": "failed"}

    try:
        results = sql_execute_query(sql, timeout=30)
        clean = []
        for row in results:
            clean_row = {}
            for k, v in row.items():
                clean_row[k] = float(v) if isinstance(v, Decimal) else v
            clean.append(clean_row)

        log.info("sql_executed", rows=len(clean))
        return {"messages": messages, "sql_results": clean}
    except Exception as e:
        log.error("sql_execution_error", error=str(e))
        return {"messages": messages, "error": f"SQL error: {str(e)}", "status": "failed"}


@trace_agent_node("sql_response")
def sql_response_node(state: AgentState) -> dict:
    """Generate natural language explanation of SQL results.

    Uses fast model for simple, heavy model handled upstream.
    """
    query = state.get("rewritten_query", "") or state.get("original_query", "")
    sql = state.get("generated_sql", "")
    results = state.get("sql_results", [])
    messages = state.get("messages", [])
    session_id = state.get("session_id", "")
    complexity = state.get("query_complexity", "moderate")
    start_time = time.time()

    if not results:
        explanation = "The query returned no results."
    elif complexity == "simple" and len(results) <= 3:
        if len(results) == 1 and len(results[0]) == 1:
            val = list(results[0].values())[0]
            explanation = f"The answer is: **{val}**"
        else:
            rows_text = "\n".join([str(r) for r in results[:10]])
            explanation = f"Results ({len(results)} rows):\n{rows_text}"
    else:
        try:
            prompt_meta = get_prompt_with_meta("response_synthesis")
            prompt_template = prompt_meta["template"]
            system_prompt = get_prompt("response_system")
            prompt_version = prompt_meta["version"]

            results_str = json.dumps(results[:10], default=str)
            formatted = prompt_template.format(
                query=query, sql=sql, total_rows=len(results), results=results_str,
            )
            llm = _get_fast_llm()
            response = resilient_call(
                llm.invoke,
                [SystemMessage(content=system_prompt), HumanMessage(content=formatted)],
                circuit=llm_circuit, rate_limiter=llm_rate_limiter,
            )
            explanation = response.content
        except Exception as e:
            explanation = f"Query returned {len(results)} rows. First result: {results[0] if results else 'N/A'}"

    _, pii_issues, sanitized = validate_output(explanation)
    if pii_issues:
        explanation = sanitized

    latency_ms = (time.time() - start_time) * 1000

    # Cache with metadata
    try:
        semantic_cache_set(
            query,
            {"sql": sql, "results": results[:10], "explanation": explanation, "pipeline": "sql"},
            pipeline="sql",
            embedding=state.get("query_embedding"),
            model=settings.groq_fast_model,
        )
    except Exception:
        pass

    # Log to postgres with metadata
    try:
        sql_log_query(query, explanation, "SQL", latency_ms, model=settings.groq_fast_model)
    except Exception:
        pass

    # Save conversation
    try:
        if session_id:
            save_conversation(session_id, "user", state.get("original_query", ""))
            save_conversation(session_id, "assistant", explanation, sql_query=sql)
    except Exception:
        pass

    log.info("sql_response_generated", rows=len(results), latency_ms=round(latency_ms, 1))
    return {
        "messages": messages,
        "sql_explanation": explanation,
        "final_answer": explanation,
        "status": "completed",
    }