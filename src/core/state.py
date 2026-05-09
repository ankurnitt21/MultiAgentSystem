"""LangGraph Agent State for the unified multi-agent system.

Combines RAG state + SQL state + Action state under one TypedDict.
The supervisor decides which pipeline to invoke based on intent.
"""

from __future__ import annotations
from typing import TypedDict, Literal
from langgraph.graph import MessagesState


class AgentState(MessagesState):
    """Unified state for RAG + SQL + Action pipelines.

    The supervisor agent routes to the appropriate pipeline(s) based on intent.
    Supports parallel execution of RAG and SQL when compound intent is detected.
    """

    # ─── Session ─────────────────────────────────────────────────────────
    session_id: str
    original_query: str

    # ─── Intent Detection ────────────────────────────────────────────────
    intent: str                        # "rag" | "sql" | "action" | "compound"
    detected_domains: list[str]        # ["HR", "PRODUCT", "SQL", "ACTION"]
    intent_confidence: float

    # ─── Memory & History ────────────────────────────────────────────────
    conversation_history: list[dict]
    conversation_summary: str
    history_token_usage: int

    # ─── Embedding ───────────────────────────────────────────────────────
    query_embedding: list[float]
    embedding_done: bool

    # ─── Guardrails ──────────────────────────────────────────────────────
    input_guard_passed: bool
    guard_issues: list[str]

    # ─── Cache ───────────────────────────────────────────────────────────
    cache_hit: bool
    l1_checked: bool
    l2_hit: bool
    cached_response: dict

    # ─── RAG Pipeline ────────────────────────────────────────────────────
    rag_domain: str                    # Routed domain (HR, PRODUCT, AI)
    rag_sub_question: str              # Rewritten sub-question for domain
    rag_retrieved_chunks: list[dict]   # Retrieved document chunks
    rag_vector_results: list[dict]     # Raw vector search results
    rag_bm25_results: list[dict]       # Raw BM25 search results
    rag_fused_results: list[dict]      # After RRF fusion
    rag_answer: str                    # LLM-generated answer
    rag_confidence: str                # HIGH / MEDIUM / LOW
    rag_sources: list[str]

    # ─── SQL Pipeline ────────────────────────────────────────────────────
    rewritten_query: str
    is_ambiguous: bool
    ambiguity_score: float
    rewrite_confidence: float
    clarification_message: str
    clarification_options: list[dict]
    schema_context: str
    tables_used: list[str]
    schema_relationships: list[str]
    generated_sql: str
    sql_confidence: float
    validation_errors: list[str]
    retry_count: int
    sql_validated: bool
    estimated_cost: str
    sql_results: list[dict]
    sql_explanation: str
    query_complexity: str              # "simple" | "moderate" | "complex"

    # ─── Action Pipeline (ReAct) ─────────────────────────────────────────
    react_steps: list[dict]
    react_result: str
    pending_tool_call: dict

    # ─── Approval (HITL) ────────────────────────────────────────────────
    require_approval: bool
    approved: bool
    approval_explanation: str

    # ─── Response ────────────────────────────────────────────────────────
    final_answer: str                  # Merged final answer
    structured_output: dict

    # ─── Control ─────────────────────────────────────────────────────────
    status: Literal[
        "processing",
        "completed",
        "failed",
        "awaiting_approval",
        "awaiting_clarification",
        "awaiting_tool_approval",
        "action_rejected",
    ]
    error: str
    next_agent: str

    # ─── Decision Tracing ────────────────────────────────────────────────
    decision_trace: list[dict]
