from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import List, Dict, Any, Optional
import re
import logging
from app.database.session import SessionLocal
from app.models.models import Transaction, TransactionItem
from app.graphs.finance_graph import llm, TransactionExtraction, TransactionItemExtraction
from langchain_core.messages import SystemMessage, HumanMessage

router = APIRouter(prefix="/agent", tags=["Agent Simulators"])

class AgentSimulationRequest(BaseModel):
    message: str
    user_id: str = "default_user"

# --- 1. ENTRY AGENT SIMULATOR ---
class EntrySimulationResponse(BaseModel):
    extracted_data: Dict[str, Any]
    confidence_score: float
    is_ambiguous: bool
    clarification_question: Optional[str]
    logs: List[str]

@router.post("/entry", response_model=EntrySimulationResponse)
async def simulate_entry_agent(payload: AgentSimulationRequest):
    logs = ["[Entry Agent Simulator] Menerima teks masukan pencatatan."]
    last_message = payload.message
    
    if llm:
        try:
            logs.append("[Entry Agent Simulator] Menghubungi model Llama-3.3 untuk ekstraksi terstruktur...")
            chat_history = [
                SystemMessage(content=(
                    "Anda adalah Entry Agent spesialis pencatatan keuangan.\n"
                    "Ekstrak intent, category, payment_method, type, items, confidence_score, is_ambiguous, dan clarification_question.\n"
                    "Gunakan aturan: jika nominal/barang tidak jelas atau hilang, set is_ambiguous=True, confidence_score < 0.8, dan tulis clarification_question."
                )),
                HumanMessage(content=last_message)
            ]
            structured_llm = llm.with_structured_output(TransactionExtraction)
            extracted = structured_llm.invoke(chat_history)
            
            items_list = []
            for item in (extracted.items or []):
                items_list.append({
                    "note": item.note,
                    "amount": item.amount if item.amount is not None else 0,
                    "quantity": item.quantity
                })
                
            conf = extracted.confidence_score if extracted.confidence_score is not None else 1.0
            logs.append(f"[Entry Agent Simulator] Ekstraksi sukses (Confidence: {int(conf * 100)}%).")
            if extracted.is_ambiguous:
                logs.append(f"[Entry Agent Simulator] Informasi kurang lengkap! Menyiapkan klarifikasi: \"{extracted.clarification_question}\"")
            else:
                logs.append(f"[Entry Agent Simulator] Informasi lengkap. Siap disimpan ke database.")
                
            return EntrySimulationResponse(
                extracted_data={
                    "category": extracted.category or "Other",
                    "payment_method": extracted.payment_method or "tunai",
                    "type": extracted.type or "OUT",
                    "items": items_list,
                    "sql_query": extracted.sql_query
                },
                confidence_score=conf,
                is_ambiguous=extracted.is_ambiguous or False,
                clarification_question=extracted.clarification_question,
                logs=logs
            )
        except Exception as e:
            logs.append(f"[Entry Agent Simulator] Error LLM: {e}. Mengaktifkan fallback rule-based.")
    
    # Fallback
    amount = 0
    note = "belanja"
    words = last_message.split()
    for word in words:
        if word.isdigit():
            amount = int(word)
        elif word.lower() not in ["saya", "beli", "bayar", "untuk", "dan"]:
            note = word
            
    is_amb = amount <= 0
    conf = 1.0 if amount > 0 else 0.5
    clarify = None if amount > 0 else "Berapa nominal transaksi belanja Anda?"
    
    logs.append(f"[Entry Agent Simulator (Fallback)] Menjalankan regex parsing (Confidence: {int(conf * 100)}%).")
    return EntrySimulationResponse(
        extracted_data={
            "category": "Other",
            "payment_method": "tunai",
            "type": "OUT",
            "items": [{"note": note, "amount": amount, "quantity": 1}],
            "sql_query": None
        },
        confidence_score=conf,
        is_ambiguous=is_amb,
        clarification_question=clarify,
        logs=logs
    )

# --- 2. ANALYST AGENT SIMULATOR ---
class AnalystSimulationResponse(BaseModel):
    sql_query: str
    results: List[Dict[str, Any]]
    logs: List[str]

