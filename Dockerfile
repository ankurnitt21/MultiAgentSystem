# ============================================================================
# Unified Multi-Agent System — App Image
# Base: python:3.11-slim
# ============================================================================
FROM python:3.11-slim

LABEL org.opencontainers.image.title="UnifiedMultiAgent - App"
LABEL org.opencontainers.image.description="FastAPI + LangGraph multi-agent system"
LABEL maintainer="ranaankur39"

# Prevents Python from writing .pyc files and enables stdout/stderr logging
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

# Install system dependencies required by psycopg and other packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies first (layer caching)
COPY requirements.txt .
RUN pip install --upgrade pip && pip install -r requirements.txt

# Copy application source
COPY main.py .
COPY run.py .
COPY src/ ./src/
COPY static/ ./static/
COPY data/ ./data/

# The app reads configuration from environment variables (.env or Docker env).
# Do NOT copy .env — pass secrets via docker-compose env_file or -e flags.

EXPOSE 8000

# Use uvicorn directly (no reload in production)
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
