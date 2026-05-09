"""Memory Service - Conversation memory with relevance filtering and summarization."""

import re
import numpy as np
from langchain_core.messages import SystemMessage, HumanMessage
from langchain_groq import ChatGroq
from src.core import get_settings
from src.core.database import get_conversations, get_conversation_summary, save_conversation_summary
from src.core.prompts import get_prompt
from src.core.resilience import resilient_call, llm_circuit, llm_rate_limiter
from src.services.embedding_service import embed_documents
import structlog

log = structlog.get_logger()
settings = get_settings()


def _estimate_tokens(text: str) -> int:
    return len(text) // 4


def _get_llm():
    return ChatGroq(api_key=settings.groq_api_key, model=settings.groq_fast_model, temperature=0)


def relevance_filter(query: str, history: list[dict],
                     query_embedding: list[float] | None = None) -> list[dict]:
    """Filter conversation history by relevance to current query."""
    if not history:
        return []

    RELEVANCE_THRESHOLD = 0.3
    if query_embedding and len(query_embedding) > 0:
        try:
            query_vec = np.array(query_embedding, dtype=np.float32)
            query_norm = np.linalg.norm(query_vec)
            if query_norm == 0:
                return history[-5:]

            history_texts = [h.get("content", "") for h in history]
            history_vectors = embed_documents(history_texts)

            scored = []
            for i, h in enumerate(history):
                h_vec = np.array(history_vectors[i], dtype=np.float32)
                h_norm = np.linalg.norm(h_vec)
                if h_norm == 0:
                    continue
                similarity = float(np.dot(query_vec, h_vec) / (query_norm * h_norm))
                recency_boost = 0.05 * (i / max(len(history), 1))
                scored.append((similarity + recency_boost, h))

            relevant = [(s, h) for s, h in scored if s >= RELEVANCE_THRESHOLD]
            relevant.sort(key=lambda x: x[0], reverse=True)
            result = [h for _, h in relevant[:10]]
            return result if result else history[-3:]
        except Exception as e:
            log.debug("relevance_filter_embedding_failed", error=str(e))

    # Fallback: keyword overlap
    query_tokens = set(re.findall(r'\b\w{3,}\b', query.lower()))
    if not query_tokens:
        return history[-5:]

    scored = []
    for i, h in enumerate(history):
        content = h.get("content", "").lower()
        h_tokens = set(re.findall(r'\b\w{3,}\b', content))
        if not h_tokens:
            continue
        overlap = len(query_tokens & h_tokens) / max(len(query_tokens), 1)
        recency_boost = 0.1 * (i / max(len(history), 1))
        scored.append((overlap + recency_boost, h))

    relevant = [(s, h) for s, h in scored if s >= RELEVANCE_THRESHOLD]
    relevant.sort(key=lambda x: x[0], reverse=True)
    result = [h for _, h in relevant[:10]]
    return result if result else history[-3:]


def summarize_messages(messages: list[dict], existing_summary: str) -> str:
    """Incremental summarization of older messages."""
    llm = _get_llm()
    messages_text = "\n".join([f"{m['role']}: {m['content']}" for m in messages])

    try:
        system_content = get_prompt("memory_summarization")
    except Exception:
        return existing_summary or ""

    user_content = f"Previous summary: {existing_summary or 'None'}\n\nNew messages:\n{messages_text}"

    try:
        response = resilient_call(
            llm.invoke,
            [SystemMessage(content=system_content), HumanMessage(content=user_content)],
            circuit=llm_circuit, rate_limiter=llm_rate_limiter,
        )
        return response.content
    except Exception as e:
        log.warning("summarization_failed", error=str(e))
        return existing_summary or ""


def load_memory(session_id: str, query: str,
                query_embedding: list[float] = None) -> dict:
    """Load conversation memory with relevance filtering and summarization.

    Returns: {conversation_history, conversation_summary, history_token_usage}
    """
    if not session_id:
        return {"conversation_history": [], "conversation_summary": "", "history_token_usage": 0}

    history = get_conversations(session_id, limit=50)
    if not history:
        return {"conversation_history": [], "conversation_summary": "", "history_token_usage": 0}

    existing_summary = get_conversation_summary(session_id) or ""
    relevant_history = relevance_filter(query, history, query_embedding)

    total_text = " ".join([h["content"] for h in relevant_history])
    total_tokens = _estimate_tokens(total_text) + _estimate_tokens(existing_summary)

    if total_tokens > settings.memory_token_limit or len(relevant_history) > settings.memory_max_messages:
        keep_count = min(5, len(relevant_history))
        kept = relevant_history[:keep_count]
        overflow = relevant_history[keep_count:]

        if overflow:
            updated_summary = summarize_messages(overflow, existing_summary)
            save_conversation_summary(session_id, updated_summary,
                                      _estimate_tokens(updated_summary))
        else:
            updated_summary = existing_summary

        return {
            "conversation_history": kept,
            "conversation_summary": updated_summary,
            "history_token_usage": _estimate_tokens(updated_summary) + _estimate_tokens(
                " ".join([m["content"] for m in kept])),
        }

    return {
        "conversation_history": relevant_history,
        "conversation_summary": existing_summary,
        "history_token_usage": total_tokens,
    }