@router.post("/analyst", response_model=AnalystSimulationResponse)
async def simulate_analyst_agent(payload: AgentSimulationRequest):
    import uuid
    try:
        uuid.UUID(payload.user_id)
    except (ValueError, TypeError):
        payload.user_id = "0c732da4-39e4-45f1-8a64-984d66baadf0"

    logs = ["[Analyst Agent Simulator] Menerima kueri analisis."]
    sql_query = ""
    results = []
    
    if llm:
        try:
            logs.append("[Analyst Agent Simulator] Meminta Llama-3.3 menyusun kueri SQL SELECT PostgreSQL...")
            chat_history = [
                SystemMessage(content=(
                    "Anda adalah Database Analyst Agent.\n"
                    "Tugas Anda HANYA menghasilkan query SQL SELECT PostgreSQL yang valid untuk tabel 'transactions' (t) dan 'transaction_items' (ti).\n"
                    "Kolom tabel 'transactions' adalah: id, user_id, amount, note, type ('IN'/'OUT'), category, payment_method, created_at.\n"
                    "Gunakan parameter ':user_id' untuk memfilter kepemilikan data.\n"
                    "PENTING: Untuk filter waktu/tanggal, gunakan PostgreSQL date functions berikut agar sangat akurat:\n"
                    "  - Harian (hari ini): `created_at::date = CURRENT_DATE` atau group by `created_at::date`\n"
                    "  - Mingguan (minggu ini): `created_at >= DATE_TRUNC('week', CURRENT_DATE)` atau group by `DATE_TRUNC('week', created_at)`\n"
                    "  - Bulanan (bulan ini): `created_at >= DATE_TRUNC('month', CURRENT_DATE)` atau group by `DATE_TRUNC('month', created_at)`\n"
                    "  - PENTING: Jika membandingkan created_at dengan string tanggal statis (misal '2024-06-01'), Anda HARUS melakukan type cast secara eksplisit seperti `'2024-06-01'::timestamp` atau `'2024-06-01'::date` (misal: `DATE_TRUNC('month', '2024-06-01'::timestamp)`), karena tanpa cast PostgreSQL akan menghasilkan error 'date_trunc(unknown, unknown) is not unique'.\n"
                    "  - Pastikan filter pengeluaran menggunakan `type = 'OUT'` dan pemasukan menggunakan `type = 'IN'`.\n"
                    "Kembalikan HANYA query SELECT sql mentah di output, tanpa markdown, tanpa penjelasan."
                )),
                HumanMessage(content=payload.message)
            ]
            response = llm.invoke(chat_history)
            sql_query = response.content.replace("```sql", "").replace("```", "").strip()
            logs.append(f"[Analyst Agent Simulator] Query dihasilkan: \"{sql_query}\".")
            
            # Validation
            normalized_sql = sql_query.upper()
            if not normalized_sql.startswith("SELECT"):
                logs.append("[Analyst Agent Simulator] Validasi gagal: Query harus berupa SELECT.")
                sql_query = "SELECT 'Akses ditolak: Hanya SELECT yang diizinkan';"
            else:
                db = SessionLocal()
                try:
                    from sqlalchemy import text
                    logs.append("[Analyst Agent Simulator] Mengeksekusi SQL query di database lokal...")
                    db_result = db.execute(text(sql_query), {"user_id": payload.user_id})
                    rows = db_result.fetchall()
                    columns = db_result.keys()
                    results = [dict(zip(columns, row)) for row in rows]
                    logs.append(f"[Analyst Agent Simulator] Eksekusi berhasil. Mendapatkan {len(results)} entri.")
                except Exception as db_err:
                    logs.append(f"[Analyst Agent Simulator] Error eksekusi DB: {db_err}")
                finally:
                    db.close()
        except Exception as e:
            logs.append(f"[Analyst Agent Simulator] Error model: {e}")
            
    if not sql_query:
        sql_query = "SELECT 'LLM tidak tersedia' as info;"
        
    return AnalystSimulationResponse(
        sql_query=sql_query,
        results=results,
        logs=logs
    )

