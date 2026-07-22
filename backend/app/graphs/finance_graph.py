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

# Helper 1: Indonesian Slang Currency Normalizer (1,5jt, 50k, 1 juta 250 ribu, setengah juta, dll.)
def normalize_indonesian_amount(val_or_str: Any) -> int:
    if isinstance(val_or_str, (int, float)):
        return int(val_or_str)
    if not val_or_str:
        return 0
        
    s = str(val_or_str).lower().strip()
    s = s.replace("rp", "").replace(".", "").replace(",", ".").strip()
    
    if "setengah juta" in s or "0.5 juta" in s or "0,5 juta" in s:
        return 500000
    if s in ["sejuta", "1 juta"]:
        return 1000000
    if s in ["seribu", "1 ribu", "1rb"]:
        return 1000

    total_val = 0
    m_juta = re.search(r'(\d+(?:\.\d+)?)\s*(?:jt|juta)', s)
    if m_juta:
        total_val += int(float(m_juta.group(1)) * 1000000)
        s = s.replace(m_juta.group(0), '')
        
    m_ribu = re.search(r'(\d+(?:\.\d+)?)\s*(?:k|rb|ribu|rebu)', s)
    if m_ribu:
        total_val += int(float(m_ribu.group(1)) * 1000)
        s = s.replace(m_ribu.group(0), '')
        
    m_ratus = re.search(r'(\d+(?:\.\d+)?)\s*(?:ratus)', s)
    if m_ratus:
        total_val += int(float(m_ratus.group(1)) * 100)
        s = s.replace(m_ratus.group(0), '')
        
    m_rem = re.search(r'\b(\d+)\b', s)
    if m_rem and total_val == 0:
        total_val += int(m_rem.group(1))
    elif m_rem and total_val > 0:
        rem_digit = int(m_rem.group(1))
        if rem_digit < 1000:
            total_val += rem_digit

    if total_val > 0:
        return total_val
        
    try:
        clean_num = re.sub(r'[^\d]', '', str(val_or_str))
        if clean_num:
            return int(clean_num)
    except Exception:
        pass
    return 0

# Helper 2: Relative & Retroactive Past Date Parser
def parse_retroactive_date(msg_text: str):
    import datetime
    now = datetime.datetime.now()
    msg_lower = msg_text.lower()
    
    if "kemarin lusa" in msg_lower or "2 hari lalu" in msg_lower:
        return now - datetime.timedelta(days=2)
    elif "kemarin" in msg_lower or "1 hari lalu" in msg_lower:
        return now - datetime.timedelta(days=1)
    elif "3 hari lalu" in msg_lower:
        return now - datetime.timedelta(days=3)
    elif "seminggu lalu" in msg_lower or "1 minggu lalu" in msg_lower:
        return now - datetime.timedelta(days=7)
        
    return now

# Define Pydantic Schema for extraction
class TransactionItemExtraction(BaseModel):
    note: str = Field(description="Nama barang atau catatan item spesifik. Contoh: 'bakso', 'es teh'.")
    amount: Optional[Any] = Field(default=0, description="Nominal harga untuk item ini (bisa angka atau teks slang seperti '15k', '1.5jt').")
    quantity: int = Field(default=1, description="Jumlah item yang dibeli.")
    item_type: Optional[str] = Field(default="OUT", description="Tipe item ini: 'OUT' untuk pengeluaran, 'IN' untuk pemasukan/gaji.")

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

# Initialize LLM Models with Tiered Routing / Fallback
# Primary: llama-3.1-8b-instant (Super Cepat & Limit 14.400 RPD)
# Backup 1: llama-3.3-70b-versatile (Smart Reasoning & Limit 1.000 RPD)
# Backup 2: mixtral-8x7b-32768 (High Throughput & Limit 14.400 RPD)
GROQ_MODELS = [
    "llama-3.1-8b-instant",
    "llama-3.3-70b-versatile",
    "mixtral-8x7b-32768"
]

