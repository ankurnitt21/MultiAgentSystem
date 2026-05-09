"""Pinecone Service - Vector store for RAG documents and SQL schema embeddings.

Uses two indexes:
  - rag-base: RAG document chunks, namespaced by domain (HR, PRODUCT, AI)
  - sql-base: SQL schema descriptions for hybrid schema retrieval

Both indexes use 384-dimensional embeddings (all-MiniLM-L6-v2 via ONNX).
"""

import time
import uuid
from pinecone import Pinecone
from src.core import get_settings
from src.core.resilience import resilient_call, embedding_circuit
from src.services.embedding_service import embed_query, embed_documents
import structlog

log = structlog.get_logger()
settings = get_settings()

_pc_client = None
_rag_index = None
_sql_index = None


def _get_pinecone():
    """Lazy Pinecone client singleton."""
    global _pc_client
    if _pc_client is None:
        _pc_client = Pinecone(api_key=settings.pinecone_api_key)
        log.info("pinecone_connected")
    return _pc_client


def _get_rag_index():
    """Get the rag-base Pinecone index."""
    global _rag_index
    if _rag_index is None:
        pc = _get_pinecone()
        _rag_index = pc.Index(settings.pinecone_rag_index)
        log.info("pinecone_rag_index_connected", index=settings.pinecone_rag_index)
    return _rag_index


def _get_sql_index():
    """Get the sql-base Pinecone index."""
    global _sql_index
    if _sql_index is None:
        pc = _get_pinecone()
        _sql_index = pc.Index(settings.pinecone_sql_index)
        log.info("pinecone_sql_index_connected", index=settings.pinecone_sql_index)
    return _sql_index


# ═══════════════════════════════════════════════════════════════════════════
# RAG OPERATIONS (rag-base index, namespaced by domain)
# ═══════════════════════════════════════════════════════════════════════════

def rag_vector_search(embedding: list[float], domain: str = None, top_k: int = 10) -> list[dict]:
    """Vector similarity search on RAG documents in Pinecone.

    Uses domain as namespace for scoped search.
    """
    index = _get_rag_index()
    namespace = domain.upper() if domain else ""

    try:
        results = index.query(
            vector=embedding,
            top_k=top_k,
            namespace=namespace if namespace else None,
            include_metadata=True,
        )

        docs = []
        for match in results.matches:
            meta = match.metadata or {}
            docs.append({
                "id": match.id,
                "content": meta.get("content", ""),
                "domain": meta.get("domain", domain or ""),
                "source": meta.get("source", ""),
                "metadata": meta,
                "similarity": float(match.score or 0.0),
            })

        log.info("pinecone_rag_search", results=len(docs), domain=domain, namespace=namespace)
        return docs
    except Exception as e:
        log.error("pinecone_rag_search_failed", error=str(e))
        return []


def rag_upsert_documents(chunks: list[dict], domain: str):
    """Upsert document chunks into Pinecone rag-base index.

    Each chunk: {content, source, domain, chunk_index, metadata}
    Uses domain as namespace.
    """
    index = _get_rag_index()
    namespace = domain.upper()

    texts = [c["content"] for c in chunks]
    embeddings = embed_documents(texts)
    if not embeddings:
        log.error("rag_upsert_embedding_failed")
        return

    vectors = []
    for i, chunk in enumerate(chunks):
        vec_id = chunk.get("id", f"{domain}-{uuid.uuid4().hex[:12]}")
        metadata = {
            "content": chunk["content"],
            "domain": domain,
            "source": chunk.get("source", ""),
            "chunk_index": chunk.get("chunk_index", i),
            "timestamp": time.time(),
        }
        if chunk.get("metadata"):
            metadata.update(chunk["metadata"])
        vectors.append({
            "id": str(vec_id),
            "values": embeddings[i],
            "metadata": metadata,
        })

    # Upsert in batches of 100
    batch_size = 100
    for i in range(0, len(vectors), batch_size):
        batch = vectors[i:i + batch_size]
        index.upsert(vectors=batch, namespace=namespace)

    log.info("pinecone_rag_upserted", count=len(vectors), domain=domain, namespace=namespace)


# ═══════════════════════════════════════════════════════════════════════════
# SQL SCHEMA OPERATIONS (sql-base index)
# ═══════════════════════════════════════════════════════════════════════════

