# app/models/user.py
from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List
from datetime import datetime
from bson import ObjectId

class PyObjectId(ObjectId):
    @classmethod
    def __get_validators__(cls):
        yield cls.validate
    @classmethod
    def validate(cls, v):
        if not ObjectId.is_valid(v):
            raise ValueError("Invalid objectid")
        return ObjectId(v)
    @classmethod
    def __get_pydantic_json_schema__(cls, field_schema):
        field_schema.update(type="string")

class UserProfile(BaseModel):
    university: Optional[str] = None
    faculty: Optional[str] = None
    year: Optional[int] = None
    goals: List[str] = []
    interests: List[str] = []
    learning_style: str = "visual"  # visual, auditory, reading, kinesthetic

class Badge(BaseModel):
    id: str
    name: str
    icon: str
    earned_at: datetime = Field(default_factory=datetime.utcnow)

class NotificationSettings(BaseModel):
    push: bool = True
    email_notif: bool = True
    reminder_time: str = "09:00"

class UserDB(BaseModel):
    id: Optional[str] = Field(default=None, alias="_id")
    name: str
    email: EmailStr
    hashed_password: str
    avatar: Optional[str] = None
    country: str = "UZ"
    language: str = "uz"  # uz, ru, en
    role: str = "student"
    profile: UserProfile = Field(default_factory=UserProfile)
    xp: int = 0
    level: int = 1
    streak: int = 0
    last_active_date: datetime = Field(default_factory=datetime.utcnow)
    badges: List[Badge] = []
    total_tasks_completed: int = 0
    total_study_minutes: int = 0
    ai_messages_count: int = 0
    notifications: NotificationSettings = Field(default_factory=NotificationSettings)
    fcm_token: Optional[str] = None
    is_verified: bool = False
    is_active: bool = True
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

    class Config:
        populate_by_name = True
        arbitrary_types_allowed = True
        json_encoders = {ObjectId: str}
