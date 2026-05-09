# System Flowchart

## Complete Pipeline Flow

```
[User Query]
     |
     v
[Phase 0: Parallel Init]
  |-- Guardrails (regex + LLM injection detection, fast model)
  |-- Embedding (ONNX fastembed, all-MiniLM-L6-v2, 384-dim)
  |-- Memory Load (conversation history + summary from PostgreSQL)
  |-- Cache L1 Check (Redis KNN vector search)
     |
     v
  Guard Failed? --> [END: Blocked]
  Cache Hit? --> [Respond from Cache] --> [END]
     |
     v
[Phase 1: Supervisor Intent Detection (fast model)]
  LLM classifies: rag | sql | action | compound
     |
     +----> [RAG Pipeline]
     |        |-- Domain Router (fast model -> Pinecone namespace)
     |        |-- Pinecone Search (rag-base index, domain namespace)
     |        |-- Context Guard (indirect injection check)
     |        |-- RAG Generation (heavy model + prompt registry)
     |        |-- PII Guard (output sanitization)
     |        |-- Cache Write (Redis + metadata)
     |        |-- Query Log (PostgreSQL + metadata)
     |        --> [END]
     |
     +----> [SQL Pipeline]
     |        |-- Complexity Detection (fast model)
     |        |-- Ambiguity Resolution (fast model + conversation history)
     |        |   |-- Ambiguous + History? -> Infer intent, suggest interpretations
     |        |   |-- Ambiguous + No History? -> Ask for clarification
     |        |   |-- Clear? -> Rewrite query
     |        |-- Cache L2 Check (Redis, rewritten query)
     |        |-- Schema Retrieval (Pinecone sql-base + keyword RRF)
     |        |-- SQL Generation (heavy model + function calling)
     |        |-- Self-Consistency (fast model)
     |        |-- SQL Validation (5-layer: safety, schema, patterns, logic, cost)
     |        |-- HITL Approval (if enabled, PostgreSQL checkpoint)
     |        |-- SQL Execution (warehouse DB)
     |        |-- Response Synthesis (fast model)
     |        |-- Cache Write (Redis + metadata)
     |        --> [END]
     |
     +----> [Action Pipeline (ReAct)]
     |        |-- LLM Think (heavy model)
     |        |-- HITL Approval (PostgreSQL checkpoint)
     |        |-- Tool Execute
     |        |-- Loop (max 5 steps)
     |        --> [END]
     |
     +----> [Compound Pipeline]
              |-- Parallel(RAG + SQL)
              |-- Supervisor Merge (fast model)
              --> [END]
```

## Model Routing Flow

```
Fast Model (llama-3.1-8b-instant):
  - Supervisor intent detection
  - Domain routing
  - Complexity detection
  - Ambiguity resolution
  - Self-consistency check
  - Response synthesis
  - Memory summarization
  - Guardrails injection detection
  - RAGAS evaluation
  - Supervisor merge

Heavy Model (llama-3.3-70b-versatile):
  - SQL generation (function calling)
  - RAG answer generation
  - ReAct action agent
```

## Cache Architecture

```
[Query] --> [Embed (ONNX)]
               |
               v
         [Redis Vector Index]
         Hash Match (O(1)) --> HIT --> [Return Cached]
               |
         KNN Search (cosine) --> similarity >= 0.92 --> [Return Cached]
               |
               v
         [MISS: Generate Answer]
               |
               v
         [Store in Redis]
         {
           embedding: [384 floats],
           query: "...",
           result: { answer, pipeline },
           metadata: { prompt_version, model, timestamp }
         }
```

## Pinecone Architecture

```
rag-base index (384-dim):
  Namespace: HR
    |-- hr_policy_2024.pdf chunks
    |-- compensation_guide.pdf chunks
  Namespace: PRODUCT
    |-- product_catalog.pdf chunks
  Namespace: AI
    |-- ai_ml_guide.pdf chunks

sql-base index (384-dim):
  (no namespace)
    |-- warehouse.name: "Warehouse name" (varchar)
    |-- product.cost_price: "Product cost price" (numeric)
    |-- ... all schema descriptions
```

## Document Upload Flow

```
[POST /api/documents/upload]
  { domain: "HR", chunks: [{content, source}], source: "policy.pdf" }
     |
     v
  [Embed chunks (ONNX fastembed)]
     |
     v
  [Upsert to Pinecone rag-base]
     |-- Namespace = domain.upper() (HR, PRODUCT, AI, etc.)
     |-- Metadata: content, domain, source, chunk_index, timestamp
     |
     v
  [Response: {status: ok, domain: HR, chunks_uploaded: 5}]

On Startup:
  data/rag_seed.json --> seed_rag_from_file() --> Pinecone (skip if already seeded)
```