def sql_schema_vector_search(embedding: list[float], top_k: int = 10) -> list[dict]:
    """Search SQL schema descriptions in Pinecone sql-base index."""
    index = _get_sql_index()

    try:
        results = index.query(
            vector=embedding,
            top_k=top_k,
            include_metadata=True,
        )

        docs = []
        for match in results.matches:
            meta = match.metadata or {}
            docs.append({
                "id": match.id,
                "table_name": meta.get("table_name", ""),
                "column_name": meta.get("column_name", ""),
                "domain": meta.get("domain", ""),
                "description": meta.get("description", ""),
                "data_type": meta.get("data_type", ""),
                "similarity": float(match.score or 0.0),
            })

        log.info("pinecone_sql_schema_search", results=len(docs))
        return docs
    except Exception as e:
        log.error("pinecone_sql_schema_search_failed", error=str(e))
        return []


def sql_schema_upsert(descriptions: list[dict]):
    """Upsert SQL schema descriptions into Pinecone sql-base index.

    Each description: {table_name, column_name, domain, description, data_type}
    """
    index = _get_sql_index()

    texts = []
    for d in descriptions:
        col = d.get("column_name") or ""
        tbl = d.get("table_name") or ""
        desc_text = d.get("description") or ""
        dtype = d.get("data_type") or ""
        if col:
            texts.append(f"{tbl}.{col}: {desc_text} ({dtype})")
        else:
            texts.append(f"{tbl}: {desc_text}")

    embeddings = embed_documents(texts)
    if not embeddings:
        log.error("sql_schema_upsert_embedding_failed")
        return

    vectors = []
    for i, desc in enumerate(descriptions):
        col = desc.get("column_name") or ""
        tbl = desc.get("table_name") or ""
        vec_id = f"schema-{tbl}-{col}" if col else f"schema-{tbl}"
        metadata = {
            "table_name": tbl,
            "column_name": col,
            "domain": desc.get("domain") or "",
            "description": desc.get("description") or "",
            "data_type": desc.get("data_type") or "",
            "text": texts[i],
            "timestamp": time.time(),
        }
        vectors.append({
            "id": vec_id,
            "values": embeddings[i],
            "metadata": metadata,
        })

    batch_size = 100
    for i in range(0, len(vectors), batch_size):
        batch = vectors[i:i + batch_size]
        index.upsert(vectors=batch)

    log.info("pinecone_sql_schema_upserted", count=len(vectors))


def seed_rag_documents():
    """No-op: RAG documents are uploaded via the /api/documents/upload API.
    
    Use the upload endpoint with a domain tag to add documents to Pinecone.
    """
    log.info("rag_seed_skipped", reason="use /api/documents/upload API instead")


def seed_rag_from_file():
    """Seed RAG documents from data/rag_seed.json file into Pinecone.
    
    Each domain becomes a namespace. Skips if namespace already has vectors.
    """
    import json
    import os

    seed_path = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "data", "rag_seed.json")
    if not os.path.exists(seed_path):
        log.info("rag_seed_file_not_found", path=seed_path)
        return

    with open(seed_path, "r", encoding="utf-8") as f:
        seed_data = json.load(f)

    domains = seed_data.get("domains", {})
    for domain, data in domains.items():
        try:
            index = _get_rag_index()
            stats = index.describe_index_stats()
            ns_stats = stats.namespaces or {}
            if domain in ns_stats and getattr(ns_stats.get(domain), 'vector_count', 0) > 0:
                log.info("pinecone_rag_already_seeded", domain=domain)
                continue

            source = data.get("source", "seed_file")
            chunks = []
            for i, chunk in enumerate(data.get("chunks", [])):
                chunks.append({
                    "content": chunk["content"],
                    "source": source,
                    "chunk_index": i,
                    "metadata": {"domain": domain, "source": source},
                })
            if chunks:
                rag_upsert_documents(chunks, domain)
                log.info("pinecone_rag_seeded_from_file", domain=domain, chunks=len(chunks))
        except Exception as e:
            log.warning("pinecone_rag_seed_failed", domain=domain, error=str(e))


def seed_sql_schema():
    """Seed SQL schema descriptions into Pinecone sql-base index from PostgreSQL."""
    from src.core.database import sql_get_schema_embeddings
    try:
        index = _get_sql_index()
        stats = index.describe_index_stats()
        total = stats.total_vector_count or 0
        if total > 0:
            log.info("pinecone_sql_schema_already_seeded", count=total)
            return

        descriptions = sql_get_schema_embeddings()
        if descriptions:
            sql_schema_upsert(descriptions)
            log.info("pinecone_sql_schema_seeded", count=len(descriptions))
    except Exception as e:
        log.warning("pinecone_sql_schema_seed_failed", error=str(e))
