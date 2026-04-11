from motor.motor_asyncio import AsyncClient, AsyncDatabase
from config import settings
import logging

logger = logging.getLogger(__name__)

client: AsyncClient = None
database: AsyncDatabase = None


async def connect_to_mongo():
    """Connect to MongoDB"""
    global client, database
    try:
        client = AsyncClient(settings.MONGODB_URL)
        database = client[settings.DATABASE_NAME]
        # Verify connection
        await database.command("ping")
        logger.info("✅ Connected to MongoDB successfully")
        print("✅ MongoDB Connected Successfully!")
    except Exception as e:
        logger.error(f"❌ Failed to connect to MongoDB: {e}")
        print(f"❌ MongoDB Connection Error: {e}")
        raise


async def close_mongo_connection():
    """Close MongoDB connection"""
    global client
    try:
        if client:
            client.close()
            logger.info("MongoDB connection closed")
            print("✅ MongoDB disconnected")
    except Exception as e:
        logger.error(f"Error closing MongoDB connection: {e}")


def get_database() -> AsyncDatabase:
    """Get database instance"""
    return database
