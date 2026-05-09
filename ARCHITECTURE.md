# Architecture Deep Dive

## System Overview

The Unified Multi-Agent System uses LangGraph to orchestrate multiple AI agents through an LLM-driven supervisor. The system combines Retrieval-Augmented Generation (RAG), Text-to-SQL, and Action execution pipelines.

## Core Architecture

```
User Query -> FastAPI -> LangGraph Pipeline
                          |
                          v
                    [Phase 0: Parallel Init]
                    Guard + Embed + Memory + Cache L1
                          |
                          v
                    [Phase 1: Supervisor]
                    LLM Intent Detection (fast model)
                          |
                   +------+------+------+
                   v      v      v      v
                 [RAG]  [SQL]  [Action] [Compound]
                   |      |      |      |
                   v      v      v      v
              Pinecone  Pinecone ReAct  Parallel
              Domain    Schema   Loop   RAG+SQL
              Search    Search          -> Merge
```

## Vector Store: Pinecone

### rag-base Index (384-dim, ONNX embeddings)

- **Namespaces**: HR, PRODUCT, AI (domain-based routing)
- **Data**: Document chunks with metadata (source, chunk_index, timestamp)
- **Search**: Domain router (LLM) selects namespace, then vector similarity search
- **Upload**: Documents uploaded via `POST /api/documents/upload` API with domain tag
- **Seed**: Initial data loaded from `data/rag_seed.json` on startup

### sql-base Index (384-dim, ONNX embeddings)

- **Data**: Schema descriptions (table.column: description)
- **Search**: Hybrid - Pinecone semantic + keyword overlap + RRF fusion

## Prompt Registry

All prompts stored in PostgreSQL `prompt_template` table:

- Versioned (version column)
- Active flag for A/B testing
- model_hint (fast/heavy) for model selection
- Fetched at runtime, never hardcoded
- Cached in memory (5 min TTL)

Prompts: supervisor_intent, domain_router, rag_generation, complexity_detection,
ambiguity_resolution, sql_generation, response_synthesis, response_system,
memory_summarization, sql_self_consistency, react_system, supervisor_merge

## Model Routing

| Task                   | Model       | Rationale                      |
| ---------------------- | ----------- | ------------------------------ |
| Intent detection       | Fast (8B)   | Low complexity, speed critical |
| Domain routing         | Fast (8B)   | Simple classification          |
| Ambiguity detection    | Fast (8B)   | Quick decision                 |
| SQL generation         | Heavy (70B) | Complex reasoning needed       |
| RAG generation         | Heavy (70B) | Quality answer generation      |
| Self-consistency       | Fast (8B)   | Simple verification            |
| Response synthesis     | Fast (8B)   | Summarization                  |
| Guardrails (injection) | Fast (8B)   | Speed critical                 |
| RAGAS evaluation       | Fast (8B)   | Background evaluation          |
| Supervisor merge       | Fast (8B)   | Simple combination             |

## Semantic Cache (Redis)

Structure per cached entry:

```json
{
  "query": "...",
  "embedding": [384 floats],
  "result": { "answer": "...", "pipeline": "rag|sql" },
  "metadata": {
    "prompt_version": 1,
    "model": "llama-3.3-70b-versatile",
    "timestamp": 1234567890.0,
    "pipeline": "rag",
    "domain": "HR"
  },
  "ttl": 300
}
```

Search flow:

1. Generate embedding for query
2. Exact hash match (O(1))
3. KNN vector similarity search via RediSearch
4. If similarity >= threshold -> return cached answer
5. Else generate answer -> store in Redis with metadata

## Ambiguity Handling

- If ambiguity detected AND conversation history exists:
  -> Use history to infer intent
  -> Provide 2-3 likely interpretations as suggestions
  -> Ask user to select one

- If ambiguity detected AND no useful history:
  -> Do NOT assume intent
  -> Ask user for clarification directly

## PostgreSQL Checkpointer

LangGraph state is checkpointed to PostgreSQL (not in-memory):

- Enables HITL interrupts (SQL approval, ReAct tool approval)
- Survives process restarts
- Supports concurrent users via thread_id

## Guardrails (guardrails-ai approach)

4-layer security:

1. **Prompt Injection**: Regex patterns + LLM-based detection (fast model)
2. **Indirect Injection**: Zero-width chars, embedded instructions in context
3. **PII Detection**: SSN, credit cards, emails, credentials -> redacted
4. **SQL Safety**: SELECT-only, blocks DDL/DML, dangerous patterns
5. **Output Parsing**: JSON extraction and validation

## RAGAS Evaluation

Uses ragas library for:

- Faithfulness scoring (answer vs context)
- Answer relevancy (answer vs question)
- Falls back to LLM-based evaluation if ragas lib fails
- Runs asynchronously (non-blocking)

## Metadata Storage

All metadata stored consistently across:

- **Pinecone**: domain, source, chunk_index, timestamp per vector
- **PostgreSQL**: prompt_version, model, latency_ms per query_log
- **Redis**: prompt_version, model, timestamp, pipeline, domain per cache entry

## Resilience Patterns

- Circuit Breaker: 5 failures -> open (30s recovery)
- Rate Limiter: Token bucket (30 tokens, 10 refill/sec)
- Pre-configured for: LLM, Redis, DB, Embeddings
