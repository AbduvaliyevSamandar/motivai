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

    # Email (SMTP) for OTP delivery
    SMTP_HOST: str = "smtp.gmail.com"
    SMTP_PORT: int = 587
    SMTP_USER: str = ""
    SMTP_PASSWORD: str = ""
    SMTP_FROM_NAME: str = "MotivAI"
    SMTP_FROM_EMAIL: str = ""  # if empty falls back to SMTP_USER

    # Google OAuth — Web client ID issued by Google Cloud Console
    GOOGLE_OAUTH_CLIENT_ID: str = ""
    # Comma-separated list of additional accepted audiences
    # (e.g. iOS / Android client IDs).
    GOOGLE_OAUTH_AUDIENCES: str = ""

    # Admin token (used by /admin/* maintenance endpoints). Empty -> off.
    ADMIN_SECRET: str = ""

    # CORS
    ALLOWED_ORIGINS: str = "*"

    class Config:
        env_file = ".env"
        case_sensitive = True

# Global settings instance
settings = Settings()