"""Pipeline - LangGraph graph builder with LLM-driven Supervisor orchestration.

Architecture: Supervisor (LLM decides) -> Route to RAG / SQL / Action / Compound
  - Pinecone for vector store (rag-base + sql-base indexes)
  - PostgreSQL checkpointing for HITL interrupts
  - Redis vector search for semantic caching
  - Prompt registry for all agent prompts
  - Fast models for routing/ambiguity, heavy models for SQL gen/RAG gen
"""

import concurrent.futures
from langgraph.graph import StateGraph, START, END
from psycopg import Connection
from langgraph.checkpoint.postgres import PostgresSaver
from src.core import get_settings
from src.core.state import AgentState
from src.core.tracing import trace_agent_node
from src.services.guardrails_service import validate_input
from src.services.embedding_service import embed_query
from src.services.memory_service import load_memory
from src.services.cache_service import semantic_cache_get
from src.agents.supervisor_agent import supervisor_intent_node, supervisor_merge_node
from src.agents.rag_agent import rag_domain_router_node, rag_retrieval_node, rag_generator_node
from src.agents.sql_agent import (
    sql_complexity_node, sql_ambiguity_node, sql_schema_node,
    sql_generator_node, sql_validator_node, sql_approval_node,
    sql_executor_node, sql_response_node,
)
from src.agents.react_agent import react_agent_node
import structlog

log = structlog.get_logger()
settings = get_settings()


@trace_agent_node("parallel_init")
def parallel_init_node(state: AgentState) -> dict:
    """Phase 0: Run Input Guard + Embedding + Memory + Cache L1 concurrently."""
    query = state.get("original_query", "")
    session_id = state.get("session_id", "")
    messages = state.get("messages", [])
    merged = {"messages": messages}

    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as executor:
        future_guard = executor.submit(validate_input, query)
        future_embed = executor.submit(embed_query, query)
        future_memory = executor.submit(load_memory, session_id, query)

        try:
            is_safe, issues = future_guard.result(timeout=5)
            merged["input_guard_passed"] = is_safe
            merged["guard_issues"] = issues
            if not is_safe:
                merged["status"] = "failed"
                merged["error"] = f"Input blocked: {'; '.join(issues)}"
                return merged
        except Exception:
            merged["input_guard_passed"] = True
            merged["guard_issues"] = []

        try:
            embedding = future_embed.result(timeout=15)
            merged["query_embedding"] = embedding
            merged["embedding_done"] = True
        except Exception:
            merged["query_embedding"] = []
            merged["embedding_done"] = True

        try:
            memory_data = future_memory.result(timeout=10)
            merged["conversation_history"] = memory_data.get("conversation_history", [])
            merged["conversation_summary"] = memory_data.get("conversation_summary", "")
            merged["history_token_usage"] = memory_data.get("history_token_usage", 0)
        except Exception:
            merged["conversation_history"] = []
            merged["conversation_summary"] = ""
            merged["history_token_usage"] = 0

    # Cache L1 check
    try:
        cached = semantic_cache_get(query, precomputed_embedding=merged.get("query_embedding"))
        if cached:
            merged["cache_hit"] = True
            merged["l1_checked"] = True
            merged["cached_response"] = cached
            if cached.get("pipeline") == "rag":
                merged["rag_answer"] = cached.get("answer", "")
                merged["rag_confidence"] = cached.get("confidence", "MEDIUM")
                merged["final_answer"] = cached.get("answer", "")
            else:
                merged["generated_sql"] = cached.get("sql", "")
                merged["sql_results"] = cached.get("results", [])
                merged["sql_explanation"] = cached.get("explanation", "")
                merged["final_answer"] = cached.get("explanation", "")
            merged["status"] = "completed"
            log.info("cache_l1_hit", query=query[:50])
        else:
            merged["cache_hit"] = False
            merged["l1_checked"] = True
    except Exception:
        merged["cache_hit"] = False
        merged["l1_checked"] = True

    return merged


