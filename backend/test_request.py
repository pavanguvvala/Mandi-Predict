import requests
import pandas as pd

url = "https://agmarknet.gov.in/SearchCmmMkt.aspx"
params = {
    'Tx_Commodity': '23', # Onion
    'Tx_State': 'MH',    # Maharashtra
    'Tx_District': '0',
    'Tx_Market': '0',
    'DateFrom': '01-Nov-2023',
    'DateTo': '05-Nov-2023',
    'Fr_Date': '01-Nov-2023',
    'To_Date': '05-Nov-2023',
    'Tx_Trend': '0',
    'Tx_CommodityHead': 'Onion',
    'Tx_StateHead': 'Maharashtra',
    'Tx_DistrictHead': 'Select',
    'Tx_MarketHead': 'Select'
}

print(f"Requesting {url} with params...")
try:
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }
    r = requests.get(url, params=params, headers=headers, timeout=20)
    print(f"Status: {r.status_code}")
    print(f"Content Length: {len(r.text)}")
    
    if "No Data Found" in r.text:
        print("Response says: No Data Found")
    
    # Check for table
    dfs = pd.read_html(r.content)
    for i, df in enumerate(dfs):
        print(f"--- Table {i} ---")
        print(df.head())
        print(df.columns)

except Exception as e:
    print(f"Error: {e}")
