# main.py - MotivAI FastAPI Application Entry Point
import logging
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from app.core.config import settings
from app.db.database import connect_db, close_db
from app.api.router import api_router

# ==============================
# Logging
# ==============================
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# ==============================
# App lifespan (startup / shutdown)
# ==============================
@asynccontextmanager
async def lifespan(app: FastAPI):
    await connect_db()
    logger.info(f"🚀 {settings.APP_NAME} v{settings.APP_VERSION} started")
    yield
    await close_db()

# ==============================
# FastAPI app yaratish
# ==============================
app = FastAPI(
    title="MotivAI API",
    description="Sun'iy intellekt yordamida talabalarning shaxsiy motivatsiya rejasini taklif qiluvchi platforma",
    version=settings.APP_VERSION,
    lifespan=lifespan,
    docs_url="/docs",
    redoc_url="/redoc"
)

# ==============================
# CORS Middleware
# ==============================
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "*"
    ],
    allow_credentials=False,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"],
    allow_headers=["*"],
    max_age=600,
)

# ==============================
# Routes
# ==============================
app.include_router(api_router)

# ==============================
# Root va Health check
# ==============================
@app.get("/")
async def root():
    return {
        "app": settings.APP_NAME,
        "version": settings.APP_VERSION,
        "status": "running",
        "docs": "/docs"
    }

@app.get("/health")
async def health():
    return {"status": "healthy", "app": settings.APP_NAME}

# ==============================
# Uvicorn orqali ishga tushirish
# ==============================
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG
    )