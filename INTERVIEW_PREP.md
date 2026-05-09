# Interview Preparation Guide

## System Overview Questions

**Q: Walk me through the architecture of your Unified Multi-Agent System.**

The system uses LangGraph to orchestrate a Supervisor-driven pipeline. A query enters through FastAPI, undergoes parallel initialization (guardrails, embedding, memory, cache check), then the Supervisor (fast LLM) classifies intent as RAG, SQL, Action, or Compound. Each pipeline has specialized nodes. Key design choices: Pinecone for vector storage with domain namespaces, PostgreSQL checkpointing for HITL, Redis Stack for semantic caching, and a prompt registry for versioned prompts.

**Q: Why did you choose Pinecone over pgvector?**

Pinecone provides managed infrastructure with built-in namespace support for domain routing. We use rag-base index with HR/PRODUCT/AI namespaces to scope searches, and sql-base index for schema embeddings. Both use 384-dim embeddings from ONNX (all-MiniLM-L6-v2). Namespaces eliminate cross-domain contamination in search results.

**Q: How does your model routing work?**

We use two Groq models: llama-3.3-70b-versatile (heavy) for SQL generation and RAG answer generation where quality matters, and llama-3.1-8b-instant (fast) for everything else - intent detection, domain routing, ambiguity, guardrails, RAGAS evaluation. This optimizes cost and latency without sacrificing quality on critical tasks.

## Pipeline-Specific Questions

**Q: How does the RAG pipeline handle domain routing?**

The Domain Router node fetches the `domain_router` prompt from the registry, sends the query to the fast LLM, which classifies the domain (HR, PRODUCT, AI, GENERAL). This domain becomes the Pinecone namespace for the search. If GENERAL, we search across all namespaces. The prompt version and model used are logged to PostgreSQL.

**Q: How do you handle ambiguous SQL queries?**

Two scenarios:

1. **With conversation history**: The fast LLM uses the ambiguity_resolution prompt with `{history_context}` to infer intent from prior conversation. It provides 2-3 likely interpretations as suggestions.
2. **Without history**: It does NOT assume intent. Instead, it asks the user for clarification directly. The status becomes "awaiting_clarification" and the graph checkpoints to PostgreSQL.

**Q: Why PostgreSQL checkpointing instead of in-memory?**

PostgreSQL checkpointing via `langgraph.checkpoint.postgres.PostgresSaver` ensures HITL (Human-in-the-Loop) state survives process restarts. When a user needs to approve SQL execution, the graph state is durably saved. In-memory would lose state on any restart or scale-out.

## Caching Strategy Questions

**Q: How does your semantic cache work?**

Redis Stack with RediSearch. Each cache entry stores: embedding vector (384 floats), query text, result JSON, and metadata (prompt_version, model, timestamp, pipeline, domain). Lookup: first exact hash match (O(1)), then KNN vector similarity search. Threshold at 0.92 cosine similarity. Metadata ensures cache hits are from the same prompt version.

**Q: Why not use embeddings as Redis keys?**

Embeddings are stored as separate vector fields, not as keys. This enables KNN similarity search via RediSearch FT.SEARCH. Direct key lookup only works for exact matches. Vector similarity catches semantically equivalent queries even if phrased differently.

## Security & Quality Questions

**Q: How do you prevent prompt injection?**

Multi-layer approach using guardrails-ai patterns:

1. Regex patterns catch known injection phrases
2. Heuristic scoring (special chars, instruction words, length anomalies)
3. LLM-based detection using fast model for sophisticated attacks
4. Context-level: check retrieved documents for embedded instructions
5. Output-level: PII redaction before returning

**Q: How do you evaluate RAG quality?**

RAGAS library integration:

- Faithfulness: measures if the answer is supported by retrieved context
- Answer relevancy: measures if the answer addresses the question
- Falls back to LLM-based evaluation if ragas library encounters issues
- Uses fast model to minimize overhead
- Runs asynchronously so it doesnt block the response

## Prompt Registry Questions

**Q: What is the prompt registry and why use it?**

All 12 system prompts are stored in a PostgreSQL `prompt_template` table with columns: name, version, template, model_hint, is_active. At runtime, agents fetch prompts by name and use the active version. This enables A/B testing, prompt versioning, and hot-swapping without code changes. The registry also specifies which model type (fast/heavy) should be used with each prompt.

## Production Readiness Questions

**Q: How does your system handle failures?**

- Circuit Breaker pattern: opens after 5 failures, 30s recovery
- Rate Limiter: token bucket (30 tokens, 10 refill/sec)
- Pre-configured for LLM calls, Redis, database, and embeddings
- SQL retry: up to 3 attempts on validation/execution failure
- Graceful fallbacks: cache miss -> generate, ragas fail -> LLM-based eval

## Document Management Questions

**Q: How do you manage RAG documents?**

Documents are uploaded via `POST /api/documents/upload` with a domain tag (HR, PRODUCT, AI, etc.). The API chunks are embedded using ONNX fastembed (all-MiniLM-L6-v2) and upserted into Pinecone rag-base index under the domain's namespace. Metadata (source, chunk_index, timestamp) is stored with each vector. Initial seed data is loaded from `data/rag_seed.json` on startup, but only if the namespace is empty.

**Q: How do you store SQL schema in the vector store?**

Schema descriptions from the `schema_description` PostgreSQL table are embedded and stored in Pinecone sql-base index. Each entry includes table_name, column_name, data_type, domain, and a natural language description. The descriptions include column sizes, types, constraints, and business context. This enables semantic search: "products by price" matches `product.unit_price` and `product.cost_price`.

**Q: What embedding model do you use and why?**

ONNX-based fastembed with all-MiniLM-L6-v2 (384 dimensions). It runs locally without external API calls, is fast (3-5x faster than transformer models), deterministic, and free. Both Pinecone indexes (rag-base and sql-base) use the same 384-dim model for consistency. The model is lazy-loaded once and cached as a singleton.
