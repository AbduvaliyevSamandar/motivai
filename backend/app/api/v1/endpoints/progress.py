"""Progress endpoints"""
from fastapi import APIRouter, Depends, Query
from app.models.progress import Progress
from app.models.user import User
from app.core.security import get_current_user
from datetime import datetime, timedelta

router = APIRouter()


@router.get("/")
async def get_progress(
    days: int = Query(default=30, ge=1, le=365),
    current_user: User = Depends(get_current_user)
):
    """Get user progress history"""
    since = datetime.utcnow() - timedelta(days=days)
    records = await Progress.find(
        Progress.user_id == str(current_user.id),
        Progress.date >= since
    ).sort(-Progress.date).to_list()

    return {
        "success": True,
        "data": {
            "records": [
                {
                    "id": str(r.id),
                    "type": r.type,
                    "xp_earned": r.xp_earned,
                    "details": r.details,
                    "date": r.date.isoformat()
                }
                for r in records
            ],
            "total_xp_period": sum(r.xp_earned for r in records),
            "total_records": len(records)
        }
    }


@router.get("/summary")
async def get_summary(current_user: User = Depends(get_current_user)):
    """Get weekly progress summary"""
    week_ago = datetime.utcnow() - timedelta(days=7)
    records = await Progress.find(
        Progress.user_id == str(current_user.id),
        Progress.date >= week_ago
    ).to_list()

    daily = {}
    for r in records:
        day = r.date.strftime("%Y-%m-%d")
        if day not in daily:
            daily[day] = {"xp": 0, "tasks": 0}
        daily[day]["xp"] += r.xp_earned
        if r.type == "task_completed":
            daily[day]["tasks"] += 1

    return {
        "success": True,
        "data": {
            "weekly_xp": sum(r.xp_earned for r in records),
            "weekly_tasks": sum(1 for r in records if r.type == "task_completed"),
            "daily_breakdown": daily
        }
    }
