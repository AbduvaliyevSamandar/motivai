from fastapi import APIRouter, Depends
from app.api.auth import get_current_user, user_to_dict
from app.models.models import User

router = APIRouter()


@router.get("/profile")
async def get_profile(current_user: User = Depends(get_current_user)):
    return user_to_dict(current_user)
