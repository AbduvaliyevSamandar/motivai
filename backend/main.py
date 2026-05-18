import os
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.db.database import (
    connect_db,
    close_db,
    cleanup_unverified_users,
    merge_duplicate_emails,
)
from app.api.router import api_router

import logging
log = logging.getLogger("startup")


@asynccontextmanager
async def lifespan(app: FastAPI):
    await connect_db()
    # Migrations are best-effort: never block startup on them.
    for step in (cleanup_unverified_users, merge_duplicate_emails):
        try:
            await step()
        except Exception as e:
            log.warning("startup migration %s failed: %s", step.__name__, e)
    yield
    try:
        await close_db()
    except Exception:
        pass

app = FastAPI(
    title="MotivAI API",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/docs",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router)

@app.get("/")
async def root():
    return {"status": "running", "version": "1.0.0"}

@app.get("/health")
async def health():
    from app.db.database import db as _db
    return {
        "status": "healthy",
        "db": "mock" if _db.is_mock else "mongodb",
    }


@app.get("/api/v1/health")
async def health_v1():
    return await health()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=int(os.getenv("PORT", 8000)))