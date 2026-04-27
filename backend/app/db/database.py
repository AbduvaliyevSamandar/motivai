# app/db/database.py
from datetime import datetime
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


async def merge_duplicate_emails() -> None:
    """One-shot migration that collapses any users sharing the same
    (case-insensitive) email into a single record.

    Picks the "winner" as the account with the most XP. Ties are broken
    by earliest ``created_at``. Re-points related collections (plans,
    progress, chat_messages, leaderboard) from the loser ids to the
    winner id, then deletes the losers. Idempotent — gated by a marker
    in ``migrations``.
    """
    try:
        marker = await db.db.migrations.find_one({"name": "merge_duplicate_emails_v2"})
        if marker:
            return

        from bson import ObjectId

        # Normalize first: trim + lowercase every email so the grouping
        # below isn't fooled by stray whitespace or mixed case.
        async for u in db.db.users.find({}, {"_id": 1, "email": 1}):
            raw = (u.get("email") or "").strip().lower()
            if raw and raw != u.get("email"):
                await db.db.users.update_one(
                    {"_id": u["_id"]},
                    {"$set": {"email": raw}},
                )

        # Group by exact email (now normalized)
        pipeline = [
            {"$match": {"email": {"$ne": None, "$type": "string"}}},
            {"$group": {
                "_id": "$email",
                "count": {"$sum": 1},
                "ids": {"$push": "$_id"},
                "names": {"$push": "$name"},
            }},
            {"$match": {"count": {"$gt": 1}}},
        ]
        merged = 0
        async for group in db.db.users.aggregate(pipeline):
            ids = group["ids"]
            logger.info(
                "🔗 Duplicate group: email=%r names=%s count=%d",
                group["_id"], group.get("names"), group["count"],
            )
            # Pull full docs to pick winner
            docs = []
            async for d in db.db.users.find({"_id": {"$in": ids}}):
                docs.append(d)
            if len(docs) < 2:
                continue

            def score(d):
                created = d.get("created_at") or datetime.max
                ts = created.timestamp() if hasattr(created, "timestamp") else 0
                return (d.get("xp", 0), -ts)

            winner = max(docs, key=score)
            losers = [d for d in docs if d["_id"] != winner["_id"]]

            winner_id_str = str(winner["_id"])
            loser_id_objs = [d["_id"] for d in losers]
            loser_id_strs = [str(x) for x in loser_id_objs]

            # Re-point ownership in related collections
            for coll_name in ("plans", "chat_messages", "progress", "leaderboard"):
                try:
                    await db.db[coll_name].update_many(
                        {"user_id": {"$in": loser_id_strs + loser_id_objs}},
                        {"$set": {"user_id": winner_id_str}},
                    )
                except Exception:
                    pass

            # Merge useful fields onto winner if missing
            patch = {}
            if not winner.get("avatar"):
                for d in losers:
                    if d.get("avatar"):
                        patch["avatar"] = d["avatar"]
                        break
            if not winner.get("google_sub"):
                for d in losers:
                    if d.get("google_sub"):
                        patch["google_sub"] = d["google_sub"]
                        break
            # Aggregate stats
            extra_xp = sum(d.get("xp", 0) for d in losers)
            extra_tasks = sum(d.get("total_tasks_completed", 0) for d in losers)
            if extra_xp:
                patch["xp"] = winner.get("xp", 0) + extra_xp
            if extra_tasks:
                patch["total_tasks_completed"] = (
                    winner.get("total_tasks_completed", 0) + extra_tasks
                )
            patch["email_verified"] = True
            patch["is_verified"] = True
            patch["updated_at"] = datetime.utcnow()

            await db.db.users.update_one(
                {"_id": winner["_id"]},
                {"$set": patch},
            )

            # Drop the duplicates
            await db.db.users.delete_many({"_id": {"$in": loser_id_objs}})
            merged += len(losers)
            logger.info(
                "🔗 Merged %d duplicate(s) into %s",
                len(losers),
                winner.get("email"),
            )

        await db.db.migrations.insert_one({
            "name": "merge_duplicate_emails_v2",
            "merged": merged,
            "ran_at": datetime.utcnow(),
        })
        logger.info("🔗 merge_duplicate_emails complete — %d duplicates collapsed", merged)
    except Exception as e:
        logger.warning(f"⚠️ merge_duplicate_emails failed: {e}")


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
