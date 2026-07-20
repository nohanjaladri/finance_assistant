import logging
import re
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
        description="Intent dari pengguna. Harus berupa 'ADD_EXPENSE', 'ADD_INCOME', 'UNDO', 'QUERY', atau 'GENERAL'."
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
    sql_query: Optional[str] = Field(
        default=None,
        description=(
            "Query SQL SELECT PostgreSQL yang valid untuk menjawab pertanyaan pengguna jika intent-nya adalah 'QUERY'. "
            "Hanya diizinkan men-query tabel 'transactions' (beserta join 'transaction_items' jika menanyakan detail item). "
            "Gunakan parameter ':user_id' untuk memfilter data transaksi milik user terkait. "
            "Contoh: 'SELECT SUM(amount) FROM transactions WHERE user_id = :user_id AND type = \\'OUT\\' AND category = \\'Food\\''"
        )
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
                    "Tugas Anda adalah mendeteksi intent pengguna dan mengekstrak informasi detail item transaksi atau menghasilkan query database.\n"
                    "Pahami konteks percakapan sebelumnya untuk kalimat rujukan atau kalimat lanjutan (follow-up) dari pengguna.\n"
                    "PILIHAN INTENT:\n"
                    "- 'ADD_EXPENSE': untuk pencatatan pengeluaran baru.\n"
                    "- 'ADD_INCOME': untuk pencatatan pemasukan baru.\n"
                    "- 'UNDO': untuk membatalkan/menghapus transaksi terakhir yang baru saja dicatat.\n"
                    "- 'QUERY': untuk menanyakan/menganalisis riwayat transaksi keuangan mereka sendiri (misal: total belanja, pengeluaran kategori tertentu, list belanja terbesar, dll).\n"
                    "- 'GENERAL': untuk sapaan, pertanyaan umum non-finansial, atau percakapan biasa.\n\n"
                    "Aturan Memori Konteks:\n"
                    "Jika pesan terakhir pengguna adalah kelanjutan transaksi (misal: 'sama es teh 5000' setelah membeli bakso),\n"
                    "ubah intent-nya menjadi 'ADD_EXPENSE' atau 'ADD_INCOME' sesuai konteks terakhir, lalu ekstrak detail item tersebut.\n"
                    "Jangan gabungkan dengan item lama, cukup kembalikan item yang baru disebutkan di pesan terakhir pengguna, tetapi pastikan context intent tetap terjaga.\n"
                    "Jika pengguna mengetik kata seperti 'batal', 'cancel', atau 'undo', ubah intent menjadi 'UNDO'.\n\n"
                    "Aturan QUERY:\n"
                    "Jika intent adalah 'QUERY', hasilkan query SQL SELECT PostgreSQL yang valid di bidang 'sql_query'.\n"
                    "Query HANYA boleh mengakses tabel 'transactions' (t) atau join 'transaction_items' (ti) jika menanyakan detail item.\n"
                    "Kolom tabel 'transactions' adalah: id, user_id, amount, note, type ('IN'/'OUT'), category, payment_method, created_at.\n"
                    "PENTING: Selalu masukkan filter `user_id = :user_id` di klausa WHERE agar data aman dan terisolasi.\n"
                    "Contoh: jika user tanya 'berapa total belanja boba?', gunakan `SELECT SUM(t.amount) FROM transactions t JOIN transaction_items ti ON t.id = ti.transaction_id WHERE t.user_id = :user_id AND LOWER(ti.note) LIKE '%boba%'`"
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
                    "items": items_list,
                    "sql_query": extracted.sql_query
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
    last_message = state["messages"][-1]["content"] if state["messages"] else ""
    
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
            
    elif intent == "QUERY":
        sql_query = extracted_data.get("sql_query")
        if not sql_query:
            return {"response": "Maaf, saya tidak dapat memahami query untuk pertanyaan Anda."}
            
        normalized_sql = sql_query.strip().upper()
        if not normalized_sql.startswith("SELECT"):
            return {"response": "Akses ditolak: Hanya query SELECT membaca data yang diizinkan."}
            
        allowed_tables = ["transactions", "transaction_items"]
        table_matches = re.findall(r'\bFROM\s+([\w\.]+)\b|\bJOIN\s+([\w\.]+)\b', sql_query, re.IGNORECASE)
        for match in table_matches:
            raw_table = (match[0] or match[1] or '').lower()
            if '.' in raw_table:
                raw_table = raw_table.split('.')[-1]
            if raw_table and raw_table not in allowed_tables:
                return {"response": f"Akses ditolak: Tidak diizinkan mengakses tabel '{raw_table}'."}
                
        blocked_keywords = ["DELETE", "DROP", "UPDATE", "INSERT", "ALTER", "CREATE", "TRUNCATE", "REPLACE"]
        for blocked in blocked_keywords:
            if re.search(r'\b' + blocked + r'\b', normalized_sql):
                return {"response": f"Akses ditolak: Query mengandung perintah terlarang '{blocked}'."}
                
        db = SessionLocal()
        try:
            from sqlalchemy import text
            result = db.execute(text(sql_query), {"user_id": user_id})
            rows = result.fetchall()
            columns = result.keys()
            
            formatted_results = []
            for row in rows:
                formatted_results.append(dict(zip(columns, row)))
                
            if not formatted_results:
                response_msg = "Tidak ditemukan data transaksi yang sesuai dengan pertanyaan Anda."
            else:
                if llm:
                    prompt = (
                        f"Pertanyaan Pengguna: '{last_message}'\n"
                        f"Data Database Hasil Query: {formatted_results}\n\n"
                        f"Tugas Anda: Jawab pertanyaan pengguna secara ringkas, ramah, dan alami dalam bahasa Indonesia berdasarkan data di atas. "
                        f"Format nominal uang dengan format Rp (Rupiah) jika ada."
                    )
                    llm_response = llm.invoke(prompt)
                    response_msg = llm_response.content
                else:
                    response_msg = f"Hasil analisis data: {formatted_results}"
        except Exception as e:
            logging.error(f"Error executing database query: {e}")
            response_msg = f"Gagal mengambil data dari database: {e}"
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
