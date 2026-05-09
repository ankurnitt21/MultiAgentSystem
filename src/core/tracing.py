"""OpenTelemetry tracing setup - exports spans to LangSmith via OTLP.

Each agent gets its own span, nested under a root 'unified_pipeline' span.
"""

import os
import time
from functools import wraps
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.sdk.resources import Resource
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter

_initialized = False
_pipeline_contexts: dict = {}


def setup_otel():
    """Initialize OTEL tracing with LangSmith OTLP endpoint."""
    global _initialized
    if _initialized:
        return
    _initialized = True

    endpoint = os.environ.get("OTEL_EXPORTER_OTLP_ENDPOINT", "https://api.smith.langchain.com/otel")
    api_key = os.environ.get("LANGCHAIN_API_KEY", os.environ.get("LANGSMITH_API_KEY", ""))
    service_name = os.environ.get("OTEL_SERVICE_NAME", "UnifiedMultiAgentSystem")

    if not api_key:
        return

    project = os.environ.get("LANGCHAIN_PROJECT", "UnifiedMultiAgentSystem")

    resource = Resource.create({
        "service.name": service_name,
        "project.name": project,
    })

    provider = TracerProvider(resource=resource)

    headers = {
        "x-api-key": api_key,
        "Langsmith-Project": project,
    }

    exporter = OTLPSpanExporter(
        endpoint=f"{endpoint}/v1/traces",
        headers=headers,
    )
    provider.add_span_processor(BatchSpanProcessor(exporter))
    trace.set_tracer_provider(provider)


def get_tracer(name: str = "unified_multi_agent"):
    """Get an OTEL tracer."""
    return trace.get_tracer(name)


def set_pipeline_context(session_id: str, ctx):
    """Store the root pipeline span context for a session."""
    _pipeline_contexts[session_id] = ctx


def clear_pipeline_context(session_id: str):
    """Remove pipeline context after request completes."""
    _pipeline_contexts.pop(session_id, None)


def _get_parent_context(state: dict):
    """Get parent context from the pipeline context store."""
    session_id = state.get("session_id", "")
    return _pipeline_contexts.get(session_id)


def trace_agent_node(node_name: str):
    """Decorator: wraps an agent node function with OTEL span tracing."""
    def decorator(func):
        @wraps(func)
        def wrapper(state: dict) -> dict:
            tracer = get_tracer()
            parent_ctx = _get_parent_context(state)
            start_time = time.time()

            with tracer.start_as_current_span(f"agent.{node_name}", context=parent_ctx) as span:
                span.set_attribute("langsmith.span.kind", "chain")
                span.set_attribute("agent.name", node_name)
                span.set_attribute("input.value", state.get("original_query", "")[:500])

                try:
                    result = func(state)
                    latency_ms = (time.time() - start_time) * 1000
                    span.set_attribute("latency_ms", latency_ms)

                    if isinstance(result, dict):
                        output_summary = (
                            result.get("final_answer")
                            or result.get("rag_answer")
                            or result.get("sql_explanation")
                            or result.get("generated_sql")
                            or result.get("rewritten_query")
                            or ""
                        )
                        span.set_attribute("output.value", str(output_summary)[:500])
                        span.set_attribute("output.status", result.get("status", ""))

                        if result.get("error"):
                            span.set_attribute("output.error", result["error"][:500])
                            span.set_status(trace.Status(trace.StatusCode.ERROR, result["error"][:200]))

                        # Decision trace
                        decision_entry = {
                            "node": node_name,
                            "latency_ms": round(latency_ms, 1),
                        }
                        if result.get("error"):
                            decision_entry["outcome"] = "error"
                        elif result.get("cache_hit"):
                            decision_entry["outcome"] = "cache_hit"
                        else:
                            decision_entry["outcome"] = "success"

                        existing_trace = state.get("decision_trace", [])
                        result["decision_trace"] = existing_trace + [decision_entry]

                    span.set_status(trace.Status(trace.StatusCode.OK))
                    return result

                except Exception as e:
                    latency_ms = (time.time() - start_time) * 1000
                    span.set_attribute("latency_ms", latency_ms)
                    span.set_status(trace.Status(trace.StatusCode.ERROR, str(e)[:200]))
                    span.record_exception(e)
                    raise

        return wrapper
    return decorator
