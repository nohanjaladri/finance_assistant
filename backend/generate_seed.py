import datetime
import random
import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Setup database path for SQLite
SQLITE_DB_PATH = "sqlite:///d:/Data/Project_Antigravity/finance_assistant/backend/finance.db"

# Categories & Notes Mapping
EXPENSE_DETAILS = {
    "Food": [
        {"note": "Makan siang Bakso & Es Teh", "items": [("Bakso Urat", 18000, 1), ("Es Teh Manis", 5000, 1)]},
        {"note": "Nasi Padang Lauk Rendang", "items": [("Nasi Padang Rendang", 25000, 1), ("Kerupuk Kulit", 5000, 1)]},
        {"note": "Kopi Susu Senja", "items": [("Es Kopi Susu", 18000, 2)]},
        {"note": "Makan Malam Nasi Goreng", "items": [("Nasi Goreng Spesial", 20000, 1)]},
        {"note": "Camilan Siang Minimarket", "items": [("Keripik Kentang", 12000, 2), ("Cokelat Bar", 8000, 1)]},
        {"note": "Sarapan Bubur Ayam", "items": [("Bubur Ayam Komplit", 15000, 1), ("Sate Usus", 3000, 2)]}
    ],
    "Groceries": [
        {"note": "Belanja Mingguan Sayur & Buah", "items": [("Apel Merah", 25000, 1), ("Sayur Bayam", 5000, 2), ("Wortel", 8000, 1)]},
        {"note": "Kebutuhan Dapur Indomaret", "items": [("Minyak Goreng 2L", 36000, 1), ("Beras 5kg", 68000, 1), ("Gula Pasir 1kg", 16000, 1)]},
        {"note": "Perlengkapan Mandi Bulanan", "items": [("Sabun Cair", 22000, 1), ("Shampoo 170ml", 25000, 1), ("Pasta Gigi", 12000, 1)]},
        {"note": "Stok Mie Instan", "items": [("Mie Goreng", 3100, 10), ("Mie Kuah Kari", 3200, 5)]}
    ],
    "Transport": [
        {"note": "Bensin Motor Pertamax", "items": [("Pertamax", 35000, 1)]},
        {"note": "Isi Saldo e-Money", "items": [("Top up e-Money", 100000, 1)]},
        {"note": "Gojek ke Kantor", "items": [("GoRide", 14000, 1)]},
        {"note": "Grab Car Bandara", "items": [("GrabCar Bandara", 150000, 1)]},
        {"note": "Bensin Mobil", "items": [("Pertalite Mobil", 200000, 1)]}
    ],
    "Shopping": [
        {"note": "Beli Kaos Polos", "items": [("Kaos Cotton Combed", 75000, 1)]},
        {"note": "Skin Care Bulanan", "items": [("Face Wash", 45000, 1), ("Sunscreen", 65000, 1)]},
        {"note": "Beli Buku Bacaan", "items": [("Buku Novel", 95000, 1)]},
        {"note": "Aksesoris Handphone", "items": [("Casing HP", 45000, 1), ("Kabel Charger", 60000, 1)]}
    ],
    "Other": [
        {"note": "Bayar Listrik Bulanan", "items": [("Tagihan Listrik PLN", 250000, 1)]},
        {"note": "Pulsa & Paket Internet", "items": [("Paket Data 50GB", 125000, 1)]},
        {"note": "Nonton Bioskop Weekend", "items": [("Tiket Bioskop", 45000, 2), ("Popcorn Large", 35000, 1)]},
        {"note": "Beli Obat di Apotek", "items": [("Vitamin C", 50000, 1), ("Obat Flu", 15000, 1)]}
    ]
}

INCOME_DETAILS = [
    {"note": "Gaji Bulanan", "category": "Salary", "amount": 7500000},
    {"note": "Project Freelance", "category": "Salary", "amount": 1500000},
    {"note": "Bonus Kinerja", "category": "Salary", "amount": 1000000}
]