@trace_agent_node("compound_parallel")
def compound_parallel_node(state: AgentState) -> dict:
    """Execute RAG and SQL pipelines in parallel for compound queries."""
    messages = state.get("messages", [])
    merged = {"messages": messages}

    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as executor:
        def _run_rag():
            s = dict(state)
            r1 = rag_domain_router_node(s)
            s.update(r1)
            r2 = rag_retrieval_node(s)
            s.update(r2)
            r3 = rag_generator_node(s)
            s.update(r3)
            return s

        def _run_sql():
            s = dict(state)
            r1 = sql_complexity_node(s)
            s.update(r1)
            r2 = sql_schema_node(s)
            s.update(r2)
            r3 = sql_generator_node(s)
            s.update(r3)
            if s.get("generated_sql") and s.get("status") != "failed":
                r4 = sql_validator_node(s)
                s.update(r4)
                if s.get("sql_validated"):
                    r5 = sql_executor_node(s)
                    s.update(r5)
                    r6 = sql_response_node(s)
                    s.update(r6)
            return s

        future_rag = executor.submit(_run_rag)
        future_sql = executor.submit(_run_sql)

        try:
            rag_state = future_rag.result(timeout=300)
            merged["rag_answer"] = rag_state.get("rag_answer", "")
            merged["rag_confidence"] = rag_state.get("rag_confidence", "")
            merged["rag_sources"] = rag_state.get("rag_sources", [])
        except Exception as e:
            log.warning("compound_rag_failed", error=str(e))
            merged["rag_answer"] = ""

        try:
            sql_state = future_sql.result(timeout=300)
            merged["sql_explanation"] = sql_state.get("sql_explanation", "")
            merged["generated_sql"] = sql_state.get("generated_sql", "")
            merged["sql_results"] = sql_state.get("sql_results", [])
        except Exception as e:
            log.warning("compound_sql_failed", error=str(e))
            merged["sql_explanation"] = ""

    return merged


@trace_agent_node("respond_from_cache")
def respond_from_cache_node(state: AgentState) -> dict:
    return {
        "messages": state.get("messages", []),
        "final_answer": state.get("final_answer", ""),
        "status": "completed",
        "cache_hit": True,
    }


@trace_agent_node("sql_cache_l2")
def sql_cache_l2_node(state: AgentState) -> dict:
    """L2 Cache: check rewritten query after ambiguity resolution."""
    rewritten = state.get("rewritten_query", "")
    original = state.get("original_query", "")
    messages = state.get("messages", [])
    embedding = state.get("query_embedding", [])

    lookup = rewritten if rewritten else original
    if not lookup:
        return {"messages": messages, "l2_hit": False}

    try:
        cached = semantic_cache_get(lookup, precomputed_embedding=embedding)
        if not cached and lookup != original:
            cached = semantic_cache_get(original, precomputed_embedding=embedding)

        if cached:
            log.info("sql_cache_l2_hit")
            return {
                "messages": messages, "l2_hit": True, "cache_hit": True,
                "cached_response": cached,
                "generated_sql": cached.get("sql", ""),
                "sql_results": cached.get("results", []),
                "sql_explanation": cached.get("explanation", ""),
                "final_answer": cached.get("explanation", ""),
                "status": "completed",
            }
    except Exception:
        pass

    return {"messages": messages, "l2_hit": False}


@trace_agent_node("sql_validation_failed")
def sql_validation_failed_node(state: AgentState) -> dict:
    errors = state.get("validation_errors", [])
    return {
        "messages": state.get("messages", []),
        "status": "failed",
        "error": f"SQL validation failed: {'; '.join(errors)}",
    }


# ---------------------------------------------------------------------------
# CONDITIONAL EDGE ROUTERS
# ---------------------------------------------------------------------------

def after_parallel_init(state: AgentState) -> str:
    if state.get("status") == "failed":
        return END
    if state.get("cache_hit") and state.get("final_answer"):
        return "respond_from_cache"
    return "supervisor_intent"


def after_supervisor(state: AgentState) -> str:
    intent = state.get("intent", "sql")
    if intent == "rag":
        return "rag_domain_router"
    elif intent == "action":
        return "react_agent"
    elif intent == "compound":
        return "compound_parallel"
    return "sql_complexity"


def after_rag_generator(state: AgentState) -> str:
    return END


def after_compound(state: AgentState) -> str:
    return "supervisor_merge"


def after_react(state: AgentState) -> str:
    status = state.get("status", "processing")
    if status in ("completed", "failed", "action_rejected"):
        return END
    return "react_agent"


def after_sql_complexity(state: AgentState) -> str:
    complexity = state.get("query_complexity", "moderate")
    if complexity == "simple":
        return "sql_cache_l2"
    return "sql_ambiguity"


def after_sql_ambiguity(state: AgentState) -> str:
    status = state.get("status", "processing")
    if status in ("awaiting_clarification", "failed"):
        return END
    return "sql_cache_l2"


