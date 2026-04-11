# app/core/config.py
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # App info
    APP_NAME: str = "MotivAI"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False

    # Server
    HOST: str = "0.0.0.0"
    PORT: int = 8000

    # Security
    SECRET_KEY: str = "motivai-secret-key-change-in-production-32chars"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 10080  # 7 days

    # Database
    DATABASE_URL: str = "postgresql://localhost/motivai"
    SYNC_DATABASE_URL: str = "postgresql://localhost/motivai"
    MODELS_DIR: str = "app/ml/models"
    MONGODB_URL: str = "mongodb://localhost:27017/motivai"
    DATABASE_NAME: str = "motivai"

    # External APIs / Services
    OPENAI_API_KEY: str = ""  # <-- Shu qo'shildi
    ANTHROPIC_API_KEY: str = ""
    FIREBASE_CREDENTIALS_PATH: str = "firebase-credentials.json"

    # CORS
    ALLOWED_ORIGINS: str = "*"

    class Config:
        env_file = ".env"
        case_sensitive = True

# Global settings instance
settings = Settings()