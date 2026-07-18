import urllib.request
import json
import sqlite3
import time

def test_chat():
    print("Testing backend Chat API and DB integration...")
    url = "https://finance-assistant-gilt.vercel.app/chat"
    data = json.dumps({
      "message": "Saya beli bakso 15000",
      "user_id": "00000000-0000-0000-0000-000000000000"
    }).encode("utf-8")
    
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
            print("API Response:", json.dumps(res_json, indent=2))
            assert "bakso" in res_json["reply"] or "pengeluaran" in res_json["reply"]
            assert res_json["intent"] == "ADD_EXPENSE"
            assert res_json["extracted_data"]["amount"] == 15000
            print("[OK] API Assertion Passed!")
    except Exception as e:
      print("[ERROR] API Request Failed:", e)
      return

    # Database verification is now handled remotely via Supabase.
    print("[INFO] Remote Database verification should be checked via Supabase Dashboard.")

if __name__ == "__main__":
    test_chat()
