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
    amount: Optional[int] = Field(default=0, description="Nominal harga untuk item ini. Contoh: 15000. Isikan 0 atau null jika tidak disebutkan.")
    quantity: int = Field(default=1, description="Jumlah item yang dibeli.")

class TransactionExtraction(BaseModel):
    intent: str = Field(
        description="Intent dari pengguna. Harus berupa 'ADD_EXPENSE', 'ADD_INCOME', 'UNDO', 'QUERY', 'APPEND_ITEM', 'MODIFY_LAST', atau 'GENERAL'."
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
    confidence_score: float = Field(
        description="Tingkat kepercayaan/keyakinan AI terhadap data yang diekstrak (nilai antara 0.0 hingga 1.0). "
                    "Berikan nilai rendah (misal < 0.8) jika nominal uang tidak ada/tidak jelas, nama barang ambigu, atau intent tidak pasti."
    )
    is_ambiguous: bool = Field(
        description="Set True jika ada informasi penting yang kurang, tidak jelas, atau membutuhkan konfirmasi/klarifikasi dari pengguna."
    )
    clarification_question: Optional[str] = Field(
        default=None,
        description="Pertanyaan ramah dalam bahasa Indonesia untuk meminta klarifikasi jika is_ambiguous bernilai True atau confidence_score rendah. Contoh: 'Berapa harga baksonya?' atau 'Apakah transaksi ini berupa pemasukan atau pengeluaran?'."
    )

# Define State Structure
class AgentState(TypedDict):
    messages: List[Dict[str, str]]
    user_id: str
    intent: Optional[str]
    extracted_data: Optional[Dict[str, Any]]
    response: Optional[str]
    logs: List[str]

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
                    "- 'APPEND_ITEM': jika pengguna ingin menambahkan item baru ke transaksi belanjaan yang paling terakhir dicatat (misal: 'tambahkan es jeruk 5000', 'eh masukkan es teh 3000 juga ke belanjaan tadi').\n"
                    "- 'MODIFY_LAST': jika pengguna ingin mengubah/merevisi detail transaksi terakhir yang baru saja diinput (misal: 'ganti harganya jadi 12000', 'harganya salah, harusnya 15000').\n"
                    "- 'GENERAL': untuk sapaan, pertanyaan umum non-finansial, atau percakapan biasa.\n\n"
                    "Aturan Memori Konteks:\n"
                    "- Jika pesan terakhir pengguna adalah kelanjutan transaksi (misal: 'sama es teh 5000' setelah membeli bakso),\n"
                    "  pilih intent 'APPEND_ITEM' jika itu berupa tambahan item baru untuk transaksi terakhir, lalu ekstrak detail item tersebut.\n"
                    "- Jika pesan terakhir bertujuan untuk merevisi nominal transaksi terakhir (misal: 'eh harganya salah, harusnya 15000'), pilih intent 'MODIFY_LAST' dan ekstrak nominal baru tersebut di bagian items.\n"
                    "- Jika pengguna mengetik kata seperti 'batal', 'cancel', atau 'undo', ubah intent menjadi 'UNDO'.\n\n"
                    "Aturan QUERY:\n"
                    "Jika intent adalah 'QUERY', hasilkan query SQL SELECT PostgreSQL yang valid di bidang 'sql_query'.\n"
                    "Query HANYA boleh mengakses tabel 'transactions' (t) atau join 'transaction_items' (ti) jika menanyakan detail item.\n"
                    "Kolom tabel 'transactions' adalah: id, user_id, amount, note, type ('IN'/'OUT'), category, payment_method, created_at.\n"
                    "PENTING: Selalu masukkan filter `user_id = :user_id` di klausa WHERE agar data aman dan terisolasi.\n"
                    "PENTING: Untuk filter waktu/tanggal, gunakan PostgreSQL date functions berikut agar sangat akurat:\n"
                    "                    "  - Harian (hari ini): `created_at::date = CURRENT_DATE` atau group by `created_at::date`\n"
                    "  - Mingguan (minggu ini): `created_at >= DATE_TRUNC('week', CURRENT_DATE)` atau group by `DATE_TRUNC('week', created_at)`\n"
                    "  - Bulanan (bulan ini): `created_at >= DATE_TRUNC('month', CURRENT_DATE)` atau group by `DATE_TRUNC('month', created_at)`\n"
                    "  - PENTING: Jika membandingkan created_at dengan string tanggal statis (misal '2024-06-01'), Anda HARUS melakukan type cast secara eksplisit seperti `'2024-06-01'::timestamp` atau `'2024-06-01'::date` (misal: `DATE_TRUNC('month', '2024-06-01'::timestamp)`), karena tanpa cast PostgreSQL akan menghasilkan error 'date_trunc(unknown, unknown) is not unique'.\n"
                    "  - Pastikan filter pengeluaran menggunakan `type = 'OUT'` dan pemasukan menggunakan `type = 'IN'`.\n"
                    "Contoh: jika user tanya 'berapa total belanja boba?', gunakan `SELECT SUM(t.amount) FROM transactions t JOIN transaction_items ti ON t.id = ti.transaction_id WHERE t.user_id = :user_id AND LOWER(ti.note) LIKE '%boba%'`\n\n"
                    "Aturan Keyakinan (Confidence Score) & Klarifikasi:\n"
                    "- Nilai 'confidence_score' harus berkisar antara 0.0 (sangat tidak yakin) hingga 1.0 (sangat yakin).\n"
                    "- Jika nominal transaksi (jumlah uang) atau nama item belanja tidak disebutkan secara eksplisit atau tidak jelas, berikan 'confidence_score' di bawah 0.8, set 'is_ambiguous' menjadi true, dan buat 'clarification_question' yang menanyakan info yang kurang secara spesifik.\n"
                    "- Contoh: jika user mengetik 'saya beli roti', nominal harganya tidak ada. Berikan confidence_score = 0.5, is_ambiguous = true, dan clarification_question = 'Berapa harga roti yang Anda beli?'\n"
                    "- Jika pesan berupa sapaan, percakapan umum, atau query yang sudah jelas maksudnya, berikan confidence_score = 1.0 dan is_ambiguous = false."
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
                    "amount": item.amount if item.amount is not None else 0,
                    "quantity": item.quantity
                })
            conf_val = extracted.confidence_score if extracted.confidence_score is not None else 1.0
            return {
                "intent": extracted.intent,
                "extracted_data": {
                    "category": extracted.category or "Other",
                    "payment_method": extracted.payment_method or "tunai",
                    "type": extracted.type or ("OUT" if extracted.intent == "ADD_EXPENSE" else "IN"),
                    "items": items_list,
                    "sql_query": extracted.sql_query,
                    "confidence_score": conf_val,
                    "is_ambiguous": extracted.is_ambiguous if extracted.is_ambiguous is not None else False,
                    "clarification_question": extracted.clarification_question
                },
                "logs": [f"[Orchestrator] Menganalisis input: \"{last_message}\". Mendeteksi intent: '{extracted.intent}' (Confidence: {int(conf_val * 100)}%)."]
            }
        except Exception as e:
            logging.error(f"LLM extraction error: {e}. Falling back to rule-based.")
            
    # Rule-based fallback
    intent = "GENERAL"
    extracted_data = {
        "category": "Other",
        "payment_method": "tunai",
        "type": "OUT",
        "items": [],
        "confidence_score": 1.0,
        "is_ambiguous": False,
        "clarification_question": None
    }
    
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
            "items": [{"note": note, "amount": amount, "quantity": 1}],
            "confidence_score": 1.0 if amount > 0 else 0.5,
            "is_ambiguous": False if amount > 0 else True,
            "clarification_question": None if amount > 0 else "Berapa nominal belanja pengeluaran Anda?"
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
            "items": [{"note": note, "amount": amount, "quantity": 1}],
            "confidence_score": 1.0 if amount > 0 else 0.5,
            "is_ambiguous": False if amount > 0 else True,
            "clarification_question": None if amount > 0 else "Berapa nominal pendapatan Anda?"
        }
        
    conf_val = extracted_data.get("confidence_score", 1.0)
    return {
        "intent": intent,
        "extracted_data": extracted_data,
        "logs": [f"[Orchestrator (Fallback)] Menganalisis input: \"{last_message}\". Mendeteksi intent: '{intent}' (Confidence: {int(conf_val * 100)}%)."]
    }