def invoke_llm_with_fallback(chat_history: list, pydantic_schema: Any, logs_list: list) -> Optional[Any]:
    if not settings.GROQ_API_KEY:
        return None
        
    for model_name in GROQ_MODELS:
        try:
            model_llm = ChatGroq(
                model=model_name,
                api_key=settings.GROQ_API_KEY,
                temperature=0.0
            ).with_structured_output(pydantic_schema)
            
            result = model_llm.invoke(chat_history)
            logs_list.append(f"[Orchestrator] Diproses menggunakan model LLM Groq: '{model_name}'.")
            return result
        except Exception as e:
            logging.warning(f"Groq LLM model '{model_name}' failed/limited: {e}. Trying next fallback model...")
            logs_list.append(f"[LLM Warning] Model '{model_name}' limit/error ({e}). Mengalihkan ke model cadangan...")
            continue
            
    return None

def _build_default_sql_query(msg_text: str) -> str:
    msg_lower = msg_text.lower()
    tx_type = "IN" if "pemasukan" in msg_lower else "OUT"
    
    if "hari ini" in msg_lower:
        time_clause = "t.created_at::date = CURRENT_DATE"
    elif "minggu ini" in msg_lower or "mingguan" in msg_lower:
        time_clause = "t.created_at >= DATE_TRUNC('week', CURRENT_DATE)"
    else:
        time_clause = "t.created_at >= DATE_TRUNC('month', CURRENT_DATE)"

    return (
        f"SELECT COALESCE(ti.note, t.note) AS item, "
        f"COALESCE(ti.quantity, 1) AS jumlah, "
        f"COALESCE(ti.amount, t.amount) AS harga_satuan, "
        f"(COALESCE(ti.amount, t.amount) * COALESCE(ti.quantity, 1)) AS total_harga, "
        f"t.category AS kategori, "
        f"t.created_at::date AS tanggal "
        f"FROM transactions t "
        f"LEFT JOIN transaction_items ti ON t.id = ti.transaction_id "
        f"WHERE t.user_id = :user_id AND t.type = '{tx_type}' AND {time_clause} "
        f"ORDER BY t.created_at DESC"
    )

