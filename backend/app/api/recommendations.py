from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from pydantic import BaseModel
import logging, traceback

from app.core.database import get_db
from app.models.models import User, MotivationLog
from app.api.auth import get_current_user
from app.ml.engine import analyze_and_recommend

router = APIRouter()
logger = logging.getLogger(__name__)


class CheckInSchema(BaseModel):
    motivation_level: int
    stress_level:     int
    mood_score:       int
    energy_level:     int


@router.post("/checkin")
async def daily_checkin(
    data: CheckInSchema,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    try:
        user_data = {
            "motivation_level":  data.motivation_level,
            "stress_level":      data.stress_level,
            "mood_score":        data.mood_score,
            "energy_level":      data.energy_level,
            "gpa":               current_user.gpa or 3.0,
            "sleep_hours":       current_user.sleep_hours or 7.0,
            "daily_study_hours": current_user.daily_study_hours or 3.0,
            "streak_days":       current_user.streak_days or 0,
            "preferred_time":    current_user.preferred_time or "morning",
        }
        recommendations = analyze_and_recommend(user_data)

        log = MotivationLog(
            user_id=current_user.id,
            motivation_level=data.motivation_level,
            stress_level=data.stress_level,
            mood_score=data.mood_score,
            energy_level=data.energy_level,
            ai_recommendations=recommendations,
        )
        db.add(log)
        current_user.points = (current_user.points or 0) + 30
        current_user.level = max(1, (current_user.points or 0) // 500)
        await db.commit()
        await db.refresh(current_user)

        return {
            "success": True,
            "points_earned": 30,
            "total_points": current_user.points,
            "level": current_user.level,
            "recommendations": recommendations,
        }
    except Exception as e:
        logger.error(traceback.format_exc())
        await db.rollback()
        raise HTTPException(500, f"{type(e).__name__}: {str(e)}")


@router.get("/my-plan")
async def get_my_plan(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(MotivationLog)
        .where(MotivationLog.user_id == current_user.id)
        .order_by(desc(MotivationLog.date))
        .limit(1)
    )
    log = result.scalar_one_or_none()
    if log and log.ai_recommendations:
        return {"has_plan": True, "date": str(log.date), "plan": log.ai_recommendations}
    return {"has_plan": False, "message": "Kunlik check-in qiling!"}


@router.get("/history")
async def get_history(
    days: int = 14,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(MotivationLog)
        .where(MotivationLog.user_id == current_user.id)
        .order_by(desc(MotivationLog.date))
        .limit(days)
    )
    logs = result.scalars().all()
    history = [
        {
            "date":       log.date.strftime("%m/%d") if log.date else "",
            "motivation": log.motivation_level,
            "stress":     log.stress_level,
            "mood":       log.mood_score,
            "energy":     log.energy_level,
        }
        for log in reversed(logs)
    ]
    return {"history": history, "total": len(history)}
