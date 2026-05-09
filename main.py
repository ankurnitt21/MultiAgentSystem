"""Unified Multi-Agent System - FastAPI Application Entry Point."""

import os
import sys
import uvicorn
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
import structlog

structlog.configure(
    processors=[
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.dev.ConsoleRenderer(),
    ],
    wrapper_class=structlog.make_filtering_bound_logger(20),
)
log = structlog.get_logger()

# Ensure project root on path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Startup / shutdown events."""
    log.info("startup", msg="Initialising Unified Multi-Agent System")

    # 1. Setup LangSmith tracing
    from src.core import setup_langsmith
    setup_langsmith()
    log.info("startup", step="langsmith_configured")

    # 2. Seed default prompts
    from src.core.prompts import seed_default_prompts
    try:
        seed_default_prompts()
        log.info("startup", step="prompts_seeded")
    except Exception as e:
        log.warning("startup", step="prompts_seed_failed", error=str(e))

    # 3. Pre-load embedding model (warm cache)
    from src.services.embedding_service import embed_query as _warmup_embed
    try:
        _warmup_embed("warmup")
        log.info("startup", step="embeddings_loaded")
    except Exception as e:
        log.warning("startup", step="embeddings_load_failed", error=str(e))

    # 4. Seed Pinecone indexes (RAG documents from file + SQL schema)
    from src.services.pinecone_service import seed_rag_from_file, seed_sql_schema
    try:
        seed_rag_from_file()
        log.info("startup", step="pinecone_rag_seeded")
    except Exception as e:
        log.warning("startup", step="pinecone_rag_seed_failed", error=str(e))

    try:
        seed_sql_schema()
        log.info("startup", step="pinecone_sql_schema_seeded")
    except Exception as e:
        log.warning("startup", step="pinecone_sql_schema_seed_failed", error=str(e))

    # 5. Ensure feedback table exists in SQL DB
    from src.services.feedback_service import _ensure_feedback_table
    try:
        _ensure_feedback_table()
        log.info("startup", step="feedback_table_ready")
    except Exception as e:
        log.warning("startup", step="feedback_table_failed", error=str(e))

    log.info("startup", msg="System ready")
    yield
    log.info("shutdown", msg="Shutting down")


app = FastAPI(
    title="Unified Multi-Agent System",
    description="RAG + SQL + Action | LLM-driven Supervisor | LangGraph",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routes
from src.api.routes import router
app.include_router(router)

# Static files
static_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "static")
if os.path.isdir(static_dir):
    app.mount("/", StaticFiles(directory=static_dir, html=True), name="static")


if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
