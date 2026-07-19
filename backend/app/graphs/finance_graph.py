import logging
from typing import TypedDict, List, Dict, Any, Optional
from pydantic import BaseModel, Field
from langchain_groq import ChatGroq
from langgraph.graph import StateGraph, END
from app.core.config import settings
from app.database.session import SessionLocal
from app.models.models import Transaction, TransactionItem
from langchain_core.messages import SystemMessage, HumanMessage, AIMessage

# Define Pydantic Schema for extraction
class TransactionItemExtraction(BaseModel):
    note: str = Field(description="Nama barang atau catatan item spesifik. Contoh: 'bakso', 'es teh'.")
    amount: int = Field(description="Nominal harga untuk item ini. Contoh: 15000.")
    quantity: int = Field(default=1, description="Jumlah item yang dibeli.")

class TransactionExtraction(BaseModel):
    intent: str = Field(
        description="Intent dari pengguna. Harus berupa 'ADD_EXPENSE', 'ADD_INCOME', 'UNDO', atau 'GENERAL'."
    )
    category: Optional[str] = Field(
        description="Kategori transaksi secara umum. Pilih salah satu: 'Food', 'Groceries', 'Transport', 'Shopping', 'Salary', 'Other'."
    )
    payment_method: Optional[str] = Field(
        description="Metode pembayaran. Nilainya bisa berupa 'tunai' atau 'non_tunai'. Default adalah 'tunai'."
    )
    type: Optional[str] = Field(
        description="Tipe transaksi. 'IN' untuk pemasukan, 'OUT' untuk pengeluaran."
    )
    items: List[TransactionItemExtraction] = Field(
        default=[],
        description="Daftar item detail dalam transaksi ini."
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
            chat_history = [
                SystemMessage(content=(
                    "Anda adalah asisten keuangan pribadi cerdas bernama Dompetku AI.\n"
                    "Tugas Anda adalah mendeteksi intent pengguna dan mengekstrak informasi detail item transaksi.\n"
                    "Pahami konteks percakapan sebelumnya untuk kalimat rujukan atau kalimat lanjutan (follow-up) dari pengguna.\n"
                    "PILIHAN INTENT:\n"
                    "- 'ADD_EXPENSE': untuk pencatatan pengeluaran baru.\n"
                    "- 'ADD_INCOME': untuk pencatatan pemasukan baru.\n"
                    "- 'UNDO': untuk membatalkan/menghapus transaksi terakhir yang baru saja dicatat.\n"
                    "- 'GENERAL': untuk sapaan, pertanyaan umum, atau percakapan biasa.\n\n"
                    "Aturan Memori Konteks:\n"
                    "Jika pesan terakhir pengguna adalah kelanjutan transaksi (misal: 'sama es teh 5000' setelah membeli bakso),\n"
                    "ubah intent-nya menjadi 'ADD_EXPENSE' atau 'ADD_INCOME' sesuai konteks terakhir, lalu ekstrak detail item tersebut.\n"
                    "Jangan gabungkan dengan item lama, cukup kembalikan item yang baru disebutkan di pesan terakhir pengguna, tetapi pastikan context intent tetap terjaga.\n"
                    "Jika pengguna mengetik kata seperti 'batal', 'cancel', atau 'undo', ubah intent menjadi 'UNDO'."
                ))
            ]
            for msg in state["messages"]:
                if msg["role"] == "user":
                    chat_history.append(HumanMessage(content=msg["content"]))
                else:
                    chat_history.append(AIMessage(content=msg["content"]))

            structured_llm = llm.with_structured_output(TransactionExtraction)
            extracted = structured_llm.invoke(chat_history)
            items_list = []
            for item in (extracted.items or []):
                items_list.append({
                    "note": item.note,
                    "amount": item.amount,
                    "quantity": item.quantity
                })
            return {
                "intent": extracted.intent,
                "extracted_data": {
                    "category": extracted.category or "Other",
                    "payment_method": extracted.payment_method or "tunai",
                    "type": extracted.type or ("OUT" if extracted.intent == "ADD_EXPENSE" else "IN"),
                    "items": items_list
                }
            }
        except Exception as e:
            logging.error(f"LLM extraction error: {e}. Falling back to rule-based.")
            
    # Rule-based fallback
    intent = "GENERAL"
    extracted_data = {}
    
    if "batal" in last_message.lower() or "undo" in last_message.lower() or "cancel" in last_message.lower():
        intent = "UNDO"
    elif "beli" in last_message.lower() or "bayar" in last_message.lower():
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
            "category": "Other",
            "payment_method": "tunai",
            "type": "OUT",
            "items": [{"note": note, "amount": amount, "quantity": 1}]
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
            "category": "Salary",
            "payment_method": "tunai",
            "type": "IN",
            "items": [{"note": note, "amount": amount, "quantity": 1}]
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
        items_data = extracted_data.get("items") or []
        if not items_data:
            return {"response": "Maaf, saya tidak menemukan item transaksi dalam pesan Anda."}
            
        total_amount = sum(item.get("amount", 0) * item.get("quantity", 1) for item in items_data)
        if total_amount <= 0:
            return {"response": "Maaf, saya tidak dapat mencatat transaksi jika nominalnya kosong atau nol. Silakan sebutkan jumlah uangnya secara jelas."}
            
        # Create summary note for parent Transaction
        note_summary = ", ".join(f"{item.get('note')} (x{item.get('quantity', 1)})" for item in items_data)
        category = extracted_data.get("category") or "Other"
        pm = extracted_data.get("payment_method") or "tunai"
        tx_type = "OUT" if intent == "ADD_EXPENSE" else "IN"
        
        # Save to DB
        db = SessionLocal()
        try:
            tx = Transaction(
                user_id=user_id,
                note=note_summary,
                amount=total_amount,
                category=category,
                type=tx_type,
                payment_method=pm
            )
            db.add(tx)
            db.flush()
            
            for item in items_data:
                db_item = TransactionItem(
                    transaction_id=tx.id,
                    note=item.get("note") or "Item",
                    amount=item.get("amount") or 0,
                    quantity=item.get("quantity") or 1
                )
                db.add(db_item)
                
            db.commit()
            db.refresh(tx)
            
            items_str = ", ".join([f"{di.note} (x{di.quantity}): Rp {di.amount}" for di in tx.items])
            response_msg = f"Berhasil mencatat {tx_type.lower()} untuk detail: [{items_str}] dengan total Rp {tx.amount} ({tx.payment_method}) ke database dengan ID Transaksi: {tx.id}."
        except Exception as e:
            db.rollback()
            response_msg = f"Gagal menyimpan transaksi ke database: {e}"
        finally:
            db.close()
            
    elif intent == "UNDO":
        db = SessionLocal()
        try:
            last_tx = db.query(Transaction)\
                .filter(Transaction.user_id == user_id)\
                .order_by(Transaction.created_at.desc())\
                .first()
            if last_tx:
                note_to_del = last_tx.note
                amount_to_del = last_tx.amount
                type_to_del = last_tx.type.lower()
                db.delete(last_tx)
                db.commit()
                response_msg = f"Berhasil membatalkan (menghapus) transaksi {type_to_del} terakhir untuk '{note_to_del}' sebesar Rp {amount_to_del}."
            else:
                response_msg = "Tidak ditemukan transaksi terakhir untuk dibatalkan."
        except Exception as e:
            db.rollback()
            response_msg = f"Gagal membatalkan transaksi: {e}"
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
