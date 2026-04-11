# app/models/plan.py
from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime

class Task(BaseModel):
    id: str = Field(default_factory=lambda: str(__import__('uuid').uuid4()))
    title: str
    description: Optional[str] = None
    category: str = "study"  # study, exercise, reading, practice, review, other
    duration_minutes: int = 30
    difficulty: str = "medium"  # easy, medium, hard
    xp_reward: int = 10
    is_completed: bool = False
    completed_at: Optional[datetime] = None
    scheduled_time: Optional[str] = None  # "09:00"
    day_of_week: List[str] = []  # ["Monday", "Wednesday"]
    order: int = 0

class Milestone(BaseModel):
    id: str = Field(default_factory=lambda: str(__import__('uuid').uuid4()))
    title: str
    description: Optional[str] = None
    target_date: Optional[datetime] = None
    is_completed: bool = False
    completed_at: Optional[datetime] = None
    xp_reward: int = 50

class PlanDB(BaseModel):
    id: Optional[str] = Field(default=None, alias="_id")
    user_id: str
    title: str
    description: Optional[str] = None
    goal: str
    ai_generated: bool = False
    ai_suggestions: List[str] = []
    category: str = "academic"  # academic, personal, career, health, skills, language
    duration_days: int = 30
    start_date: datetime = Field(default_factory=datetime.utcnow)
    end_date: Optional[datetime] = None
    tasks: List[Task] = []
    milestones: List[Milestone] = []
    progress: float = 0.0  # 0-100
    is_active: bool = True
    is_completed: bool = False
    completed_at: Optional[datetime] = None
    total_xp: int = 0
    reminder_enabled: bool = True
    visibility: str = "private"  # private, friends, public
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        populate_by_name = True

class ProgressDB(BaseModel):
    id: Optional[str] = Field(default=None, alias="_id")
    user_id: str
    plan_id: Optional[str] = None
    task_id: Optional[str] = None
    type: str  # task_completed, milestone_reached, streak_maintained, plan_completed, xp_gained
    xp_earned: int = 0
    details: Optional[dict] = None
    date: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        populate_by_name = True

class ChatMessageDB(BaseModel):
    id: Optional[str] = Field(default=None, alias="_id")
    user_id: str
    role: str  # user, assistant
    content: str
    session_id: Optional[str] = None
    metadata: Optional[dict] = None
    timestamp: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        populate_by_name = True
