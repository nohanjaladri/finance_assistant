import urllib.request
import json

def test_local_endpoint(message: str, user_id: str):
    url = "http://127.0.0.1:8000/chat"
    payload = {
        "message": message,
        "user_id": user_id
    }
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=data,
        headers={"Content-Type": "application/json"},
        method="POST"
    )
    try:
        with urllib.request.urlopen(req) as response:
            res_body = response.read().decode("utf-8")
            res_json = json.loads(res_body)
            print(f"\n[INPUT] User: {user_id} | Message: \"{message}\"")
            print(f"[REPLY] {res_json.get('reply')}")
            print(f"[INTENT] {res_json.get('intent')}")
            print(f"[EXTRACTED DATA] {res_json.get('extracted_data')}")
    except Exception as e:
        print(f"[ERROR] Failed for message: \"{message}\" -> {e}")

if __name__ == "__main__":
    # Test cases representing different intents and various user inputs
    test_cases = [
        # 1. Standard ADD_EXPENSE
        ("Saya baru saja makan nasi padang habis 25 ribu rupiah", "user_budi_123"),
        
        # 2. ADD_EXPENSE with payment method and categories
        ("Beli bensin pertamax 50k pakai gopay", "user_budi_123"),
        
        # 3. ADD_INCOME
        ("Gajian masuk sebesar 5000000 rupiah", "user_budi_123"),
        
        # 4. UNDO intent
        ("eh salah tolong batalin transaksi tadi", "user_budi_123"),
        
        # 5. Generic/Question (UNKNOWN or GENERAL intent)
        ("bagaimana cara menabung yang baik?", "user_budi_123"),
        
        # 6. Another user session (checking memory isolation)
        ("Saya beli bakso 15000", "user_ani_456"),
        ("eh batalkan saja", "user_ani_456")
    ]
    
    for msg, uid in test_cases:
        test_local_endpoint(msg, uid)
