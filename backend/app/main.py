from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Dict
from app.database.session import engine, Base
from app.models.models import Transaction
from app.graphs.finance_graph import finance_graph

# Initialize Database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(title="AI Personal Finance Assistant")

class ChatRequest(BaseModel):
    message: str
    user_id: str = "default_user"

class ChatResponse(BaseModel):
    reply: str
    intent: str
    extracted_data: dict

@app.post("/chat", response_model=ChatResponse)
async def chat_endpoint(payload: ChatRequest):
    try:
        # Run LangGraph with input state
        initial_state = {
            "messages": [{"role": "user", "content": payload.message}],
            "user_id": payload.user_id,
            "intent": None,
            "extracted_data": None,
            "response": None
        }
        
        result = await finance_graph.ainvoke(initial_state)
        
        return ChatResponse(
            reply=result.get("response") or "Gagal memproses pesan.",
            intent=result.get("intent") or "UNKNOWN",
            extracted_data=result.get("extracted_data") or {}
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