# 1. Detect Intent Node
def detect_intent_node(state: AgentState) -> Dict[str, Any]:
    last_message = state["messages"][-1]["content"] if state["messages"] else ""
    import datetime
    current_time_str = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    logs = []
    
    chat_history = [
        SystemMessage(content=(
            "Anda adalah asisten keuangan pribadi cerdas bernama Dompetku AI yang melayani pengguna bagaikan JARVIS.\n"
            "PENTING / PERATURAN PERSONA SIR:\n"
            "1. Selalu panggil pengguna dengan sebutan 'Sir'.\n"
            "2. Selalu akhiri setiap respon atau pertanyaan Anda dengan kata ', Sir.' atau ', Sir?' (Contoh: 'Berhasil mencatat pengeluaran Anda, Sir.' atau 'Berapa harga baksonya, Sir?').\n\n"
            f"Waktu Sekarang: {current_time_str} (PENTING: Gunakan ini sebagai acuan tahun/tanggal saat ini saat menganalisis kueri waktu pengguna seperti 'bulan juni', 'minggu lalu', dsb. Selalu asumsikan tahun saat ini sesuai tahun sekarang kecuali pengguna menyebutkan tahun lain secara spesifik).\n"
            "Tugas Anda adalah mendeteksi intent pengguna dan mengekstrak informasi detail item transaksi atau menghasilkan query database.\n"
            "Pahami konteks percakapan sebelumnya untuk kalimat rujukan atau kalimat lanjutan (follow-up) dari pengguna.\n"
            "PILIHAN INTENT:\n"
            "- 'ADD_EXPENSE': untuk pencatatan pengeluaran baru.\n"
            "- 'ADD_INCOME': untuk pencatatan pemasukan baru.\n"
            "- 'UNDO': untuk membatalkan/menghapus transaksi terakhir yang baru saja dicatat.\n"
            "- 'QUERY': untuk menanyakan/menganalisis riwayat transaksi keuangan mereka sendiri (misal: 'berapa pengeluaran hari ini', 'pengeluaran bulan ini', total belanja, pengeluaran kategori tertentu, list belanja terbesar, dll).\n"
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
            "Query HANYA boleh mengakses tabel 'transactions' (t) dan 'transaction_items' (ti).\n"
            "Kolom tabel 'transactions' adalah: id, user_id, amount, note, type ('IN'/'OUT'), category, payment_method, created_at.\n"
            "Kolom tabel 'transaction_items' adalah: id, transaction_id, note, amount, quantity.\n"
            "PENTING: Selalu masukkan filter `t.user_id = :user_id` di klausa WHERE agar data aman dan terisolasi.\n"
            "PENTING / DILARANG KERAS: DILARANG MENGGUNAKAN FUNGSI `SUM()` atau `GROUP BY` jika pengguna menanyakan 'apa saja', 'daftar', 'rincian', 'riwayat', 'pengeluaran bulan ini', 'transaksi hari ini', atau 'list belanja'. HANYA gunakan `SUM()` JIKA DAN HANYA JIKA pengguna secara eksplisit meminta 'berapa total...'.\n"
            "PENTING: Jika pengguna meminta daftar/rincian transaksi (misal: 'pengeluaran bulan ini', 'transaksi hari ini', 'list belanja minggu ini', 'apa saja pengeluaran saya'):\n"
            "  - Gunakan LEFT JOIN antara `transactions t` dan `transaction_items ti ON t.id = ti.transaction_id`.\n"
            "  - Pilih kolom dengan alias yang jelas: `COALESCE(ti.note, t.note) AS item`, `COALESCE(ti.quantity, 1) AS jumlah`, `COALESCE(ti.amount, t.amount) AS harga_satuan`, `(COALESCE(ti.amount, t.amount) * COALESCE(ti.quantity, 1)) AS total_harga`, `t.category AS kategori`, `t.created_at::date AS tanggal`.\n"
            "  - DILARANG MENGGUNAKAN `SUM()` di sini! Pilih setiap baris transaksi secara individual agar tabel di UI menampilkan daftar item secara rinci.\n"
            "PENTING: Untuk filter waktu/tanggal, gunakan PostgreSQL date functions berikut agar sangat akurat:\n"
            "  - Harian (hari ini): `t.created_at::date = CURRENT_DATE`\n"
            "  - Mingguan (minggu ini): `t.created_at >= DATE_TRUNC('week', CURRENT_DATE)`\n"
            "  - Bulanan (bulan ini): `t.created_at >= DATE_TRUNC('month', CURRENT_DATE)`\n"
            "  - PENTING: Jika membandingkan created_at dengan string tanggal statis (misal '2024-06-01'), Anda HARUS melakukan type cast secara eksplisit seperti `'2024-06-01'::timestamp` atau `'2024-06-01'::date` (misal: `DATE_TRUNC('month', '2024-06-01'::timestamp)`), karena tanpa cast PostgreSQL akan menghasilkan error 'date_trunc(unknown, unknown) is not unique'.\n"
            "  - Pastikan filter pengeluaran menggunakan `t.type = 'OUT'` dan pemasukan menggunakan `t.type = 'IN'`.\n"
            "Contoh jika user tanya 'pengeluaran bulan ini apa saja?':\n"
            "`SELECT COALESCE(ti.note, t.note) AS item, COALESCE(ti.quantity, 1) AS jumlah, (COALESCE(ti.amount, t.amount) * COALESCE(ti.quantity, 1)) AS total_harga, t.category AS kategori, t.created_at::date AS tanggal FROM transactions t LEFT JOIN transaction_items ti ON t.id = ti.transaction_id WHERE t.user_id = :user_id AND t.type = 'OUT' AND t.created_at >= DATE_TRUNC('month', CURRENT_DATE) ORDER BY t.created_at DESC`\n\n"
            "Aturan Keyakinan (Confidence Score) & Klarifikasi:\n"
            "- Nilai 'confidence_score' harus berkisar antara 0.0 (sangat tidak yakin) hingga 1.0 (sangat yakin).\n"
            "- Jika nominal transaksi (jumlah uang) atau nama item belanja tidak disebutkan secara eksplisit atau tidak jelas, berikan 'confidence_score' di bawah 0.8, set 'is_ambiguous' menjadi true, dan buat 'clarification_question' yang menanyakan info yang kurang secara spesifik dengan akhiran ', Sir?'.\n"
            "- Contoh: jika user mengetik 'saya beli roti', nominal harganya tidak ada. Berikan confidence_score = 0.5, is_ambiguous = true, dan clarification_question = 'Berapa harga roti yang Anda beli, Sir?'\n"
            "- Jika pesan berupa sapaan, percakapan umum, atau query yang sudah jelas maksudnya, berikan confidence_score = 1.0 dan is_ambiguous = false."
        ))
    ]
    recent_messages = state["messages"][-6:] if len(state["messages"]) > 6 else state["messages"]
    for msg in recent_messages:
        if msg["role"] == "user":
            chat_history.append(HumanMessage(content=msg["content"]))
        else:
            chat_history.append(AIMessage(content=msg["content"]))

    extracted = invoke_llm_with_fallback(chat_history, TransactionExtraction, logs)
    if extracted:
        items_list = []
        for item in (extracted.items or []):
            items_list.append({
                "note": item.note,
                "amount": item.amount if item.amount is not None else 0,
                "quantity": item.quantity
            })
        conf_val = extracted.confidence_score if extracted.confidence_score is not None else 1.0

        intent = extracted.intent
        sql_q = extracted.sql_query
        msg_lower = last_message.lower()

        # Override intent to QUERY if user message is asking for financial history/totals
        query_kws = ["berapa", "pengeluaran", "pemasukan", "total", "riwayat", "daftar", "rincian", "list"]
        if any(kw in msg_lower for kw in query_kws) and not any(kw in msg_lower for kw in ["beli", "bayar", "terima", "gaji"]):
            intent = "QUERY"

        if intent == "QUERY" and (not sql_q or "SELECT" not in sql_q.upper()):
            sql_q = _build_default_sql_query(last_message)

        logs.append(f"[Orchestrator] Menganalisis input: \"{last_message}\". Mendeteksi intent: '{intent}' (Confidence: {int(conf_val * 100)}%).")
        return {
            "intent": intent,
            "extracted_data": {
                "category": extracted.category or "Other",
                "payment_method": extracted.payment_method or "tunai",
                "type": extracted.type or ("OUT" if intent == "ADD_EXPENSE" else "IN"),
                "items": items_list,
                "sql_query": sql_q,
                "confidence_score": conf_val,
                "is_ambiguous": extracted.is_ambiguous if extracted.is_ambiguous is not None else False,
                "clarification_question": extracted.clarification_question
            },
            "logs": logs
        }
            
    # Rule-based fallback (Lokal tanpa LLM)
    logs.append("[Orchestrator Fallback] Menjalankan rule-based parsing lokal.")
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
        note_words = []
        for word in words:
            if word.isdigit():
                amount = int(word)
            elif word.lower() not in ["saya", "beli", "bayar", "untuk", "dan"]:
                note_words.append(word)
        note = " ".join(note_words) if note_words else "belanja"
        extracted_data = {
            "category": "Other",
            "payment_method": "tunai",
            "type": "OUT",
            "items": [{"note": note, "amount": amount, "quantity": 1}],
            "confidence_score": 1.0 if amount > 0 else 0.5,
            "is_ambiguous": False if amount > 0 else True,
            "clarification_question": None if amount > 0 else "Berapa nominal belanja pengeluaran Anda, Sir?"
        }
    elif "terima" in last_message.lower() or "gaji" in last_message.lower():
        intent = "ADD_INCOME"
        words = last_message.split()
        amount = 0
        note_words = []
        for word in words:
            if word.isdigit():
                amount = int(word)
            elif word.lower() not in ["saya", "terima", "gaji", "dari"]:
                note_words.append(word)
        note = " ".join(note_words) if note_words else "pendapatan"
        extracted_data = {
            "category": "Salary",
            "payment_method": "tunai",
            "type": "IN",
            "items": [{"note": note, "amount": amount, "quantity": 1}],
            "confidence_score": 1.0 if amount > 0 else 0.5,
            "is_ambiguous": False if amount > 0 else True,
            "clarification_question": None if amount > 0 else "Berapa nominal pemasukan Anda, Sir?"
        }
    elif any(kw in last_message.lower() for kw in ["pengeluaran", "pemasukan", "total", "riwayat", "daftar", "rincian", "list", "berapa", "transaksi"]):
        intent = "QUERY"
        sql_q = _build_default_sql_query(last_message)
        extracted_data = {
            "category": "Other",
            "payment_method": "tunai",
            "type": "OUT",
            "items": [],
            "sql_query": sql_q,
            "confidence_score": 1.0,
            "is_ambiguous": False,
            "clarification_question": None
        }
        
    conf_val = extracted_data.get("confidence_score", 1.0)
    logs.append(f"[Orchestrator (Fallback)] Menganalisis input: \"{last_message}\". Mendeteksi intent: '{intent}' (Confidence: {int(conf_val * 100)}%).")
    return {
        "intent": intent,
        "extracted_data": extracted_data,
        "logs": logs
    }

