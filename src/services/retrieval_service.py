"""Retrieval Service - Pinecone vector search + keyword fallback.

Used by RAG pipeline for document retrieval and SQL pipeline for schema retrieval.
Pinecone indexes: rag-base (domain-namespaced), sql-base (schema).
"""

import re
import numpy as np
from src.core import get_settings
from src.core.database import sql_get_schema_embeddings
from src.services.pinecone_service import rag_vector_search, sql_schema_vector_search
from src.services.embedding_service import embed_query, embed_documents
import structlog

log = structlog.get_logger()
settings = get_settings()

_schema_embeddings_cache: dict = {}


def reciprocal_rank_fusion(result_lists: list[list[dict]], k: int = 60) -> list[dict]:
    scores = {}
    docs = {}
    for result_list in result_lists:
        for rank, doc in enumerate(result_list):
            doc_id = doc.get("id") or doc.get("content", "")[:100]
            if doc_id not in scores:
                scores[doc_id] = 0.0
                docs[doc_id] = doc
            scores[doc_id] += 1.0 / (k + rank + 1)
    sorted_ids = sorted(scores.keys(), key=lambda x: scores[x], reverse=True)
    fused = []
    for doc_id in sorted_ids:
        doc = docs[doc_id].copy()
        doc["fusion_score"] = round(scores[doc_id], 4)
        fused.append(doc)
    return fused


def rag_hybrid_search(query: str, domain: str = None,
                      embedding: list[float] = None, top_k: int = 10) -> list[dict]:
    if embedding is None:
        embedding = embed_query(query)
    if not embedding:
        log.warning("rag_search_no_embedding")
        return []
    try:
        results = rag_vector_search(embedding, domain=domain, top_k=top_k)
        log.info("rag_pinecone_search", results=len(results), domain=domain)
        return results
    except Exception as e:
        log.warning("rag_pinecone_search_failed", error=str(e))
        return []


def _load_schema_for_keywords():
    global _schema_embeddings_cache
    if _schema_embeddings_cache:
        return _schema_embeddings_cache
    try:
        descriptions = sql_get_schema_embeddings()
        if not descriptions:
            return {}
        texts = [
            f"{d['table_name']}.{d['column_name']}: {d['description']} ({d['data_type']})"
            for d in descriptions
        ]
        _schema_embeddings_cache = {"descriptions": descriptions, "texts": texts}
        log.info("schema_keyword_cache_loaded", count=len(descriptions))
        return _schema_embeddings_cache
    except Exception as e:
        log.error("schema_keyword_cache_load_failed", error=str(e))
        return {}


def sql_schema_search(query: str, embedding: list[float] = None, top_k: int = 10) -> list[dict]:
    results_semantic = []
    results_keyword = []

    if embedding is None:
        embedding = embed_query(query)
    if embedding:
        try:
            pinecone_results = sql_schema_vector_search(embedding, top_k=top_k)
            results_semantic = pinecone_results
            log.info("sql_schema_pinecone_search", results=len(results_semantic))
        except Exception as e:
            log.warning("sql_schema_pinecone_search_failed", error=str(e))

    cache = _load_schema_for_keywords()
    if cache:
        descriptions = cache["descriptions"]
        texts = cache["texts"]
        _SYNONYMS = {
            "product": ["item", "sku", "goods"],
            "supplier": ["vendor", "provider"],
            "order": ["purchase", "sales", "po"],
            "inventory": ["stock", "quantity"],
            "warehouse": ["storage", "depot"],
            "customer": ["client", "buyer"],
            "shipment": ["delivery", "shipping"],
            "price": ["cost", "amount", "total"],
        }
        query_tokens = set(re.findall(r'\b\w{3,}\b', query.lower()))
        expanded = set(query_tokens)
        for token in list(query_tokens):
            for key, syns in _SYNONYMS.items():
                if token == key or token in syns:
                    expanded.add(key)
                    expanded.update(syns)
        for i, text in enumerate(texts):
            text_tokens = set(re.findall(r'\b\w{3,}\b', text.lower()))
            overlap = len(expanded & text_tokens)
            if overlap > 0:
                d = descriptions[i].copy()
                d["keyword_score"] = overlap / max(len(expanded), 1)
                results_keyword.append(d)
        results_keyword.sort(key=lambda x: x.get("keyword_score", 0), reverse=True)
        results_keyword = results_keyword[:top_k]

    if results_semantic or results_keyword:
        fused = reciprocal_rank_fusion([results_semantic, results_keyword], k=60)
        return fused[:top_k]

    if cache:
        return cache["descriptions"][:top_k]
    return []