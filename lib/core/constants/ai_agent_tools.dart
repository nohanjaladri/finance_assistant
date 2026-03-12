const List<Map<String, dynamic>> agentTools = [
  {
    "type": "function",
    "function": {
      "name": "record_transaction",
      "description": """Catat transaksi keuangan ke database.
Gunakan tool ini HANYA jika nominal/amount eksplisit disebutkan user.
PENTING: Jika ada beberapa transaksi (campuran pemasukan dan pengeluaran), WAJIB panggil tool ini berkali-kali secara terpisah untuk tiap item. JANGAN HANYA MEMBALAS DENGAN TEKS.""",
      "parameters": {
        "type": "object",
        "properties": {
          "note": {
            "type": "string",
            "description":
                "Deskripsi transaksi, contoh: 'Gaji bulanan', 'Makan siang', 'Ojek ke kantor'",
          },
          "amount": {
            "type": "string",
            "description":
                "Nominal uang MURNI ANGKA TANPA TITIK/KOMA dikirim sebagai teks. CONTOH BENAR: '15000'. CONTOH SALAH: '15.000' atau 'Rp15000'.",
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
        "required": ["note", "amount", "type", "category"],
      },
    },
  },
  {
    "type": "function",
    "function": {
      "name": "save_pending",
      "description": """Simpan transaksi yang belum lengkap ke antrian pending.
Gunakan tool ini ketika input transaksi tidak memiliki nominal/amount atau nama.
PENTING: JANGAN bertanya kepada user. Cukup konfirmasi singkat bahwa data telah dimasukkan ke antrean pending.""",
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
          "amount": {
            "type": "string",
            "description":
                "Nominal uang MURNI ANGKA TANPA TITIK/KOMA dikirim sebagai teks. CONTOH BENAR: '15000'. Biarkan kosong jika nominal yang kurang.",
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
          "reason": {
            "type": "string",
            "description": "Alasan kenapa disimpan sebagai pending",
          },
        },
        "required": [
          "original_input",
          "missing_fields",
          "partial_note",
          "reason",
        ],
      },
    },
  },
  {
    "type": "function",
    "function": {
      "name": "update_transaction",
      "description":
          """Perbarui nominal atau catatan transaksi yang sudah ada di database.
Gunakan tool ini HANYA JIKA user secara eksplisit meminta untuk mengubah/mengupdate harga atau nama transaksi yang salah.""",
      "parameters": {
        "type": "object",
        "properties": {
          "id": {
            "type": "string",
            "description":
                "ID transaksi yang ingin diubah dikirim sebagai teks (harus dicari via query_database terlebih dahulu jika tidak tahu)",
          },
          "new_amount": {
            "type": "string",
            "description":
                "Nominal baru MURNI ANGKA TANPA TITIK/KOMA (dikirim sebagai teks)",
          },
          "new_note": {
            "type": "string",
            "description": "Nama/catatan transaksi baru",
          },
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
          """Jalankan query SQL untuk mengambil data transaksi historis.
Gunakan tool ini ketika user bertanya tentang data keuangan mereka. Tabel: transactions, messages.""",
      "parameters": {
        "type": "object",
        "properties": {
          "sql": {
            "type": "string",
            "description":
                """Query SELECT valid. PENTING: Untuk mencari tanggal tertentu, gunakan fungsi LIKE karena format di DB adalah ISO8601. Contoh: WHERE date LIKE '2026-03-13%'""",
          },
          "viz_type": {
            "type": "string",
            "enum": ["bar", "pie", "line", "table", "auto"],
            "description": "Tipe visualisasi",
          },
          "summary_prompt": {
            "type": "string",
            "description": "Instruksi untuk merangkum hasil",
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
      "description":
          """Tanyakan klarifikasi ke user tanpa menyimpan ke pending.""",
      "parameters": {
        "type": "object",
        "properties": {
          "question": {
            "type": "string",
            "description": "Pertanyaan klarifikasi",
          },
          "context": {"type": "string", "description": "Konteks klarifikasi"},
        },
        "required": ["question", "context"],
      },
    },
  },
];
