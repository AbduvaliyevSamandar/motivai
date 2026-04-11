"""ChatMessage model"""
from beanie import Document
from pydantic import Field
from typing import Optional
from datetime import datetime
from enum import Enum


class MessageRole(str, Enum):
    USER = "user"
    ASSISTANT = "assistant"


class ChatMessage(Document):
    user_id: str
    role: MessageRole
    content: str
    session_id: Optional[str] = None
    plan_generated: bool = False
    plan_id: Optional[str] = None
    timestamp: datetime = Field(default_factory=datetime.utcnow)

    class Settings:
        name = "chat_messages"
        indexes = ["user_id", "session_id", "timestamp"]
