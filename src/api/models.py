"""Pydantic models for API request/response."""

from pydantic import BaseModel, Field
from typing import Optional


class QueryRequest(BaseModel):
    query: str = Field(..., min_length=1, max_length=2000)
    session_id: str = Field(default="default")
    require_approval: bool = Field(default=False)


class ClarifyOption(BaseModel):
    index: int
    query: str
    reason: str = ""


class ClarifyRequest(BaseModel):
    session_id: str
    selected_query: str
    thread_id: str = ""


class ApproveRequest(BaseModel):
    session_id: str
    approved: bool
    feedback: str = ""
    thread_id: str = ""


class ActionApproveRequest(BaseModel):
    session_id: str
    approved: bool
    feedback: str = ""
    thread_id: str = ""


class FeedbackRequest(BaseModel):
    session_id: str = ""
    run_id: str = ""
    query: str = ""
    rating: int = Field(..., ge=-1, le=1)
    comment: str = ""
    correction: str = ""
    generated_sql: str = ""
    pipeline: str = "sql"


class DocumentChunk(BaseModel):
    content: str = Field(..., min_length=1, max_length=10000)
    source: str = ""
    metadata: dict = {}


class DocumentUploadRequest(BaseModel):
    domain: str = Field(..., description="Domain tag: HR, PRODUCT, AI, etc.")
    chunks: list[DocumentChunk] = Field(..., min_length=1)
    source: str = Field(default="", description="Source file name")


class DocumentUploadResponse(BaseModel):
    status: str = "ok"
    domain: str = ""
    chunks_uploaded: int = 0
    message: str = ""


class QueryResponse(BaseModel):
    status: str = "processing"
    intent: str = ""
    detected_domains: list[str] = []
    final_answer: str = ""

    # RAG fields
    rag_answer: str = ""
    rag_confidence: str = ""
    rag_sources: list[str] = []

    # SQL fields
    generated_sql: str = ""
    sql_results: list[dict] = []
    sql_explanation: str = ""
    sql_confidence: float = 0.0
    query_complexity: str = ""
    tables_used: list[str] = []
    estimated_cost: str = ""

    # Action fields
    react_steps: list[dict] = []
    react_result: str = ""
    pending_tool_call: dict = {}

    # Ambiguity
    is_ambiguous: bool = False
    clarification_message: str = ""
    clarification_options: list[dict] = []

    # Cache
    cache_hit: bool = False

    # Control
    error: str = ""
    run_id: str = ""
    thread_id: str = ""

    # Tracing
    decision_trace: list[dict] = []
