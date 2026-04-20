const List<Map<String, dynamic>> agentTools = [
  {
    "type": "function",
    "function": {
      "name": "record_transaction",
      "description": """HANYA UNTUK TRANSAKSI BARU YANG LENGKAP. 
DILARANG KERAS digunakan untuk menyelesaikan DAFTAR TRANSAKSI TERTUNDA. Jika kamu sedang membahas transaksi tertunda, gunakan `update_pending_state` saja!""",
      "parameters": {
        "type": "object",
        "properties": {
          "note": {"type": "string"},
          "amount": {
            "type": "string",
            "description": "Nominal murni angka. Contoh: '15000'.",
          },
          "type": {
            "type": "string",
            "enum": ["IN", "OUT"],
          },
          "category_id": {
            "type": "string",
            "description": "Kategori transaksi, default 'cat_other_out'",
          },
          "friendly_reply": {
            "type": "string",
            "description": "Pesan balasan ramah untuk user",
          },
        },
        "required": ["note", "amount", "type"],
      },
    },
  },
  {
    "type": "function",
    "function": {
      "name": "record_receipt_items",
      "description":
          "Gunakan HANYA untuk menyimpan hasil ekstraksi teks/gambar struk belanja yang memiliki banyak barang (multiple items).",
      "parameters": {
        "type": "object",
        "properties": {
          "merchant_name": {"type": "string"},
          "date": {"type": "string"},
          "items": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "name": {"type": "string"},
                "price": {
                  "type": "string",
                  "description": "Harga barang dalam format string angka murni",
                },
                "category_id": {"type": "string"},
              },
              "required": ["name", "price"],
            },
          },
          "total_amount": {
            "type": "string",
            "description": "Total harga dalam format string angka murni",
          },
        },
        "required": ["merchant_name", "items", "total_amount"],
      },
    },
  },
  {
    "type": "function",
    "function": {
      "name": "create_pending_state",
      "description":
          "FASE 1 (INISIASI): Gunakan jika input BARU dari user tidak lengkap (misal harga kosong).",
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
        },
        "required": ["missing_fields", "ai_generated_question"],
      },
    },
  },
  {
    "type": "function",
    "function": {
      "name": "update_pending_state",
      "description":
          "FASE 2 (RESOLUSI): Gunakan HANYA UNTUK MENGISI DAFTAR TERTUNDA.",
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
  {
    "type": "function",
    "function": {
      "name": "cancel_pending_state",
      "description": "Membatalkan/menghapus antrean pending jika user menolak.",
      "parameters": {
        "type": "object",
        "properties": {
          "pending_id": {"type": "string"},
        },
        "required": ["pending_id"],
      },
    },
  },
  {
    "type": "function",
    "function": {
      "name": "update_transaction",
      "description":
          "Perbarui nominal atau catatan histori berdasarkan ID. Gunakan setelah query_database untuk mencari ID.",
      "parameters": {
        "type": "object",
        "properties": {
          "id": {"type": "string"},
          "new_amount": {"type": "string"},
          "new_note": {"type": "string"},
        },
        "required": ["id", "new_amount"],
      },
    },
  },
  {
    "type": "function",
    "function": {
      "name": "query_database",
      "description":
          """AKSES SUPER-ADMIN: Gunakan tool ini JIKA user bertanya info histori, total pengeluaran, perbandingan, atau mencari ID transaksi untuk diupdate. 
SKEMA TABEL: transactions(id INTEGER PRIMARY KEY, amount INTEGER, note TEXT, type TEXT (IN/OUT), category TEXT, date TEXT (ISO8601 format)).
Buat query SQL murni untuk SQLite. Contoh: SELECT SUM(amount) FROM transactions WHERE type='OUT' AND date LIKE '2026-03%';
DILARANG MENGGUNAKAN DROP ATAU DELETE!""",
      "parameters": {
        "type": "object",
        "properties": {
          "sql": {
            "type": "string",
            "description": "Query SQLite yang valid (Hanya SELECT atau UPDATE)",
          },
          "viz_type": {
            "type": "string",
            "enum": ["bar", "pie", "line", "table", "auto"],
          },
          "summary_prompt": {
            "type": "string",
            "description": "Instruksi caramu merangkum hasilnya nanti.",
          },
        },
        "required": ["sql", "viz_type", "summary_prompt"],
      },
    },
  },
  {
    "type": "function",
    "function": {
      "name": "ask_clarification",
      "description": "Gunakan JIKA jawaban user SANGAT AMBIGU.",
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
];
