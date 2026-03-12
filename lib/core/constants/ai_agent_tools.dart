const List<Map<String, dynamic>> agentTools = [
  {
    "type": "function",
    "function": {
      "name": "record_transaction",
      "description": """Catat transaksi keuangan ke database.
Gunakan tool ini HANYA jika nominal/amount eksplisit disebutkan user.
JANGAN gunakan tool ini jika tidak ada angka di input user.
Amount akan diambil otomatis dari input — cukup kirim note, type, category.""",
      "parameters": {
        "type": "object",
        "properties": {
          "note": {
            "type": "string",
            "description":
                "Deskripsi transaksi, contoh: 'Gaji bulanan', 'Makan siang', 'Ojek ke kantor'",
          },
          "type": {
            "type": "string",
            "enum": ["IN", "OUT"],
            "description": "IN untuk pemasukan, OUT untuk pengeluaran",
          },
          "category": {
            "type": "string",
            "enum": [
              "Food",
              "Transport",
              "Shopping",
              "Health",
              "Entertainment",
              "Salary",
              "Business",
              "Other",
            ],
            "description": "Kategori terbaik berdasarkan konteks transaksi",
          },
        },
        "required": ["note", "type", "category"],
      },
    },
  },
  {
    "type": "function",
    "function": {
      "name": "save_pending",
      "description": """Simpan transaksi yang belum lengkap ke antrian pending.
Gunakan tool ini ketika:
- Input adalah transaksi tapi amount tidak disebutkan
- Ada informasi yang ambigu dan butuh konfirmasi user
- AI tidak yakin dengan data yang ada (confidence rendah)
Setelah save_pending, tanyakan langsung ke user apa yang kurang.""",
      "parameters": {
        "type": "object",
        "properties": {
          "original_input": {
            "type": "string",
            "description": "Input asli dari user",
          },
          "missing_fields": {
            "type": "array",
            "items": {"type": "string"},
            "description": "Field yang kurang, contoh: ['amount', 'category']",
          },
          "partial_note": {
            "type": "string",
            "description": "Deskripsi transaksi dari konteks yang ada",
          },
          "partial_type": {
            "type": "string",
            "enum": ["IN", "OUT", "UNKNOWN"],
            "description": "Tipe transaksi jika sudah bisa ditebak",
          },
          "partial_category": {
            "type": "string",
            "description":
                "Kategori jika sudah bisa ditebak, kosong jika tidak tahu",
          },
          "question": {
            "type": "string",
            "description":
                "Pertanyaan spesifik ke user untuk melengkapi data yang kurang",
          },
          "reason": {
            "type": "string",
            "description": "Alasan kenapa disimpan sebagai pending",
          },
        },
        "required": [
          "original_input",
          "missing_fields",
          "partial_note",
          "question",
          "reason",
        ],
      },
    },
  },
  {
    "type": "function",
    "function": {
      "name": "query_database",
      "description":
          """Jalankan query SQL untuk mengambil data transaksi historis.
Gunakan tool ini ketika user bertanya tentang data keuangan mereka.
Hanya SELECT yang diizinkan. Tabel: transactions, messages.""",
      "parameters": {
        "type": "object",
        "properties": {
          "sql": {
            "type": "string",
            "description": """Query SELECT valid. Contoh:
- SELECT * FROM transactions ORDER BY date DESC LIMIT 10
- SELECT SUM(amount) as total FROM transactions WHERE type='OUT'
- SELECT category, SUM(amount) as total FROM transactions GROUP BY category""",
          },
          "viz_type": {
            "type": "string",
            "enum": ["bar", "pie", "line", "table", "auto"],
            "description": "Tipe visualisasi terbaik untuk hasil query ini",
          },
          "summary_prompt": {
            "type": "string",
            "description":
                "Instruksi untuk merangkum hasil query dalam bahasa natural",
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
      "description": """Tanyakan klarifikasi ke user tanpa menyimpan ke pending.
Gunakan tool ini ketika input benar-benar ambigu dan tidak bisa ditentukan
apakah itu transaksi atau bukan, sebelum memutuskan mau disimpan ke pending.""",
      "parameters": {
        "type": "object",
        "properties": {
          "question": {
            "type": "string",
            "description": "Pertanyaan klarifikasi ke user",
          },
          "context": {
            "type": "string",
            "description": "Konteks kenapa butuh klarifikasi",
          },
        },
        "required": ["question", "context"],
      },
    },
  },
];
