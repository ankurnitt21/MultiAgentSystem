"""Core configuration loaded from environment.

Separate settings for SQL database, Pinecone, Redis, LLM config.
"""

import os
from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # ─── LLM ─────────────────────────────────────────────────────────────
    groq_api_key: str = ""
    groq_base_url: str = "https://api.groq.com/openai/v1"
    groq_chat_model: str = "llama-3.3-70b-versatile"
    groq_fast_model: str = "llama-3.1-8b-instant"

    # ─── Pinecone ────────────────────────────────────────────────────────
    pinecone_api_key: str = ""
    pinecone_rag_index: str = "rag-base"
    pinecone_sql_index: str = "sql-base"

    # ─── SQL Database (Warehouse) ────────────────────────────────────────
    sql_database_url: str = "postgresql+asyncpg://warehouse_admin:warehouse_secret_2024@localhost:5433/warehouse_db"
    sql_database_url_sync: str = "postgresql://warehouse_admin:warehouse_secret_2024@localhost:5433/warehouse_db"

    # ─── Redis ───────────────────────────────────────────────────────────
    redis_url: str = "redis://localhost:6379"

    # ─── LangSmith ───────────────────────────────────────────────────────
    langsmith_api_key: str = ""
    langsmith_endpoint: str = "https://api.smith.langchain.com"
    langsmith_project: str = "UnifiedMultiAgentSystem"

    # ─── App ─────────────────────────────────────────────────────────────
    default_page_size: int = 50
    max_retries: int = 3
    cache_ttl_seconds: int = 300
    semantic_cache_threshold: float = 0.92

    # ─── Memory ──────────────────────────────────────────────────────────
    memory_token_limit: int = 4000
    memory_max_messages: int = 20

    # ─── Embedding ───────────────────────────────────────────────────────
    embedding_model: str = "all-MiniLM-L6-v2"
    embedding_dim: int = 384

    # ─── Schema Retrieval ────────────────────────────────────────────────
    schema_top_k: int = 10

    # ─── RAG ─────────────────────────────────────────────────────────────
    rag_top_k: int = 10
    rag_domains: str = "HR,PRODUCT,AI"

    # ─── Guardrails ──────────────────────────────────────────────────────
    guardrails_enabled: bool = True

    class Config:
        env_file = os.path.join(
            os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
            ".env",
        )
        extra = "ignore"


@lru_cache()
def get_settings() -> Settings:
    return Settings()


def setup_langsmith():
    """Configure LangSmith environment variables for tracing via OTEL."""
    s = get_settings()
    os.environ["LANGCHAIN_TRACING_V2"] = "false"
    if s.langsmith_api_key:
        os.environ["LANGCHAIN_API_KEY"] = s.langsmith_api_key
        os.environ["LANGCHAIN_ENDPOINT"] = s.langsmith_endpoint
        os.environ["LANGCHAIN_PROJECT"] = s.langsmith_project
