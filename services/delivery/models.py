from pydantic import BaseModel


class OrderStatus(BaseModel):
    order_id: str
    status: str
    last_updated: str


class UpdateStatusRequest(BaseModel):
    status: str
