"""
Pre-seed products into MongoDB. Run once: python seed.py
Set CATALOG_MONGODB_URL and CATALOG_MONGODB_DB or use defaults.
"""
import os
import sys

# Allow importing config from current dir
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from pymongo import MongoClient

from config import settings

PRODUCTS = [
    {
        "product_id": "prod_1",
        "name": "Organic Bananas",
        "description": "Fresh organic bananas, 1 dozen",
        "price": 49.0,
        "category": "Fruits",
        "image_url": "https://example.com/bananas.jpg",
        "availability": True,
    },
    {
        "product_id": "prod_2",
        "name": "Whole Milk 1L",
        "description": "Fresh full-fat milk",
        "price": 60.0,
        "category": "Dairy",
        "image_url": "https://example.com/milk.jpg",
        "availability": True,
    },
    {
        "product_id": "prod_3",
        "name": "Brown Bread",
        "description": "Multigrain brown bread loaf",
        "price": 35.0,
        "category": "Bakery",
        "image_url": "https://example.com/bread.jpg",
        "availability": True,
    },
    {
        "product_id": "prod_4",
        "name": "Tomatoes 500g",
        "description": "Fresh red tomatoes",
        "price": 40.0,
        "category": "Vegetables",
        "image_url": "https://example.com/tomatoes.jpg",
        "availability": True,
    },
    {
        "product_id": "prod_5",
        "name": "Eggs - Dozen",
        "description": "Farm fresh eggs",
        "price": 90.0,
        "category": "Dairy",
        "image_url": "https://example.com/eggs.jpg",
        "availability": False,
    },
]

def main():
    client = MongoClient(settings.mongodb_url)
    db = client[settings.mongodb_db]
    db.products.delete_many({})
    db.products.insert_many(PRODUCTS)
    print(f"Seeded {len(PRODUCTS)} products into {settings.mongodb_db}.products")
    client.close()


if __name__ == "__main__":
    main()
