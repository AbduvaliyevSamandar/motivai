"""API v1 Router"""
from fastapi import APIRouter
from app.api.v1.endpoints import auth, users, ai, plans, progress, leaderboard

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["Authentication"])
api_router.include_router(users.router, prefix="/users", tags=["Users"])
api_router.include_router(ai.router, prefix="/ai", tags=["AI"])
api_router.include_router(plans.router, prefix="/plans", tags=["Plans"])
api_router.include_router(progress.router, prefix="/progress", tags=["Progress"])
api_router.include_router(leaderboard.router, prefix="/leaderboard", tags=["Leaderboard"])
