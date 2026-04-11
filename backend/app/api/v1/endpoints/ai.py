"""AI Chat endpoints"""
from fastapi import APIRouter, HTTPException, Depends
from app.schemas.schemas import ChatRequest
from app.models.user import User
from app.models.chat_message import ChatMessage
from app.services.ai_service import ai_service
from app.core.security import get_current_user
import uuid

router = APIRouter()


@router.post("/chat")
async def chat(
    data: ChatRequest,
    current_user: User = Depends(get_current_user)
):
    """Chat with AI - get motivation, create plans"""
    session_id = data.session_id or str(uuid.uuid4())

    try:
        result = await ai_service.chat(
            user=current_user,
            message=data.message,
            session_id=session_id,
            conversation_history=data.conversation_history
        )
        return {"success": True, "data": result}
    except Exception as e:
        raise HTTPException(status_code=503, detail=str(e))


@router.get("/history")
async def get_chat_history(
    session_id: str = None,
    limit: int = 50,
    current_user: User = Depends(get_current_user)
):
    """Get chat history"""
    query = ChatMessage.find(ChatMessage.user_id == str(current_user.id))
    if session_id:
        query = ChatMessage.find(
            ChatMessage.user_id == str(current_user.id),
            ChatMessage.session_id == session_id
        )

    messages = await query.sort(-ChatMessage.timestamp).limit(limit).to_list()
    messages.reverse()

    return {
        "success": True,
        "data": {
            "messages": [
                {
                    "id": str(m.id),
                    "role": m.role,
                    "content": m.content,
                    "session_id": m.session_id,
                    "timestamp": m.timestamp.isoformat()
                }
                for m in messages
            ]
        }
    }


@router.get("/sessions")
async def get_sessions(current_user: User = Depends(get_current_user)):
    """Get unique chat sessions"""
    pipeline = [
        {"$match": {"user_id": str(current_user.id), "role": "user"}},
        {"$group": {
            "_id": "$session_id",
            "last_message": {"$last": "$content"},
            "last_time": {"$last": "$timestamp"},
            "count": {"$sum": 1}
        }},
        {"$sort": {"last_time": -1}},
        {"$limit": 20}
    ]
    # Simplified: just return recent distinct sessions
    messages = await ChatMessage.find(
        ChatMessage.user_id == str(current_user.id)
    ).sort(-ChatMessage.timestamp).limit(100).to_list()

    sessions = {}
    for m in messages:
        sid = m.session_id
        if sid and sid not in sessions:
            sessions[sid] = {
                "session_id": sid,
                "last_message": m.content[:50] + "..." if len(m.content) > 50 else m.content,
                "timestamp": m.timestamp.isoformat()
            }

    return {"success": True, "data": {"sessions": list(sessions.values())[:20]}}


@router.post("/quick-motivate")
async def quick_motivate(current_user: User = Depends(get_current_user)):
    """Get a quick AI motivation message"""
    try:
        message = await ai_service.quick_motivate(current_user)
        return {"success": True, "data": {"message": message}}
    except Exception as e:
        raise HTTPException(status_code=503, detail="AI service unavailable")


@router.post("/analyze-progress")
async def analyze_progress(current_user: User = Depends(get_current_user)):
    """AI analyzes user's progress"""
    try:
        analysis = await ai_service.analyze_progress(current_user)
        return {"success": True, "data": {"analysis": analysis}}
    except Exception as e:
        raise HTTPException(status_code=503, detail="AI service unavailable")


@router.post("/suggest-tasks")
async def suggest_tasks(
    goal: str,
    current_user: User = Depends(get_current_user)
):
    """Get AI task suggestions for a goal"""
    try:
        tasks = await ai_service.suggest_tasks(current_user, goal)
        return {"success": True, "data": {"tasks": tasks}}
    except Exception as e:
        raise HTTPException(status_code=503, detail="AI service unavailable")
