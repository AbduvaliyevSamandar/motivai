"""Pydantic schemas for request/response validation"""
from pydantic import BaseModel, EmailStr, Field, validator
from typing import Optional, List, Any
from datetime import datetime
from enum import Enum


# ===== AUTH SCHEMAS =====
class RegisterRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=50)
    email: EmailStr
    password: str = Field(..., min_length=6)
    language: str = Field(default="uz", pattern="^(uz|ru|en)$")
    country: str = Field(default="UZ")


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class RefreshRequest(BaseModel):
    refresh_token: str


class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str = Field(..., min_length=6)


class UpdateProfileRequest(BaseModel):
    name: Optional[str] = Field(None, min_length=2, max_length=50)
    avatar: Optional[str] = None
    language: Optional[str] = None
    country: Optional[str] = None
    profile: Optional[dict] = None
    notifications_push: Optional[bool] = None
    reminder_time: Optional[str] = None
    fcm_token: Optional[str] = None


# ===== AI SCHEMAS =====
class ChatRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=2000)
    session_id: Optional[str] = None
    conversation_history: List[dict] = []


class ChatResponse(BaseModel):
    message: str
    session_id: Optional[str] = None
    plan_created: Optional[dict] = None


class QuickMotivateResponse(BaseModel):
    message: str


# ===== PLAN SCHEMAS =====
class TaskCreate(BaseModel):
    title: str
    description: Optional[str] = None
    category: str = "study"
    duration: int = 30
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
    duration: int = Field(default=30, ge=1, le=365)
    tasks: List[TaskCreate] = []
    milestones: List[MilestoneCreate] = []
    reminder_enabled: bool = True
    visibility: str = "private"


class PlanUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    goal: Optional[str] = None
    reminder_enabled: Optional[bool] = None
    visibility: Optional[str] = None


class CompleteTaskRequest(BaseModel):
    task_id: str
    study_minutes: int = 0


# ===== LEADERBOARD SCHEMAS =====
class LeaderboardQuery(BaseModel):
    period: str = "weekly"
    country: Optional[str] = None
    limit: int = Field(default=50, ge=1, le=100)


# ===== COMMON SCHEMAS =====
class SuccessResponse(BaseModel):
    success: bool = True
    message: str
    data: Optional[Any] = None


class PaginatedResponse(BaseModel):
    success: bool = True
    data: Any
    total: int
    page: int
    limit: int
    has_next: bool
