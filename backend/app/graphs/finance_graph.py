import logging
from typing import TypedDict, List, Dict, Any, Optional
from pydantic import BaseModel, Field
from langchain_groq import ChatGroq
from langgraph.graph import StateGraph, END
from app.core.config import settings
from app.database.session import SessionLocal
from app.models.models import Transaction

# Define Pydantic Schema for extraction
class TransactionExtraction(BaseModel):
    intent: str = Field(
        description="Intent dari pengguna. Harus berupa 'ADD_EXPENSE', 'ADD_INCOME', atau 'GENERAL'."
    )
    note: Optional[str] = Field(
        description="Nama barang, deskripsi pengeluaran/pemasukan, atau catatan transaksi. Contoh: 'kopi', 'gaji'."
    )
    amount: Optional[int] = Field(
        description="Jumlah uang atau nominal transaksi dalam angka murni. Contoh: 25000."
    )
    category: Optional[str] = Field(
        description="Kategori transaksi. Pilih salah satu: 'Food', 'Groceries', 'Transport', 'Shopping', 'Salary', 'Other'."
    )
    payment_method: Optional[str] = Field(
        description="Metode pembayaran. Nilainya bisa berupa 'tunai' atau 'non_tunai'. Default adalah 'tunai'."
    )
    type: Optional[str] = Field(
        description="Tipe transaksi. 'IN' untuk pemasukan, 'OUT' untuk pengeluaran."
    )

# Define State Structure
class AgentState(TypedDict):
    messages: List[Dict[str, str]]
    user_id: str
    intent: Optional[str]
    extracted_data: Optional[Dict[str, Any]]
    response: Optional[str]

# Initialize LLM
llm = None
if settings.GROQ_API_KEY:
    try:
        llm = ChatGroq(
            model="llama-3.3-70b-versatile",
            api_key=settings.GROQ_API_KEY,
            temperature=0.0
        )
    except Exception as e:
        logging.warning(f"Failed to initialize ChatGroq: {e}")

# 1. Detect Intent Node
def detect_intent_node(state: AgentState) -> Dict[str, Any]:
    last_message = state["messages"][-1]["content"] if state["messages"] else ""
    
    # Try using Groq if available
    if llm:
        try:
            structured_llm = llm.with_structured_output(TransactionExtraction)
            extracted = structured_llm.invoke(last_message)
            return {
                "intent": extracted.intent,
                "extracted_data": {
                    "note": extracted.note,
                    "amount": extracted.amount,
                    "category": extracted.category,
                    "payment_method": extracted.payment_method or "tunai",
                    "type": extracted.type or ("OUT" if extracted.intent == "ADD_EXPENSE" else "IN")
                }
            }
        except Exception as e:
            logging.error(f"LLM extraction error: {e}. Falling back to rule-based.")
            
    # Rule-based fallback
    intent = "GENERAL"
    extracted_data = {}
    
    if "beli" in last_message.lower() or "bayar" in last_message.lower():
        intent = "ADD_EXPENSE"
        words = last_message.split()
        amount = 0
        note = "belanja"
        for word in words:
            if word.isdigit():
                amount = int(word)
            elif word.lower() not in ["saya", "beli", "bayar", "untuk", "dan"]:
                note = word
        extracted_data = {
            "note": note,
            "amount": amount,
            "category": "Other",
            "payment_method": "tunai",
            "type": "OUT"
        }
    elif "terima" in last_message.lower() or "gaji" in last_message.lower():
        intent = "ADD_INCOME"
        words = last_message.split()
        amount = 0
        note = "pendapatan"
        for word in words:
            if word.isdigit():
                amount = int(word)
            elif word.lower() not in ["saya", "terima", "gaji", "dari"]:
                note = word
        extracted_data = {
            "note": note,
            "amount": amount,
            "category": "Salary",
            "payment_method": "tunai",
            "type": "IN"
        }
        
    return {
        "intent": intent,
        "extracted_data": extracted_data
    }

# 2. Tool Executor Node
def tool_executor_node(state: AgentState) -> Dict[str, Any]:
    intent = state.get("intent")
    extracted_data = state.get("extracted_data") or {}
    user_id = state.get("user_id", "default_user")
    
    if intent in ["ADD_EXPENSE", "ADD_INCOME"]:
        amount = extracted_data.get("amount") or 0
        if amount <= 0:
            return {"response": "Maaf, saya tidak dapat mencatat transaksi jika nominalnya kosong atau nol. Silakan sebutkan jumlah uangnya secara jelas."}
            
        note = extracted_data.get("note") or "Transaksi"
        category = extracted_data.get("category") or "Other"
        pm = extracted_data.get("payment_method") or "tunai"
        tx_type = "OUT" if intent == "ADD_EXPENSE" else "IN"
        
        # Save to DB
        db = SessionLocal()
        try:
            tx = Transaction(
                user_id=user_id,
                note=note,
                amount=amount,
                category=category,
                type=tx_type,
                payment_method=pm
            )
            db.add(tx)
            db.commit()
            db.refresh(tx)
            response_msg = f"Berhasil mencatat {tx_type.lower()} untuk '{tx.note}' sebesar Rp {tx.amount} ({tx.payment_method}) ke database dengan ID: {tx.id}."
        except Exception as e:
            db.rollback()
            response_msg = f"Gagal menyimpan transaksi ke database: {e}"
        finally:
            db.close()
    else:
        response_msg = "Halo! Ada yang bisa saya bantu dengan keuangan Anda?"
        
    return {"response": response_msg}

# Build LangGraph StateGraph
builder = StateGraph(AgentState)

# Add nodes
builder.add_node("detect_intent", detect_intent_node)
builder.add_node("tool_executor", tool_executor_node)

# Set entry point
builder.set_entry_point("detect_intent")

# Define edges
builder.add_edge("detect_intent", "tool_executor")
builder.add_edge("tool_executor", END)

# Compile graph
finance_graph = builder.compile()
