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
            "description":
                "Groceries=Sayur/Bahan Pokok, Bills=Tagihan/Listrik/Internet, EWallet=Topup DANA/GoPay, Charity=Sedekah, Transfer_In/Out=Kirim/Terima Uang.",
          },
        },
        "required": ["note", "amount", "type", "category"],
      },
    },
  },
  {
    "type": "function",
    "function": {
      "name": "create_pending_state",
      "description":
          """FASE 1 (INISIASI): Gunakan jika input BARU dari user tidak lengkap (misal harga kosong). Buat status pending di database.""",
      "parameters": {
        "type": "object",
        "properties": {
          "partial_note": {"type": "string"},
          "partial_amount": {"type": "string"},
          "missing_fields": {
            "type": "array",
            "items": {"type": "string"},
            "description": "Contoh: ['amount'] atau ['note']",
          },
          "ai_generated_question": {
            "type": "string",
            "description":
                "Pertanyaan spesifik buatanmu untuk menagih data yang kurang.",
          },
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
          """FASE 2 (RESOLUSI): Gunakan HANYA UNTUK MENGISI DAFTAR TERTUNDA. Jika setelah ditambah jawaban user datanya sudah lengkap, set remaining_missing_fields = [] dan tool ini akan otomatis mencatatnya!""",
      "parameters": {
        "type": "object",
        "properties": {
          "pending_id": {"type": "string"},
          "updated_note": {"type": "string"},
          "updated_amount": {"type": "string"},
          "remaining_missing_fields": {
            "type": "array",
            "items": {"type": "string"},
            "description": "JIKA SUDAH LENGKAP SEMUA, BERIKAN ARRAY KOSONG [].",
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
      "description":
          "Gunakan tool ini JIKA user secara eksplisit ingin MEMBATALKAN, MENOLAK, atau MENGHAPUS transaksi yang sedang ditanyakan (contoh: 'nggak jadi', 'batal', 'abaikan yang tadi').",
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
      "description": "Perbarui transaksi historis.",
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
      "description": "Jalankan query SQL untuk mengambil data historis.",
      "parameters": {
        "type": "object",
        "properties": {
          "sql": {"type": "string"},
          "viz_type": {
            "type": "string",
            "enum": ["bar", "pie", "line", "table", "auto"],
          },
          "summary_prompt": {"type": "string"},
        },
        "required": ["sql", "viz_type", "summary_prompt"],
      },
    },
  },
  {
    "type": "function",
    "function": {
      "name": "ask_clarification",
      "description":
          "Gunakan JIKA jawaban user SANGAT AMBIGU dan kamu tidak tahu angka tersebut untuk ID pending yang mana.",
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
