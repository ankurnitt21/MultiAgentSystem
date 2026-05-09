"""Feedback Service - User ratings with LangSmith integration."""

import httpx
from sqlalchemy import text
from src.core import get_settings
from src.core.database import SQLSession
import structlog

log = structlog.get_logger()
settings = get_settings()


def _ensure_feedback_table():
    """Create feedback table if not exists."""
    with SQLSession() as session:
        session.execute(text("""
            CREATE TABLE IF NOT EXISTS query_feedback (
                id BIGSERIAL PRIMARY KEY,
                session_id VARCHAR(100),
                run_id VARCHAR(100),
                query TEXT,
                generated_sql TEXT,
                rating INTEGER NOT NULL,
                comment TEXT,
                correction TEXT,
                pipeline VARCHAR(20) DEFAULT 'sql',
                created_at TIMESTAMP DEFAULT NOW()
            )
        """))
        session.commit()


def save_feedback(session_id: str, run_id: str, query: str,
                  rating: int, comment: str = "", correction: str = "",
                  generated_sql: str = "", pipeline: str = "sql"):
    """Save user feedback to DB and sync to LangSmith."""
    _ensure_feedback_table()

    with SQLSession() as session:
        session.execute(text(
            "INSERT INTO query_feedback (session_id, run_id, query, generated_sql, "
            "rating, comment, correction, pipeline) "
            "VALUES (:sid, :rid, :q, :sql, :r, :c, :corr, :p)"
        ), {
            "sid": session_id, "rid": run_id, "q": query,
            "sql": generated_sql, "r": rating, "c": comment,
            "corr": correction, "p": pipeline,
        })
        session.commit()

    # Sync to LangSmith
    if run_id and settings.langsmith_api_key:
        try:
            _sync_to_langsmith(run_id, rating, comment)
        except Exception as e:
            log.warning("langsmith_feedback_sync_failed", error=str(e))


def _sync_to_langsmith(run_id: str, rating: int, comment: str = ""):
    """Send feedback to LangSmith API."""
    try:
        with httpx.Client(timeout=5.0) as client:
            client.post(
                f"{settings.langsmith_endpoint}/feedback",
                json={
                    "run_id": run_id,
                    "key": "user_rating",
                    "score": 1.0 if rating > 0 else 0.0,
                    "comment": comment or ("thumbs_up" if rating > 0 else "thumbs_down"),
                },
                headers={"x-api-key": settings.langsmith_api_key},
            )
    except Exception as e:
        log.debug("langsmith_feedback_error", error=str(e))


def get_feedback_stats() -> dict:
    """Get aggregate feedback statistics."""
    _ensure_feedback_table()
    with SQLSession() as session:
        result = session.execute(text(
            "SELECT pipeline, "
            "COUNT(*) as total, "
            "SUM(CASE WHEN rating > 0 THEN 1 ELSE 0 END) as thumbs_up, "
            "SUM(CASE WHEN rating < 0 THEN 1 ELSE 0 END) as thumbs_down "
            "FROM query_feedback GROUP BY pipeline"
        ))
        rows = [dict(zip(result.keys(), row)) for row in result.fetchall()]
        return {"pipelines": rows}
