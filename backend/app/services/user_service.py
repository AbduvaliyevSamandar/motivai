# app/services/user_service.py
from datetime import datetime, timedelta
from app.db.database import get_db
from app.core.security import get_password_hash, verify_password
from bson import ObjectId
import logging

logger = logging.getLogger(__name__)

LEVEL_THRESHOLDS = [0,100,250,500,900,1400,2000,2700,3500,4400,5500]
BADGES = {
    "first_plan": {"id": "first_plan", "name": "Birinchi reja", "icon": "🎯"},
    "streak_7": {"id": "streak_7", "name": "7 kunlik streak", "icon": "🔥"},
    "streak_30": {"id": "streak_30", "name": "30 kunlik streak", "icon": "⚡"},
    "level_5": {"id": "level_5", "name": "5-daraja", "icon": "⭐"},
    "tasks_10": {"id": "tasks_10", "name": "10 vazifa", "icon": "✅"},
    "tasks_50": {"id": "tasks_50", "name": "50 vazifa", "icon": "🏆"},
    "ai_explorer": {"id": "ai_explorer", "name": "AI Explorer", "icon": "🤖"},
    "completionist": {"id": "completionist", "name": "Mukammal", "icon": "💎"},
}

def calculate_level(xp: int) -> int:
    for i, threshold in enumerate(reversed(LEVEL_THRESHOLDS)):
        if xp >= threshold:
            return len(LEVEL_THRESHOLDS) - i
    return 1

async def get_user_by_id(user_id: str) -> dict:
    db = get_db()
    user = await db.users.find_one({"_id": ObjectId(user_id)})
    if user:
        user["_id"] = str(user["_id"])
    return user

async def get_user_by_email(email: str) -> dict:
    db = get_db()
    user = await db.users.find_one({"email": email.lower()})
    if user:
        user["_id"] = str(user["_id"])
    return user

async def create_user(data: dict) -> dict:
    db = get_db()
    now = datetime.utcnow()
    user_doc = {
        "name": data["name"],
        "email": data["email"].lower(),
        "hashed_password": get_password_hash(data["password"]),
        "avatar": None,
        "country": data.get("country", "UZ"),
        "language": data.get("language", "uz"),
        "role": "student",
        "profile": {
            "university": None, "faculty": None, "year": None,
            "goals": [], "interests": [], "learning_style": "visual"
        },
        "xp": 0, "level": 1, "streak": 0,
        "last_active_date": now,
        "badges": [],
        "total_tasks_completed": 0,
        "total_study_minutes": 0,
        "ai_messages_count": 0,
        "notifications": {"push": True, "email_notif": True, "reminder_time": "09:00"},
        "fcm_token": None,
        "is_verified": False,
        "is_active": True,
        "created_at": now,
        "updated_at": now
    }
    result = await db.users.insert_one(user_doc)
    user_doc["_id"] = str(result.inserted_id)
    return user_doc

async def update_streak_and_xp(user_id: str, xp_gained: int = 0) -> dict:
    db = get_db()
    user = await db.users.find_one({"_id": ObjectId(user_id)})
    if not user:
        return {}
    
    now = datetime.utcnow()
    last_active = user.get("last_active_date", now)
    diff_days = (now.date() - last_active.date()).days
    
    new_streak = user.get("streak", 0)
    if diff_days == 1:
        new_streak += 1
    elif diff_days > 1:
        new_streak = 0
    
    new_xp = user.get("xp", 0) + xp_gained
    new_level = calculate_level(new_xp)
    
    updates = {
        "$set": {
            "xp": new_xp,
            "level": new_level,
            "streak": new_streak,
            "last_active_date": now,
            "updated_at": now
        }
    }
    
    # Check badges
    earned_badges = user.get("badges", [])
    existing_badge_ids = [b["id"] for b in earned_badges]
    
    new_badges = []
    if new_streak >= 7 and "streak_7" not in existing_badge_ids:
        new_badges.append({**BADGES["streak_7"], "earned_at": now})
    if new_streak >= 30 and "streak_30" not in existing_badge_ids:
        new_badges.append({**BADGES["streak_30"], "earned_at": now})
    if new_level >= 5 and "level_5" not in existing_badge_ids:
        new_badges.append({**BADGES["level_5"], "earned_at": now})
    
    if new_badges:
        updates["$push"] = {"badges": {"$each": new_badges}}
    
    await db.users.update_one({"_id": ObjectId(user_id)}, updates)
    return {"new_xp": new_xp, "new_level": new_level, "new_streak": new_streak, "new_badges": new_badges}

async def add_task_badge(user_id: str, total_completed: int):
    db = get_db()
    user = await db.users.find_one({"_id": ObjectId(user_id)})
    if not user:
        return
    existing = [b["id"] for b in user.get("badges", [])]
    now = datetime.utcnow()
    new_badges = []
    if total_completed >= 10 and "tasks_10" not in existing:
        new_badges.append({**BADGES["tasks_10"], "earned_at": now})
    if total_completed >= 50 and "tasks_50" not in existing:
        new_badges.append({**BADGES["tasks_50"], "earned_at": now})
    if new_badges:
        await db.users.update_one(
            {"_id": ObjectId(user_id)},
            {"$push": {"badges": {"$each": new_badges}}}
        )

async def safe_user_dict(user: dict) -> dict:
    """Remove sensitive fields"""
    user.pop("hashed_password", None)
    return user
