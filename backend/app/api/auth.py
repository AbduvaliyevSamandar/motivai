from fastapi import APIRouter, HTTPException, Depends
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, text
from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime
import logging
import traceback

from app.core.database import get_db
from app.core.security import hash_password, verify_password, create_access_token, decode_token
from app.models.models import User

router = APIRouter()
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")
logger = logging.getLogger(__name__)


class RegisterSchema(BaseModel):
    email:             EmailStr
    username:          str
    full_name:         str
    password:          str
    faculty:           Optional[str]   = None
    year:              Optional[int]   = None
    age:               Optional[int]   = None
    goal_type:         Optional[str]   = "academic"
    preferred_time:    Optional[str]   = "morning"
    gpa:               Optional[float] = 0.0
    daily_study_hours: Optional[float] = 3.0
    sleep_hours:       Optional[float] = 7.0


class UpdateProfileSchema(BaseModel):
    full_name:             Optional[str]   = None
    faculty:               Optional[str]   = None
    year:                  Optional[int]   = None
    age:                   Optional[int]   = None
    goal_type:             Optional[str]   = None
    preferred_time:        Optional[str]   = None
    gpa:                   Optional[float] = None
    attendance_rate:       Optional[float] = None
    daily_study_hours:     Optional[float] = None
    sleep_hours:           Optional[float] = None
    stress_level:          Optional[int]   = None
    fcm_token:             Optional[str]   = None
    notifications_enabled: Optional[bool]  = None


def user_to_dict(user: User) -> dict:
    return {
        "id":                    user.id,
        "email":                 user.email,
        "username":              user.username,
        "full_name":             user.full_name,
        "faculty":               user.faculty,
        "year":                  user.year,
        "age":                   user.age,
        "goal_type":             user.goal_type or "academic",
        "preferred_time":        user.preferred_time or "morning",
        "gpa":                   user.gpa or 0.0,
        "attendance_rate":       user.attendance_rate or 80.0,
        "daily_study_hours":     user.daily_study_hours or 3.0,
        "sleep_hours":           user.sleep_hours or 7.0,
        "stress_level":          user.stress_level or 5,
        "points":                user.points or 0,
        "streak_days":           user.streak_days or 0,
        "level":                 user.level or 1,
        "badges":                user.badges if user.badges else [],
        "fcm_token":             user.fcm_token,
        "notifications_enabled": user.notifications_enabled,
        "created_at":            str(user.created_at) if user.created_at else None,
    }


async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    user_id = decode_token(token)
    if not user_id:
        raise HTTPException(status_code=401, detail="Token yaroqsiz")
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="Foydalanuvchi topilmadi")
    return user


@router.get("/ping")
async def ping(db: AsyncSession = Depends(get_db)):
    try:
        await db.execute(text("SELECT 1"))
        return {"status": "ok", "db": "connected"}
    except Exception as e:
        return {"status": "error", "detail": str(e)}


@router.post("/register")
async def register(data: RegisterSchema, db: AsyncSession = Depends(get_db)):
    try:
        res = await db.execute(select(User).where(User.email == data.email))
        if res.scalar_one_or_none():
            raise HTTPException(400, "Bu email allaqachon royxatdan otgan")

        res = await db.execute(select(User).where(User.username == data.username))
        if res.scalar_one_or_none():
            raise HTTPException(400, "Bu username band")

        user = User(
            email=data.email,
            username=data.username,
            full_name=data.full_name,
            hashed_password=hash_password(data.password),
            faculty=data.faculty,
            year=data.year,
            age=data.age,
            goal_type=data.goal_type or "academic",
            preferred_time=data.preferred_time or "morning",
            gpa=data.gpa or 0.0,
            attendance_rate=80.0,
            daily_study_hours=data.daily_study_hours or 3.0,
            sleep_hours=data.sleep_hours or 7.0,
            stress_level=5,
            points=100,
            streak_days=0,
            level=1,
            badges=["Yangi Boshlash"],
            is_active=True,
            notifications_enabled=True,
            last_active=datetime.utcnow(),
        )
        db.add(user)
        await db.commit()
        await db.refresh(user)

        token = create_access_token(user.id)
        return {"access_token": token, "token_type": "bearer", "user": user_to_dict(user)}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Register xato: {traceback.format_exc()}")
        await db.rollback()
        raise HTTPException(500, f"{type(e).__name__}: {str(e)}")


@router.post("/login")
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: AsyncSession = Depends(get_db),
):
    try:
        res = await db.execute(select(User).where(User.email == form_data.username))
        user = res.scalar_one_or_none()

        if not user or not verify_password(form_data.password, user.hashed_password):
            raise HTTPException(401, "Email yoki parol notogri")

        now = datetime.utcnow()
        if user.last_active:
            diff = (now.date() - user.last_active.date()).days
            if diff == 1:
                user.streak_days = (user.streak_days or 0) + 1
                if user.streak_days in [3, 7, 14, 30, 60, 100]:
                    user.points = (user.points or 0) + user.streak_days * 10
                    badges = list(user.badges) if user.badges else []
                    badges.append(f"{user.streak_days} kun streak!")
                    user.badges = badges
            elif diff > 1:
                user.streak_days = 1
        else:
            user.streak_days = 1

        user.last_active = now
        await db.commit()
        await db.refresh(user)

        token = create_access_token(user.id)
        return {"access_token": token, "token_type": "bearer", "user": user_to_dict(user)}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Login xato: {traceback.format_exc()}")
        await db.rollback()
        raise HTTPException(500, f"{type(e).__name__}: {str(e)}")


@router.get("/me")
async def get_me(current_user: User = Depends(get_current_user)):
    return user_to_dict(current_user)


@router.put("/profile")
async def update_profile(
    data: UpdateProfileSchema,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    try:
        for field, value in data.model_dump(exclude_none=True).items():
            setattr(current_user, field, value)
        await db.commit()
        await db.refresh(current_user)
        return {"message": "Profil yangilandi", "user": user_to_dict(current_user)}
    except Exception as e:
        await db.rollback()
        raise HTTPException(500, f"{type(e).__name__}: {str(e)}")
