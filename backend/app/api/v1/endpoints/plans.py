"""Plans endpoints"""
from fastapi import APIRouter, HTTPException, Depends, Query
from app.schemas.schemas import PlanCreate, PlanUpdate, CompleteTaskRequest
from app.models.plan import Plan
from app.models.user import User
from app.services.gamification_service import complete_task
from app.core.security import get_current_user
from datetime import datetime
import uuid

router = APIRouter()


@router.post("/", status_code=201)
async def create_plan(
    data: PlanCreate,
    current_user: User = Depends(get_current_user)
):
    """Create a new motivation plan"""
    end_date = datetime.utcnow()
    end_date = end_date.replace(day=end_date.day + data.duration)

    # Add IDs to tasks
    tasks = []
    for i, task in enumerate(data.tasks):
        t = task.model_dump()
        t["id"] = str(uuid.uuid4())
        t["order"] = i
        tasks.append(t)

    milestones = []
    for m in data.milestones:
        ml = m.model_dump()
        ml["id"] = str(uuid.uuid4())
        milestones.append(ml)

    plan = Plan(
        user_id=str(current_user.id),
        title=data.title,
        description=data.description,
        goal=data.goal,
        category=data.category,
        duration=data.duration,
        end_date=end_date,
        tasks=tasks,
        milestones=milestones,
        reminder_enabled=data.reminder_enabled,
        visibility=data.visibility
    )
    await plan.insert()

    current_user.total_plans_created += 1
    current_user.xp += 20
    current_user.level = current_user.calculate_level()
    await current_user.save()

    return {
        "success": True,
        "message": "Plan created",
        "data": {"plan": plan.model_dump()}
    }


@router.get("/")
async def get_plans(
    active_only: bool = True,
    current_user: User = Depends(get_current_user)
):
    """Get user's plans"""
    if active_only:
        plans = await Plan.find(
            Plan.user_id == str(current_user.id),
            Plan.is_active == True
        ).sort(-Plan.created_at).to_list()
    else:
        plans = await Plan.find(
            Plan.user_id == str(current_user.id)
        ).sort(-Plan.created_at).to_list()

    return {
        "success": True,
        "data": {"plans": [p.model_dump() for p in plans]}
    }


@router.get("/{plan_id}")
async def get_plan(
    plan_id: str,
    current_user: User = Depends(get_current_user)
):
    """Get a specific plan"""
    plan = await Plan.get(plan_id)
    if not plan:
        raise HTTPException(status_code=404, detail="Plan not found")
    if plan.user_id != str(current_user.id):
        raise HTTPException(status_code=403, detail="Access denied")

    return {"success": True, "data": {"plan": plan.model_dump()}}


@router.put("/{plan_id}")
async def update_plan(
    plan_id: str,
    data: PlanUpdate,
    current_user: User = Depends(get_current_user)
):
    """Update plan"""
    plan = await Plan.get(plan_id)
    if not plan or plan.user_id != str(current_user.id):
        raise HTTPException(status_code=404, detail="Plan not found")

    update_data = data.model_dump(exclude_none=True)
    for field, value in update_data.items():
        setattr(plan, field, value)
    plan.updated_at = datetime.utcnow()
    await plan.save()

    return {"success": True, "message": "Plan updated", "data": {"plan": plan.model_dump()}}


@router.delete("/{plan_id}")
async def delete_plan(
    plan_id: str,
    current_user: User = Depends(get_current_user)
):
    """Delete (deactivate) a plan"""
    plan = await Plan.get(plan_id)
    if not plan or plan.user_id != str(current_user.id):
        raise HTTPException(status_code=404, detail="Plan not found")

    plan.is_active = False
    await plan.save()
    return {"success": True, "message": "Plan deleted"}


@router.post("/{plan_id}/complete-task")
async def complete_task_endpoint(
    plan_id: str,
    data: CompleteTaskRequest,
    current_user: User = Depends(get_current_user)
):
    """Mark a task as completed"""
    try:
        result = await complete_task(
            user=current_user,
            plan_id=plan_id,
            task_id=data.task_id,
            study_minutes=data.study_minutes
        )
        return {
            "success": True,
            "message": "Task completed! 🎉",
            "data": result
        }
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.post("/{plan_id}/add-task")
async def add_task(
    plan_id: str,
    task: dict,
    current_user: User = Depends(get_current_user)
):
    """Add task to plan"""
    plan = await Plan.get(plan_id)
    if not plan or plan.user_id != str(current_user.id):
        raise HTTPException(status_code=404, detail="Plan not found")

    task["id"] = str(uuid.uuid4())
    task["is_completed"] = False
    task["order"] = len(plan.tasks)
    plan.tasks.append(task)
    await plan.save()

    return {"success": True, "message": "Task added", "data": {"task": task}}
