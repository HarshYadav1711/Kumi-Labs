from motor.motor_asyncio import AsyncIOMotorClient

from config import settings

client: AsyncIOMotorClient | None = None


async def get_db():
    global client
    if client is None:
        client = AsyncIOMotorClient(settings.mongodb_url)
    return client[settings.mongodb_db]


async def close_db():
    global client
    if client:
        client.close()
        client = None
