import os
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application configuration settings"""
    
    # App Settings
    APP_NAME: str = "MotivAI - Student Motivation Platform"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = True
    
    # Database Settings
    MONGODB_URL: str = "mongodb://localhost:27017"
    DATABASE_NAME: str = "motivai_db"
    
    # JWT Settings
    SECRET_KEY: str = "your-secret-key-change-in-production-motivai-2026"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7
    
    # API Settings
    API_V1_PREFIX: str = "/api/v1"
    CORS_ORIGINS: list = [
        "http://localhost",
        "http://localhost:3000",
        "http://localhost:8080",
        "http://localhost:5173",
        "http://13.49.73.105",
        "http://13.49.73.105:8000",
    ]
    
    # OpenAI Settings (Real AI)
    OPENAI_API_KEY: str = "sk-placeholder"  # Set via .env in production
    OPENAI_MODEL: str = "gpt-3.5-turbo"
    
    # AI Settings
    AI_MODEL_TYPE: str = "openai"  # simple or openai or llm
    MAX_MOTIVATION_PLANS: int = 100
    
    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings()
