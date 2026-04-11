from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, ForeignKey, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.core.database import Base


class User(Base):
    __tablename__ = "users"

    id              = Column(Integer, primary_key=True, index=True)
    email           = Column(String(255), unique=True, index=True, nullable=False)
    username        = Column(String(100), unique=True, index=True, nullable=False)
    full_name       = Column(String(255), nullable=False)
    hashed_password = Column(String(255), nullable=False)

    faculty        = Column(String(100), nullable=True)
    year           = Column(Integer,     nullable=True)
    age            = Column(Integer,     nullable=True)
    goal_type      = Column(String(50),  nullable=True)
    preferred_time = Column(String(20),  nullable=True)

    gpa               = Column(Float,   nullable=True)
    attendance_rate   = Column(Float,   nullable=True)
    daily_study_hours = Column(Float,   nullable=True)
    sleep_hours       = Column(Float,   nullable=True)
    stress_level      = Column(Integer, nullable=True)   # ← BOR

    points      = Column(Integer, nullable=False, default=0)
    streak_days = Column(Integer, nullable=False, default=0)
    level       = Column(Integer, nullable=False, default=1)
    badges      = Column(JSON,    nullable=True)

    fcm_token             = Column(String(500), nullable=True)
    notifications_enabled = Column(Boolean, nullable=False, default=True)

    is_active   = Column(Boolean,  nullable=False, default=True)
    last_active = Column(DateTime, nullable=True)
    created_at  = Column(DateTime, server_default=func.now())
    updated_at  = Column(DateTime, server_default=func.now(), onupdate=func.now())

    logs        = relationship("MotivationLog",  back_populates="user", cascade="all, delete-orphan")
    completions = relationship("TaskCompletion", back_populates="user", cascade="all, delete-orphan")


class MotivationLog(Base):
    __tablename__ = "motivation_logs"

    id      = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    date    = Column(DateTime, server_default=func.now())

    motivation_level   = Column(Integer, nullable=True)
    stress_level       = Column(Integer, nullable=True)
    mood_score         = Column(Integer, nullable=True)
    energy_level       = Column(Integer, nullable=True)
    ai_recommendations = Column(JSON,    nullable=True)

    user = relationship("User", back_populates="logs")


class TaskCompletion(Base):
    __tablename__ = "task_completions"

    id            = Column(Integer,     primary_key=True, index=True)
    user_id       = Column(Integer,     ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    task_key      = Column(String(50),  nullable=True)
    task_title    = Column(String(255), nullable=True)
    points_earned = Column(Integer,     nullable=True)
    completed_at  = Column(DateTime,    server_default=func.now())

    user = relationship("User", back_populates="completions")