def generate_data(user_id="user_budi_123"):
    start_date = datetime.date(2026, 4, 22)
    end_date = datetime.date(2026, 7, 21)
    current_date = start_date
    
    transactions = []
    
    while current_date <= end_date:
        # Determine number of transactions for this day (1 to 3)
        num_tx = random.randint(1, 3)
        
        # Monthly Salary on the 25th
        if current_date.day == 25:
            # Add Salary
            tx_time = datetime.datetime.combine(current_date, datetime.time(8, 0, 0))
            salary = INCOME_DETAILS[0]
            transactions.append({
                "user_id": user_id,
                "note": salary["note"],
                "amount": salary["amount"],
                "type": "IN",
                "category": salary["category"],
                "payment_method": "non_tunai",
                "created_at": tx_time,
                "items": [(salary["note"], salary["amount"], 1)]
            })
            
        # Freelance Income occasionally (15% chance on weekends)
        if current_date.weekday() in [5, 6] and random.random() < 0.15:
            tx_time = datetime.datetime.combine(current_date, datetime.time(13, 0, 0))
            freelance = random.choice(INCOME_DETAILS[1:])
            transactions.append({
                "user_id": user_id,
                "note": freelance["note"],
                "amount": freelance["amount"],
                "type": "IN",
                "category": freelance["category"],
                "payment_method": "non_tunai",
                "created_at": tx_time,
                "items": [(freelance["note"], freelance["amount"], 1)]
            })
            
        # Regular Expenses
        for idx in range(num_tx):
            category = random.choice(list(EXPENSE_DETAILS.keys()))
            choice = random.choice(EXPENSE_DETAILS[category])
            
            # Create a time variation
            hour = random.randint(9, 21)
            minute = random.randint(0, 59)
            second = random.randint(0, 59)
            tx_time = datetime.datetime.combine(current_date, datetime.time(hour, minute, second))
            
            payment_method = random.choice(["tunai", "non_tunai"])
            
            # Map items
            items_list = []
            total_amount = 0
            for item_name, price, qty in choice["items"]:
                # Add slight price variation of +/- 10%
                price_var = int(price * random.uniform(0.9, 1.1))
                price_var = (price_var // 100) * 100 # Round to nearest 100
                total_amount += price_var * qty
                items_list.append((item_name, price_var, qty))
                
            transactions.append({
                "user_id": user_id,
                "note": choice["note"],
                "amount": total_amount,
                "type": "OUT",
                "category": category,
                "payment_method": payment_method,
                "created_at": tx_time,
                "items": items_list
            })
            
        current_date += datetime.timedelta(days=1)
        
    return transactions

def write_sql_file(transactions, filename="d:/Data/Project_Antigravity/finance_assistant/seed_data.sql"):
    with open(filename, "w", encoding="utf-8") as f:
        f.write("-- ==========================================================\n")
        f.write("-- SEED DATA FOR TESTING (3 Months back: 2026-04-22 s/d 2026-07-21)\n")
        f.write("-- ==========================================================\n\n")
        f.write("DO $$\n")
        f.write("DECLARE\n")
        f.write("    -- GANTI UUID DI BAWAH INI DENGAN USER ID ANDA DARI TABLE auth.users\n")
        f.write("    v_user_id UUID := '0c732da4-39e4-45f1-8a64-984d66baadf0';\n")
        f.write("    v_tx_id BIGINT;\n")
        f.write("BEGIN\n")
        f.write("    RAISE NOTICE 'Memulai seeding data...';\n\n")
        
        for tx in transactions:
            created_at_str = tx["created_at"].strftime("%Y-%m-%d %H:%M:%S")
            f.write(f"    -- Transaksi: {tx['note']}\n")
            f.write(f"    INSERT INTO public.transactions (user_id, amount, note, type, category, payment_method, created_at)\n")
            f.write(f"    VALUES (v_user_id, {tx['amount']}, '{tx['note']}', '{tx['type']}', '{tx['category']}', '{tx['payment_method']}', '{created_at_str}+07')\n")
            f.write(f"    RETURNING id INTO v_tx_id;\n\n")
            
            for item_name, price, qty in tx["items"]:
                f.write(f"    INSERT INTO public.transaction_items (transaction_id, note, amount, quantity)\n")
                f.write(f"    VALUES (v_tx_id, '{item_name}', {price}, {qty});\n")
            f.write("\n")
            
        f.write("    RAISE NOTICE 'Seeding selesai!';\n")
        f.write("END $$;\n")
    print(f"[SQL] Berhasil menulis file SQL ke {filename}")

def seed_sqlite(transactions):
    try:
        from app.models.models import Transaction, TransactionItem
        engine = create_engine(SQLITE_DB_PATH)
        Session = sessionmaker(bind=engine)
        session = Session()
        
        # Optional: Clear existing transactions to prevent bloat
        # session.query(TransactionItem).delete()
        # session.query(Transaction).delete()
        
        print("Seeding SQLite database...")
        for tx in transactions:
            db_tx = Transaction(
                user_id=tx["user_id"],
                note=tx["note"],
                amount=tx["amount"],
                category=tx["category"],
                type=tx["type"],
                payment_method=tx["payment_method"],
                created_at=tx["created_at"]
            )
            session.add(db_tx)
            session.flush() # To get db_tx.id
            
            for item_name, price, qty in tx["items"]:
                db_item = TransactionItem(
                    transaction_id=db_tx.id,
                    note=item_name,
                    amount=price,
                    quantity=qty
                )
                session.add(db_item)
                
        session.commit()
        print("[SQLITE] Berhasil melakukan seed ke database SQLite!")
    except Exception as e:
        print(f"[SQLITE ERROR] Gagal melakukan seed: {e}")

if __name__ == "__main__":
    txs = generate_data()
    write_sql_file(txs)
    
    # Try seeding SQLite if models can be imported
    if os.path.exists("d:/Data/Project_Antigravity/finance_assistant/backend/app"):
        import sys
        sys.path.append("d:/Data/Project_Antigravity/finance_assistant/backend")
        seed_sqlite(txs)
