"""Supervisor Agent - LLM-driven intent detection and pipeline orchestration.

Uses fast model for intent detection, prompt registry for all prompts.
Logs prompt version and model for every execution.
"""

import json
from langchain_core.messages import SystemMessage, HumanMessage
from langchain_groq import ChatGroq
from src.core import get_settings
from src.core.state import AgentState
from src.core.prompts import get_prompt, get_prompt_with_meta
from src.core.tracing import trace_agent_node
from src.core.resilience import resilient_call, llm_circuit, llm_rate_limiter
from src.services.guardrails_service import parse_json_output
import structlog

log = structlog.get_logger()
settings = get_settings()


def _get_fast_llm():
    return ChatGroq(api_key=settings.groq_api_key, model=settings.groq_fast_model, temperature=0)


@trace_agent_node("supervisor_intent")
def supervisor_intent_node(state: AgentState) -> dict:
    """LLM-driven intent detection using fast model + prompt registry."""
    query = state.get("original_query", "")
    messages = state.get("messages", [])

    try:
        prompt_meta = get_prompt_with_meta("supervisor_intent")
        system_content = prompt_meta["template"]
        prompt_version = prompt_meta["version"]
    except Exception as e:
        log.error("prompt_load_failed", prompt="supervisor_intent", error=str(e))
        return {"messages": messages, "intent": "sql", "intent_confidence": 0.5,
                "detected_domains": ["SQL"]}

    try:
        llm = _get_fast_llm()
        response = resilient_call(
            llm.invoke,
            [SystemMessage(content=system_content), HumanMessage(content=query)],
            circuit=llm_circuit, rate_limiter=llm_rate_limiter,
        )

        data = parse_json_output(response.content, ["intent"])
        intent = data.get("intent", "sql")
        if intent not in ("rag", "sql", "action", "compound"):
            intent = "sql"

        confidence = float(data.get("confidence", 0.8))
        domains = data.get("detected_domains", [])

        log.info("supervisor_intent_detected", intent=intent, confidence=confidence,
                 domains=domains, query=query[:60],
                 prompt_version=prompt_version, model=settings.groq_fast_model)

        return {
            "messages": messages,
            "intent": intent,
            "intent_confidence": confidence,
            "detected_domains": domains,
        }

    except Exception as e:
        log.warning("supervisor_intent_failed", error=str(e), fallback="sql")
        return {"messages": messages, "intent": "sql", "intent_confidence": 0.5,
                "detected_domains": ["SQL"]}


@trace_agent_node("supervisor_merge")
def supervisor_merge_node(state: AgentState) -> dict:
    """Merge results from parallel RAG + SQL pipelines. Uses fast model."""
    messages = state.get("messages", [])
    rag_answer = state.get("rag_answer", "")
    sql_explanation = state.get("sql_explanation", "")

    if rag_answer and not sql_explanation:
        return {"messages": messages, "final_answer": rag_answer, "status": "completed"}

    if sql_explanation and not rag_answer:
        return {"messages": messages, "final_answer": sql_explanation, "status": "completed"}

    if rag_answer and sql_explanation:
        try:
            prompt_meta = get_prompt_with_meta("supervisor_merge")
            merge_prompt = prompt_meta["template"]

            llm = _get_fast_llm()
            formatted = merge_prompt.format(rag_result=rag_answer, sql_result=sql_explanation)

            response = resilient_call(
                llm.invoke,
                [HumanMessage(content=formatted)],
                circuit=llm_circuit, rate_limiter=llm_rate_limiter,
            )

            return {"messages": messages, "final_answer": response.content, "status": "completed"}
        except Exception as e:
            log.warning("supervisor_merge_failed", error=str(e))
            return {
                "messages": messages,
                "final_answer": f"**Knowledge Base:**\n{rag_answer}\n\n**Database Query:**\n{sql_explanation}",
                "status": "completed",
            }

    return {
        "messages": messages,
        "final_answer": state.get("error", "No results from any pipeline."),
        "status": "failed" if state.get("error") else "completed",
    }