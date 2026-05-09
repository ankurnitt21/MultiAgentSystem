"""Action Tools - Executable tools the ReAct agent can call.

Each tool makes a real DB mutation or simulated external call.
"""

import uuid
from datetime import date, timedelta
from sqlalchemy import text
from src.core.database import SQLSession
import structlog

log = structlog.get_logger()

TOOLS: dict = {}


def register_tool(name: str):
    def decorator(fn):
        TOOLS[name] = fn
        return fn
    return decorator


def execute_tool(tool_name: str, tool_args: dict) -> dict:
    """Dispatch to the correct tool by name."""
    if tool_name not in TOOLS:
        return {"success": False, "message": f"Unknown tool: {tool_name}", "data": {}}
    try:
        return TOOLS[tool_name](**tool_args)
    except TypeError as e:
        return {"success": False, "message": f"Invalid args for {tool_name}: {e}", "data": {}}
    except Exception as e:
        log.error("tool_execution_error", tool=tool_name, error=str(e))
        return {"success": False, "message": f"Tool error: {e}", "data": {}}


@register_tool("create_po")
def create_po(product_id: int, qty: int, warehouse_id: int = 1) -> dict:
    """Create a Purchase Order for a product."""
    with SQLSession() as session:
        row = session.execute(text(
            "SELECT supplier_id, cost_price, name FROM product WHERE id = :pid"
        ), {"pid": product_id}).fetchone()
        if not row:
            return {"success": False, "message": f"Product {product_id} not found", "data": {}}

        supplier_id, cost_price, product_name = row
        cost_price = cost_price or 0.0
        po_number = f"PO-{date.today().strftime('%Y%m%d')}-{str(uuid.uuid4())[:6].upper()}"
        total = float(cost_price) * qty
        expected = date.today() + timedelta(days=7)

        session.execute(text("""
            INSERT INTO purchase_order
                (po_number, supplier_id, warehouse_id, status, order_date, expected_delivery, total_amount, created_by)
            VALUES (:po_num, :sup_id, :wh_id, 'SUBMITTED', :od, :ed, :total, 'react_agent')
        """), {"po_num": po_number, "sup_id": supplier_id, "wh_id": warehouse_id,
               "od": date.today(), "ed": expected, "total": total})

        po_id = session.execute(text(
            "SELECT id FROM purchase_order WHERE po_number = :po_num"
        ), {"po_num": po_number}).scalar()

        session.execute(text("""
            INSERT INTO purchase_order_line
                (purchase_order_id, product_id, quantity_ordered, quantity_received, unit_price)
            VALUES (:po_id, :pid, :qty, 0, :up)
        """), {"po_id": po_id, "pid": product_id, "qty": qty, "up": float(cost_price)})
        session.commit()

    return {
        "success": True,
        "message": f"PO {po_number} created for {qty} units of '{product_name}'. Total: ${total:,.2f}",
        "data": {"po_number": po_number, "po_id": po_id, "product_id": product_id,
                 "qty": qty, "total_amount": total},
    }


@register_tool("notify_supplier")
def notify_supplier(supplier_id: int, message: str = "") -> dict:
    """Send notification to a supplier (simulated)."""
    with SQLSession() as session:
        row = session.execute(text(
            "SELECT name, email, contact_name FROM supplier WHERE id = :sid"
        ), {"sid": supplier_id}).fetchone()
        if not row:
            return {"success": False, "message": f"Supplier {supplier_id} not found", "data": {}}
        name, email, contact = row

    nid = str(uuid.uuid4())[:8].upper()
    return {
        "success": True,
        "message": f"Notification sent to {name} ({email or 'N/A'}). Ref: {nid} [Simulated]",
        "data": {"notification_id": nid, "supplier_id": supplier_id, "supplier_name": name},
    }


