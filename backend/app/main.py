from fastapi import FastAPI, HTTPException, File, UploadFile
from pydantic import BaseModel
from typing import List, Dict
import logging
from app.database.session import engine, Base, SessionLocal
from app.models.models import Transaction, ChatMessage
from app.graphs.finance_graph import finance_graph

from app.agents_endpoints import router as agents_router

# Initialize Database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(title="AI Personal Finance Assistant")
app.include_router(agents_router)

class ChatRequest(BaseModel):
    message: str
    user_id: str = "default_user"

class ChatResponse(BaseModel):
    reply: str
    intent: str
    extracted_data: dict
    logs: List[str] = []

@app.post("/chat", response_model=ChatResponse)
async def chat_endpoint(payload: ChatRequest):
    try:
        messages_state = []
        
        # Load last 10 messages from DB for memory (within last 30 minutes to prevent context drift)
        import datetime
        db = SessionLocal()
        try:
            time_threshold = datetime.datetime.utcnow() - datetime.timedelta(minutes=30)
            past_db_msgs = db.query(ChatMessage)\
                .filter(ChatMessage.user_id == payload.user_id)\
                .filter(ChatMessage.created_at >= time_threshold)\
                .order_by(ChatMessage.created_at.desc())\
                .limit(10)\
                .all()
            
            # Reverse to chronological order (oldest first)
            past_db_msgs.reverse()
            
            for msg in past_db_msgs:
                role = "assistant" if msg.is_ai else "user"
                messages_state.append({"role": role, "content": msg.text})
        except Exception as db_err:
            logging.error(f"Error loading chat history from DB: {db_err}")
        finally:
            db.close()
            
        # Append the new user message
        messages_state.append({"role": "user", "content": payload.message})
        
        # Run LangGraph with input state
        initial_state = {
            "messages": messages_state,
            "user_id": payload.user_id,
            "intent": None,
            "extracted_data": None,
            "response": None
        }
        
        result = await finance_graph.ainvoke(initial_state)
        reply_text = result.get("response") or "Gagal memproses pesan."
        
        # Save user message and AI reply to DB for short-term history
        db = SessionLocal()
        try:
            user_msg = ChatMessage(user_id=payload.user_id, text=payload.message, is_ai=False)
            ai_msg = ChatMessage(user_id=payload.user_id, text=reply_text, is_ai=True)
            db.add(user_msg)
            db.add(ai_msg)
            db.commit()
        except Exception as save_err:
            logging.error(f"Error saving chat history to DB: {save_err}")
            db.rollback()
        finally:
            db.close()
            
        return ChatResponse(
            reply=reply_text,
            intent=result.get("intent") or "UNKNOWN",
            extracted_data=result.get("extracted_data") or {},
            logs=result.get("logs") or []
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/transcribe")
async def transcribe_endpoint(file: UploadFile = File(...)):
    from app.core.config import settings
    if not settings.GROQ_API_KEY:
        raise HTTPException(status_code=500, detail="GROQ_API_KEY is not set.")
    try:
        from groq import Groq
        groq_client = Groq(api_key=settings.GROQ_API_KEY)
        
        file_bytes = await file.read()
        transcription = groq_client.audio.transcriptions.create(
            file=(file.filename, file_bytes),
            model="whisper-large-v3",
            prompt="Saya beli bakso 15000 dan es teh 5000",
            language="id"
        )
        return {"text": transcription.text}
    except Exception as e:
        logging.error(f"Groq STT transcription error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


