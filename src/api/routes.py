"""FastAPI routes for the Unified Multi-Agent System.

Endpoints:
  POST /api/query          - Execute query (sync)
  POST /api/query/stream   - Execute query (SSE streaming)
  POST /api/clarify        - Handle ambiguity clarification
  POST /api/approve        - SQL approval (HITL)
  POST /api/action/approve - ReAct tool approval (HITL)
  POST /api/feedback       - Submit user feedback
  GET  /api/feedback/stats - Feedback statistics
  GET  /api/prompts        - List all prompts
  GET  /api/action/tools   - List available action tools
  GET  /health             - Health check
"""

import uuid
import json
import time
import threading
from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse
from langgraph.types import Command
from src.api.models import (
    QueryRequest, QueryResponse, ClarifyRequest,
    ApproveRequest, ActionApproveRequest, FeedbackRequest,
    DocumentUploadRequest, DocumentUploadResponse,
)
from src.agents.pipeline import build_graph
from src.core.tracing import get_tracer, set_pipeline_context, clear_pipeline_context
from src.core.prompts import list_prompts
from src.agents.action_tools import TOOL_DESCRIPTIONS
from src.services.feedback_service import save_feedback, get_feedback_stats
from src.services.ragas_service import evaluate_faithfulness
from src.services.pinecone_service import rag_upsert_documents
from opentelemetry import trace, context as otel_context
import structlog

log = structlog.get_logger()
router = APIRouter()

# ── Graph singleton ──
_graph = None
_graph_lock = threading.Lock()


def _get_graph():
    global _graph
    if _graph is None:
        with _graph_lock:
            if _graph is None:
                _graph = build_graph()
                log.info("graph_built")
    return _graph


# ═══════════════════════════════════════════════════════════════════════════
# POST /api/query - Synchronous execution
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/api/query", response_model=QueryResponse)
async def execute_query(req: QueryRequest):
    """Execute a query through the unified multi-agent pipeline."""
    graph = _get_graph()
    thread_id = f"{req.session_id}-{uuid.uuid4().hex[:8]}"
    run_id = str(uuid.uuid4())

    tracer = get_tracer()
    with tracer.start_as_current_span("unified_pipeline") as root_span:
        root_span.set_attribute("langsmith.span.kind", "agent")
        root_span.set_attribute("input.value", req.query[:500])
        root_span.set_attribute("run_id", run_id)
        root_span.set_attribute("session_id", req.session_id)
        ctx = otel_context.get_current()
        set_pipeline_context(req.session_id, ctx)

        try:
            config = {"configurable": {"thread_id": thread_id}}
            initial_state = {
                "messages": [],
                "original_query": req.query,
                "session_id": req.session_id,
                "require_approval": req.require_approval,
                "status": "processing",
                "intent": "",
                "retry_count": 0,
                "react_steps": [],
                "pending_tool_call": {},
                "decision_trace": [],
                "detected_domains": [],
            }

            start = time.time()
            final_state = None
            for event in graph.stream(initial_state, config=config, stream_mode="values"):
                final_state = event

            latency_ms = (time.time() - start) * 1000
            root_span.set_attribute("latency_ms", latency_ms)

            if final_state is None:
                final_state = initial_state

            # Async RAGAS evaluation (non-blocking)
            _async_ragas(final_state, run_id)

            response = _build_response(final_state, run_id, thread_id)
            root_span.set_attribute("output.value", response.final_answer[:500])
            root_span.set_attribute("output.status", response.status)
            root_span.set_attribute("output.intent", response.intent)
            return response

        except Exception as e:
            root_span.set_status(trace.Status(trace.StatusCode.ERROR, str(e)[:200]))
            log.error("query_failed", error=str(e))
            raise HTTPException(status_code=500, detail=str(e))
        finally:
            clear_pipeline_context(req.session_id)


