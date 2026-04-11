# app/api/endpoints/ai.py
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
from bson import ObjectId
from app.api.dependencies import get_current_user
from app.services.ai_service import chat_with_ai, generate_quick_motivation, analyze_progress, generate_daily_tip
from app.db.database import get_db
import uuid

router = APIRouter(prefix="/ai", tags=["AI"])

class ChatRequest(BaseModel):
    message: str
    session_id: Optional[str] = None
    conversation_history: List[dict] = []

class QuickMotivationRequest(BaseModel):
    context: Optional[str] = None

@router.post("/chat", response_model=dict)
async def chat(request: ChatRequest, current_user: dict = Depends(get_current_user)):
    if not request.message.strip():
        raise HTTPException(status_code=400, detail="Message cannot be empty")
    
    db = get_db()
    session_id = request.session_id or str(uuid.uuid4())
    
    user_context = {
        "name": current_user["name"],
        "level": current_user["level"],
        "xp": current_user["xp"],
        "streak": current_user["streak"],
        "language": current_user["language"],
        "goals": current_user.get("profile", {}).get("goals", []),
        "interests": current_user.get("profile", {}).get("interests", []),
        "learning_style": current_user.get("profile", {}).get("learning_style", "visual"),
        "faculty": current_user.get("profile", {}).get("faculty", ""),
        "university": current_user.get("profile", {}).get("university", ""),
    }
    
    result = await chat_with_ai(
        message=request.message,
        user_context=user_context,
        conversation_history=request.conversation_history
    )
    
    now = datetime.utcnow()
    # Save messages to DB
    await db.chat_messages.insert_many([
        {
            "user_id": current_user["_id"],
            "role": "user",
            "content": request.message,
            "session_id": session_id,
            "timestamp": now
        },
        {
            "user_id": current_user["_id"],
            "role": "assistant",
            "content": result["message"],
            "session_id": session_id,
            "metadata": {"plan_generated": bool(result.get("plan_data"))},
            "timestamp": now
        }
    ])
    
    # Create plan if AI suggested one
    created_plan = None
    if result.get("plan_data") and result["plan_data"].get("create_plan"):
        plan_info = result["plan_data"]["plan"]
        end_date = datetime.utcnow()
        end_date = end_date.replace(day=end_date.day + plan_info.get("duration_days", 30))
        
        plan_doc = {
            "user_id": current_user["_id"],
            "title": plan_info.get("title", "Mening Rejam"),
            "description": plan_info.get("description"),
            "goal": plan_info.get("goal", ""),
            "category": plan_info.get("category", "academic"),
            "duration_days": plan_info.get("duration_days", 30),
            "start_date": datetime.utcnow(),
            "end_date": None,
            "tasks": [
                {**t, "id": str(uuid.uuid4()), "is_completed": False, "completed_at": None}
                for t in plan_info.get("tasks", [])
            ],
            "milestones": [
                {**m, "id": str(uuid.uuid4()), "is_completed": False, "completed_at": None}
                for m in plan_info.get("milestones", [])
            ],
            "ai_suggestions": plan_info.get("ai_suggestions", []),
            "ai_generated": True,
            "progress": 0.0,
            "is_active": True,
            "is_completed": False,
            "total_xp": 0,
            "reminder_enabled": True,
            "visibility": "private",
            "created_at": now,
            "updated_at": now
        }
        
        res = await db.plans.insert_one(plan_doc)
        created_plan = {"id": str(res.inserted_id), "title": plan_doc["title"]}
        
        # XP for creating plan
        await db.users.update_one(
            {"_id": ObjectId(current_user["_id"])},
            {"$inc": {"xp": 25, "ai_messages_count": 2}}
        )
        
        # First plan badge
        user_plans_count = await db.plans.count_documents({"user_id": current_user["_id"]})
        if user_plans_count == 1:
            from app.services.user_service import BADGES
            await db.users.update_one(
                {"_id": ObjectId(current_user["_id"])},
                {"$push": {"badges": {**BADGES["first_plan"], "earned_at": now}}}
            )
    else:
        await db.users.update_one(
            {"_id": ObjectId(current_user["_id"])},
            {"$inc": {"xp": 2, "ai_messages_count": 1}}
        )
    
    return {
        "success": True,
        "data": {
            "message": result["message"],
            "session_id": session_id,
            "created_plan": created_plan,
            "tokens_used": result.get("tokens_used", 0)
        }
    }