# 2. Tool Executor Node
def tool_executor_node(state: AgentState) -> Dict[str, Any]:
    intent = state.get("intent")
    extracted_data = state.get("extracted_data") or {}
    user_id = state.get("user_id", "default_user")
    import uuid
    try:
        uuid.UUID(user_id)
    except (ValueError, TypeError):
        user_id = "0c732da4-39e4-45f1-8a64-984d66baadf0"
        
    last_message = state["messages"][-1]["content"] if state["messages"] else ""
    
    # Initialize current execution logs
    current_logs = list(state.get("logs") or [])
    
    if intent in ["ADD_EXPENSE", "ADD_INCOME"]:
        confidence_score = extracted_data.get("confidence_score", 1.0)
        is_ambiguous = extracted_data.get("is_ambiguous", False)
        clarification_question = extracted_data.get("clarification_question")

        # Check for ambiguity or low confidence
        if is_ambiguous or confidence_score < 0.8:
            confidence_pct = int(confidence_score * 100)
            current_logs.append(f"[Entry Agent] Transaksi terdeteksi kurang lengkap/ambigu (Confidence: {confidence_pct}%). Mengaktifkan alur klarifikasi reaktif.")
            reply = clarification_question or "Maaf, informasi transaksi kurang lengkap. Bisa tolong sebutkan nominal uang dan detail barangnya secara jelas?"
            return {"response": f"{reply} (Confidence: {confidence_pct}%)", "logs": current_logs}

        items_data = extracted_data.get("items") or []
        if not items_data:
            current_logs.append("[Entry Agent] Gagal memproses: tidak menemukan item detail belanja.")
            return {"response": "Maaf, saya tidak menemukan item transaksi dalam pesan Anda.", "logs": current_logs}
            
        total_amount = sum(item.get("amount", 0) * item.get("quantity", 1) for item in items_data)
        if total_amount <= 0:
            current_logs.append("[Entry Agent] Gagal memproses: nominal belanja nol.")
            return {"response": "Maaf, saya tidak dapat mencatat transaksi jika nominalnya kosong atau nol. Silakan sebutkan jumlah uangnya secara jelas.", "logs": current_logs}
            
        # Create summary note for parent Transaction
        note_summary = ", ".join(f"{item.get('note')}" for item in items_data)
        category = extracted_data.get("category") or "Other"
        pm = extracted_data.get("payment_method") or "tunai"
        tx_type = "OUT" if intent == "ADD_EXPENSE" else "IN"
        
        current_logs.append(f"[Entry Agent] Membuka koneksi database untuk merekam transaksi {tx_type.lower()} sebesar Rp {total_amount}.")
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
            
            current_logs.append(f"[Entry Agent] Sukses menyimpan transaksi (ID: {tx.id}) ke database.")
            items_str = ", ".join([f"{di.note} (x{di.quantity}): Rp {di.amount}" for di in tx.items])
            confidence_pct = int(confidence_score * 100)
            if llm:
                prompt = (
                    f"Pertanyaan/Perintah Pengguna: '{last_message}'\n"
                    f"Aksi Database: Berhasil mencatat transaksi {tx_type.lower()} (pemasukan/pengeluaran) senilai Rp {tx.amount} dengan metode pembayaran {tx.payment_method}. Detail item: {items_str}.\n\n"
                    f"Tugas Anda: Beritahu pengguna dengan ramah, santai, dan alami dalam bahasa Indonesia bahwa transaksinya sudah berhasil dicatat."
                )
                llm_response = llm.invoke(prompt)
                response_msg = f"{llm_response.content} (Confidence: {confidence_pct}%)"
            else:
                response_msg = f"Berhasil mencatat {tx_type.lower()} untuk detail: [{items_str}] dengan total Rp {tx.amount} ({tx.payment_method}). (Confidence: {confidence_pct}%)"
        except Exception as e:
            db.rollback()
            current_logs.append(f"[Entry Agent] Error penyimpanan database: {e}")
            response_msg = f"Gagal menyimpan transaksi ke database: {e}"
        finally:
            db.close()
            
    elif intent == "APPEND_ITEM":
        items_data = extracted_data.get("items") or []
        if not items_data:
            current_logs.append("[Entry Agent] Gagal menambahkan: item tidak ditemukan.")
            return {"response": "Maaf, saya tidak menemukan item tambahan dalam pesan Anda.", "logs": current_logs}
            
        current_logs.append("[Context Agent] Mencari transaksi terakhir pengguna untuk menambahkan item...")
        db = SessionLocal()
        try:
            last_tx = db.query(Transaction)\
                .filter(Transaction.user_id == user_id)\
                .order_by(Transaction.created_at.desc())\
                .first()
            if not last_tx:
                current_logs.append("[Context Agent] Gagal: Tidak ada transaksi sebelumnya yang ditemukan di database.")
                return {"response": "Tidak ditemukan transaksi sebelumnya untuk ditambahkan item.", "logs": current_logs}
                
            current_logs.append(f"[Context Agent] Ditemukan transaksi terakhir (ID: {last_tx.id}) '{last_tx.note}' sebesar Rp {last_tx.amount}.")
            total_added = 0
            added_items_str_list = []
            for item in items_data:
                db_item = TransactionItem(
                    transaction_id=last_tx.id,
                    note=item.get("note") or "Item",
                    amount=item.get("amount") or 0,
                    quantity=item.get("quantity") or 1
                )
                db.add(db_item)
                item_cost = db_item.amount * db_item.quantity
                total_added += item_cost
                added_items_str_list.append(f"{db_item.note} (x{db_item.quantity}): Rp {db_item.amount}")
                
            last_tx.amount += total_added
            additional_notes = ", ".join(item.get("note") for item in items_data)
            last_tx.note = f"{last_tx.note}, {additional_notes}"
            
            db.commit()
            db.refresh(last_tx)
            
            current_logs.append(f"[Entry Agent] Ditambahkan item baru. Total transaksi diupdate menjadi Rp {last_tx.amount}.")
            added_items_str = ", ".join(added_items_str_list)
            if llm:
                prompt = (
                    f"Pertanyaan/Perintah Pengguna: '{last_message}'\n"
                    f"Aksi Database: Berhasil menambahkan item: [{added_items_str}] senilai total tambahan Rp {total_added} ke transaksi '{last_tx.note}' (ID: {last_tx.id}). Total nominal baru transaksi sekarang adalah Rp {last_tx.amount}.\n\n"
                    f"Tugas Anda: Beritahu pengguna dengan ramah, santai, dan alami dalam bahasa Indonesia bahwa item belanjaan tambahan tersebut sudah berhasil ditambahkan ke transaksi terakhir mereka."
                )
                llm_response = llm.invoke(prompt)
                response_msg = llm_response.content
            else:
                response_msg = f"Berhasil menambahkan [{added_items_str}] ke transaksi terakhir. Total transaksi sekarang: Rp {last_tx.amount}."
        except Exception as e:
            db.rollback()
            current_logs.append(f"[Entry Agent] Error saat menambahkan item ke DB: {e}")
            response_msg = f"Gagal menambahkan item ke transaksi terakhir: {e}"
        finally:
            db.close()

    elif intent == "MODIFY_LAST":
        items_data = extracted_data.get("items") or []
        current_logs.append("[Context Agent] Mencari transaksi terakhir pengguna untuk direvisi...")
        db = SessionLocal()
        try:
            last_tx = db.query(Transaction)\
                .filter(Transaction.user_id == user_id)\
                .order_by(Transaction.created_at.desc())\
                .first()
            if not last_tx:
                current_logs.append("[Context Agent] Gagal: Tidak ada transaksi sebelumnya yang ditemukan.")
                return {"response": "Tidak ditemukan transaksi sebelumnya untuk dimodifikasi.", "logs": current_logs}
                
            current_logs.append(f"[Context Agent] Ditemukan transaksi (ID: {last_tx.id}) '{last_tx.note}' Rp {last_tx.amount}.")
            if items_data:
                new_amount = items_data[0].get("amount", 0)
                if new_amount > 0:
                    old_amount = last_tx.amount
                    last_tx.amount = new_amount
                    
                    if last_tx.items:
                        last_tx.items[0].amount = new_amount
                        
                    db.commit()
                    db.refresh(last_tx)
                    
                    current_logs.append(f"[Entry Agent] Berhasil mengupdate nominal transaksi dari Rp {old_amount} menjadi Rp {new_amount}.")
                    if llm:
                        prompt = (
                            f"Pertanyaan/Perintah Pengguna: '{last_message}'\n"
                            f"Aksi Database: Berhasil merevisi nominal transaksi terakhir '{last_tx.note}' dari Rp {old_amount} menjadi Rp {new_amount}.\n\n"
                            f"Tugas Anda: Beritahu pengguna dengan ramah dan alami dalam bahasa Indonesia bahwa perubahan nominal transaksi terakhir tersebut sudah berhasil disimpan."
                        )
                        llm_response = llm.invoke(prompt)
                        response_msg = llm_response.content
                    else:
                        response_msg = f"Berhasil mengubah nominal transaksi terakhir menjadi Rp {new_amount}."
                else:
                    current_logs.append("[Entry Agent] Gagal merevisi: nominal harga baru 0 atau kurang.")
                    response_msg = "Maaf, nominal harga baru tidak valid atau tidak terbaca."
            else:
                current_logs.append("[Entry Agent] Gagal merevisi: data revisi kosong.")
                response_msg = "Maaf, tidak menemukan informasi nominal revisi baru."
        except Exception as e:
            db.rollback()
            current_logs.append(f"[Entry Agent] Error modifikasi database: {e}")
            response_msg = f"Gagal memodifikasi transaksi terakhir: {e}"
        finally:
            db.close()
            
    elif intent == "UNDO":
        current_logs.append("[Context Agent] Mencari transaksi terakhir pengguna untuk dihapus...")
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
                
                current_logs.append(f"[Entry Agent] Berhasil menghapus transaksi ID: {last_tx.id} ('{note_to_del}') sebesar Rp {amount_to_del}.")
                response_msg = f"Berhasil membatalkan (menghapus) transaksi {type_to_del} terakhir untuk '{note_to_del}' sebesar Rp {amount_to_del}."
                if llm:
                    prompt = (
                        f"Pertanyaan/Perintah Pengguna: '{last_message}'\n"
                        f"Aksi Database: Berhasil membatalkan/menghapus transaksi {type_to_del} terakhir untuk '{note_to_del}' sebesar Rp {amount_to_del}.\n\n"
                        f"Tugas Anda: Beritahu pengguna dengan ramah, santai, dan alami dalam bahasa Indonesia bahwa transaksi tersebut sudah berhasil dibatalkan."
                    )
                    llm_response = llm.invoke(prompt)
                    response_msg = llm_response.content
            else:
                current_logs.append("[Context Agent] Gagal: Tidak ada transaksi terakhir ditemukan untuk dibatalkan.")
                response_msg = "Tidak ditemukan transaksi terakhir untuk dibatalkan."
                if llm:
                    prompt = (
                        f"Pertanyaan/Perintah Pengguna: '{last_message}'\n"
                        f"Aksi Database: Tidak ada transaksi terakhir yang ditemukan untuk dibatalkan.\n\n"
                        f"Tugas Anda: Beritahu pengguna secara ramah dan sopan dalam bahasa Indonesia bahwa tidak ada transaksi terakhir yang ditemukan untuk dibatalkan."
                    )
                    llm_response = llm.invoke(prompt)
                    response_msg = llm_response.content
        except Exception as e:
            db.rollback()
            current_logs.append(f"[Entry Agent] Error database undo: {e}")
            response_msg = f"Gagal membatalkan transaksi: {e}"
        finally:
            db.close()
            
    elif intent == "QUERY":
        sql_query = extracted_data.get("sql_query")
        if not sql_query:
            current_logs.append("[Analyst Agent] Gagal: SQL query tidak dihasilkan oleh model.")
            return {"response": "Maaf, saya tidak dapat memahami query untuk pertanyaan Anda.", "logs": current_logs}
            
        normalized_sql = sql_query.strip().upper()
        if not normalized_sql.startswith("SELECT"):
            current_logs.append("[Analyst Agent] Keamanan terpicu: Query tidak diawali dengan SELECT.")
            return {"response": "Akses ditolak: Hanya query SELECT membaca data yang diizinkan.", "logs": current_logs}
            
        # Clean function calls like EXTRACT(... FROM ...) to avoid false positive table matches
        check_query = re.sub(r'\b\w+\s*\([^)]*?FROM[^)]*?\)', '', sql_query, flags=re.IGNORECASE)
            
        allowed_tables = ["transactions", "transaction_items"]
        table_matches = re.findall(r'\bFROM\s+([\w\.]+)\b|\bJOIN\s+([\w\.]+)\b', check_query, re.IGNORECASE)
        for match in table_matches:
            raw_table = (match[0] or match[1] or '').lower()
            if '.' in raw_table:
                raw_table = raw_table.split('.')[-1]
            if raw_table and raw_table not in allowed_tables:
                current_logs.append(f"[Analyst Agent] Keamanan terpicu: Mencoba mengakses tabel terlarang '{raw_table}'.")
                return {"response": f"Akses ditolak: Tidak diizinkan mengakses tabel '{raw_table}'.", "logs": current_logs}
                
        blocked_keywords = ["DELETE", "DROP", "UPDATE", "INSERT", "ALTER", "CREATE", "TRUNCATE", "REPLACE"]
        for blocked in blocked_keywords:
            if re.search(r'\b' + blocked + r'\b', normalized_sql):
                current_logs.append(f"[Analyst Agent] Keamanan terpicu: Query mengandung keyword destruktif '{blocked}'.")
                return {"response": f"Akses ditolak: Query mengandung perintah terlarang '{blocked}'.", "logs": current_logs}
                
        current_logs.append(f"[Analyst Agent] Query tervalidasi aman. Mengeksekusi SQL: \"{sql_query}\".")
        db = SessionLocal()
        try:
            from sqlalchemy import text
            result = db.execute(text(sql_query), {"user_id": user_id})
            rows = result.fetchall()
            columns = result.keys()
            
            formatted_results = []
            for row in rows:
                formatted_results.append(dict(zip(columns, row)))
                
            current_logs.append(f"[Analyst Agent] Kueri berhasil dieksekusi, mendapatkan {len(formatted_results)} baris hasil.")
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
            current_logs.append(f"[Analyst Agent] Gagal mengeksekusi SQL query: {e}")
            response_msg = f"Gagal mengambil data dari database: {e}"
        finally:
            db.close()
    else:
        current_logs.append("[Conversation Agent] Menjawab pesan obrolan umum/sapaan pengguna.")
        response_msg = "Halo! Ada yang bisa saya bantu dengan keuangan Anda?"
        if llm:
            prompt = (
                f"Pesan Pengguna: '{last_message}'\n\n"
                f"Tugas Anda: Jawab pesan pengguna secara alami, ramah, santai, dan ringkas dalam bahasa Indonesia untuk membantunya mengelola keuangan. "
                f"Jika pesan pengguna tidak jelas nominal transaksinya, ingatkan mereka secara sopan untuk memberikan nominal agar bisa dicatat."
            )
            llm_response = llm.invoke(prompt)
            response_msg = llm_response.content
        
    return {"response": response_msg, "logs": current_logs}

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
