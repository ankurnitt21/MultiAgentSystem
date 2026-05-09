"""Database layer - SQL warehouse database + Pinecone vector store.

SQL DB (port 5433): Warehouse business tables, schema_description, conversations, prompts
Pinecone: rag-base index (RAG documents by namespace/domain), sql-base index (schema embeddings)
"""

from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from src.core import get_settings

settings = get_settings()

# ─── SQL Database Engine ────────────────────────────────────────────────────
sql_engine = create_engine(
    settings.sql_database_url_sync,
    pool_size=10,
    max_overflow=5,
    pool_timeout=30,
    pool_recycle=1800,
)
SQLSession = sessionmaker(bind=sql_engine)


# ═══════════════════════════════════════════════════════════════════════════
# SQL DATABASE OPERATIONS
# ═══════════════════════════════════════════════════════════════════════════

def sql_execute_query(sql: str, timeout: int = 30) -> list[dict]:
    """Execute a read-only SQL query on the warehouse database with timeout."""
    with SQLSession() as session:
        session.execute(text(f"SET statement_timeout = '{timeout}s'"))
        result = session.execute(text(sql))
        columns = list(result.keys())
        rows = result.fetchall()
        return [dict(zip(columns, row)) for row in rows]


def sql_get_full_schema_ddl() -> str:
    """Get complete DDL for all business tables including FK relationships."""
    with SQLSession() as session:
        tables_result = session.execute(text(
            "SELECT table_name FROM information_schema.tables "
            "WHERE table_schema = 'public' AND table_type = 'BASE TABLE' "
            "AND table_name NOT IN ('conversation', 'conversation_summary', "
            "'schema_description', 'prompt_template', 'query_feedback', 'query_logs') "
            "ORDER BY table_name"
        ))
        tables = [r[0] for r in tables_result.fetchall()]

        lines = []
        for table in tables:
            cols_result = session.execute(text(
                "SELECT column_name, data_type, is_nullable, column_default "
                "FROM information_schema.columns "
                "WHERE table_name = :tbl AND table_schema = 'public' "
                "ORDER BY ordinal_position"
            ), {"tbl": table})
            cols = cols_result.fetchall()
            lines.append(f"TABLE {table} (")
            for col_name, data_type, nullable, default in cols:
                parts = [f"  {col_name} {data_type}"]
                if nullable == "NO":
                    parts.append("NOT NULL")
                if default and "nextval" in str(default):
                    parts.append("PRIMARY KEY")
                lines.append(" ".join(parts))
            lines.append(")")
            lines.append("")

        fk_result = session.execute(text(
            "SELECT tc.table_name, kcu.column_name, "
            "ccu.table_name AS foreign_table, ccu.column_name AS foreign_column "
            "FROM information_schema.table_constraints tc "
            "JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name "
            "JOIN information_schema.constraint_column_usage ccu ON ccu.constraint_name = tc.constraint_name "
            "WHERE tc.constraint_type = 'FOREIGN KEY' AND tc.table_schema = 'public'"
        ))
        fks = fk_result.fetchall()
        if fks:
            lines.append("FOREIGN KEYS:")
            for src, src_col, fk_tbl, fk_col in fks:
                lines.append(f"  {src}.{src_col} -> {fk_tbl}.{fk_col}")

        return "\n".join(lines)


def sql_get_schema_descriptions() -> list[dict]:
    """Get all schema descriptions from the warehouse DB for LLM context."""
    with SQLSession() as session:
        result = session.execute(text(
            "SELECT table_name, column_name, domain, description, data_type "
            "FROM schema_description ORDER BY domain, table_name"
        ))
        return [dict(zip(result.keys(), row)) for row in result.fetchall()]


def sql_get_schema_embeddings() -> list[dict]:
    """Get schema descriptions for vector search."""
    with SQLSession() as session:
        result = session.execute(text(
            "SELECT id, table_name, column_name, domain, description, data_type "
            "FROM schema_description ORDER BY domain, table_name"
        ))
        return [dict(zip(result.keys(), row)) for row in result.fetchall()]


def sql_log_query(query: str, response: str, domain: str, latency_ms: float,
                  confidence: str = "", ragas_faithfulness: float = None,
                  prompt_version: int = None, model: str = ""):
    """Log a query to query_logs table in SQL DB."""
    with SQLSession() as session:
        session.execute(text("""
            CREATE TABLE IF NOT EXISTS query_logs (
                id BIGSERIAL PRIMARY KEY,
                query TEXT NOT NULL,
                response TEXT,
                domain VARCHAR(50),
                latency_ms FLOAT,
                confidence VARCHAR(20),
                ragas_faithfulness FLOAT,
                prompt_version INTEGER,
                model VARCHAR(100),
                created_at TIMESTAMP DEFAULT NOW()
            )
        """))
        session.execute(text(
            "INSERT INTO query_logs (query, response, domain, latency_ms, confidence, "
            "ragas_faithfulness, prompt_version, model) "
            "VALUES (:q, :r, :d, :l, :c, :rf, :pv, :m)"
        ), {"q": query, "r": response, "d": domain, "l": latency_ms,
            "c": confidence, "rf": ragas_faithfulness, "pv": prompt_version, "m": model})
        session.commit()


# ═══════════════════════════════════════════════════════════════════════════
# CONVERSATION OPERATIONS (SQL DB stores conversations)
# ═══════════════════════════════════════════════════════════════════════════

def get_conversations(session_id: str, limit: int = 10) -> list[dict]:
    """Get recent conversation history."""
    with SQLSession() as session:
        result = session.execute(text(
            "SELECT role, content, sql_query, created_at "
            "FROM conversation WHERE session_id = :sid "
            "ORDER BY created_at DESC LIMIT :lim"
        ), {"sid": session_id, "lim": limit})
        rows = [dict(zip(result.keys(), row)) for row in result.fetchall()]
        return list(reversed(rows))


def save_conversation(session_id: str, role: str, content: str, sql_query: str | None = None):
    """Save a conversation turn."""
    with SQLSession() as session:
        session.execute(text(
            "INSERT INTO conversation (session_id, role, content, sql_query) "
            "VALUES (:sid, :role, :content, :sql)"
        ), {"sid": session_id, "role": role, "content": content, "sql": sql_query})
        session.commit()


def get_conversation_summary(session_id: str) -> str | None:
    """Get stored conversation summary for a session."""
    with SQLSession() as session:
        result = session.execute(text(
            "SELECT summary FROM conversation_summary WHERE session_id = :sid"
        ), {"sid": session_id})
        row = result.fetchone()
        return row[0] if row else None


def save_conversation_summary(session_id: str, summary: str, approximate_tokens: int = 0):
    """Upsert conversation summary."""
    with SQLSession() as session:
        session.execute(text(
            "INSERT INTO conversation_summary (session_id, summary, approximate_tokens, updated_at) "
            "VALUES (:sid, :summary, :tokens, NOW()) "
            "ON CONFLICT (session_id) DO UPDATE SET summary = :summary, "
            "approximate_tokens = :tokens, updated_at = NOW()"
        ), {"sid": session_id, "summary": summary, "tokens": approximate_tokens})
        session.commit()
