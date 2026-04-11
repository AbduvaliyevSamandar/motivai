# app/api/endpoints/progress.py
from fastapi import APIRouter, Depends
from datetime import datetime, timedelta
from app.api.dependencies import get_current_user
from app.db.database import get_db

router = APIRouter(prefix="/progress", tags=["Progress"])

@router.get("/", response_model=dict)
async def get_progress(
    days: int = 7,
    current_user: dict = Depends(get_current_user)
):
    db = get_db()
    since = datetime.utcnow() - timedelta(days=days)
    
    progress = await db.progress.find({
        "user_id": current_user["_id"],
        "date": {"$gte": since}
    }).sort("date", -1).to_list(200)
    
    for p in progress:
        p["_id"] = str(p["_id"])
    
    # Daily summary
    daily = {}
    for p in progress:
        date_key = p["date"].strftime("%Y-%m-%d")
        if date_key not in daily:
            daily[date_key] = {"date": date_key, "tasks": 0, "xp": 0, "minutes": 0}
        if p["type"] == "task_completed":
            daily[date_key]["tasks"] += 1
            daily[date_key]["xp"] += p.get("xp_earned", 0)
            daily[date_key]["minutes"] += p.get("details", {}).get("study_minutes", 0)
    
    return {
        "success": True,
        "data": {
            "logs": progress,
            "daily_summary": list(daily.values()),
            "total_xp": sum(p.get("xp_earned", 0) for p in progress),
            "total_tasks": sum(1 for p in progress if p["type"] == "task_completed")
        }
    }

@router.get("/heatmap", response_model=dict)
async def get_heatmap(current_user: dict = Depends(get_current_user)):
    """Activity heatmap for last 365 days"""
    db = get_db()
    since = datetime.utcnow() - timedelta(days=365)
    
    pipeline = [
        {"$match": {"user_id": current_user["_id"], "date": {"$gte": since}, "type": "task_completed"}},
        {"$group": {
            "_id": {"$dateToString": {"format": "%Y-%m-%d", "date": "$date"}},
            "count": {"$sum": 1},
            "xp": {"$sum": "$xp_earned"}
        }},
        {"$sort": {"_id": 1}}
    ]
    
    data = await db.progress.aggregate(pipeline).to_list(365)
    return {"success": True, "data": {"heatmap": data}}
