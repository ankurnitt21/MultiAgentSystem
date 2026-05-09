"""RAG Agent - Retrieval-Augmented Generation pipeline using Pinecone.

Flow: Domain Routing (LLM) -> Pinecone Namespace Search -> Output Guard -> LLM Generation -> PII Guard -> Cache Write
Uses domain as Pinecone namespace for scoped retrieval.
Heavy model for generation, fast model for domain routing.
"""

import json
import time
import concurrent.futures
from langchain_core.messages import SystemMessage, HumanMessage
from langchain_groq import ChatGroq
from src.core import get_settings
from src.core.state import AgentState
from src.core.prompts import get_prompt, get_prompt_with_meta
from src.core.tracing import trace_agent_node
from src.core.resilience import resilient_call, llm_circuit, llm_rate_limiter
from src.services.retrieval_service import rag_hybrid_search
from src.services.guardrails_service import validate_context, validate_output, parse_json_output
from src.services.cache_service import semantic_cache_set
from src.services.memory_service import load_memory
import structlog

log = structlog.get_logger()
settings = get_settings()


def _get_fast_llm():
    return ChatGroq(api_key=settings.groq_api_key, model=settings.groq_fast_model, temperature=0)


def _get_heavy_llm():
    return ChatGroq(api_key=settings.groq_api_key, model=settings.groq_chat_model, temperature=0)


@trace_agent_node("rag_domain_router")
def rag_domain_router_node(state: AgentState) -> dict:
    """Route query to appropriate RAG domain (namespace in Pinecone).

    Uses fast model + prompt registry.
    """
    query = state.get("original_query", "")
    messages = state.get("messages", [])

    try:
        prompt_meta = get_prompt_with_meta("domain_router")
        system_content = prompt_meta["template"]
        prompt_version = prompt_meta["version"]

        llm = _get_fast_llm()
        response = resilient_call(
            llm.invoke,
            [SystemMessage(content=system_content), HumanMessage(content=query)],
            circuit=llm_circuit, rate_limiter=llm_rate_limiter,
        )

        data = parse_json_output(response.content, ["domain", "sub_question"])
        domain = data.get("domain", "HR")
        sub_question = data.get("sub_question", query)

        log.info("rag_domain_routed", domain=domain, sub_question=sub_question[:60],
                 prompt_version=prompt_version, model=settings.groq_fast_model)
        return {
            "messages": messages,
            "rag_domain": domain,
            "rag_sub_question": sub_question,
        }
    except Exception as e:
        log.warning("rag_domain_routing_failed", error=str(e))
        return {
            "messages": messages,
            "rag_domain": "HR",
            "rag_sub_question": query,
        }


@trace_agent_node("rag_retrieval")
def rag_retrieval_node(state: AgentState) -> dict:
    """Retrieve from Pinecone using domain as namespace."""
    query = state.get("rag_sub_question", "") or state.get("original_query", "")
    domain = state.get("rag_domain", "")
    embedding = state.get("query_embedding", [])
    messages = state.get("messages", [])
    session_id = state.get("session_id", "")

    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as executor:
        future_search = executor.submit(
            rag_hybrid_search, query, domain, embedding, settings.rag_top_k
        )
        future_memory = executor.submit(
            load_memory, session_id, query, embedding
        )

        try:
            search_results = future_search.result(timeout=15)
        except Exception as e:
            log.warning("rag_retrieval_failed", error=str(e))
            search_results = []

        try:
            memory_data = future_memory.result(timeout=10)
        except Exception:
            memory_data = {"conversation_history": [], "conversation_summary": ""}

    # Context guard
    context_text = "\n\n".join([r.get("content", "") for r in search_results])
    context_safe, context_issues = validate_context(context_text)
    if not context_safe:
        log.warning("rag_context_guard_triggered", issues=context_issues)
        safe_results = []
        for r in search_results:
            _, chunk_issues = validate_context(r.get("content", ""))
            if not chunk_issues:
                safe_results.append(r)
        search_results = safe_results if safe_results else search_results[:3]

    return {
        "messages": messages,
        "rag_fused_results": search_results,
        "conversation_history": memory_data.get("conversation_history", []),
        "conversation_summary": memory_data.get("conversation_summary", ""),
        "history_token_usage": memory_data.get("history_token_usage", 0),
    }


@trace_agent_node("rag_generator")
def rag_generator_node(state: AgentState) -> dict:
    """Generate answer from retrieved context using heavy model.

    Fetches prompt from registry, logs prompt version and model used.
    """
    query = state.get("rag_sub_question", "") or state.get("original_query", "")
    chunks = state.get("rag_fused_results", [])
    history = state.get("conversation_history", [])
    summary = state.get("conversation_summary", "")
    messages = state.get("messages", [])
    start_time = time.time()

    if not chunks:
        return {
            "messages": messages,
            "rag_answer": "I don't have enough information in the knowledge base to answer this question.",
            "rag_confidence": "LOW",
            "rag_sources": [],
            "status": "completed",
        }

    context = "\n\n---\n\n".join([
        f"[Source: {c.get('source', 'unknown')}]\n{c.get('content', '')}"
        for c in chunks[:5]
    ])

    history_parts = []
    if summary:
        history_parts.append(f"Summary: {summary}")
    for h in history[-5:]:
        history_parts.append(f"{h.get('role', 'user')}: {h.get('content', '')}")
    history_str = "\n".join(history_parts) if history_parts else "No prior conversation."

    try:
        prompt_meta = get_prompt_with_meta("rag_generation")
        gen_prompt = prompt_meta["template"]
        prompt_version = prompt_meta["version"]
        model_name = settings.groq_chat_model  # heavy model for RAG generation

        formatted = gen_prompt.format(context=context, history=history_str, query=query)

        llm = _get_heavy_llm()
        response = resilient_call(
            llm.invoke,
            [HumanMessage(content=formatted)],
            circuit=llm_circuit, rate_limiter=llm_rate_limiter,
        )

        data = parse_json_output(response.content, ["answer"])
        answer = data.get("answer", response.content.strip())
        confidence = data.get("confidence", "MEDIUM")
        sources = data.get("sources", [c.get("source", "") for c in chunks[:3] if c.get("source")])

        # Output guard: PII check
        _, pii_issues, sanitized = validate_output(answer)
        if pii_issues:
            answer = sanitized

        latency_ms = (time.time() - start_time) * 1000

        # Cache with metadata
        try:
            semantic_cache_set(
                query,
                {"answer": answer, "confidence": confidence, "sources": sources, "pipeline": "rag"},
                pipeline="rag",
                domain=state.get("rag_domain", ""),
                embedding=state.get("query_embedding"),
                prompt_version=prompt_version,
                model=model_name,
            )
        except Exception:
            pass

        # Log to postgres with metadata
        try:
            from src.core.database import sql_log_query
            sql_log_query(query, answer, state.get("rag_domain", ""), latency_ms,
                         confidence, prompt_version=prompt_version, model=model_name)
        except Exception:
            pass

        log.info("rag_answer_generated", confidence=confidence, sources=len(sources),
                 prompt_version=prompt_version, model=model_name,
                 latency_ms=round(latency_ms, 1))
        return {
            "messages": messages,
            "rag_answer": answer,
            "rag_confidence": confidence,
            "rag_sources": sources,
        }

    except Exception as e:
        log.error("rag_generation_failed", error=str(e))
        return {
            "messages": messages,
            "rag_answer": f"Error generating answer: {str(e)}",
            "rag_confidence": "LOW",
            "rag_sources": [],
            "error": str(e),
        }