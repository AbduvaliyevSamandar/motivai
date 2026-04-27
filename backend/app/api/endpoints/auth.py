# app/api/endpoints/auth.py
import logging
from fastapi import APIRouter, HTTPException, Depends
from app.schemas.auth import (
    RegisterRequest,
    LoginRequest,
    TokenResponse,
    ChangePasswordRequest,
    UpdateProfileRequest,
    SendOtpRequest,
    VerifyOtpRequest,
    RegisterWithOtpRequest,
    ResetPasswordRequest,
    GoogleAuthRequest,
)
from app.services.user_service import create_user, get_user_by_email, get_user_by_id, safe_user_dict, update_streak_and_xp
from app.services.email_service import send_otp_email
from app.services.email_validator_service import validate_email, EmailValidationError
from app.services import otp_service
from app.core.security import verify_password, create_access_token, get_password_hash
from app.core.config import settings
from app.api.dependencies import get_current_user
from app.db.database import get_db
from bson import ObjectId
from datetime import datetime

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/register", response_model=dict)
async def register(data: RegisterRequest):
    """Legacy direct-register endpoint — DISABLED. Email accounts must
    now go through /auth/send-otp + /auth/register-with-otp so we can
    confirm the email belongs to the user before creating the account.
    """
    raise HTTPException(
        status_code=410,
        detail="Direct registration is disabled. Use /auth/send-otp + "
               "/auth/register-with-otp instead.",
    )

@router.post("/login", response_model=dict)
async def login(data: LoginRequest):
    user = await get_user_by_email(data.email)
    if not user or not verify_password(data.password, user["hashed_password"]):
        raise HTTPException(status_code=401, detail="Invalid email or password")
    if not user.get("is_active"):
        raise HTTPException(status_code=403, detail="Account deactivated")

    # Reject accounts that never confirmed their email. The only way to
    # mark an account verified is through OTP flow or Google sign-in.
    if not user.get("email_verified") and user.get("auth_provider") != "google":
        raise HTTPException(
            status_code=403,
            detail="Email tasdiqlanmagan. Iltimos, parolni tiklash orqali "
                   "yangilang yoki yangi akkaunt yarating.",
        )

    await update_streak_and_xp(user["_id"], xp_gained=5)
    token = create_access_token({"sub": user["_id"]})
    
    updated_user = await get_user_by_id(user["_id"])
    return {
        "success": True,
        "message": "Login successful",
        "data": {
            "token": token,
            "token_type": "bearer",
            "user": await safe_user_dict(updated_user)
        }
    }

@router.get("/me", response_model=dict)
async def get_me(current_user: dict = Depends(get_current_user)):
    return {"success": True, "data": {"user": await safe_user_dict(current_user)}}

@router.put("/profile", response_model=dict)
async def update_profile(data: UpdateProfileRequest, current_user: dict = Depends(get_current_user)):
    db = get_db()
    update_data = {k: v for k, v in data.model_dump().items() if v is not None}
    update_data["updated_at"] = datetime.utcnow()
    
    if update_data:
        await db.users.update_one(
            {"_id": ObjectId(current_user["_id"])},
            {"$set": update_data}
        )
    
    user = await get_user_by_id(current_user["_id"])
    return {"success": True, "message": "Profile updated", "data": {"user": await safe_user_dict(user)}}

@router.put("/change-password", response_model=dict)
async def change_password(data: ChangePasswordRequest, current_user: dict = Depends(get_current_user)):
    if not verify_password(data.current_password, current_user["hashed_password"]):
        raise HTTPException(status_code=401, detail="Current password is incorrect")

    db = get_db()
    await db.users.update_one(
        {"_id": ObjectId(current_user["_id"])},
        {"$set": {"hashed_password": get_password_hash(data.new_password), "updated_at": datetime.utcnow()}}
    )
    return {"success": True, "message": "Password changed successfully"}


# ─── EMAIL OTP FLOWS ──────────────────────────────────────────────
@router.post("/send-otp", response_model=dict)
async def send_otp(data: SendOtpRequest):
    """Send a 6-digit verification code to ``data.email``.

    For ``purpose='register'`` we reject if the email is already taken.
    For ``purpose='reset'`` we reject if there is no such user. ``login``
    is accepted unconditionally (used as 2FA-ish flow).
    """
    try:
        validate_email(data.email)
    except EmailValidationError as exc:
        raise HTTPException(status_code=400, detail=str(exc))

    existing = await get_user_by_email(data.email)
    if data.purpose == "register" and existing:
        raise HTTPException(status_code=409, detail="Email already registered")
    if data.purpose == "reset" and not existing:
        raise HTTPException(status_code=404, detail="No account with this email")

    try:
        code = await otp_service.issue_otp(email=data.email, purpose=data.purpose)
    except PermissionError:
        raise HTTPException(status_code=429, detail="Too many requests, try again later")

    delivered = send_otp_email(to=data.email, code=code, purpose=data.purpose)
    return {
        "success": True,
        "message": "Verification code sent" if delivered else "Code generated (email service not configured)",
        "data": {"sent": delivered, "expires_in_minutes": 10},
    }


