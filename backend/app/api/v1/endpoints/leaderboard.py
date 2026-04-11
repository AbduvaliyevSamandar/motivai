"""Leaderboard endpoints"""
from fastapi import APIRouter, Depends, Query
from app.models.user import User
from app.models.leaderboard import LeaderboardEntry
from app.core.security import get_current_user

router = APIRouter()


@router.get("/")
async def get_leaderboard(
    period: str = Query(default="weekly", pattern="^(daily|weekly|monthly|alltime)$"),
    country: str = None,
    limit: int = Query(default=50, ge=1, le=100),
    current_user: User = Depends(get_current_user)
):
    """Get global leaderboard"""
    # Get top users by XP
    query = User.find(User.is_active == True)
    if country:
        query = User.find(User.is_active == True, User.country == country)

    users = await query.sort(-User.xp).limit(limit).to_list()

    leaderboard = []
    current_rank = None

    for i, u in enumerate(users, 1):
        entry = {
            "rank": i,
            "user_id": str(u.id),
            "name": u.name,
            "avatar": u.avatar,
            "country": u.country,
            "xp": u.xp,
            "level": u.level,
            "streak": u.streak,
            "total_tasks": u.total_tasks_completed,
            "is_current_user": str(u.id) == str(current_user.id)
        }
        if str(u.id) == str(current_user.id):
            current_rank = i
        leaderboard.append(entry)

    return {
        "success": True,
        "data": {
            "leaderboard": leaderboard,
            "current_user_rank": current_rank,
            "period": period,
            "total": len(leaderboard)
        }
    }


@router.get("/my-rank")
async def get_my_rank(current_user: User = Depends(get_current_user)):
    """Get current user's rank"""
    higher_count = await User.find(
        User.is_active == True,
        User.xp > current_user.xp
    ).count()

    rank = higher_count + 1
    return {
        "success": True,
        "data": {
            "rank": rank,
            "xp": current_user.xp,
            "level": current_user.level,
            "streak": current_user.streak
        }
    }
