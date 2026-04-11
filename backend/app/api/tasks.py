from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
import logging, traceback

from app.core.database import get_db
from app.models.models import User, TaskCompletion
from app.api.auth import get_current_user
from app.ml.engine import get_tasks_for_user, CHALLENGES

router = APIRouter()
logger = logging.getLogger(__name__)

LEVEL_BADGES = {2: "Bronze", 5: "Silver", 10: "Gold", 20: "Diamond", 50: "Legend"}


class CompleteTaskSchema(BaseModel):
    task_key:      str
    task_title:    str
    points_earned: int
    mood_after:    Optional[int] = None


@router.get("/daily")
async def get_daily_tasks(current_user: User = Depends(get_current_user)):
    preferred = current_user.preferred_time or "morning"
    return {
        "preferred_time": preferred,
        "tasks":          get_tasks_for_user(preferred),
        "challenges":     CHALLENGES[:4],
    }


@router.post("/complete")
async def complete_task(
    data: CompleteTaskSchema,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    try:
        current_user.points = (current_user.points or 0) + data.points_earned
        old_level = current_user.level or 1
        current_user.level = max(1, (current_user.points or 0) // 500)

        new_badge = None
        if current_user.level != old_level and current_user.level in LEVEL_BADGES:
            badge = LEVEL_BADGES[current_user.level]
            badges = list(current_user.badges) if current_user.badges else []
            if badge not in badges:
                badges.append(badge)
                current_user.badges = badges
                new_badge = badge

        db.add(TaskCompletion(
            user_id=current_user.id,
            task_key=data.task_key,
            task_title=data.task_title,
            points_earned=data.points_earned,
            completed_at=datetime.utcnow(),
        ))
        await db.commit()
        await db.refresh(current_user)

        return {
            "success":       True,
            "points_earned": data.points_earned,
            "total_points":  current_user.points,
            "level":         current_user.level,
            "new_badge":     new_badge,
            "badges":        current_user.badges or [],
        }
    except Exception as e:
        logger.error(traceback.format_exc())
        await db.rollback()
        raise HTTPException(500, f"{type(e).__name__}: {str(e)}")


@router.get("/stats")
async def get_stats(current_user: User = Depends(get_current_user)):
    lvl = current_user.level or 1
    pts = current_user.points or 0
    return {
        "total_points":      pts,
        "streak_days":       current_user.streak_days or 0,
        "level":             lvl,
        "badges":            current_user.badges or [],
        "next_level_points": (lvl + 1) * 500,
        "points_to_next":    max(0, (lvl + 1) * 500 - pts),
    }
