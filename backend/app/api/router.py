# app/api/router.py
from fastapi import APIRouter
from app.api.endpoints import auth, ai, plans, leaderboard, progress

api_router = APIRouter(prefix="/api/v1")

api_router.include_router(auth.router)
api_router.include_router(ai.router)
api_router.include_router(plans.router)
api_router.include_router(leaderboard.router)
api_router.include_router(progress.router)