@register_tool("update_shipment")
def update_shipment(shipment_id: int, status: str) -> dict:
    """Update shipment status."""
    valid = {"PENDING", "PROCESSING", "SHIPPED", "DELIVERED", "CANCELLED", "RETURNED"}
    status_upper = status.upper()
    if status_upper not in valid:
        return {"success": False, "message": f"Invalid status. Valid: {', '.join(sorted(valid))}", "data": {}}

    with SQLSession() as session:
        row = session.execute(text(
            "SELECT shipment_number, status FROM shipment WHERE id = :sid"
        ), {"sid": shipment_id}).fetchone()
        if not row:
            return {"success": False, "message": f"Shipment {shipment_id} not found", "data": {}}

        old_status = row[1]
        ts = ""
        if status_upper == "SHIPPED":
            ts = ", shipped_date = NOW()"
        elif status_upper == "DELIVERED":
            ts = ", delivered_date = NOW()"

        session.execute(text(f"UPDATE shipment SET status = :s {ts} WHERE id = :sid"),
                        {"s": status_upper, "sid": shipment_id})
        session.commit()

    return {
        "success": True,
        "message": f"Shipment {row[0]} updated: {old_status} → {status_upper}",
        "data": {"shipment_id": shipment_id, "old_status": old_status, "new_status": status_upper},
    }


@register_tool("call_erp_sync")
def call_erp_sync(order_ids: list, sync_type: str = "sales_orders") -> dict:
    """Trigger ERP synchronization for orders (simulated)."""
    if not order_ids:
        return {"success": False, "message": "No order IDs provided", "data": {}}

    batch_id = f"ERP-SYNC-{str(uuid.uuid4())[:8].upper()}"

    with SQLSession() as session:
        table = "sales_order" if sync_type == "sales_orders" else "purchase_order"
        placeholders = ", ".join(f":id{i}" for i in range(len(order_ids)))
        params = {f"id{i}": oid for i, oid in enumerate(order_ids)}
        found = session.execute(text(f"SELECT id FROM {table} WHERE id IN ({placeholders})"),
                                params).fetchall()
        found_ids = [r[0] for r in found]
        missing = [oid for oid in order_ids if oid not in found_ids]

    msg = f"ERP sync {batch_id}: {len(found_ids)} {sync_type} queued."
    if missing:
        msg += f" Missing: {missing}"
    msg += " [Simulated]"

    return {
        "success": True, "message": msg,
        "data": {"batch_id": batch_id, "found": found_ids, "missing": missing},
    }


TOOL_DESCRIPTIONS = {
    "create_po": {
        "description": "Create a purchase order for a product",
        "args": {"product_id": "int", "qty": "int", "warehouse_id": "int (optional, default=1)"},
        "example": '{"tool": "create_po", "args": {"product_id": 5, "qty": 100}}',
    },
    "notify_supplier": {
        "description": "Send notification to a supplier",
        "args": {"supplier_id": "int", "message": "str (optional)"},
        "example": '{"tool": "notify_supplier", "args": {"supplier_id": 3}}',
    },
    "update_shipment": {
        "description": "Update shipment status",
        "args": {"shipment_id": "int", "status": "str (PENDING|PROCESSING|SHIPPED|DELIVERED|CANCELLED|RETURNED)"},
        "example": '{"tool": "update_shipment", "args": {"shipment_id": 12, "status": "SHIPPED"}}',
    },
    "call_erp_sync": {
        "description": "Trigger ERP synchronization for orders",
        "args": {"order_ids": "list[int]", "sync_type": 'str (default="sales_orders")'},
        "example": '{"tool": "call_erp_sync", "args": {"order_ids": [1, 2, 3]}}',
    },
}


def get_tools_prompt() -> str:
    """Build tools section for the ReAct system prompt."""
    lines = ["Available tools:"]
    for name, info in TOOL_DESCRIPTIONS.items():
        lines.append(f"\n## {name}")
        lines.append(f"  Description: {info['description']}")
        lines.append("  Arguments:")
        for arg, desc in info["args"].items():
            lines.append(f"    - {arg}: {desc}")
        lines.append(f"  Example: {info['example']}")
    return "\n".join(lines)
