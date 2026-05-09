-- ============================================================================
-- RAG Database Schema (ragbase_db)
-- PostgreSQL with pgvector extension
-- ============================================================================

-- Enable pgvector
CREATE EXTENSION IF NOT EXISTS vector;

-- ─── Documents (parent records) ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS documents (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(500) NOT NULL,
    domain VARCHAR(50) NOT NULL DEFAULT 'HR',
    source VARCHAR(500),
    version INTEGER DEFAULT 1,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ─── Document Chunks (hybrid retrieval) ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS document_chunks (
    id BIGSERIAL PRIMARY KEY,
    document_id BIGINT REFERENCES documents(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    domain VARCHAR(50) NOT NULL DEFAULT 'HR',
    source VARCHAR(500),
    chunk_index INTEGER DEFAULT 0,
    metadata JSONB DEFAULT '{}',
    embedding vector(384),
    created_at TIMESTAMP DEFAULT NOW()
);

-- HNSW index for fast vector search
CREATE INDEX IF NOT EXISTS idx_chunks_embedding ON document_chunks
    USING hnsw (embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);

-- Full-text search index for BM25
CREATE INDEX IF NOT EXISTS idx_chunks_fts ON document_chunks
    USING gin(to_tsvector('english', content));

-- Domain index
CREATE INDEX IF NOT EXISTS idx_chunks_domain ON document_chunks(domain);

-- ─── Query Logs (observability) ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS query_logs (
    id BIGSERIAL PRIMARY KEY,
    query TEXT NOT NULL,
    response TEXT,
    domain VARCHAR(50),
    latency_ms FLOAT,
    confidence VARCHAR(20),
    ragas_faithfulness FLOAT,
    prompt_version INTEGER,
    created_at TIMESTAMP DEFAULT NOW()
);

-- ─── Prompt Templates ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS rag_prompt_templates (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    version INTEGER DEFAULT 1,
    template TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════════════════════
-- SEED DATA: Sample HR documents
-- ═══════════════════════════════════════════════════════════════════════════

INSERT INTO documents (title, domain, source, version) VALUES
    ('Employee Leave Policy', 'HR', 'hr_policy_2024.pdf', 1),
    ('Compensation & Benefits Guide', 'HR', 'compensation_guide.pdf', 1),
    ('Product Catalog 2024', 'PRODUCT', 'product_catalog.pdf', 1),
    ('AI/ML Best Practices', 'AI', 'ai_ml_guide.pdf', 1);

INSERT INTO document_chunks (document_id, content, domain, source, chunk_index) VALUES
    (1, 'Annual Leave: All full-time employees are entitled to 24 days of paid annual leave per calendar year. Leave accrues at 2 days per month. Unused leave can be carried forward up to 5 days into the next year. Leave requests must be submitted at least 2 weeks in advance for periods longer than 3 days.', 'HR', 'hr_policy_2024.pdf', 0),
    (1, 'Sick Leave: Employees receive 12 days of paid sick leave per year. A medical certificate is required for absences exceeding 3 consecutive days. Unused sick leave does not carry forward. Part-time employees receive pro-rated sick leave based on their contracted hours.', 'HR', 'hr_policy_2024.pdf', 1),
    (1, 'Maternity & Paternity Leave: Female employees are entitled to 16 weeks of paid maternity leave. Male employees receive 4 weeks of paid paternity leave. Both must be taken within 12 months of the child''s birth. Additional unpaid leave of up to 6 months may be requested.', 'HR', 'hr_policy_2024.pdf', 2),
    (1, 'Work From Home Policy: Employees may work from home up to 3 days per week with manager approval. A stable internet connection and dedicated workspace are required. Core hours of 10 AM - 4 PM must be observed for meetings and collaboration.', 'HR', 'hr_policy_2024.pdf', 3),
    (2, 'Base Salary Structure: Salaries are reviewed annually in March. Pay bands are organized by job level: Junior (L1-L3), Senior (L4-L6), Management (L7-L9), Executive (L10+). Each level has a salary range with 25th, 50th, and 75th percentile benchmarks.', 'HR', 'compensation_guide.pdf', 0),
    (2, 'Health Insurance: The company provides comprehensive health insurance covering medical, dental, and vision care. Family coverage is available with employee contribution of 20%. Annual deductible is $500 individual / $1500 family. Mental health services are fully covered.', 'HR', 'compensation_guide.pdf', 1),
    (2, 'Retirement Benefits: 401(k) plan with company match of 100% on first 3% and 50% on next 2% of salary. Employees are eligible after 90 days of employment. Vesting schedule: 25% per year over 4 years. Financial planning consultations are available quarterly.', 'HR', 'compensation_guide.pdf', 2),
    (3, 'Product Line Overview: Our warehouse manages products across 5 categories: Electronics, Office Supplies, Industrial Equipment, Safety Gear, and Raw Materials. Each product has SKU, cost price, selling price, and reorder levels defined. Seasonal demand patterns affect inventory planning.', 'PRODUCT', 'product_catalog.pdf', 0),
    (3, 'Pricing Strategy: Products are priced using cost-plus methodology with target margins of 25-40% depending on category. Volume discounts are available: 5% for 100+ units, 10% for 500+ units, 15% for 1000+ units. Special pricing requires management approval.', 'PRODUCT', 'product_catalog.pdf', 1),
    (4, 'RAG Architecture: Retrieval-Augmented Generation combines document retrieval with LLM generation. Key components: Vector embeddings (dense retrieval), BM25 (sparse retrieval), Reciprocal Rank Fusion (hybrid combining). Best practice: chunk documents at 300-500 tokens with 50-token overlap.', 'AI', 'ai_ml_guide.pdf', 0),
    (4, 'LangGraph Patterns: LangGraph enables building stateful multi-agent systems. Key patterns: Supervisor agent (orchestration), ReAct agent (reasoning + acting), Parallel execution (concurrent tasks), Human-in-the-loop (interrupt/resume). State is managed via TypedDict and checkpointed to PostgreSQL.', 'AI', 'ai_ml_guide.pdf', 1),
    (4, 'Prompt Engineering: Effective prompts use structured output (JSON), few-shot examples, and chain-of-thought reasoning. System prompts should be versioned and stored in databases. Dynamic prompts improve maintainability. Temperature 0 for deterministic outputs, 0.7 for creative tasks.', 'AI', 'ai_ml_guide.pdf', 2);
