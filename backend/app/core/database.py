"""MongoDB connection using Motor + Beanie"""
from motor.motor_asyncio import AsyncIOMotorClient
from beanie import init_beanie
from app.core.config import settings
import logging

logger = logging.getLogger(__name__)


async def init_db():
    """Initialize database connection"""
    try:
        client = AsyncIOMotorClient(settings.MONGODB_URL)
        
        # Import all models
        from app.models.user import User
        from app.models.plan import Plan, Task, Milestone
        from app.models.progress import Progress
        from app.models.chat_message import ChatMessage
        from app.models.leaderboard import LeaderboardEntry

        await init_beanie(
            database=client[settings.DATABASE_NAME],
            document_models=[
                User,
                Plan,
                Progress,
                ChatMessage,
                LeaderboardEntry
            ]
        )
        
        # Create indexes
        await create_indexes()
        logger.info(f"✅ Connected to MongoDB: {settings.DATABASE_NAME}")
        
    except Exception as e:
        logger.error(f"❌ Database connection failed: {e}")
        raise


async def create_indexes():
    """Create necessary database indexes"""
    from app.models.user import User
    from app.models.plan import Plan
    from app.models.progress import Progress
    from app.models.chat_message import ChatMessage
    from app.models.leaderboard import LeaderboardEntry

    # These are automatically handled by Beanie via Settings class
    logger.info("✅ Database indexes ready")
