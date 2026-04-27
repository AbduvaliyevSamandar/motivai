# app/schemas/auth.py
from pydantic import BaseModel, EmailStr, Field
from typing import Optional

class RegisterRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=50)
    email: EmailStr
    password: str = Field(..., min_length=6)
    language: str = "uz"
    country: str = "UZ"

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: dict

class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str = Field(..., min_length=6)

class UpdateProfileRequest(BaseModel):
    name: Optional[str] = None
    avatar: Optional[str] = None
    language: Optional[str] = None
    country: Optional[str] = None
    profile: Optional[dict] = None
    notifications: Optional[dict] = None
    fcm_token: Optional[str] = None


# ── Email OTP flows ────────────────────────────────────────
class SendOtpRequest(BaseModel):
    email: EmailStr
    purpose: str = Field(default="register", pattern="^(register|reset|login)$")


class VerifyOtpRequest(BaseModel):
    email: EmailStr
    purpose: str = Field(default="register", pattern="^(register|reset|login)$")
    code: str = Field(..., min_length=6, max_length=6)


class RegisterWithOtpRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=50)
    email: EmailStr
    password: str = Field(..., min_length=6)
    code: str = Field(..., min_length=6, max_length=6)
    language: str = "uz"
    country: str = "UZ"


class ResetPasswordRequest(BaseModel):
    email: EmailStr
    code: str = Field(..., min_length=6, max_length=6)
    new_password: str = Field(..., min_length=6)


# ── Google OAuth ───────────────────────────────────────────
class GoogleAuthRequest(BaseModel):
    id_token: str
    language: str = "uz"
    country: str = "UZ"