def _ensure_sir_suffix(text: str) -> str:
    if not text:
        return "Baik, Sir."
    text = text.strip()
    if re.search(r'\bSir[\.\?\!\s]*$', text, re.IGNORECASE):
        return text
    clean_text = text.rstrip('.!? ')
    return f"{clean_text}, Sir."

# 2. Tool Executor Node
def tool_executor_node(state: AgentState) -> Dict[str, Any]:
    res = _internal_tool_executor(state)
    if "response" in res and res["response"]:
        res["response"] = _ensure_sir_suffix(res["response"])
    return res

def _internal_tool_executor(state: AgentState) -> Dict[str, Any]:
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
            
        # 1. Normalize slang amounts (1,5jt, 50k, 50rb, setengah juta, dll.)
        for item in items_data:
            item["amount"] = normalize_indonesian_amount(item.get("amount"))

        # 2. Check for partial missing amounts in multi-item input (e.g. "Beli bakso 15rb, es teh, kerupuk")
        missing_amount_items = [item.get("note", "item") for item in items_data if item.get("amount", 0) <= 0]
        if missing_amount_items:
            missing_str = ", ".join(missing_amount_items)
            current_logs.append(f"[Entry Agent] Terdeteksi item tanpa harga: [{missing_str}]. Mengirimkan pertanyaan klarifikasi.")
            return {
                "response": f"Berapa nominal harga untuk **{missing_str}** yang Anda beli?",
                "logs": current_logs,
                "extracted_data": extracted_data
            }

        total_amount = sum(item.get("amount", 0) * item.get("quantity", 1) for item in items_data)
        if total_amount <= 0:
            current_logs.append("[Entry Agent] Gagal memproses: nominal belanja nol.")
            return {"response": "Maaf, saya tidak dapat mencatat transaksi jika nominalnya kosong atau nol. Silakan sebutkan jumlah uangnya secara jelas.", "logs": current_logs}
            
        # 3. Parse relative retroactive date (kemarin, kemarin lusa, 2 hari lalu, dsb.)
        tx_created_at = parse_retroactive_date(last_message)

        # Create summary note for parent Transaction
        note_summary = ", ".join(f"{item.get('note')}" for item in items_data)
        category = extracted_data.get("category") or "Other"
        pm = extracted_data.get("payment_method") or "tunai"
        tx_type = "OUT" if intent == "ADD_EXPENSE" else "IN"
        
        current_logs.append(f"[Entry Agent] Membuka koneksi database untuk merekam transaksi {tx_type.lower()} sebesar Rp {total_amount} (Tanggal: {tx_created_at.strftime('%Y-%m-%d')}).")
        # Save to DB with retroactive created_at
        db = SessionLocal()
        try:
            tx = Transaction(
                user_id=user_id,
                note=note_summary,
                amount=total_amount,
                category=category,
                type=tx_type,
                payment_method=pm,
                created_at=tx_created_at
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
            response_msg = f"Berhasil mencatat {tx_type.lower()} untuk detail: [{items_str}] dengan total Rp {tx.amount} ({tx.payment_method}). (Confidence: {confidence_pct}%)"
            if settings.GROQ_API_KEY:
                for model_name in GROQ_MODELS:
                    try:
                        chat_llm = ChatGroq(model=model_name, api_key=settings.GROQ_API_KEY, temperature=0.3)
                        prompt = (
                            f"Pertanyaan/Perintah Pengguna: '{last_message}'\n"
                            f"Aksi Database: Berhasil mencatat transaksi {tx_type.lower()} (pemasukan/pengeluaran) senilai Rp {tx.amount} dengan metode pembayaran {tx.payment_method}. Detail item: {items_str}.\n\n"
                            f"Tugas Anda: Beritahu pengguna dengan ramah, santai, dan alami dalam bahasa Indonesia bahwa transaksinya sudah berhasil dicatat. PENTING: Panggil 'Sir' dan akhiri dengan ', Sir.'."
                        )
                        llm_response = chat_llm.invoke(prompt)
                        response_msg = f"{llm_response.content} (Confidence: {confidence_pct}%)"
                        break
                    except Exception as e:
                        logging.warning(f"Groq model '{model_name}' failed in response gen: {e}")
                        continue
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
            response_msg = f"Berhasil menambahkan [{added_items_str}] ke transaksi terakhir. Total transaksi sekarang: Rp {last_tx.amount}."
            if settings.GROQ_API_KEY:
                for model_name in GROQ_MODELS:
                    try:
                        chat_llm = ChatGroq(model=model_name, api_key=settings.GROQ_API_KEY, temperature=0.3)
                        prompt = (
                            f"Pertanyaan/Perintah Pengguna: '{last_message}'\n"
                            f"Aksi Database: Berhasil menambahkan item: [{added_items_str}] senilai total tambahan Rp {total_added} ke transaksi '{last_tx.note}' (ID: {last_tx.id}). Total nominal baru transaksi sekarang adalah Rp {last_tx.amount}.\n\n"
                            f"Tugas Anda: Beritahu pengguna dengan ramah, santai, dan alami dalam bahasa Indonesia bahwa item belanjaan tambahan tersebut sudah berhasil ditambahkan ke transaksi terakhir mereka. PENTING: Panggil 'Sir' dan akhiri dengan ', Sir.'."
                        )
                        llm_response = chat_llm.invoke(prompt)
                        response_msg = llm_response.content
                        break
                    except Exception as e:
                        logging.warning(f"Groq model '{model_name}' failed in APPEND_ITEM gen: {e}")
                        continue
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
                    response_msg = f"Berhasil mengubah nominal transaksi terakhir menjadi Rp {new_amount}."
                    if settings.GROQ_API_KEY:
                        for model_name in GROQ_MODELS:
                            try:
                                chat_llm = ChatGroq(model=model_name, api_key=settings.GROQ_API_KEY, temperature=0.3)
                                prompt = (
                                    f"Pertanyaan/Perintah Pengguna: '{last_message}'\n"
                                    f"Aksi Database: Berhasil merevisi nominal transaksi terakhir '{last_tx.note}' dari Rp {old_amount} menjadi Rp {new_amount}.\n\n"
                                    f"Tugas Anda: Beritahu pengguna dengan ramah dan alami dalam bahasa Indonesia bahwa perubahan nominal transaksi terakhir tersebut sudah berhasil disimpan. PENTING: Panggil 'Sir' dan akhiri dengan ', Sir.'."
                                )
                                llm_response = chat_llm.invoke(prompt)
                                response_msg = llm_response.content
                                break
                            except Exception as e:
                                logging.warning(f"Groq model '{model_name}' failed in MODIFY_LAST gen: {e}")
                                continue
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
                if settings.GROQ_API_KEY:
                    for model_name in GROQ_MODELS:
                        try:
                            chat_llm = ChatGroq(model=model_name, api_key=settings.GROQ_API_KEY, temperature=0.3)
                            prompt = (
                                f"Pertanyaan/Perintah Pengguna: '{last_message}'\n"
                                f"Aksi Database: Berhasil membatalkan/menghapus transaksi {type_to_del} terakhir untuk '{note_to_del}' sebesar Rp {amount_to_del}.\n\n"
                                f"Tugas Anda: Beritahu pengguna dengan ramah, santai, dan alami dalam bahasa Indonesia bahwa transaksi tersebut sudah berhasil dibatalkan. PENTING: Panggil 'Sir' dan akhiri dengan ', Sir.'."
                            )
                            llm_response = chat_llm.invoke(prompt)
                            response_msg = llm_response.content
                            break
                        except Exception as e:
                            logging.warning(f"Groq model '{model_name}' failed in UNDO gen: {e}")
                            continue
            else:
                current_logs.append("[Context Agent] Gagal: Tidak ada transaksi terakhir ditemukan untuk dibatalkan.")
                response_msg = "Tidak ditemukan transaksi terakhir untuk dibatalkan."
        except Exception as e:
            db.rollback()
            current_logs.append(f"[Entry Agent] Error database undo: {e}")
            response_msg = f"Gagal membatalkan transaksi: {e}"
        finally:
            db.close()
            
    elif intent == "QUERY":
        # Check if user message lacks explicit time specification (e.g., "pengeluaran saya banyak gak?")
        time_kws = ["hari ini", "minggu ini", "bulan ini", "bulan", "minggu", "hari", "tahun", "kemarin", "tgl", "tanggal", "januari", "februari", "maret", "april", "mei", "juni", "juli", "agustus", "september", "oktober", "november", "desember"]
        has_time_spec = any(kw in last_message.lower() for kw in time_kws)

        if not has_time_spec and (extracted_data.get("is_ambiguous") or not extracted_data.get("clarification_question")):
            extracted_data["is_ambiguous"] = True
            extracted_data["clarification_question"] = "Apakah Anda ingin melihat analisis pengeluaran untuk **hari ini**, **minggu ini**, atau **bulan ini**, Sir?"

        if extracted_data.get("is_ambiguous") and extracted_data.get("clarification_question"):
            clarification_msg = extracted_data["clarification_question"]
            current_logs.append(f"[Analyst Agent] Kueri ambigu (tanpa rentang waktu). Mengirimkan pertanyaan klarifikasi: \"{clarification_msg}\".")
            return {"response": clarification_msg, "logs": current_logs, "extracted_data": extracted_data}

        sql_query = extracted_data.get("sql_query")
        if not sql_query:
            current_logs.append("[Analyst Agent] Gagal: SQL query tidak dihasilkan oleh model.")
            return {"response": "Maaf, saya tidak dapat memahami query untuk pertanyaan Anda.", "logs": current_logs}
            
        normalized_sql = sql_query.strip().upper()
        if not normalized_sql.startswith("SELECT"):
            current_logs.append("[Analyst Agent] Keamanan terpicu: Query tidak diawali dengan SELECT.")
            return {"response": "Akses ditolak: Hanya query SELECT membaca data yang diizinkan.", "logs": current_logs}

        # Guardrail: Prevent SUM() hallucination when user asked for itemized breakdown/list
        msg_lower = last_message.lower()
        is_list_request = any(kw in msg_lower for kw in ["apa", "list", "daftar", "rincian", "detail", "bulan ini", "minggu ini", "hari ini", "terakhir"])
        is_explicit_total = any(kw in msg_lower for kw in ["berapa total", "jumlah total", "total pengeluaran", "total pemasukan"])

        if "SUM(" in normalized_sql and is_list_request and not is_explicit_total:
            current_logs.append("[Analyst Agent] Guardrail terpicu: Mencegah halusinasi SUM() pada permintaan rincian. Mengubah query ke rincian item individual.")
            
            time_clause = ""
            if "MONTH" in normalized_sql or "bulan ini" in msg_lower:
                time_clause = "AND t.created_at >= DATE_TRUNC('month', CURRENT_DATE)"
            elif "WEEK" in normalized_sql or "minggu ini" in msg_lower:
                time_clause = "AND t.created_at >= DATE_TRUNC('week', CURRENT_DATE)"
            elif "CURRENT_DATE" in normalized_sql or "hari ini" in msg_lower:
                time_clause = "AND t.created_at::date = CURRENT_DATE"

            type_clause = "AND t.type = 'OUT'"
            if "type = 'in'" in sql_query.lower() or "pemasukan" in msg_lower:
                type_clause = "AND t.type = 'IN'"

            sql_query = (
                f"SELECT COALESCE(ti.note, t.note) AS item, "
                f"COALESCE(ti.quantity, 1) AS jumlah, "
                f"COALESCE(ti.amount, t.amount) AS harga_satuan, "
                f"(COALESCE(ti.amount, t.amount) * COALESCE(ti.quantity, 1)) AS total_harga, "
                f"t.category AS kategori, "
                f"t.created_at::date AS tanggal "
                f"FROM transactions t "
                f"LEFT JOIN transaction_items ti ON t.id = ti.transaction_id "
                f"WHERE t.user_id = :user_id {type_clause} {time_clause} "
                f"ORDER BY t.created_at DESC"
            )
            normalized_sql = sql_query.strip().upper()
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
            columns = list(result.keys())
            
            formatted_results = []
            for row in rows:
                formatted_results.append(dict(zip(columns, row)))
                
            current_logs.append(f"[Analyst Agent] Kueri berhasil dieksekusi, mendapatkan {len(formatted_results)} baris hasil.")
            
            # Attach query_result payload so frontend gets rows, columns, and sql_query
            query_result_payload = {
                "columns": columns,
                "rows": formatted_results,
                "sql_query": sql_query
            }
            extracted_data["query_result"] = query_result_payload
            # Calculate exact total sum in Python to prevent LLM calculation errors
            calculated_total_sum = 0
            for r in formatted_results:
                row_amt = r.get("total_harga") or r.get("total_amount") or r.get("amount") or r.get("total")
                if row_amt is None and "harga_satuan" in r:
                    price = r.get("harga_satuan") or 0
                    qty = r.get("jumlah") or r.get("quantity") or 1
                    row_amt = price * qty
                if isinstance(row_amt, (int, float)):
                    calculated_total_sum += int(row_amt)

            formatted_total_str = f"Rp {calculated_total_sum:,}".replace(',', '.')

            if not formatted_results:
                response_msg = "Tidak ditemukan data transaksi yang sesuai dengan pertanyaan Anda."
            else:
                total_count = len(formatted_results)
                # Extract ONLY essential item names as clean simple strings (max 4)
                sample_item_names = [
                    str(r.get("item") or r.get("note") or "Item").strip()
                    for r in formatted_results[:4]
                    if (r.get("item") or r.get("note"))
                ]
                sample_names_str = ", ".join(sample_item_names) if sample_item_names else "transaksi harian"

                response_msg = f"Pengeluaran Anda berdasarkan {total_count} data transaksi yang ditemukan mencapai total {formatted_total_str}."
                if settings.GROQ_API_KEY:
                    for model_name in GROQ_MODELS:
                        try:
                            chat_llm = ChatGroq(model=model_name, api_key=settings.GROQ_API_KEY, temperature=0.3)
                            prompt = (
                                f"Pertanyaan Pengguna: '{last_message}'\n"
                                f"Jumlah Transaksi: {total_count} entri\n"
                                f"Total Nominal Keseluruhan: {formatted_total_str}\n"
                                f"Contoh Item: {sample_names_str}\n\n"
                                f"Tugas Anda: Jawab pertanyaan pengguna secara ringkas, ramah, dan alami dalam bahasa Indonesia (1-2 kalimat saja).\n"
                                f"PENTING: Sebutkan secara eksplisit Total Nominal Keseluruhan ({formatted_total_str}) dalam kalimat jawaban Anda. Akhiri dengan ', Sir.'."
                            )
                            llm_response = chat_llm.invoke(prompt)
                            response_msg = llm_response.content
                            break
                        except Exception as llm_err:
                            logging.warning(f"Analyst Groq model '{model_name}' failed: {llm_err}")
                            continue
        except Exception as e:
            logging.error(f"Error executing database query: {e}")
            current_logs.append(f"[Analyst Agent] Gagal mengeksekusi SQL query: {e}")
            response_msg = f"Gagal mengambil data dari database: {e}"
        finally:
            db.close()
            
        return {"response": response_msg, "logs": current_logs, "extracted_data": extracted_data}
    else:
        current_logs.append("[Conversation Agent] Menjawab pesan obrolan umum/sapaan pengguna.")
        response_msg = "Halo! Ada yang bisa saya bantu dengan keuangan Anda, Sir?"
        if settings.GROQ_API_KEY:
            for model_name in GROQ_MODELS:
                try:
                    chat_llm = ChatGroq(
                        model=model_name,
                        api_key=settings.GROQ_API_KEY,
                        temperature=0.7
                    )
                    prompt = (
                        f"Pesan Pengguna: '{last_message}'\n\n"
                        f"Tugas Anda: Jawab pesan pengguna secara alami, ramah, santai, dan ringkas dalam bahasa Indonesia untuk membantunya mengelola keuangan. "
                        f"PENTING: Panggil pengguna dengan sebutan 'Sir' dan akhiri jawaban dengan ', Sir.'."
                    )
                    llm_response = chat_llm.invoke(prompt)
                    response_msg = llm_response.content
                    break
                except Exception as e:
                    logging.warning(f"General chat LLM model '{model_name}' failed: {e}")
                    continue
        
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
