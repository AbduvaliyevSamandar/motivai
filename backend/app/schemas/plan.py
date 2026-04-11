# app/schemas/plan.py
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

class TaskCreate(BaseModel):
    title: str
    description: Optional[str] = None
    category: str = "study"
    duration_minutes: int = 30
    difficulty: str = "medium"
    xp_reward: int = 10
    scheduled_time: Optional[str] = None
    day_of_week: List[str] = []
    order: int = 0

class MilestoneCreate(BaseModel):
    title: str
    description: Optional[str] = None
    target_date: Optional[datetime] = None
    xp_reward: int = 50

class PlanCreate(BaseModel):
    title: str
    description: Optional[str] = None
    goal: str
    category: str = "academic"
    duration_days: int = 30
    tasks: List[TaskCreate] = []
    milestones: List[MilestoneCreate] = []
    reminder_enabled: bool = True
    visibility: str = "private"

class TaskCompleteRequest(BaseModel):
    task_id: str
    study_minutes: Optional[int] = None

class PlanResponse(BaseModel):
    id: str
    title: str
    description: Optional[str]
    goal: str
    category: str
    progress: float
    tasks_total: int
    tasks_completed: int
    is_active: bool
    created_at: datetime