# ═══════════════════════════════════════════════════════════════════════════
# POST /api/query/stream - SSE streaming
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/api/query/stream")
async def stream_query(req: QueryRequest):
    """Stream pipeline execution step-by-step via SSE."""
    graph = _get_graph()
    thread_id = f"{req.session_id}-{uuid.uuid4().hex[:8]}"
    run_id = str(uuid.uuid4())

    def _generate():
        tracer = get_tracer()
        with tracer.start_as_current_span("unified_pipeline_stream") as root_span:
            root_span.set_attribute("input.value", req.query[:500])
            ctx = otel_context.get_current()
            set_pipeline_context(req.session_id, ctx)

            try:
                config = {"configurable": {"thread_id": thread_id}}
                initial_state = {
                    "messages": [],
                    "original_query": req.query,
                    "session_id": req.session_id,
                    "require_approval": req.require_approval,
                    "status": "processing",
                    "intent": "",
                    "retry_count": 0,
                    "react_steps": [],
                    "pending_tool_call": {},
                    "decision_trace": [],
                    "detected_domains": [],
                }

                final_state = None
                for event in graph.stream(initial_state, config=config, stream_mode="updates"):
                    for node_name, node_output in event.items():
                        step_data = {
                            "node": node_name,
                            "status": node_output.get("status", "processing"),
                            "intent": node_output.get("intent", ""),
                            "cache_hit": node_output.get("cache_hit", False),
                        }

                        # Include relevant data based on node
                        if node_output.get("rag_answer"):
                            step_data["rag_answer"] = node_output["rag_answer"][:500]
                        if node_output.get("generated_sql"):
                            step_data["sql"] = node_output["generated_sql"]
                        if node_output.get("sql_explanation"):
                            step_data["sql_explanation"] = node_output["sql_explanation"][:500]
                        if node_output.get("final_answer"):
                            step_data["final_answer"] = node_output["final_answer"][:500]
                        if node_output.get("error"):
                            step_data["error"] = node_output["error"][:300]
                        if node_output.get("is_ambiguous"):
                            step_data["is_ambiguous"] = True
                            step_data["clarification_message"] = node_output.get("clarification_message", "")
                            step_data["clarification_options"] = node_output.get("clarification_options", [])
                        if node_output.get("react_steps"):
                            step_data["react_steps"] = node_output["react_steps"]
                        if node_output.get("pending_tool_call"):
                            step_data["pending_tool_call"] = node_output["pending_tool_call"]

                        yield f"data: {json.dumps(step_data, default=str)}\n\n"
                        final_state = node_output

                # Final event
                if final_state:
                    response = _build_response(final_state, run_id, thread_id)
                    yield f"data: {json.dumps({'node': 'DONE', 'response': response.model_dump()}, default=str)}\n\n"

            except Exception as e:
                yield f"data: {json.dumps({'node': 'ERROR', 'error': str(e)})}\n\n"
            finally:
                clear_pipeline_context(req.session_id)

    return StreamingResponse(_generate(), media_type="text/event-stream")


# ═══════════════════════════════════════════════════════════════════════════
# POST /api/clarify - Ambiguity clarification
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/api/clarify", response_model=QueryResponse)
async def clarify_query(req: ClarifyRequest):
    """Re-run pipeline with clarified query."""
    return await execute_query(QueryRequest(
        query=req.selected_query,
        session_id=req.session_id,
    ))


# ═══════════════════════════════════════════════════════════════════════════
# POST /api/approve - SQL Approval (HITL)
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/api/approve", response_model=QueryResponse)
async def approve_sql(req: ApproveRequest):
    """Resume pipeline after SQL approval."""
    graph = _get_graph()
    thread_id = req.thread_id

    if not thread_id:
        raise HTTPException(status_code=400, detail="thread_id required for approval")

    try:
        config = {"configurable": {"thread_id": thread_id}}
        resume_cmd = Command(resume={"approved": req.approved, "feedback": req.feedback})

        final_state = None
        for event in graph.stream(resume_cmd, config=config, stream_mode="values"):
            final_state = event

        if final_state is None:
            raise HTTPException(status_code=500, detail="No state after resume")

        return _build_response(final_state, "", thread_id)

    except Exception as e:
        log.error("approve_failed", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))


# ═══════════════════════════════════════════════════════════════════════════
# POST /api/action/approve - ReAct Tool Approval
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/api/action/approve", response_model=QueryResponse)
async def approve_action(req: ActionApproveRequest):
    """Resume ReAct agent after tool approval."""
    graph = _get_graph()
    thread_id = req.thread_id

    if not thread_id:
        raise HTTPException(status_code=400, detail="thread_id required")

    try:
        config = {"configurable": {"thread_id": thread_id}}
        resume_cmd = Command(resume={"approved": req.approved, "feedback": req.feedback})

        final_state = None
        for event in graph.stream(resume_cmd, config=config, stream_mode="values"):
            final_state = event

        if final_state is None:
            raise HTTPException(status_code=500, detail="No state after resume")

        return _build_response(final_state, "", thread_id)

    except Exception as e:
        log.error("action_approve_failed", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))


# ═══════════════════════════════════════════════════════════════════════════
# POST /api/feedback - User Feedback
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/api/feedback")
async def submit_feedback(req: FeedbackRequest):
    """Submit thumbs up/down feedback."""
    save_feedback(
        session_id=req.session_id, run_id=req.run_id, query=req.query,
        rating=req.rating, comment=req.comment, correction=req.correction,
        generated_sql=req.generated_sql, pipeline=req.pipeline,
    )
    return {"status": "ok"}


