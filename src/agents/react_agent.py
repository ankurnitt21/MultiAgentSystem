"""ReAct Action Agent - Tool-calling agent with HITL approval.

Flow: Think → Interrupt(approve) → Execute → Loop (max 5 iterations)
"""

import json
from langchain_core.messages import SystemMessage, HumanMessage
from langchain_groq import ChatGroq
from langgraph.types import interrupt, Command
from src.core import get_settings
from src.core.state import AgentState
from src.core.prompts import get_prompt
from src.core.tracing import trace_agent_node
from src.core.resilience import resilient_call, llm_circuit, llm_rate_limiter
from src.agents.action_tools import execute_tool, get_tools_prompt
import structlog

log = structlog.get_logger()
settings = get_settings()

MAX_REACT_STEPS = 5


@trace_agent_node("react_agent")
def react_agent_node(state: AgentState) -> dict:
    """ReAct loop: LLM thinks → HITL approval → execute tool → repeat.

    Each invocation is one iteration of the loop.
    The graph re-enters this node until done or max steps reached.
    """
    query = state.get("original_query", "")
    messages = state.get("messages", [])
    steps = state.get("react_steps", [])
    pending = state.get("pending_tool_call", {})

    # ── If resuming from an interrupt (user approved/rejected) ──
    if pending:
        return _handle_approval_resume(state)

    # ── Check step limit ──
    if len(steps) >= MAX_REACT_STEPS:
        summary = _build_summary(steps)
        return {
            "messages": messages,
            "react_result": f"Reached maximum steps ({MAX_REACT_STEPS}). {summary}",
            "status": "completed",
        }

    # ── LLM Thinks ──
    tools_prompt = get_tools_prompt()
    try:
        system_content = get_prompt("react_system")
    except Exception:
        system_content = f"{tools_prompt}\nYou are an action agent. Reply with JSON: {{\"action\": \"call_tool\", ...}} or {{\"action\": \"done\", ...}}"

    system_content = system_content.format(tools_prompt=tools_prompt, max_steps=MAX_REACT_STEPS)

    # Build conversation context
    context_parts = [f"User request: {query}"]
    for step in steps:
        context_parts.append(
            f"Step {step.get('step', '?')}: Called {step.get('tool', '?')} → "
            f"{'SUCCESS' if step.get('success') else 'FAILED'}: {step.get('message', '')[:200]}"
        )

    llm = ChatGroq(api_key=settings.groq_api_key, model=settings.groq_chat_model, temperature=0)

    try:
        response = resilient_call(
            llm.invoke,
            [
                SystemMessage(content=system_content),
                HumanMessage(content="\n".join(context_parts)),
            ],
            circuit=llm_circuit, rate_limiter=llm_rate_limiter,
        )

        text = response.content.strip()
        if text.startswith("```"):
            text = text.split("\n", 1)[-1].rsplit("```", 1)[0].strip()
        data = json.loads(text)

    except Exception as e:
        log.error("react_llm_error", error=str(e))
        return {
            "messages": messages,
            "react_result": f"ReAct agent error: {str(e)}",
            "status": "failed",
        }

    action = data.get("action", "done")

    # ── DONE ──
    if action == "done":
        summary = data.get("summary", _build_summary(steps))
        return {
            "messages": messages,
            "react_result": summary,
            "react_steps": steps,
            "status": "completed",
        }

    # ── CALL TOOL → Interrupt for approval ──
    tool_name = data.get("tool_name", "")
    tool_args = data.get("tool_args", {})
    reasoning = data.get("reasoning", "")

    step_num = len(steps) + 1
    pending_call = {
        "tool_name": tool_name,
        "tool_args": tool_args,
        "reasoning": reasoning,
        "step": step_num,
    }

    log.info("react_tool_proposed", tool=tool_name, step=step_num)

    # HITL Interrupt
    user_decision = interrupt({
        "status": "awaiting_tool_approval",
        "pending_tool_call": pending_call,
    })

    # After resume
    approved = user_decision.get("approved", False) if isinstance(user_decision, dict) else False
    feedback = user_decision.get("feedback", "") if isinstance(user_decision, dict) else ""

    if not approved:
        steps.append({
            "step": step_num, "tool": tool_name, "args": tool_args,
            "reasoning": reasoning, "approved": False, "success": False,
            "message": f"Rejected by user. {feedback}",
        })
        if feedback:
            return {
                "messages": messages, "react_steps": steps,
                "pending_tool_call": {},
                "status": "processing",
            }
        return {
            "messages": messages, "react_steps": steps,
            "react_result": f"Action rejected by user. {feedback}",
            "pending_tool_call": {},
            "status": "action_rejected",
        }

    # Execute tool
    result = execute_tool(tool_name, tool_args)
    steps.append({
        "step": step_num, "tool": tool_name, "args": tool_args,
        "reasoning": reasoning, "approved": True,
        "success": result.get("success", False),
        "message": result.get("message", ""),
        "result": result.get("data", {}),
    })

    log.info("react_tool_executed", tool=tool_name, success=result.get("success"))

    return {
        "messages": messages,
        "react_steps": steps,
        "pending_tool_call": {},
        "status": "processing",
    }


def _handle_approval_resume(state: AgentState) -> dict:
    """Handle resumption after HITL approval interrupt."""
    messages = state.get("messages", [])
    steps = list(state.get("react_steps", []))
    pending = state.get("pending_tool_call", {})

    tool_name = pending.get("tool_name", "")
    tool_args = pending.get("tool_args", {})
    reasoning = pending.get("reasoning", "")
    step_num = pending.get("step", len(steps) + 1)

    result = execute_tool(tool_name, tool_args)
    steps.append({
        "step": step_num, "tool": tool_name, "args": tool_args,
        "reasoning": reasoning, "approved": True,
        "success": result.get("success", False),
        "message": result.get("message", ""),
        "result": result.get("data", {}),
    })

    return {
        "messages": messages,
        "react_steps": steps,
        "pending_tool_call": {},
        "status": "processing",
    }


def _build_summary(steps: list[dict]) -> str:
    """Build a summary of all executed steps."""
    if not steps:
        return "No actions were taken."
    parts = []
    for s in steps:
        status = "SUCCESS" if s.get("success") else "FAILED"
        parts.append(f"Step {s.get('step')}: {s.get('tool')} → {status}: {s.get('message', '')[:100]}")
    return "\n".join(parts)
