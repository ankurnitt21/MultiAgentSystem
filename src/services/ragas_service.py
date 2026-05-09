"""RAGAS Evaluation Service - Using ragas library for evaluation metrics.

Uses ragas library for:
  - Faithfulness scoring
  - Answer relevancy
  - Context precision

Falls back to LLM-based evaluation if ragas lib fails.
Uses fast model for evaluation.
"""

import json
from langchain_core.messages import SystemMessage, HumanMessage
from langchain_groq import ChatGroq
from src.core import get_settings
from src.core.resilience import resilient_call, llm_circuit, llm_rate_limiter
import structlog

log = structlog.get_logger()
settings = get_settings()


def _get_fast_llm():
    return ChatGroq(api_key=settings.groq_api_key, model=settings.groq_fast_model, temperature=0)


def evaluate_faithfulness(query: str, answer: str, context: str) -> float | None:
    """Score faithfulness of an answer against retrieved context.

    Tries ragas library first, falls back to LLM-based evaluation.
    Returns a score 0.0-1.0, or None on failure.
    """
    # Try ragas library
    try:
        from ragas.metrics import faithfulness
        from ragas import evaluate
        from datasets import Dataset

        ds = Dataset.from_dict({
            "question": [query],
            "answer": [answer],
            "contexts": [[context[:3000]]],
        })

        result = evaluate(ds, metrics=[faithfulness])
        score = float(result.get("faithfulness", 0.0))
        log.info("ragas_faithfulness_scored", score=score, method="ragas_lib")
        return score
    except Exception as e:
        log.debug("ragas_lib_evaluation_failed", error=str(e))

    # Fallback: LLM-based evaluation using fast model
    try:
        llm = _get_fast_llm()

        prompt = f"""Rate how faithfully this answer is supported by the provided context.

Context:
{context[:3000]}

Question: {query}

Answer: {answer}

Score from 0.0 (completely unsupported) to 1.0 (fully supported by context).
Reply with ONLY a JSON: {{"faithfulness": 0.85}}
No explanation."""

        response = resilient_call(
            llm.invoke,
            [HumanMessage(content=prompt)],
            circuit=llm_circuit,
            rate_limiter=llm_rate_limiter,
        )

        text = response.content.strip()
        if text.startswith("```"):
            text = text.split("\n", 1)[-1].rsplit("```", 1)[0].strip()
        data = json.loads(text)
        score = float(data.get("faithfulness", 0.0))
        log.info("ragas_faithfulness_scored", score=score, method="llm_fallback")
        return score
    except Exception as e:
        log.warning("ragas_evaluation_failed", error=str(e))
        return None


def evaluate_answer_relevancy(query: str, answer: str) -> float | None:
    """Score how relevant the answer is to the question. Uses fast model."""
    try:
        llm = _get_fast_llm()
        prompt = f"""Rate how relevant this answer is to the question.
Question: {query}
Answer: {answer}
Score 0.0 (irrelevant) to 1.0 (perfectly relevant).
Reply ONLY JSON: {{"relevancy": 0.85}}"""

        response = resilient_call(
            llm.invoke,
            [HumanMessage(content=prompt)],
            circuit=llm_circuit,
            rate_limiter=llm_rate_limiter,
        )
        text = response.content.strip()
        if text.startswith("```"):
            text = text.split("\n", 1)[-1].rsplit("```", 1)[0].strip()
        data = json.loads(text)
        score = float(data.get("relevancy", 0.0))
        log.info("ragas_relevancy_scored", score=score)
        return score
    except Exception as e:
        log.warning("ragas_relevancy_failed", error=str(e))
        return None