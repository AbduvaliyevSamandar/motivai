from fastapi import APIRouter, Depends
from config.database import get_db
from middleware.auth_middleware import get_authenticated_user
from datetime import datetime, timezone, timedelta

router = APIRouter(prefix="/leaderboard", tags=["Leaderboard"])
UTC = timezone.utc


def _entry(u: dict, rank: int) -> dict:
    level = u.get("level", 1)
    emojis = {range(1,3):'🌱', range(3,5):'📚', range(5,8):'🚀',
               range(8,11):'⭐', range(11,16):'🔥', range(16,21):'💎'}
    emoji = next((e for r,e in emojis.items() if level in r), '🌱')
    return {
        "user_id":   str(u["_id"]),
        "full_name": u.get("full_name", u.get("username", "")),
        "username":  u.get("username", ""),
        "rank":      rank,
        "points":    u.get("points", 0),
        "level":     level,
        "streak":    u.get("streak", 0),
        "level_emoji": emoji,
    }


@router.get("/global")
async def global_lb(
    limit: int = 50,
    current_user: dict = Depends(get_authenticated_user),
    db=Depends(get_db),
):
    users = await db.users.find(
        {"is_active": True, "role": "student"}
    ).sort("points", -1).limit(limit).to_list(limit)

    return {
        "leaderboard": [_entry(u, i+1) for i, u in enumerate(users)],
        "total": await db.users.count_documents(
            {"is_active": True, "role": "student"}),
    }


@router.get("/weekly")
async def weekly_lb(
    limit: int = 50,
    current_user: dict = Depends(get_authenticated_user),
    db=Depends(get_db),
):
    since = datetime.now(UTC) - timedelta(days=7)

    pipeline = [
        {"$match": {"completed_at": {"$gte": since}}},
        {"$group": {
            "_id":    "$user_id",
            "weekly": {"$sum": "$points_earned"},
        }},
        {"$sort": {"weekly": -1}},
        {"$limit": limit},
    ]
    rows = await db.progress.aggregate(pipeline).to_list(limit)
    uid_map = {r["_id"]: r["weekly"] for r in rows}

    users = await db.users.find(
        {"_id": {"$in": []}, "is_active": True}  # placeholder
    ).to_list(0)

    # user objekt va ballar birlashtirish
    result = []
    for i, r in enumerate(rows):
        u = await db.users.find_one({"_id": __import__('bson').ObjectId(r["_id"])
                                     if len(r["_id"])==24 else r["_id"]})
        if u:
            e = _entry(u, i+1)
            e["points"] = r["weekly"]   # Bu haftaki ball
            result.append(e)

    return {"leaderboard": result, "period": "weekly"}


@router.get("/my-rank")
async def my_rank(
    current_user: dict = Depends(get_authenticated_user),
    db=Depends(get_db),
):
    pts   = current_user.get("points", 0)
    total = await db.users.count_documents(
        {"is_active": True, "role": "student"})
    higher= await db.users.count_documents(
        {"is_active": True, "role": "student", "points": {"$gt": pts}})
    rank  = higher + 1
    pct   = round((1 - rank / max(total, 1)) * 100, 1)

    return {
        "rank":        rank,
        "total_users": total,
        "percentile":  pct,
        "points":      pts,
        "level":       current_user.get("level", 1),
    }
