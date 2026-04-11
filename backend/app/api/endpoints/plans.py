# app/api/endpoints/plans.py
from fastapi import APIRouter, HTTPException, Depends
from typing import Optional, List
from datetime import datetime
from bson import ObjectId
import uuid
from app.api.dependencies import get_current_user
from app.schemas.plan import PlanCreate, TaskCompleteRequest
from app.services.user_service import update_streak_and_xp, add_task_badge
from app.db.database import get_db

router = APIRouter(prefix="/plans", tags=["Plans"])

def serialize_plan(plan: dict) -> dict:
    plan["_id"] = str(plan["_id"])
    plan["tasks_total"] = len(plan.get("tasks", []))
    plan["tasks_completed"] = sum(1 for t in plan.get("tasks", []) if t.get("is_completed"))
    return plan

@router.post("/", response_model=dict)
async def create_plan(data: PlanCreate, current_user: dict = Depends(get_current_user)):
    db = get_db()
    now = datetime.utcnow()
    
    tasks = [
        {**t.model_dump(), "id": str(uuid.uuid4()), "is_completed": False, "completed_at": None}
        for t in data.tasks
    ]
    milestones = [
        {**m.model_dump(), "id": str(uuid.uuid4()), "is_completed": False, "completed_at": None}
        for m in data.milestones
    ]
    
    plan_doc = {
        **data.model_dump(exclude={"tasks", "milestones"}),
        "user_id": current_user["_id"],
        "tasks": tasks,
        "milestones": milestones,
        "ai_generated": False,
        "ai_suggestions": [],
        "progress": 0.0,
        "is_active": True,
        "is_completed": False,
        "total_xp": 0,
        "created_at": now,
        "updated_at": now
    }
    
    result = await db.plans.insert_one(plan_doc)
    plan_doc["_id"] = str(result.inserted_id)
    
    await update_streak_and_xp(current_user["_id"], xp_gained=15)
    
    return {"success": True, "message": "Plan created", "data": {"plan": serialize_plan(plan_doc)}}

@router.get("/", response_model=dict)
async def get_plans(
    is_active: Optional[bool] = None,
    category: Optional[str] = None,
    current_user: dict = Depends(get_current_user)
):
    db = get_db()
    query = {"user_id": current_user["_id"]}
    if is_active is not None:
        query["is_active"] = is_active
    if category:
        query["category"] = category
    
    plans = await db.plans.find(query).sort("created_at", -1).to_list(50)
    return {"success": True, "data": {"plans": [serialize_plan(p) for p in plans]}}

@router.get("/{plan_id}", response_model=dict)
async def get_plan(plan_id: str, current_user: dict = Depends(get_current_user)):
    db = get_db()
    plan = await db.plans.find_one({"_id": ObjectId(plan_id), "user_id": current_user["_id"]})
    if not plan:
        raise HTTPException(status_code=404, detail="Plan not found")
    return {"success": True, "data": {"plan": serialize_plan(plan)}}

@router.post("/{plan_id}/complete-task", response_model=dict)
async def complete_task(
    plan_id: str,
    data: TaskCompleteRequest,
    current_user: dict = Depends(get_current_user)
):
    db = get_db()
    plan = await db.plans.find_one({"_id": ObjectId(plan_id), "user_id": current_user["_id"]})
    if not plan:
        raise HTTPException(status_code=404, detail="Plan not found")
    
    # Find task
    task_idx = None
    task_xp = 10
    for i, t in enumerate(plan.get("tasks", [])):
        if t["id"] == data.task_id:
            if t.get("is_completed"):
                raise HTTPException(status_code=400, detail="Task already completed")
            task_idx = i
            task_xp = t.get("xp_reward", 10)
            break
    
    if task_idx is None:
        raise HTTPException(status_code=404, detail="Task not found")
    
    now = datetime.utcnow()
    # Update task
    await db.plans.update_one(
        {"_id": ObjectId(plan_id)},
        {
            "$set": {
                f"tasks.{task_idx}.is_completed": True,
                f"tasks.{task_idx}.completed_at": now,
                "updated_at": now
            }
        }
    )
    
    # Recalculate progress
    updated_plan = await db.plans.find_one({"_id": ObjectId(plan_id)})
    tasks = updated_plan.get("tasks", [])
    progress = (sum(1 for t in tasks if t.get("is_completed")) / len(tasks)) * 100 if tasks else 0
    
    await db.plans.update_one(
        {"_id": ObjectId(plan_id)},
        {"$set": {"progress": round(progress, 1)}}
    )
    
    # Update user stats
    study_mins = data.study_minutes or 0
    await db.users.update_one(
        {"_id": ObjectId(current_user["_id"])},
        {"$inc": {"total_tasks_completed": 1, "total_study_minutes": study_mins}}
    )
    
    # XP & streak
    xp_result = await update_streak_and_xp(current_user["_id"], xp_gained=task_xp)
    
    # Badge check
    user = await db.users.find_one({"_id": ObjectId(current_user["_id"])})
    await add_task_badge(current_user["_id"], user.get("total_tasks_completed", 0))
    
    # Save progress log
    await db.progress.insert_one({
        "user_id": current_user["_id"],
        "plan_id": plan_id,
        "task_id": data.task_id,
        "type": "task_completed",
        "xp_earned": task_xp,
        "details": {"task_title": tasks[task_idx]["title"], "study_minutes": study_mins},
        "date": now
    })
    
    # Check plan completion
    if progress >= 100:
        await db.plans.update_one(
            {"_id": ObjectId(plan_id)},
            {"$set": {"is_completed": True, "is_active": False, "completed_at": now}}
        )
        await update_streak_and_xp(current_user["_id"], xp_gained=100)
    
    return {
        "success": True,
        "message": "Task completed!",
        "data": {
            "xp_earned": task_xp,
            "new_xp": xp_result.get("new_xp", 0),
            "new_level": xp_result.get("new_level", 1),
            "plan_progress": round(progress, 1),
            "new_badges": xp_result.get("new_badges", []),
            "plan_completed": progress >= 100
        }
    }

@router.delete("/{plan_id}", response_model=dict)
async def delete_plan(plan_id: str, current_user: dict = Depends(get_current_user)):
    db = get_db()
    result = await db.plans.delete_one({"_id": ObjectId(plan_id), "user_id": current_user["_id"]})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Plan not found")
    return {"success": True, "message": "Plan deleted"}

@router.get("/stats/summary", response_model=dict)
async def get_stats(current_user: dict = Depends(get_current_user)):
    db = get_db()
    uid = current_user["_id"]
    
    total_plans = await db.plans.count_documents({"user_id": uid})
    active_plans = await db.plans.count_documents({"user_id": uid, "is_active": True})
    completed_plans = await db.plans.count_documents({"user_id": uid, "is_completed": True})
    
    # Week progress
    from datetime import timedelta
    week_ago = datetime.utcnow() - timedelta(days=7)
    week_completed = await db.progress.count_documents({
        "user_id": uid, "type": "task_completed", "date": {"$gte": week_ago}
    })
    
    return {
        "success": True,
        "data": {
            "total_plans": total_plans,
            "active_plans": active_plans,
            "completed_plans": completed_plans,
            "total_tasks_completed": current_user.get("total_tasks_completed", 0),
            "total_study_minutes": current_user.get("total_study_minutes", 0),
            "week_tasks_completed": week_completed,
            "streak": current_user["streak"],
            "xp": current_user["xp"],
            "level": current_user["level"],
            "badges_count": len(current_user.get("badges", []))
        }
    }
