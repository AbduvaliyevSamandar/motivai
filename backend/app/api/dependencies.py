# app/api/dependencies.py
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from app.core.security import verify_token
from app.services.user_service import get_user_by_id

security = HTTPBearer()

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security)
) -> dict:
    token = credentials.credentials
    payload = verify_token(token)
    user = await get_user_by_id(payload["user_id"])
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if not user.get("is_active"):
        raise HTTPException(status_code=403, detail="Account deactivated")
    return user
