from pydantic import BaseModel


class CartItem(BaseModel):
    product_id: str
    quantity: int


class CartAddRequest(BaseModel):
    product_id: str
    quantity: int = 1


class CartRemoveRequest(BaseModel):
    product_id: str


class CartResponse(BaseModel):
    user_id: str
    items: list[CartItem]


class OrderCreateRequest(BaseModel):
    total: float = 0.0


class OrderItem(BaseModel):
    product_id: str
    quantity: int


class OrderResponse(BaseModel):
    order_ref: str
    user_id: str
    items: list[OrderItem]
    total: float
    timestamp: str
