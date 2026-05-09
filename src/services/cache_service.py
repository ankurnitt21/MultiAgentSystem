"""Cache Service - Redis vector search semantic caching with metadata.

Structure per cached entry:
{
  embedding: [...],
  query: "...",
  answer: "...",
  metadata: { prompt_version, model, timestamp, pipeline, domain }
}

Uses RediSearch vector index for KNN similarity search.
"""

import hashlib
import json
import time
import redis
import numpy as np
from src.core import get_settings
from src.core.resilience import redis_circuit
from src.services.embedding_service import embed_query
import structlog

log = structlog.get_logger()
settings = get_settings()

_redis_client = None
_index_created = False


def _get_redis():
    global _redis_client
    if _redis_client is not None:
        try:
            _redis_client.ping()
            return _redis_client
        except Exception:
            log.warning("redis_reconnecting", reason="stale connection")
            _redis_client = None
    try:
        _redis_client = redis.from_url(
            settings.redis_url,
            decode_responses=True,
            socket_connect_timeout=3,
            socket_timeout=3,
            retry_on_timeout=True,
            health_check_interval=30,
        )
        _redis_client.ping()
        log.info("redis_connected")
    except Exception as e:
        log.error("redis_connection_failed", error=str(e))
        _redis_client = None
        return None
    return _redis_client


def _ensure_index():
    global _index_created
    if _index_created:
        return
    r = _get_redis()
    if r is None:
        return
    try:
        from redis.commands.search.field import TagField, TextField, NumericField, VectorField
        from redis.commands.search.index_definition import IndexDefinition, IndexType

        schema = (
            TagField("$.pipeline", as_name="pipeline"),
            TextField("$.query", as_name="query"),
            TagField("$.domain", as_name="domain"),
            NumericField("$.timestamp", as_name="timestamp"),
            NumericField("$.ttl", as_name="ttl"),
            TextField("$.metadata.model", as_name="model"),
            NumericField("$.metadata.prompt_version", as_name="prompt_version"),
            VectorField(
                "$.embedding",
                "FLAT",
                {"TYPE": "FLOAT32", "DIM": settings.embedding_dim, "DISTANCE_METRIC": "COSINE"},
                as_name="embedding",
            ),
        )
        r.ft("idx:unified_cache").create_index(
            schema,
            definition=IndexDefinition(prefix=["cache:"], index_type=IndexType.JSON),
        )
        _index_created = True
        log.info("redis_index_created", index="idx:unified_cache")
    except Exception as e:
        if "Index already exists" in str(e):
            _index_created = True
        else:
            log.warning("redis_index_create_failed", error=str(e))


def _query_hash(query: str) -> str:
    return hashlib.sha256(query.strip().lower().encode()).hexdigest()[:16]


def semantic_cache_get(query: str, pipeline: str = "any",
                       precomputed_embedding: list[float] = None) -> dict | None:
    """Search Redis vector index for semantically similar cached query.

    Flow: Convert query -> embedding -> search Redis vector index
          If similarity >= threshold -> return cached answer
    """
    r = _get_redis()
    if r is None:
        return None

    _ensure_index()

    # Step 1: Exact hash match (O(1))
    qhash = _query_hash(query)
    try:
        for key in r.scan_iter(f"cache:*:{qhash}", count=10):
            data_str = r.json().get(key, "$")
            if data_str and len(data_str) > 0:
                data = data_str[0] if isinstance(data_str, list) else data_str
                ts = data.get("timestamp", 0)
                ttl = data.get("ttl", settings.cache_ttl_seconds)
                if time.time() - ts < ttl:
                    log.info("cache_exact_hit", key=key)
                    return data.get("result", {})
    except Exception as e:
        log.debug("cache_exact_lookup_failed", error=str(e))

    # Step 2: KNN semantic search via Redis vector index
    try:
        embedding = precomputed_embedding if precomputed_embedding else embed_query(query)
        if not embedding:
            return None

        query_vec = np.array(embedding, dtype=np.float32).tobytes()

        from redis.commands.search.query import Query
        q = (
            Query("*=>[KNN 1 @embedding $vec AS score]")
            .sort_by("score")
            .return_fields("score", "query", "pipeline", "timestamp", "ttl")
            .dialect(2)
        )
        results = r.ft("idx:unified_cache").search(q, query_params={"vec": query_vec})

        if results.total > 0:
            doc = results.docs[0]
            score = float(doc.score)
            similarity = 1.0 - score

            if similarity >= settings.semantic_cache_threshold:
                ts = float(doc.timestamp) if hasattr(doc, "timestamp") else 0
                ttl = float(doc.ttl) if hasattr(doc, "ttl") else settings.cache_ttl_seconds
                if time.time() - ts < ttl:
                    full_data = r.json().get(doc.id, "$")
                    if full_data:
                        data = full_data[0] if isinstance(full_data, list) else full_data
                        log.info("cache_semantic_hit", similarity=round(similarity, 3))
                        return data.get("result", {})
    except Exception as e:
        log.debug("cache_semantic_lookup_failed", error=str(e))

    return None


def semantic_cache_set(query: str, result: dict, pipeline: str = "sql",
                       domain: str = "", embedding: list[float] = None,
                       ttl: int = None, prompt_version: int = None,
                       model: str = ""):
    """Store query result in Redis with embedding + metadata for vector search.

    Structure: { embedding, query, result, metadata: {prompt_version, model, timestamp} }
    """
    r = _get_redis()
    if r is None:
        return

    _ensure_index()

    if embedding is None:
        embedding = embed_query(query)
    if not embedding:
        return

    qhash = _query_hash(query)
    cache_key = f"cache:{pipeline}:{qhash}"
    cache_ttl = ttl or settings.cache_ttl_seconds

    try:
        cache_data = {
            "query": query,
            "pipeline": pipeline,
            "domain": domain,
            "result": result,
            "embedding": embedding,
            "timestamp": time.time(),
            "ttl": cache_ttl,
            "metadata": {
                "prompt_version": prompt_version or 0,
                "model": model or "",
                "timestamp": time.time(),
                "pipeline": pipeline,
                "domain": domain,
            },
        }
        r.json().set(cache_key, "$", cache_data)
        r.expire(cache_key, cache_ttl + 60)
        log.info("cache_written", key=cache_key, pipeline=pipeline,
                 prompt_version=prompt_version, model=model)
    except Exception as e:
        log.warning("cache_write_failed", error=str(e))