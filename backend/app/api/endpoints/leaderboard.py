# app/api/endpoints/leaderboard.py
from fastapi import APIRouter, Depends
from typing import Optional
from app.api.dependencies import get_current_user
from app.db.database import get_db
from bson import ObjectId

router = APIRouter(prefix="/leaderboard", tags=["Leaderboard"])

@router.get("/", response_model=dict)
async def get_leaderboard(
    period: str = "weekly",  # daily, weekly, monthly, alltime
    limit: int = 50,
    current_user: dict = Depends(get_current_user)
):
    db = get_db()
    
    if period == "alltime":
        sort_field = "xp"
    else:
        sort_field = "xp"
    
    pipeline = [
        {"$match": {"is_active": True}},
        {"$sort": {"xp": -1}},
        {"$limit": limit},
        {"$project": {
            "name": 1,
            "avatar": 1,
            "xp": 1,
            "level": 1,
            "streak": 1,
            "total_tasks_completed": 1,
            "badges": {"$slice": ["$badges", 3]},
            "country": 1
        }}
    ]
    
    users = await db.users.aggregate(pipeline).to_list(limit)
    
    leaderboard = []
    current_user_rank = None
    
    for i, u in enumerate(users):
        u["_id"] = str(u["_id"])
        u["rank"] = i + 1
        u["is_current_user"] = u["_id"] == current_user["_id"]
        if u["is_current_user"]:
            current_user_rank = i + 1
        leaderboard.append(u)
    
    # Find current user rank if not in top
    if current_user_rank is None:
        count = await db.users.count_documents({"xp": {"$gt": current_user["xp"]}, "is_active": True})
        current_user_rank = count + 1
    
    return {
        "success": True,
        "data": {
            "leaderboard": leaderboard,
            "current_user_rank": current_user_rank,
            "period": period
        }
    }

@router.get("/my-rank", response_model=dict)
async def get_my_rank(current_user: dict = Depends(get_current_user)):
    db = get_db()
    rank = await db.users.count_documents({"xp": {"$gt": current_user["xp"]}, "is_active": True})
    total = await db.users.count_documents({"is_active": True})
    
    return {
        "success": True,
        "data": {
            "rank": rank + 1,
            "total_users": total,
            "xp": current_user["xp"],
            "level": current_user["level"],
            "percentile": round(((total - rank) / total) * 100, 1) if total > 0 else 100
        }
    }
