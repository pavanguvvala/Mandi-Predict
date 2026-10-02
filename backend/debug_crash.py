import requests
import json

URL = "http://127.0.0.1:8000"

def test_dashboard():
    print("Testing /dashboard...")
    try:
        payload = {
            "state": "Andhra Pradesh",
            "mandi": "Rajahmundry",
            "crops": ["Banana"]
        }
        res = requests.post(f"{URL}/dashboard", json=payload)
        print(f"Status: {res.status_code}")
        if res.status_code != 200:
            print("Error:", res.text)
        else:
            print("Success (Dashboard)")
    except Exception as e:
        print(f"Request Failed: {e}")

def test_optimize():
    print("\nTesting /optimize...")
    try:
        payload = {
            "mandis": ["Rajahmundry", "Vijayawada"],
            "commodity": "Banana",
            "quantity_quintal": 10,
            "storage_days_max": 3,
            "storage_cost_per_quintal_per_day": 5,
            "transport_cost_per_km_per_quintal": 5,
            "distance_to_mandi": {"Rajahmundry": 3, "Vijayawada": 150}
        }
        res = requests.post(f"{URL}/optimize", json=payload)
        print(f"Status: {res.status_code}")
        if res.status_code != 200:
            print("Error:", res.text)
        else:
            print("Success (Optimize)")
    except Exception as e:
        print(f"Request Failed: {e}")

if __name__ == "__main__":
    test_dashboard()
    test_optimize()
