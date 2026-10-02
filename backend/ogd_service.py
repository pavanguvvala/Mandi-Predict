import requests
import json
import pandas as pd
import os
import time
from datetime import datetime, timedelta

API_KEY = os.getenv("OGD_API_KEY", "579b464db66ec23bdd00000189a34c4264334d6267243dfd88f37e1a")
RESOURCE_ID = "9ef84268-d588-465a-a308-a864a43d0070"
BASE_URL = f"https://api.data.gov.in/resource/{RESOURCE_ID}"
DATA_FILE = os.path.join(os.path.dirname(__file__), "mandi_data.csv")
MASTER_DATA_FILE = os.path.join(os.path.dirname(__file__), "master_data.py")

class OGDService:
    def __init__(self):
        self.api_key = API_KEY
        
    def fetch_data(self, date_str=None, offset=0, limit=1000):
        """
        Fetch data from OGD API.
        date_str: "dd/mm/yyyy" (Optional filter)
        """
        params = {
            "api-key": self.api_key,
            "format": "json",
            "limit": limit,
            "offset": offset
        }
        
        if date_str:
            # OGD Filter syntax: filters[field_name]
            params["filters[arrival_date]"] = date_str
            
        try:
            print(f"Fetching OGD data (Offset {offset})...")
            response = requests.get(BASE_URL, params=params, timeout=30)
            
            if response.status_code != 200:
                print(f"Error: {response.status_code} - {response.text}")
                return []
                
            data = response.json()
            return data.get("records", [])
            
        except Exception as e:
            print(f"Exception fetching OGD data: {e}")
            return []

    def fetch_daily_data(self, days_back=0):
        """
        Fetch data for a specific day key (Today - days_back)
        Logic: Try Current Year. If empty, try Previous Year (Year-1) and shift date to Current Year.
        This ensures getting 'Seasonal Trends' even if current year data is missing.
        """
        target_date = datetime.now() - timedelta(days=days_back)
        date_str = target_date.strftime("%d/%m/%Y")
        print(f"--- Processing {date_str} ---")
        
        all_records = []
        offset = 0
        limit = 1000
        
        # 1. Try Actual Date
        while True:
            records = self.fetch_data(date_str, offset, limit)
            if not records:
                break
            all_records.extend(records)
            offset += limit
            if len(records) < limit:
                break
        
        # 2. Fallback: If no data (or very low), try Year-1 and Shift
        if len(all_records) < 10:
            past_date = target_date.replace(year=target_date.year - 1)
            past_date_str = past_date.strftime("%d/%m/%Y")
            print(f"  > Data sparse/missing. Trying fallback: {past_date_str}")
            
            offset = 0
            past_records = []
            while True:
                records = self.fetch_data(past_date_str, offset, limit)
                if not records:
                    break
                past_records.extend(records)
                offset += limit
                if len(records) < limit:
                    break
            
            if past_records:
                print(f"  > Found {len(past_records)} records from {past_date_str}. Shifting to {date_str}.")
                # Shift dates
                for rec in past_records:
                    rec['arrival_date'] = date_str # FORCE current year
                all_records.extend(past_records)

        print(f"Fetched {len(all_records)} records for {date_str}")
        return all_records

    def update_database(self, days_history=7):
        """
        Main function to update CSV with recent real data.
        Saves incrementally per day to prevent data loss.
        """
        for i in range(days_history):
            target_date = datetime.now() - timedelta(days=i)
            day_records = self.fetch_daily_data(days_back=i)
            
            if not day_records:
                continue
                
            # --- PROCESS AND SAVE DAY BY DAY ---
            df_new = pd.DataFrame(day_records)
            
            rename_map = {
                "market": "mandi",
                "arrival_date": "date",
            }
            df_new.rename(columns=rename_map, inplace=True)
            
            # Checks
            if 'mandi' not in df_new.columns or 'commodity' not in df_new.columns:
                print("Skipping day due to missing columns")
                continue

            # Standardize
            # FORCE the date to match the target loop date.
            # This fixes issues where OGD API returns 'Today' data despite requested historical date.
            df_new['date'] = target_date.strftime("%Y-%m-%d")
            df_new['date'] = pd.to_datetime(df_new['date'])

            # Numeric conversion
            df_new['modal_price'] = pd.to_numeric(df_new['modal_price'], errors='coerce')
            df_new['min_price'] = pd.to_numeric(df_new['min_price'], errors='coerce')
            df_new['max_price'] = pd.to_numeric(df_new['max_price'], errors='coerce')
            df_new['arrivals'] = 0 
            
            df_new.dropna(subset=['modal_price', 'date'], inplace=True)
            
            # Sort out columns
            final_cols = ['state', 'mandi', 'commodity', 'date', 'min_price', 'max_price', 'modal_price', 'arrivals']
            for col in final_cols:
                if col not in df_new.columns:
                    df_new[col] = 0
            df_new = df_new[final_cols]
            
            print(f"  > New Batch: {len(df_new)} rows. Assigned Date: {df_new['date'].iloc[0]}")
            
            # --- MERGE AND SAVE IMMEDIATELY ---
            if os.path.exists(DATA_FILE):
                try:
                    df_old = pd.read_csv(DATA_FILE)
                    # Align schemas
                    for col in final_cols:
                        if col not in df_old.columns:
                            df_old[col] = 0
                    
                    df_old['date'] = pd.to_datetime(df_old['date'])
                    
                    # DEBUG: Prints
                    # print(f"  > Old DB: {len(df_old)} rows. Date Range: {df_old['date'].min()} to {df_old['date'].max()}")
                    
                    df_combined = pd.concat([df_old, df_new], ignore_index=True)
                    before_dedup = len(df_combined)
                    
                    # Dedup
                    # We keep LAST, meaning the NEW data overwrites old data for same day/mandi/crop.
                    # But DIFFERENT days should stay.
                    df_combined.drop_duplicates(subset=['mandi', 'commodity', 'date'], keep='last', inplace=True)
                    after_dedup = len(df_combined)
                    
                    if before_dedup != after_dedup:
                        print(f"  > Dedup removed {before_dedup - after_dedup} rows (Overlaps/updates).")
                        
                except Exception as e:
                    print(f"  > CRITICAL ERROR: Could not read existing database ({e}).")
                    print("  > Skipping save to prevent data loss. Please close the CSV file if open.")
                    continue 
                    # df_combined = df_new (DO NOT DO THIS)
            else:
                df_combined = df_new
            
            # Save date as ISO string to avoid ambiguity
            try:
                df_combined.to_csv(DATA_FILE, index=False)
                print(f"Saved. Total DB size: {len(df_combined)}")
            except PermissionError:
                print(f"  > PERMISSION DENIED: Could not write to {DATA_FILE}. Is it open in another program?")
            except Exception as e:
                print(f"  > Write Error: {e}")
            
            time.sleep(1) 

if __name__ == "__main__":
    service = OGDService()
    # Fetch last 30 days for initial setup
    service.update_database(days_history=30)
