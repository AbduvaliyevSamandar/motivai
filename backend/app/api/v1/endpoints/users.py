"""Users endpoint"""
from fastapi import APIRouter, Depends
from app.models.user import User
from app.core.security import get_current_user

router = APIRouter()


@router.get("/stats")
async def get_stats(current_user: User = Depends(get_current_user)):
    """Get detailed user stats"""
    return {
        "success": True,
        "data": {
            "xp": current_user.xp,
            "level": current_user.level,
            "streak": current_user.streak,
            "longest_streak": current_user.longest_streak,
            "total_tasks_completed": current_user.total_tasks_completed,
            "total_study_minutes": current_user.total_study_minutes,
            "total_plans_created": current_user.total_plans_created,
            "total_plans_completed": current_user.total_plans_completed,
            "ai_messages_count": current_user.ai_messages_count,
            "badges": current_user.badges,
            "badges_count": len(current_user.badges)
        }
    }
