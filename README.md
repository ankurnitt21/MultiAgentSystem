# Unified Multi-Agent System

LLM-driven multi-agent orchestration system combining RAG, SQL, and Action pipelines with LangGraph.

## Architecture

- **Supervisor Agent** - LLM-driven intent classification (fast model)
- **RAG Pipeline** - Domain-routed retrieval from Pinecone (domain namespaces) + heavy model generation
- **SQL Pipeline** - Text-to-SQL with Pinecone schema retrieval + heavy model generation
- **Action Pipeline** - ReAct agent with HITL approval
- **Compound Pipeline** - Parallel RAG + SQL execution with merge

## Tech Stack

| Component      | Technology                                              |
| -------------- | ------------------------------------------------------- |
| Orchestration  | LangGraph with PostgreSQL checkpointer                  |
| LLM            | Groq (llama-3.3-70b-versatile + llama-3.1-8b-instant)   |
| Vector Store   | Pinecone (rag-base + sql-base indexes, 384-dim)         |
| Embeddings     | ONNX via fastembed (all-MiniLM-L6-v2)                   |
| Semantic Cache | Redis Stack with RediSearch vector index                |
| SQL Database   | PostgreSQL (warehouse data + checkpoints + prompts)     |
| Guardrails     | guardrails-ai (prompt injection + PII + output parsing) |
| Evaluation     | RAGAS library (faithfulness + relevancy)                |
| Observability  | OpenTelemetry -> LangSmith                              |
| API            | FastAPI with SSE streaming                              |

## Key Design Decisions

1. **Pinecone over pgvector** - Managed vector store, domain namespaces for scoped search
2. **PostgreSQL Saver** - Durable checkpointing for HITL interrupts (not in-memory)
3. **Prompt Registry** - All prompts fetched from DB with versioning, no hardcoded prompts
4. **Redis Vector Search** - Semantic caching with proper embedding storage + KNN search
5. **Fast/Heavy Model Split** - Fast model for routing/ambiguity/guardrails, heavy model for SQL gen/RAG gen
6. **Domain Router** - LLM-based domain classification routes to Pinecone namespace
7. **Metadata Everywhere** - prompt_version, model, timestamp stored in Pinecone, Postgres, Redis
8. **Ambiguity Handling** - Uses conversation history to infer intent, provides contextual suggestions

## Quick Start

```bash
# 1. Start infrastructure
cd docker && docker compose up -d

# 2. Install dependencies
pip install -r requirements.txt

# 3. Configure environment
cp .env.example .env
# Fill in GROQ_API_KEY and PINECONE_API_KEY

# 4. Run
python run.py
```

Open http://localhost:8000 for the chat UI.

## API Endpoints

| Method | Path                  | Description                    |
| ------ | --------------------- | ------------------------------ |
| POST   | /api/query            | Execute query (sync)           |
| POST   | /api/query/stream     | Execute query (SSE streaming)  |
| POST   | /api/clarify          | Handle ambiguity clarification |
| POST   | /api/approve          | SQL approval (HITL)            |
| POST   | /api/action/approve   | ReAct tool approval            |
| POST   | /api/documents/upload | Upload RAG documents by domain |
| POST   | /api/feedback         | User feedback                  |
| GET    | /api/feedback/stats   | Feedback statistics            |
| GET    | /api/prompts          | List prompt templates          |
| GET    | /api/action/tools     | List available tools           |
| GET    | /health               | Health check                   |

## Project Structure

```
UnifiedMultiAgentSystem/
  main.py                 # FastAPI entry point
  run.py                  # Dev runner
  requirements.txt        # Dependencies
  .env                    # Environment config
  data/
    rag_seed.json         # RAG seed documents (uploaded via API on startup)
  docker/
    docker-compose.yml    # PostgreSQL + Redis Stack
    init/
      sql_schema.sql      # Warehouse schema + seed data
  src/
    core/
      __init__.py          # Settings (Pydantic)
      database.py          # SQL DB operations
      prompts.py           # Prompt registry (PostgreSQL)
      resilience.py        # Circuit breaker + rate limiter
      state.py             # AgentState TypedDict
      tracing.py           # OpenTelemetry setup
    agents/
      pipeline.py          # LangGraph graph builder
      supervisor_agent.py  # Intent detection
      rag_agent.py         # RAG pipeline (3 nodes)
      sql_agent.py         # SQL pipeline (7 nodes)
      react_agent.py       # ReAct action agent
      action_tools.py      # Executable tools
    services/
      pinecone_service.py  # Pinecone vector store operations
      embedding_service.py # ONNX embeddings (fastembed)
      cache_service.py     # Redis vector search caching
      retrieval_service.py # Hybrid retrieval (Pinecone + keyword)
      guardrails_service.py # guardrails-ai validation
      ragas_service.py     # RAGAS evaluation
      memory_service.py    # Conversation memory
      feedback_service.py  # User feedback
    api/
      routes.py            # FastAPI routes
      models.py            # Pydantic models
  static/
    index.html             # Chat UI
```

## Databases & Storage

| Store               | Purpose            | Data                                                           |
| ------------------- | ------------------ | -------------------------------------------------------------- |
| Pinecone (rag-base) | RAG documents      | Document chunks by domain namespace (HR, PRODUCT, AI)          |
| Pinecone (sql-base) | Schema embeddings  | Table/column descriptions for SQL pipeline                     |
| PostgreSQL          | Warehouse + system | Business tables, checkpoints, prompts, conversations, feedback |
| Redis Stack         | Semantic cache     | Query embeddings + results with KNN vector search              |

## Sample Queries

**RAG:** "What is the annual leave policy?" / "How does RAG architecture work?"
**SQL:** "Show top 5 products by price" / "How many pending shipments?"
**Action:** "Create a purchase order for product 5, qty 100"
**Compound:** "What is the leave policy and show me total employees?"
