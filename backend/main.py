"""
MotivAI Backend — FastAPI
Render.com da ishlashi uchun optimallashtirilgan
"""
import os
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from config.database import connect_db, close_db
from routers import auth_router, tasks_router, ai_router, leaderboard_router, users_router, admin_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    await connect_db()
    yield
    await close_db()


app = FastAPI(
    title="MotivAI API",
    version="2.0.0",
    description="AI-powered student motivation platform",
    lifespan=lifespan,
)

# ── CORS ─────────────────────────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # Production'da o'zgartiring
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── ROUTERS ───────────────────────────────────────────────────────────────────
PREFIX = "/api/v1"
app.include_router(auth_router.router,        prefix=PREFIX)
app.include_router(tasks_router.router,       prefix=PREFIX)
app.include_router(ai_router.router,          prefix=PREFIX)
app.include_router(leaderboard_router.router, prefix=PREFIX)
app.include_router(users_router.router,       prefix=PREFIX)
app.include_router(admin_router.router,       prefix=PREFIX)


# ── HEALTH ───────────────────────────────────────────────────────────────────
@app.get("/health")
async def health():
    return {"status": "ok", "version": "2.0.0"}


@app.get("/")
async def root():
    return {"message": "MotivAI API v2.0 ishlayapti! /docs ga o'ting."}


# ── LOCAL RUN ─────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0",
                port=int(os.getenv("PORT", 8000)), reload=True)
