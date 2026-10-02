import requests
import json

url = "http://127.0.0.1:8000/predict"
payload = {"mandi": "Adoni", "commodity": "Cotton"}
headers = {"Content-Type": "application/json"}

try:
    print(f"Testing URL: {url}")
    response = requests.post(url, json=payload, headers=headers)
    print(f"Status Code: {response.status_code}")
    print("Response Body:")
    print(response.text)
except Exception as e:
    print(f"Request Failed: {e}")
