"""Progress tracking model"""
from beanie import Document
from pydantic import Field
from typing import Optional, Any
from datetime import datetime
from enum import Enum


class ProgressType(str, Enum):
    TASK_COMPLETED = "task_completed"
    MILESTONE_REACHED = "milestone_reached"
    STREAK_MAINTAINED = "streak_maintained"
    PLAN_COMPLETED = "plan_completed"
    XP_GAINED = "xp_gained"
    BADGE_EARNED = "badge_earned"
    LEVEL_UP = "level_up"


class Progress(Document):
    user_id: str
    plan_id: Optional[str] = None
    task_id: Optional[str] = None
    type: ProgressType
    xp_earned: int = 0
    details: Optional[dict] = None
    date: datetime = Field(default_factory=datetime.utcnow)

    class Settings:
        name = "progress"
        indexes = ["user_id", "date", "type"]
