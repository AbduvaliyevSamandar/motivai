# app/db/database.py
from motor.motor_asyncio import AsyncIOMotorClient
from app.core.config import settings
import logging

logger = logging.getLogger(__name__)

class Database:
    client: AsyncIOMotorClient = None
    db = None
    is_mock = False  # Track if using mock storage

db = Database()

async def connect_db():
    try:
        db.client = AsyncIOMotorClient(
            settings.MONGODB_URL,
            serverSelectionTimeoutMS=5000,  # Quick timeout for testing
            connectTimeoutMS=5000,
        )
        db.db = db.client[settings.DATABASE_NAME]
        # Try to verify connection
        await db.client.admin.command('ping')
        # Create indexes
        await create_indexes()
        db.is_mock = False
        logger.info("✅ MongoDB connected successfully")
    except Exception as e:
        logger.warning(f"⚠️ MongoDB connection warning: {e}")
        logger.warning("⚠️ Running WITH MOCK DATABASE (testing mode only)")
        # For local testing without DB, use mock database
        if not settings.DEBUG:
            raise e
        # Use mock database for testing
        from app.services.mock_storage import get_mock_db
        db.db = get_mock_db()
        db.client = None
        db.is_mock = True

async def close_db():
    if db.client:
        db.client.close()
        logger.info("MongoDB connection closed")

async def create_indexes():
    try:
        # Users
        await db.db.users.create_index("email", unique=True)
        await db.db.users.create_index("xp")
        # Plans
        await db.db.plans.create_index("user_id")
        await db.db.plans.create_index([("user_id", 1), ("is_active", 1)])
        # Progress
        await db.db.progress.create_index([("user_id", 1), ("date", -1)])
        # Chat messages
        await db.db.chat_messages.create_index([("user_id", 1), ("session_id", 1), ("timestamp", -1)])
        # Leaderboard
        await db.db.leaderboard.create_index([("period", 1), ("xp", -1)])
    except Exception as e:
        logger.warning(f"⚠️ Could not create indexes: {e}")


async def cleanup_unverified_users() -> None:
    """One-shot migration that purges all pre-existing demo / fake accounts.

    Runs at startup. Gated by a marker document in ``migrations`` so it
    only fires once. Strategy:
      1. Mark every existing user as ``email_verified=False`` if the field
         is missing — these were created before the OTP flow existed.
      2. Delete every user that is still ``email_verified=False`` after
         step 1, plus their plans + chat messages + progress + leaderboard
         entries to avoid dangling references.

    The user explicitly asked for a clean slate ("hammasini tozalash") so
    we drop unverified accounts hard rather than asking them to re-verify.
    """
    try:
        marker = await db.db.migrations.find_one({"name": "cleanup_unverified_v1"})
        if marker:
            return

        # Step 1: backfill the field so the next stage sees consistent data.
        await db.db.users.update_many(
            {"email_verified": {"$exists": False}},
            {"$set": {"email_verified": False, "is_verified": False}},
        )

        # Step 2: collect ids of unverified accounts (skip Google-authed).
        cursor = db.db.users.find(
            {
                "$and": [
                    {"$or": [
                        {"email_verified": False},
                        {"email_verified": {"$exists": False}},
                    ]},
                    {"$or": [
                        {"auth_provider": {"$ne": "google"}},
                        {"auth_provider": {"$exists": False}},
                    ]},
                ]
            },
            {"_id": 1, "email": 1},
        )
        ids = []
        emails = []
        async for u in cursor:
            ids.append(u["_id"])
            emails.append(u.get("email"))

        if ids:
            from bson import ObjectId
            id_strs = [str(i) for i in ids]
            await db.db.plans.delete_many({"user_id": {"$in": id_strs + ids}})
            await db.db.chat_messages.delete_many({"user_id": {"$in": id_strs + ids}})
            await db.db.progress.delete_many({"user_id": {"$in": id_strs + ids}})
            await db.db.leaderboard.delete_many({"user_id": {"$in": id_strs + ids}})
            await db.db.users.delete_many({"_id": {"$in": ids}})
            logger.info(
                "🧹 Cleanup: removed %d unverified accounts: %s",
                len(ids),
                ", ".join([e for e in emails if e][:10]),
            )
        else:
            logger.info("🧹 Cleanup: no unverified accounts to remove")

        await db.db.migrations.insert_one({
            "name": "cleanup_unverified_v1",
            "removed": len(ids),
        })
    except Exception as e:
        logger.warning(f"⚠️ cleanup_unverified_users failed: {e}")


def get_db():
    return db.db