@router.get("/api/feedback/stats")
async def feedback_stats():
    """Get feedback statistics."""
    return get_feedback_stats()


# ═══════════════════════════════════════════════════════════════════════════
# GET endpoints
# ═══════════════════════════════════════════════════════════════════════════

@router.get("/api/prompts")
async def get_prompts():
    """List all DB-stored prompt templates."""
    return list_prompts()


@router.get("/api/action/tools")
async def get_action_tools():
    """List available action tools."""
    return TOOL_DESCRIPTIONS


# ═══════════════════════════════════════════════════════════════════════════
# POST /api/documents/upload - RAG Document Upload
# ═══════════════════════════════════════════════════════════════════════════

@router.post("/api/documents/upload", response_model=DocumentUploadResponse)
async def upload_documents(req: DocumentUploadRequest):
    """Upload document chunks to Pinecone rag-base index under a domain namespace.

    The domain tag determines the Pinecone namespace for scoped retrieval.
    Supported domains: HR, PRODUCT, AI (or any custom domain).
    """
    domain = req.domain.upper().strip()
    if not domain:
        raise HTTPException(status_code=400, detail="domain is required")

    chunks = []
    for i, chunk in enumerate(req.chunks):
        chunks.append({
            "content": chunk.content,
            "source": chunk.source or req.source or "api_upload",
            "chunk_index": i,
            "metadata": chunk.metadata,
        })

    try:
        rag_upsert_documents(chunks, domain)
        log.info("documents_uploaded", domain=domain, count=len(chunks))
        return DocumentUploadResponse(
            status="ok",
            domain=domain,
            chunks_uploaded=len(chunks),
            message=f"Uploaded {len(chunks)} chunks to domain '{domain}'",
        )
    except Exception as e:
        log.error("document_upload_failed", domain=domain, error=str(e))
        raise HTTPException(status_code=500, detail=f"Upload failed: {str(e)}")


@router.get("/health")
async def health():
    """Health check."""
    return {"status": "healthy", "service": "UnifiedMultiAgentSystem", "version": "1.0.0"}


# ═══════════════════════════════════════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════════════════════════════════════

def _build_response(state: dict, run_id: str, thread_id: str) -> QueryResponse:
    """Build QueryResponse from final graph state."""
    return QueryResponse(
        status=state.get("status", "completed"),
        intent=state.get("intent", ""),
        detected_domains=state.get("detected_domains", []),
        final_answer=state.get("final_answer", "") or state.get("rag_answer", "") or state.get("sql_explanation", "") or state.get("react_result", ""),
        rag_answer=state.get("rag_answer", ""),
        rag_confidence=state.get("rag_confidence", ""),
        rag_sources=state.get("rag_sources", []),
        generated_sql=state.get("generated_sql", ""),
        sql_results=state.get("sql_results", []),
        sql_explanation=state.get("sql_explanation", ""),
        sql_confidence=state.get("sql_confidence", 0.0),
        query_complexity=state.get("query_complexity", ""),
        tables_used=state.get("tables_used", []),
        estimated_cost=state.get("estimated_cost", ""),
        react_steps=state.get("react_steps", []),
        react_result=state.get("react_result", ""),
        pending_tool_call=state.get("pending_tool_call", {}),
        is_ambiguous=state.get("is_ambiguous", False),
        clarification_message=state.get("clarification_message", ""),
        clarification_options=state.get("clarification_options", []),
        cache_hit=state.get("cache_hit", False),
        error=state.get("error", ""),
        run_id=run_id,
        thread_id=thread_id,
        decision_trace=state.get("decision_trace", []),
    )


def _async_ragas(state: dict, run_id: str):
    """Non-blocking RAGAS evaluation."""
    rag_answer = state.get("rag_answer", "")
    chunks = state.get("rag_fused_results", [])

    if not rag_answer or not chunks:
        return

    def _eval():
        try:
            context = "\n".join([c.get("content", "") for c in chunks[:5]])
            score = evaluate_faithfulness(
                state.get("original_query", ""), rag_answer, context
            )
            if score is not None:
                from src.core.database import sql_log_query
                sql_log_query(
                    state.get("original_query", ""), rag_answer,
                    state.get("rag_domain", ""), 0, state.get("rag_confidence", ""),
                    ragas_faithfulness=score,
                )
        except Exception as e:
            log.debug("async_ragas_failed", error=str(e))

    threading.Thread(target=_eval, daemon=True).start()
