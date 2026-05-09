"""Embedding Service - ONNX-based embeddings via fastembed (all-MiniLM-L6-v2, 384-dim).

Uses fastembed ONNX runtime for fast, local embedding generation.
No external API calls needed for embeddings.
"""

from src.core import get_settings
from src.core.resilience import resilient_call, embedding_circuit
import structlog

log = structlog.get_logger()
settings = get_settings()

_model = None


def _get_model():
    """Lazy-load fastembed ONNX model singleton."""
    global _model
    if _model is None:
        from fastembed import TextEmbedding
        _model = TextEmbedding(model_name=settings.embedding_model)
        log.info("embeddings_loaded", model=settings.embedding_model, backend="fastembed-onnx", dim=settings.embedding_dim)
    return _model


def embed_query(query: str) -> list[float]:
    """Embed a single query string using ONNX. Returns empty list on failure."""
    try:
        model = _get_model()
        result = list(model.embed([query]))
        return result[0].tolist()
    except Exception as e:
        log.error("embed_query_failed", error=str(e))
        return []


def embed_documents(texts: list[str]) -> list[list[float]]:
    """Embed multiple document texts using ONNX. Returns empty list on failure."""
    if not texts:
        return []
    try:
        model = _get_model()
        results = list(model.embed(texts))
        return [r.tolist() for r in results]
    except Exception as e:
        log.error("embed_documents_failed", error=str(e))
        return []