@router.post("/verify-otp", response_model=dict)
async def verify_otp(data: VerifyOtpRequest):
    """Validate a code without creating/changing the account.

    Useful for the 'verify email before showing password field' flow.
    """
    ok = await otp_service.verify_otp(
        email=data.email, purpose=data.purpose, code=data.code
    )
    if not ok:
        raise HTTPException(status_code=400, detail="Invalid or expired code")
    return {"success": True, "message": "Code verified", "data": {"verified": True}}


@router.post("/register-with-otp", response_model=dict)
async def register_with_otp(data: RegisterWithOtpRequest):
    """Single-call registration: validates the code AND creates the user.

    Frontend may either: (a) verify-otp first then call register without code,
    or (b) skip the intermediate check and submit code+password together.
    """
    try:
        validate_email(data.email)
    except EmailValidationError as exc:
        raise HTTPException(status_code=400, detail=str(exc))

    existing = await get_user_by_email(data.email)
    if existing:
        raise HTTPException(status_code=409, detail="Email already registered")

    ok = await otp_service.verify_otp(
        email=data.email, purpose="register", code=data.code
    )
    if not ok:
        raise HTTPException(status_code=400, detail="Invalid or expired code")

    payload = data.model_dump(exclude={"code"})
    user = await create_user(payload)
    token = create_access_token({"sub": user["_id"]})
    return {
        "success": True,
        "message": "Registration successful",
        "data": {
            "token": token,
            "token_type": "bearer",
            "user": await safe_user_dict(user),
        },
    }


@router.post("/forgot-password", response_model=dict)
async def forgot_password(data: SendOtpRequest):
    """Alias for ``send-otp`` with purpose='reset'. Kept as a friendlier name."""
    data.purpose = "reset"
    return await send_otp(data)


@router.post("/reset-password", response_model=dict)
async def reset_password(data: ResetPasswordRequest):
    user = await get_user_by_email(data.email)
    if not user:
        raise HTTPException(status_code=404, detail="No account with this email")
    ok = await otp_service.verify_otp(
        email=data.email, purpose="reset", code=data.code
    )
    if not ok:
        raise HTTPException(status_code=400, detail="Invalid or expired code")

    db = get_db()
    # Reset password also confirms the email (they received the code), so
    # mark the account as verified — useful for accounts created before
    # we required OTP verification.
    await db.users.update_one(
        {"_id": ObjectId(user["_id"])},
        {"$set": {
            "hashed_password": get_password_hash(data.new_password),
            "email_verified": True,
            "is_verified": True,
            "updated_at": datetime.utcnow(),
        }},
    )
    return {"success": True, "message": "Password reset successful"}


# ─── GOOGLE OAUTH ─────────────────────────────────────────────────
@router.post("/google", response_model=dict)
async def google_login(data: GoogleAuthRequest):
    """Verify a Google ID token and either log the user in or create them.

    Requires ``GOOGLE_OAUTH_CLIENT_ID`` (and optionally additional
    audiences via ``GOOGLE_OAUTH_AUDIENCES``) to be set in env vars.
    """
    if not settings.GOOGLE_OAUTH_CLIENT_ID:
        raise HTTPException(status_code=503, detail="Google sign-in not configured")

    try:
        from google.oauth2 import id_token as google_id_token
        from google.auth.transport import requests as g_requests
    except ImportError:
        raise HTTPException(
            status_code=503,
            detail="google-auth package not installed on server",
        )

    accepted_audiences = {settings.GOOGLE_OAUTH_CLIENT_ID}
    if settings.GOOGLE_OAUTH_AUDIENCES:
        accepted_audiences.update(
            {a.strip() for a in settings.GOOGLE_OAUTH_AUDIENCES.split(",") if a.strip()}
        )

    try:
        info = google_id_token.verify_oauth2_token(
            data.id_token,
            g_requests.Request(),
        )
    except ValueError as exc:
        logger.warning("Google ID token verification failed: %s", exc)
        raise HTTPException(status_code=401, detail="Invalid Google token")

    if info.get("aud") not in accepted_audiences:
        raise HTTPException(status_code=401, detail="Audience mismatch")
    if not info.get("email") or not info.get("email_verified"):
        raise HTTPException(status_code=401, detail="Email not verified by Google")

    email = info["email"].lower()
    name = info.get("name") or info.get("given_name") or email.split("@")[0]
    avatar = info.get("picture")

    user = await get_user_by_email(email)
    if not user:
        # Create user with a random unguessable password — they will only
        # ever sign in via Google (or use forgot-password to set a real one).
        import secrets as _secrets

        payload = {
            "name": name,
            "email": email,
            "password": _secrets.token_urlsafe(32),
            "language": data.language,
            "country": data.country,
            "avatar": avatar,
            "auth_provider": "google",
            "google_sub": info.get("sub"),
        }
        user = await create_user(payload)

    token = create_access_token({"sub": user["_id"]})
    return {
        "success": True,
        "message": "Login successful",
        "data": {
            "token": token,
            "token_type": "bearer",
            "user": await safe_user_dict(user),
        },
    }
