import uuid
from datetime import datetime, timezone

from fastapi import Depends, FastAPI, Header, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from database import close_db, get_db
from models import (
    CartAddRequest,
    CartItem,
    CartRemoveRequest,
    CartResponse,
    OrderCreateRequest,
    OrderItem,
    OrderResponse,
)

app = FastAPI(title="Cart and Order Service")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


async def _require_user_id(
    x_user_id: str | None = Header(None, alias="X-User-Id"),
) -> str:
    if not x_user_id:
        raise HTTPException(status_code=400, detail="X-User-Id header required")
    return x_user_id


@app.get("/health")
def health():
    return {"status": "ok"}


@app.on_event("shutdown")
async def shutdown():
    await close_db()


@app.post("/cart/add", response_model=CartResponse)
async def cart_add(body: CartAddRequest, user_id: str = Depends(_require_user_id)):
    db = await get_db()
    doc = await db.carts.find_one({"user_id": user_id})
    if not doc:
        doc = {"user_id": user_id, "items": []}
        await db.carts.insert_one(doc)
    items = list(doc["items"])
    found = False
    for it in items:
        if it["product_id"] == body.product_id:
            it["quantity"] += body.quantity
            found = True
            break
    if not found:
        items.append({"product_id": body.product_id, "quantity": body.quantity})
    await db.carts.update_one({"user_id": user_id}, {"$set": {"items": items}})
    return CartResponse(
        user_id=user_id,
        items=[CartItem(product_id=i["product_id"], quantity=i["quantity"]) for i in items],
    )


@app.post("/cart/remove", response_model=CartResponse)
async def cart_remove(body: CartRemoveRequest, user_id: str = Depends(_require_user_id)):
    db = await get_db()
    doc = await db.carts.find_one({"user_id": user_id})
    if not doc:
        return CartResponse(user_id=user_id, items=[])
    items = [i for i in doc["items"] if i["product_id"] != body.product_id]
    await db.carts.update_one({"user_id": user_id}, {"$set": {"items": items}})
    return CartResponse(
        user_id=user_id,
        items=[CartItem(product_id=i["product_id"], quantity=i["quantity"]) for i in items],
    )


@app.get("/cart", response_model=CartResponse)
async def get_cart(user_id: str = Depends(_require_user_id)):
    db = await get_db()
    doc = await db.carts.find_one({"user_id": user_id})
    if not doc:
        return CartResponse(user_id=user_id, items=[])
    return CartResponse(
        user_id=user_id,
        items=[CartItem(product_id=i["product_id"], quantity=i["quantity"]) for i in doc["items"]],
    )


def _order_ref() -> str:
    return "ORD-" + uuid.uuid4().hex[:8].upper()


@app.post("/order/create", response_model=OrderResponse)
async def order_create(body: OrderCreateRequest, user_id: str = Depends(_require_user_id)):
    db = await get_db()
    doc = await db.carts.find_one({"user_id": user_id})
    if not doc or not doc.get("items"):
        raise HTTPException(status_code=400, detail="Cart is empty")
    items = [OrderItem(product_id=i["product_id"], quantity=i["quantity"]) for i in doc["items"]]
    order_ref = _order_ref()
    timestamp = datetime.now(timezone.utc).isoformat()
    order_doc = {
        "order_ref": order_ref,
        "user_id": user_id,
        "items": [i.model_dump() for i in items],
        "total": body.total,
        "timestamp": timestamp,
    }
    await db.orders.insert_one(order_doc)
    await db.carts.update_one({"user_id": user_id}, {"$set": {"items": []}})
    return OrderResponse(
        order_ref=order_ref,
        user_id=user_id,
        items=items,
        total=body.total,
        timestamp=timestamp,
    )


@app.get("/orders", response_model=list[OrderResponse])
async def list_orders(user_id: str = Depends(_require_user_id)):
    db = await get_db()
    cursor = db.orders.find({"user_id": user_id}).sort("timestamp", -1)
    return [
        OrderResponse(
            order_ref=doc["order_ref"],
            user_id=doc["user_id"],
            items=[OrderItem(**i) for i in doc["items"]],
            total=doc["total"],
            timestamp=doc["timestamp"],
        )
        async for doc in cursor
    ]
