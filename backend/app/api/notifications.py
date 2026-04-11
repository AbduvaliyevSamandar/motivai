import logging
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel

from app.core.database import get_db
from app.models.models import User
from app.api.auth import get_current_user

router = APIRouter()
logger = logging.getLogger(__name__)


class NotificationSettings(BaseModel):
    morning_reminder: bool = True
    evening_reminder: bool = True


async def send_notification(fcm_token: str, title: str, body: str) -> bool:
    try:
        import firebase_admin
        from firebase_admin import messaging, credentials
        from app.core.config import settings
        if not firebase_admin._apps:
            cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
            firebase_admin.initialize_app(cred)
        messaging.send(messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            token=fcm_token,
            android=messaging.AndroidConfig(
                notification=messaging.AndroidNotification(color="#7C6FFF", sound="default")
            ),
        ))
        return True
    except Exception as e:
        logger.error(f"FCM xato: {e}")
        return False


@router.get("/settings")
async def get_settings(current_user: User = Depends(get_current_user)):
    return {
        "notifications_enabled": current_user.notifications_enabled,
        "fcm_token_set": bool(current_user.fcm_token),
    }


@router.put("/settings")
async def update_settings(
    data: NotificationSettings,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    current_user.notifications_enabled = data.morning_reminder or data.evening_reminder
    await db.commit()
    return {"message": "Saqlandi"}


@router.post("/test")
async def test_notification(current_user: User = Depends(get_current_user)):
    if not current_user.fcm_token:
        return {"success": False, "message": "FCM token yoq"}
    ok = await send_notification(current_user.fcm_token, "MotivAI", "Test ishlayapti!")
    return {"success": ok}


@router.put("/fcm-token")
async def update_fcm_token(
    token: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    current_user.fcm_token = token
    await db.commit()
    return {"message": "Token saqlandi"}
