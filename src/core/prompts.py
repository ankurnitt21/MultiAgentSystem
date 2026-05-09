"""Dynamic Prompt Registry - stored in PostgreSQL with versioning.

All agent prompts are fetched from the registry at runtime.
No hardcoded prompts - everything comes from the database.
Logs prompt version, model, and parameters used for every execution.
"""

import time
from sqlalchemy import text
from src.core.database import SQLSession
import structlog

log = structlog.get_logger()

_prompt_cache: dict = {}
_cache_ts: float = 0
_CACHE_TTL = 300  # 5 minutes


def _ensure_prompt_table():
    with SQLSession() as session:
        session.execute(text("""
            CREATE TABLE IF NOT EXISTS prompt_template (
                id BIGSERIAL PRIMARY KEY,
                name VARCHAR(100) UNIQUE NOT NULL,
                version INTEGER DEFAULT 1,
                template TEXT NOT NULL,
                description TEXT,
                model_hint VARCHAR(50) DEFAULT 'fast',
                is_active BOOLEAN DEFAULT TRUE,
                created_at TIMESTAMP DEFAULT NOW(),
                updated_at TIMESTAMP DEFAULT NOW()
            )
        """))
        session.commit()


def seed_default_prompts():
    """Seed default prompts for the unified system."""
    _ensure_prompt_table()
    with SQLSession() as session:
        prompts = [
            (
                "supervisor_intent", 1,
                """You classify user queries into exactly one intent category.

Categories:
- "rag" - User wants to READ knowledge from documents: policies, benefits, product info, FAQs, how-to guides.
  Examples: "What are leave benefits?", "Explain our return policy", "How does product X work?"

- "sql" - User wants to QUERY structured data: reports, counts, listings, analytics from database tables.
  Examples: "Show top 5 products by price", "How many orders today?", "List pending shipments"

- "action" - User wants to MUTATE data or trigger a process: create, update, notify, sync, send, cancel.
  Examples: "Create a purchase order for product 5", "Notify supplier 3", "Update shipment to SHIPPED"

- "compound" - User asks about BOTH documents AND data in the same query.
  Examples: "What is the leave policy and show me pending leave requests?"

Reply with ONLY JSON:
{"intent": "rag|sql|action|compound", "confidence": 0.0-1.0, "detected_domains": ["HR"|"PRODUCT"|"AI"|"SQL"|"ACTION"]}
No explanation. No markdown.""",
                "Supervisor intent detection", "fast",
            ),
            (
                "domain_router", 1,
                """You are a domain router for a knowledge base with these domains:
- HR: Leave policies, benefits, compensation, employee handbook, HR procedures
- PRODUCT: Product catalog, pricing, features, specifications, comparisons
- AI: AI/ML concepts, GenAI, LangChain, RAG, prompt engineering, LLM topics

Given the user query, determine:
1. Which domain to search
2. A rewritten sub-question optimized for retrieval

Reply with ONLY JSON:
{"domain": "HR|PRODUCT|AI", "sub_question": "optimized search query", "confidence": 0.0-1.0}
No explanation. No markdown.""",
                "RAG domain routing prompt", "fast",
            ),
            (
                "rag_generation", 1,
                """You are a knowledgeable assistant. Answer the user's question using ONLY the provided context.

Rules:
- If the context doesn't contain the answer, say "I don't have enough information to answer this."
- Cite sources when available
- Be concise but thorough (2-4 sentences for simple questions, more for complex)
- Rate your confidence: HIGH (directly answered), MEDIUM (partially), LOW (inferred)

Context:
{context}

Conversation History:
{history}

Question: {query}

Provide your answer in JSON format:
{{"answer": "your answer here", "confidence": "HIGH|MEDIUM|LOW", "sources": ["source1", "source2"]}}""",
                "RAG answer generation with context", "heavy",
            ),
            (
                "complexity_detection", 1,
                """Classify the following query complexity for SQL generation against a warehouse database.

Reply with ONLY JSON: {"complexity": "simple"} or {"complexity": "moderate"} or {"complexity": "complex"}

simple = single table lookups, counts, direct data retrieval
moderate = multi-table joins, filtering with conditions
complex = aggregations with grouping, subqueries, temporal analysis

No explanation. No markdown.""",
                "Complexity detection", "fast",
            ),
            (
                "ambiguity_resolution", 1,
                """You are an ambiguity resolution agent for a warehouse management SQL system.

Your job:
1. Determine if the user's query is ambiguous or unclear for SQL generation
2. If CLEAR: set is_ambiguous=false and rewrite as a clearer natural language question
3. If AMBIGUOUS: set is_ambiguous=true and provide 2-3 likely interpretations as suggestions

Context from conversation history (use this to infer intent if available):
{history_context}

Rules:
- If conversation history exists and helps clarify, use it to infer intent
- If ambiguous with history: provide interpretations based on context
- If ambiguous without useful history: ask for clarification directly
- Always prefer clarification over wrong assumptions
- Keep suggestions concise and context-aware
- Most queries are CLEAR. Only flag as ambiguous if truly impossible to answer.

Call resolve_ambiguity with your determination.""",
                "Ambiguity resolution prompt", "fast",
            ),
            (
                "sql_generation", 1,
                """Generate a PostgreSQL SELECT for a warehouse DB.
Rules: exact table/column names from schema, LIMIT <=50, proper JOINs via FK, no SELECT *.
Schema: {schema}
Question: {query}
{context}
Call generate_sql tool with sql, confidence, tables_used, reasoning.""",
                "SQL generation prompt", "heavy",
            ),
            (
                "response_synthesis", 1,
                """Explain SQL results concisely (2-3 sentences). Highlight key insights.
Question: {query}
SQL: {sql}
Results ({total_rows} rows, first 10): {results}""",
                "Response synthesis prompt", "fast",
            ),
            (
                "response_system", 1,
                """You are a data analyst for a warehouse management system. Explain SQL query results concisely in 2-3 sentences. Highlight key insights, trends, or notable values. Use natural language that a business user would understand.""",
                "Response agent system message", "fast",
            ),
            (
                "memory_summarization", 1,
                """You are a conversation summarizer for a multi-agent assistant.
Create a concise summary that captures key information from the conversation.
Preserve: entities mentioned, queries asked, results discussed, user preferences.
Keep it under 500 words. Focus on facts that would help answer future questions.""",
                "Memory summarization system prompt", "fast",
            ),
            (
                "sql_self_consistency", 1,
                """You verify if a generated SQL query correctly answers the user's natural language question.
Reply with ONLY JSON: {"aligned": true, "penalty": 0.0} if SQL matches the question.
Or {"aligned": false, "penalty": 0.15, "reason": "brief reason"} if misaligned.
No explanation outside JSON. No markdown.""",
                "SQL self-consistency check", "fast",
            ),
            (
                "react_system", 1,
                """{tools_prompt}

You are a warehouse management action agent. Execute actions requested by the user.

REACT LOOP RULES:
1. Analyze the user request and any previous tool results.
2. Decide: call a tool OR done?
3. Reply with ONLY valid JSON.

If you need to call a tool:
{{"action": "call_tool", "tool_name": "<name>", "tool_args": {{...}}, "reasoning": "..."}}

If done:
{{"action": "done", "summary": "concise summary of what was accomplished"}}

Maximum steps: {max_steps}""",
                "ReAct agent system prompt", "heavy",
            ),
            (
                "supervisor_merge", 1,
                """Merge results from two pipelines into a unified response.

RAG Result (from knowledge base):
{rag_result}

SQL Result (from database):
{sql_result}

Create a unified, coherent response that combines both sources. Be concise.""",
                "Supervisor merge prompt for compound queries", "fast",
            ),
        ]

        for p in prompts:
            name, version, template, description, model_hint = p
            existing = session.execute(
                text("SELECT id FROM prompt_template WHERE name = :name"),
                {"name": name}
            ).fetchone()
            if not existing:
                session.execute(text(
                    "INSERT INTO prompt_template (name, version, template, description, model_hint) "
                    "VALUES (:name, :version, :template, :description, :model_hint)"
                ), {"name": name, "version": version, "template": template,
                    "description": description, "model_hint": model_hint})

        session.commit()
    log.info("prompts_seeded")


