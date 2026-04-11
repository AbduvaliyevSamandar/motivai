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
