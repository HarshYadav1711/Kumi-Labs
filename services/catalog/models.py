from pydantic import BaseModel


class Product(BaseModel):
    product_id: str
    name: str
    description: str
    price: float
    category: str
    image_url: str
    availability: bool


class CategoryItem(BaseModel):
    name: str
