import requests
import json

API_KEY = "579b464db66ec23bdd00000189a34c4264334d6267243dfd88f37e1a"
RESOURCE_ID = "9ef84268-d588-465a-a308-a864a43d0070"
URL = f"https://api.data.gov.in/resource/{RESOURCE_ID}"

params = {
    "api-key": API_KEY,
    "format": "json",
    "limit": 5
}

print(f"Connecting to {URL}...")
try:
    response = requests.get(URL, params=params, timeout=10)
    print(f"Status Code: {response.status_code}")
    
    if response.status_code == 200:
        data = response.json()
        print("--- SUCCESS ---")
        print(json.dumps(data, indent=2))
    else:
        print("--- ERROR ---")
        print(response.text)

except Exception as e:
    print(f"Exception: {e}")
