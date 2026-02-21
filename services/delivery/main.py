from datetime import datetime, timezone

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from database import close_db, get_db
from models import OrderStatus, UpdateStatusRequest

app = FastAPI(title="Delivery and Order Status Service")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

VALID_STATUSES = {"PLACED", "PACKED", "OUT_FOR_DELIVERY", "DELIVERED"}


@app.get("/health")
def health():
    return {"status": "ok"}


@app.on_event("shutdown")
async def shutdown():
    await close_db()


@app.get("/order/{order_id}/status", response_model=OrderStatus)
async def get_order_status(order_id: str):
    db = await get_db()
    doc = await db.order_status.find_one({"order_id": order_id})
    if not doc:
        raise HTTPException(status_code=404, detail="Order not found")
    return OrderStatus(
        order_id=doc["order_id"],
        status=doc["status"],
        last_updated=doc["last_updated"],
    )


@app.post("/order/{order_id}/update-status", response_model=OrderStatus)
async def update_order_status(order_id: str, body: UpdateStatusRequest):
    if body.status not in VALID_STATUSES:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid status. Must be one of: {', '.join(sorted(VALID_STATUSES))}",
        )
    db = await get_db()
    last_updated = datetime.now(timezone.utc).isoformat()
    doc = {
        "order_id": order_id,
        "status": body.status,
        "last_updated": last_updated,
    }
    await db.order_status.update_one(
        {"order_id": order_id},
        {"$set": doc},
        upsert=True,
    )
    return OrderStatus(order_id=order_id, status=body.status, last_updated=last_updated)