def after_sql_cache_l2(state: AgentState) -> str:
    if state.get("l2_hit") and state.get("final_answer"):
        return "respond_from_cache"
    return "sql_schema"


def after_sql_gen(state: AgentState) -> str:
    if state.get("status") == "failed" or not state.get("generated_sql"):
        return END
    return "sql_validator"


def after_sql_validation(state: AgentState) -> str:
    errors = state.get("validation_errors", [])
    retry = state.get("retry_count", 0)
    if errors:
        if retry < settings.max_retries:
            return "sql_generator"
        return "sql_validation_failed"
    return "sql_approval"


def after_sql_approval(state: AgentState) -> str:
    if state.get("approved") is False or state.get("status") == "failed":
        return END
    return "sql_executor"


def after_sql_execution(state: AgentState) -> str:
    if state.get("status") == "failed" or state.get("error"):
        retry = state.get("retry_count", 0)
        if retry < settings.max_retries:
            return "sql_generator"
        return END
    return "sql_response"


# ---------------------------------------------------------------------------
# BUILD THE GRAPH
# ---------------------------------------------------------------------------

def build_graph():
    """Build the unified multi-agent graph with PostgreSQL checkpointer."""
    graph = StateGraph(AgentState)

    graph.add_node("parallel_init", parallel_init_node)
    graph.add_node("respond_from_cache", respond_from_cache_node)
    graph.add_node("supervisor_intent", supervisor_intent_node)
    graph.add_node("supervisor_merge", supervisor_merge_node)
    graph.add_node("rag_domain_router", rag_domain_router_node)
    graph.add_node("rag_retrieval", rag_retrieval_node)
    graph.add_node("rag_generator", rag_generator_node)
    graph.add_node("sql_complexity", sql_complexity_node)
    graph.add_node("sql_ambiguity", sql_ambiguity_node)
    graph.add_node("sql_cache_l2", sql_cache_l2_node)
    graph.add_node("sql_schema", sql_schema_node)
    graph.add_node("sql_generator", sql_generator_node)
    graph.add_node("sql_validator", sql_validator_node)
    graph.add_node("sql_validation_failed", sql_validation_failed_node)
    graph.add_node("sql_approval", sql_approval_node)
    graph.add_node("sql_executor", sql_executor_node)
    graph.add_node("sql_response", sql_response_node)
    graph.add_node("react_agent", react_agent_node)
    graph.add_node("compound_parallel", compound_parallel_node)

    graph.add_edge(START, "parallel_init")

    graph.add_conditional_edges("parallel_init", after_parallel_init, {
        END: END,
        "respond_from_cache": "respond_from_cache",
        "supervisor_intent": "supervisor_intent",
    })

    graph.add_edge("respond_from_cache", END)

    graph.add_conditional_edges("supervisor_intent", after_supervisor, {
        "rag_domain_router": "rag_domain_router",
        "sql_complexity": "sql_complexity",
        "react_agent": "react_agent",
        "compound_parallel": "compound_parallel",
    })

    graph.add_edge("rag_domain_router", "rag_retrieval")
    graph.add_edge("rag_retrieval", "rag_generator")
    graph.add_edge("rag_generator", END)

    graph.add_conditional_edges("sql_complexity", after_sql_complexity)
    graph.add_conditional_edges("sql_ambiguity", after_sql_ambiguity)
    graph.add_conditional_edges("sql_cache_l2", after_sql_cache_l2)
    graph.add_edge("sql_schema", "sql_generator")
    graph.add_conditional_edges("sql_generator", after_sql_gen)
    graph.add_conditional_edges("sql_validator", after_sql_validation)
    graph.add_edge("sql_validation_failed", END)
    graph.add_conditional_edges("sql_approval", after_sql_approval)
    graph.add_conditional_edges("sql_executor", after_sql_execution)
    graph.add_edge("sql_response", END)

    graph.add_conditional_edges("react_agent", after_react, {
        "react_agent": "react_agent",
        END: END,
    })

    graph.add_conditional_edges("compound_parallel", after_compound)
    graph.add_edge("supervisor_merge", END)

    # PostgreSQL checkpointer (not in-memory)
    db_url = settings.sql_database_url_sync
    conn = Connection.connect(db_url, autocommit=True, prepare_threshold=0)
    checkpointer = PostgresSaver(conn)
    checkpointer.setup()

    return graph.compile(checkpointer=checkpointer)