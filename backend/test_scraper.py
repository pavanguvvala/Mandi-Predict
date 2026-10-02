
import requests
from bs4 import BeautifulSoup

URL = "https://agmarknet.ceda.ashoka.edu.in/"

def test_connectivity():
    try:
        print(f"Connecting to {URL}...")
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }
        response = requests.get(URL, headers=headers, timeout=10)
        response.raise_for_status()
        
        print("Connection successful!")
        
        soup = BeautifulSoup(response.content, 'html.parser')
        
        # Check title
        print("Page Title:", soup.title.string.strip())
        
        # Debug: Print all select IDs
        print("--- ALL SELECTS ---")
        for s in soup.find_all('select'):
            print(f"Select: id={s.get('id')}, name={s.get('name')}")
            
        print("--- ALL INPUTS ---")
        for i in soup.find_all('input'):
            print(f"Input: id={i.get('id')}, name={i.get('name')}")
            
        # Print snippet
        print("--- CONTENT SNIPPET ---")
        print(response.text[:1000])

    except Exception as e:
        print(f"Connection failed: {e}")

if __name__ == "__main__":
    test_connectivity()