# --- 3. BUDGET AGENT SIMULATOR ---
class BudgetSimulationResponse(BaseModel):
    limit: int
    spent: int
    status: str
    tips: List[str]
    logs: List[str]

@router.get("/budget/{user_id}", response_model=BudgetSimulationResponse)
async def simulate_budget_agent(user_id: str):
    import uuid
    try:
        uuid.UUID(user_id)
    except (ValueError, TypeError):
        user_id = "0c732da4-39e4-45f1-8a64-984d66baadf0"

    logs = ["[Budget Agent Simulator] Menerima permintaan evaluasi limit anggaran."]
    db = SessionLocal()
    spent = 0
    try:
        # Calculate spending in current month
        txs = db.query(Transaction).filter(Transaction.user_id == user_id).all()
        spent = sum(t.amount for t in txs if t.type == "OUT")
        logs.append(f"[Budget Agent Simulator] Membaca total pengeluaran user dari DB: Rp {spent}.")
    except Exception as e:
        logs.append(f"[Budget Agent Simulator] Error reading DB: {e}")
    finally:
        db.close()
        
    limit = 5000000 # Mock Limit Rp 5.000.000
    pct = (spent / limit) * 100 if limit > 0 else 0
    
    if pct > 90:
        status = "BAHAYA (Overbudget)"
        tips = [
            "Batasi pengeluaran non-esensial sekarang!",
            "Tunda belanja keinginan hingga bulan depan.",
            "Gunakan metode amplop tunai untuk sisa hari ini."
        ]
    elif pct > 70:
        status = "PERINGATAN (Mendekati Limit)"
        tips = [
            "Kurangi makan di luar atau beralih ke memasak sendiri.",
            "Cek kembali budget kategori Shopping Anda."
        ]
    else:
        status = "AMAN"
        tips = [
            "Keuangan Anda sehat bulan ini.",
            "Pertahankan pola belanja ini agar tabungan Anda berkembang."
        ]
        
    logs.append(f"[Budget Agent Simulator] Evaluasi selesai. Status: {status} ({int(pct)}% terpakai).")
    return BudgetSimulationResponse(
        limit=limit,
        spent=spent,
        status=status,
        tips=tips,
        logs=logs
    )

# --- 4. WEB SEARCH AGENT SIMULATOR ---
class SearchSimulationResponse(BaseModel):
    query: str
    results: List[Dict[str, Any]]
    logs: List[str]

@router.post("/search", response_model=SearchSimulationResponse)
async def simulate_search_agent(payload: AgentSimulationRequest):
    logs = [f"[Web Search Agent Simulator] Menerima kueri pencarian pasar: \"{payload.message}\"."]
    search_results = []
    
    if llm:
        try:
            logs.append("[Web Search Agent Simulator] Menghubungi Llama-3.3 untuk mensimulasikan pencarian web...")
            prompt = (
                f"Simulasikan hasil pencarian google real-time untuk kueri: '{payload.message}'.\n"
                f"Tuliskan 3 hasil pencarian yang relevan beserta estimasi harganya saat ini dalam format JSON array yang memuat kunci: title, snippet, price."
            )
            response = llm.invoke(prompt)
            # Parse list from response
            import json
            match = re.search(r'\[\s*\{.*\}\s*\]', response.content, re.DOTALL)
            if match:
                search_results = json.loads(match.group(0))
                logs.append(f"[Web Search Agent Simulator] Berhasil mensimulasikan {len(search_results)} hasil pencarian.")
        except Exception as e:
            logs.append(f"[Web Search Agent Simulator] Gagal mensimulasikan LLM search: {e}")
            
    if not search_results:
        # Static mock fallback
        search_results = [
            {"title": f"Harga {payload.message} Terbaru", "snippet": "Dapatkan harga termurah mulai dari Rp 12.000.000 di marketplace lokal.", "price": "Rp 12.000.000"},
            {"title": f"Spesifikasi Lengkap {payload.message}", "snippet": "Simak review dan perbandingan harga resmi Indonesia.", "price": "N/A"}
        ]
        logs.append("[Web Search Agent Simulator] Menggunakan data simulasi fallback statis.")
        
    return SearchSimulationResponse(
        query=payload.message,
        results=search_results,
        logs=logs
    )
