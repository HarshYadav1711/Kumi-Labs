from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from database import close_db, get_db
from models import CategoryItem, Product

app = FastAPI(title="Catalog Service")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health():
    return {"status": "ok"}


@app.on_event("shutdown")
async def shutdown():
    await close_db()


def _doc_to_product(doc: dict) -> Product:
    return Product(
        product_id=doc["product_id"],
        name=doc["name"],
        description=doc["description"],
        price=doc["price"],
        category=doc["category"],
        image_url=doc["image_url"],
        availability=doc["availability"],
    )


@app.get("/products", response_model=list[Product])
async def list_products():
    db = await get_db()
    cursor = db.products.find({})
    return [_doc_to_product(doc) async for doc in cursor]


@app.get("/products/{product_id}", response_model=Product)
async def get_product(product_id: str):
    db = await get_db()
    doc = await db.products.find_one({"product_id": product_id})
    if not doc:
        raise HTTPException(status_code=404, detail="Product not found")
    return _doc_to_product(doc)


@app.get("/categories", response_model=list[CategoryItem])
async def list_categories():
    db = await get_db()
    categories = await db.products.distinct("category")
    return [CategoryItem(name=c) for c in sorted(categories)]
