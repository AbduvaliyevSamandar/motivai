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


@app.get("/ai-debug")
async def ai_debug():
    """Public debug endpoint — shows which AI providers are configured
    and runs a 'ping' message through the fallback chain to identify
    whichever one actually answers (or how each one fails)."""
    from app.services.ai_providers import (
        PROVIDER_ORDER, configured_providers, _PROVIDER_FN,
    )
    out = {
        "configured": configured_providers(),
        "all_in_order": list(PROVIDER_ORDER),
        "env_present": {
            "OPENAI_API_KEY": bool(os.getenv("OPENAI_API_KEY", "").strip()),
            "GEMINI_API_KEY": bool(os.getenv("GEMINI_API_KEY", "").strip()),
            "GROQ_API_KEY":   bool(os.getenv("GROQ_API_KEY", "").strip()),
        },
        "tests": {},
    }
    msgs = [{"role": "user", "content": "Reply with the single word PONG."}]
    for name in out["configured"]:
        try:
            text = await _PROVIDER_FN[name](
                messages=msgs, json_mode=False,
                max_tokens=10, temperature=0.0)
            out["tests"][name] = {"ok": True, "reply": (text or "")[:80]}
        except Exception as e:
            out["tests"][name] = {"ok": False, "error": str(e)[:300]}
    return out

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=int(os.getenv("PORT", 8000)))