def get_prompt(name: str, version: int = None) -> str:
    """Retrieve active prompt template by name.

    Always fetch from registry. Uses "active" version unless overridden.
    """
    global _prompt_cache, _cache_ts

    cache_key = f"{name}:v{version}" if version else name

    if time.time() - _cache_ts < _CACHE_TTL and cache_key in _prompt_cache:
        return _prompt_cache[cache_key]["template"]

    with SQLSession() as session:
        if version:
            result = session.execute(text(
                "SELECT template, version, model_hint FROM prompt_template "
                "WHERE name = :name AND version = :version"
            ), {"name": name, "version": version})
        else:
            result = session.execute(text(
                "SELECT template, version, model_hint FROM prompt_template "
                "WHERE name = :name AND is_active = TRUE ORDER BY version DESC LIMIT 1"
            ), {"name": name})

        row = result.fetchone()
        if row:
            _prompt_cache[cache_key] = {
                "template": row[0],
                "version": row[1],
                "model_hint": row[2] if len(row) > 2 else "fast",
            }
            _cache_ts = time.time()
            log.info("prompt_loaded", name=name, version=row[1])
            return row[0]

    raise ValueError(f"Prompt '{name}' not found in registry")


def get_prompt_with_meta(name: str, version: int = None) -> dict:
    """Retrieve prompt template with metadata (version, model_hint).

    Returns: {"template": str, "version": int, "model_hint": str}
    """
    global _prompt_cache, _cache_ts

    cache_key = f"{name}:v{version}" if version else name

    if time.time() - _cache_ts < _CACHE_TTL and cache_key in _prompt_cache:
        return _prompt_cache[cache_key]

    template = get_prompt(name, version)
    return _prompt_cache.get(cache_key, {"template": template, "version": 1, "model_hint": "fast"})


def list_prompts() -> list[dict]:
    """List all stored prompts."""
    with SQLSession() as session:
        result = session.execute(text(
            "SELECT name, version, description, model_hint, is_active, updated_at "
            "FROM prompt_template ORDER BY name"
        ))
        return [dict(zip(result.keys(), row)) for row in result.fetchall()]