"""Leaderboard model"""
from beanie import Document
from pydantic import Field
from typing import Optional
from datetime import datetime
from enum import Enum


class LeaderboardPeriod(str, Enum):
    DAILY = "daily"
    WEEKLY = "weekly"
    MONTHLY = "monthly"
    ALL_TIME = "alltime"


class LeaderboardEntry(Document):
    user_id: str
    period: LeaderboardPeriod
    xp: int = 0
    tasks_completed: int = 0
    streak: int = 0
    rank: Optional[int] = None
    country: str = "UZ"
    date: datetime = Field(default_factory=datetime.utcnow)

    class Settings:
        name = "leaderboard"
        indexes = ["user_id", "period", "xp", "country"]
