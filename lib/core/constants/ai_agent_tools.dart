/// ai_agent_tools.dart (v2)
/// Definisi 8 AI function-calling tools untuk Dompetku AI
/// Digunakan oleh Groq API (primary) dan Gemini API (fallback)
library;

const List<Map<String, dynamic>> agentTools = [
  // ─────────────────────────────────────────────────────────
  // 1. RECORD TRANSACTION — Catat transaksi baru yang lengkap
  // ─────────────────────────────────────────────────────────
  {
    "type": "function",
    "function": {
      "name": "record_transaction",
      "description": """HANYA UNTUK TRANSAKSI BARU YANG LENGKAP.
DILARANG KERAS digunakan untuk menyelesaikan DAFTAR TRANSAKSI TERTUNDA.
Jika sedang membahas transaksi tertunda, gunakan `update_pending_state` saja!
PENTING: Tentukan payment_method berdasarkan KONTEKS TABS CHAT SAAT INI yang diberikan di system prompt (jika berada di tab TUNAI gunakan 'tunai', jika di tab NON-TUNAI gunakan 'non_tunai'), KECUALI user secara spesifik menyebutkan metode pembayaran yang berbeda secara eksplisit.""",
      "parameters": {
        "type": "object",
        "properties": {
          "note": {"type": "string", "description": "Deskripsi singkat transaksi"},
          "amount": {
            "type": "string",
            "description": "Nominal murni angka. Contoh: '15000'.",
          },
          "type": {
            "type": "string",
            "enum": ["IN", "OUT"],
            "description": "IN = pemasukan, OUT = pengeluaran",
          },
          "category": {
            "type": "string",
            "enum": [
              "Food",
              "Groceries",
              "Transport",
              "Shopping",
              "Health",
              "Entertainment",
              "Bills",
              "EWallet",
              "Education",
              "Charity",
              "Investment",
              "Salary",
              "Business",
              "Transfer_In",
              "Transfer_Out",
              "Other",
            ],
          },
          "payment_method": {
            "type": "string",
            "enum": ["tunai", "non_tunai"],
            "description": "Wajib disamakan dengan KONTEKS TABS CHAT SAAT INI ('tunai' atau 'non_tunai') kecuali jika pengguna secara eksplisit menyebutkan metode lain secara lisan/tulisan.",
          },
        },
        "required": ["note", "amount", "type", "category", "payment_method"],
      },
    },
  },

  // ─────────────────────────────────────────────────────────
  // 2. CREATE PENDING — Input tidak lengkap, buat antrian
  // ─────────────────────────────────────────────────────────
  {
    "type": "function",
    "function": {
      "name": "create_pending_state",
      "description": "FASE 1 (INISIASI): Gunakan jika input BARU dari user tidak lengkap (misal harga kosong).",
      "parameters": {
        "type": "object",
        "properties": {
          "partial_note": {"type": "string"},
          "partial_amount": {"type": "string"},
          "missing_fields": {
            "type": "array",
            "items": {"type": "string"},
          },
          "ai_generated_question": {"type": "string"},
          "payment_method_hint": {
            "type": "string",
            "enum": ["tunai", "non_tunai", "unknown"],
            "description": "Tebakan awal metode pembayaran berdasarkan konteks",
          },
        },
        "required": ["missing_fields", "ai_generated_question"],
      },
    },
  },

  // ─────────────────────────────────────────────────────────
  // 3. UPDATE PENDING — Isi field yang hilang
  // ─────────────────────────────────────────────────────────
  {
    "type": "function",
    "function": {
      "name": "update_pending_state",
      "description": "FASE 2 (RESOLUSI): Gunakan HANYA UNTUK MENGISI field yang kurang di DAFTAR TERTUNDA.",
      "parameters": {
        "type": "object",
        "properties": {
          "pending_id": {"type": "string"},
          "updated_note": {"type": "string"},
          "updated_amount": {"type": "string"},
          "remaining_missing_fields": {
            "type": "array",
            "items": {"type": "string"},
          },
          "next_ai_question": {"type": "string"},
          "payment_method": {
            "type": "string",
            "enum": ["tunai", "non_tunai"],
          },
        },
        "required": [
          "pending_id",
          "updated_note",
          "updated_amount",
          "remaining_missing_fields",
        ],
      },
    },
  },

  // ─────────────────────────────────────────────────────────
  // 4. CANCEL PENDING — Batalkan antrian
  // ─────────────────────────────────────────────────────────
  {
    "type": "function",
    "function": {
      "name": "cancel_pending_state",
      "description": "Membatalkan/menghapus antrean pending jika user menolak atau topik berganti.",
      "parameters": {
        "type": "object",
        "properties": {
          "pending_id": {"type": "string"},
        },
        "required": ["pending_id"],
      },
    },
  },

  // ─────────────────────────────────────────────────────────
  // 5. UPDATE TRANSACTION — Edit transaksi yang sudah ada
  // ─────────────────────────────────────────────────────────
  {
    "type": "function",
    "function": {
      "name": "update_transaction",
      "description": "Perbarui nominal, catatan, atau metode pembayaran berdasarkan ID. Gunakan setelah query_database untuk mencari ID.",
      "parameters": {
        "type": "object",
        "properties": {
          "id": {"type": "string"},
          "new_amount": {"type": "string"},
          "new_note": {"type": "string"},
          "new_payment_method": {
            "type": "string",
            "enum": ["tunai", "non_tunai"],
          },
        },
        "required": ["id"],
      },
    },
  },

  // ─────────────────────────────────────────────────────────
  // 6. QUERY DATABASE — Analitik & pencarian data
  // ─────────────────────────────────────────────────────────
  {
    "type": "function",
    "function": {
      "name": "query_database",
      "description": """SUPER-ADMIN ACCESS: Gunakan tool ini JIKA user bertanya info histori, total, perbandingan, atau mencari ID.
SKEMA TABEL: transactions(id, amount INTEGER, note TEXT, type TEXT (IN/OUT), category TEXT, payment_method TEXT (tunai/non_tunai), created_at TIMESTAMPTZ).
Gunakan query SQL PostgreSQL. Contoh: SELECT SUM(amount) FROM transactions WHERE type='OUT' AND created_at >= NOW() - INTERVAL '30 days';
Untuk filter waktu: gunakan created_at dengan INTERVAL atau DATE_TRUNC.
DILARANG: DROP, DELETE, UPDATE, INSERT, ALTER, CREATE, TRUNCATE.""",
      "parameters": {
        "type": "object",
        "properties": {
          "sql": {
            "type": "string",
            "description": "Query PostgreSQL yang valid (Hanya SELECT)",
          },
          "viz_type": {
            "type": "string",
            "enum": ["bar", "pie", "line", "table", "auto"],
          },
          "summary_prompt": {
            "type": "string",
            "description": "Instruksi cara merangkum hasilnya secara natural.",
          },
        },
        "required": ["sql", "viz_type", "summary_prompt"],
      },
    },
  },

  // ─────────────────────────────────────────────────────────
  // 7. ASK CLARIFICATION — Minta klarifikasi dari user
  // ─────────────────────────────────────────────────────────
  {
    "type": "function",
    "function": {
      "name": "ask_clarification",
      "description": "Gunakan JIKA jawaban user SANGAT AMBIGU dan tidak bisa diproses tanpa klarifikasi.",
      "parameters": {
        "type": "object",
        "properties": {
          "question": {"type": "string"},
          "context": {"type": "string"},
        },
        "required": ["question", "context"],
      },
    },
  },

  // ─────────────────────────────────────────────────────────
  // 8. GENERAL RESPONSE — Jawab pertanyaan umum (chatbot mode)
  // ─────────────────────────────────────────────────────────
  {
    "type": "function",
    "function": {
      "name": "general_response",
      "description": """Gunakan HANYA jika user bertanya sesuatu yang bukan transaksi dan bukan analitik database.
Contoh valid: tips menabung, penjelasan istilah keuangan, pertanyaan tentang fitur aplikasi.
BATASAN: Jangan berikan saran investasi saham spesifik, prediksi harga aset, atau informasi berita terkini (real-time).
Jika pertanyaan di luar topik keuangan pribadi, sampaikan dengan sopan bahwa kamu hanya berfokus pada keuangan pribadi.""",
      "parameters": {
        "type": "object",
        "properties": {
          "answer": {
            "type": "string",
            "description": "Jawaban natural dan ramah dalam Bahasa Indonesia",
          },
          "topic_category": {
            "type": "string",
            "enum": [
              "finance_tips",
              "app_help",
              "financial_terms",
              "budgeting",
              "savings",
              "out_of_scope",
            ],
          },
        },
        "required": ["answer", "topic_category"],
      },
    },
  },
];