@router.get("/history", response_model=dict)
async def get_chat_history(
    session_id: Optional[str] = None,
    limit: int = 50,
    current_user: dict = Depends(get_current_user)
):
    db = get_db()
    query = {"user_id": current_user["_id"]}
    if session_id:
        query["session_id"] = session_id
    
    messages = await db.chat_messages.find(query).sort("timestamp", -1).limit(limit).to_list(limit)
    for m in messages:
        m["_id"] = str(m["_id"])
    
    return {"success": True, "data": {"messages": list(reversed(messages)), "session_id": session_id}}

@router.get("/sessions", response_model=dict)
async def get_chat_sessions(current_user: dict = Depends(get_current_user)):
    db = get_db()
    pipeline = [
        {"$match": {"user_id": current_user["_id"]}},
        {"$group": {
            "_id": "$session_id",
            "last_message": {"$last": "$content"},
            "last_time": {"$last": "$timestamp"},
            "count": {"$sum": 1}
        }},
        {"$sort": {"last_time": -1}},
        {"$limit": 20}
    ]
    sessions = await db.chat_messages.aggregate(pipeline).to_list(20)
    return {"success": True, "data": {"sessions": sessions}}

@router.post("/quick-motivate", response_model=dict)
async def quick_motivate(current_user: dict = Depends(get_current_user)):
    user_context = {
        "name": current_user["name"],
        "streak": current_user["streak"],
        "level": current_user["level"],
        "language": current_user["language"]
    }
    message = await generate_quick_motivation(user_context)
    return {"success": True, "data": {"message": message}}

@router.post("/analyze-progress", response_model=dict)
async def analyze_my_progress(current_user: dict = Depends(get_current_user)):
    db = get_db()
    progress = await db.progress.find({"user_id": current_user["_id"]}).sort("date", -1).limit(20).to_list(20)
    plans = await db.plans.find({"user_id": current_user["_id"], "is_active": True}).to_list(10)
    
    for p in progress:
        p["_id"] = str(p["_id"])
    
    user_context = {
        "name": current_user["name"],
        "xp": current_user["xp"],
        "level": current_user["level"],
        "streak": current_user["streak"],
        "language": current_user["language"]
    }
    
    analysis = await analyze_progress(user_context, progress, plans)
    return {"success": True, "data": {"analysis": analysis}}

@router.get("/daily-tip", response_model=dict)
async def get_daily_tip(
    category: str = "academic",
    current_user: dict = Depends(get_current_user)
):
    tip = await generate_daily_tip(category, current_user["language"])
    return {"success": True, "data": {"tip": tip, "category": category}}

@router.get("/daily-insight", response_model=dict)
async def get_daily_insight(current_user: dict = Depends(get_current_user)):
    """Get daily insight and recommendations"""
    try:
        db = get_db()
        user_id = current_user["_id"]
        
        # Get today's tasks
        today_start = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
        today_end = datetime.utcnow().replace(hour=23, minute=59, second=59, microsecond=999999)
        
        today_progress = await db.progress.find({
            "user_id": user_id,
            "created_at": {"$gte": today_start, "$lte": today_end}
        }).to_list(None)
        
        completed_today = len([p for p in today_progress if p["status"] == "completed"])
        total_today = len(today_progress)
        completion_rate = (completed_today / total_today * 100) if total_today > 0 else 0
        
        points_earned_today = sum([p.get("points_earned", 0) for p in today_progress if p["status"] == "completed"])
        
        # Generate motivation message
        motivation_messages = {
            0: "Great start! Complete your first task to build momentum. 🚀",
            1: f"Awesome! You've completed {completed_today} task(s) today. Keep the streak alive!",
            3: "Incredible focus! You're on fire today! 🔥",
            5: "Amazing dedication! You're crushing your goals! 💪"
        }
        
        motivation_msg = motivation_messages.get(completed_today, f"Fantastic! You're on a roll with {completed_today} tasks completed!")
        
        # Get next recommended task
        next_recommendation = None
        if total_today < 3:  # Encourage more tasks
            available = await db.tasks.find({"is_active": True}).limit(1).to_list(None)
            if available:
                task = available[0]
                next_recommendation = {
                    "task_id": str(task["_id"]),
                    "title": task["title"],
                    "points_reward": task["points_reward"]
                }
        
        return {
            "success": True,
            "data": {
                "date": today_start.isoformat(),
                "total_tasks": total_today,
                "completed_tasks": completed_today,
                "completion_rate": round(completion_rate, 2),
                "points_earned": points_earned_today,
                "motivation_message": motivation_msg,
                "next_recommendation": next_recommendation,
                "streak": current_user.get("streak", 0)
            }
        }
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error getting daily insight: {str(e)}"
        )
