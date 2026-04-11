from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc, func

from app.core.database import get_db
from app.models.models import User
from app.api.auth import get_current_user

router = APIRouter()


def _fmt(user: User, rank: int, my_id: int) -> dict:
    name = (user.full_name or user.username or "U").split()
    initials = (name[0][0] + (name[-1][0] if len(name) > 1 else "")).upper()
    return {
        "rank":        rank,
        "username":    user.username,
        "full_name":   user.full_name,
        "faculty":     user.faculty or "-",
        "points":      user.points or 0,
        "streak_days": user.streak_days or 0,
        "level":       user.level or 1,
        "badges":      (user.badges or [])[:2],
        "is_me":       user.id == my_id,
        "initials":    initials,
    }


@router.get("/global")
async def global_leaderboard(
    limit: int = 50,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(User).where(User.is_active == True).order_by(desc(User.points)).limit(limit)
    )
    users = result.scalars().all()
    board = [_fmt(u, i + 1, current_user.id) for i, u in enumerate(users)]
    my_entry = next((x for x in board if x["is_me"]), None)
    if not my_entry:
        above = await db.execute(
            select(func.count(User.id)).where(User.is_active == True, User.points > (current_user.points or 0))
        )
        my_entry = _fmt(current_user, (above.scalar() or 0) + 1, current_user.id)
    return {"leaderboard": board, "my_rank": my_entry, "total": len(board)}


@router.get("/faculty")
async def faculty_leaderboard(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if not current_user.faculty:
        return {"error": "Profilingizga fakultet qoshing", "leaderboard": []}
    result = await db.execute(
        select(User).where(User.faculty == current_user.faculty, User.is_active == True)
        .order_by(desc(User.points)).limit(20)
    )
    users = result.scalars().all()
    board = [_fmt(u, i + 1, current_user.id) for i, u in enumerate(users)]
    return {"faculty": current_user.faculty, "leaderboard": board, "total": len(board)}


@router.get("/weekly")
async def weekly_leaderboard(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(User).where(User.is_active == True)
        .order_by(desc(User.streak_days), desc(User.points)).limit(20)
    )
    users = result.scalars().all()
    board = [_fmt(u, i + 1, current_user.id) for i, u in enumerate(users)]
    return {"leaderboard": board, "total": len(board)}
