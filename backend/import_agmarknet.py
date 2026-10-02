import pandas as pd
import os
import sys
from model_utils import train_models

# Path to the main data file
DATA_FILE = os.path.join(os.path.dirname(__file__), "mandi_data.csv")

def import_file(file_path):
    print(f"Reading file: {file_path}...")
    
    try:
        if file_path.endswith('.csv'):
            df = pd.read_csv(file_path)
        elif file_path.endswith('.xlsx') or file_path.endswith('.xls'):
            df = pd.read_excel(file_path)
        else:
            print("Unsupported file format. Please use CSV or Excel.")
            return

        # Normalize Columns
        # Agmarknet often has: "Market Name", "Commodity", "Modal Price (Rs./Quintal)", "Price Date"
        # We need: mandi, commodity, date, modal_price, arrivals(optional)
        
        df.columns = [c.lower().strip() for c in df.columns]
        
        # Mapping attempts
        rename_map = {}
        for col in df.columns:
            if 'market' in col: rename_map[col] = 'mandi'
            elif 'commodity' in col: rename_map[col] = 'commodity'
            elif 'modal' in col: rename_map[col] = 'modal_price'
            elif 'date' in col: rename_map[col] = 'date'
            elif 'arrival' in col: rename_map[col] = 'arrivals'
            elif 'state' in col: rename_map[col] = 'state'
            
        df.rename(columns=rename_map, inplace=True)
        
        # Validation
        required = ['mandi', 'commodity', 'date', 'modal_price']
        for r in required:
            if r not in df.columns:
                print(f"Error: Column '{r}' not found. Found: {list(df.columns)}")
                print("Please ensure the file has standard headers.")
                return

        # Clean Data
        df['date'] = pd.to_datetime(df['date'])
        df['modal_price'] = pd.to_numeric(df['modal_price'], errors='coerce')
        if 'arrivals' in df.columns:
            df['arrivals'] = pd.to_numeric(df['arrivals'], errors='coerce').fillna(0)
        else:
            df['arrivals'] = 0
            
        df.dropna(subset=['modal_price'], inplace=True)
        
        # Standardize Strings
        df['mandi'] = df['mandi'].str.title().str.strip()
        df['commodity'] = df['commodity'].str.title().str.strip()
        
        # Keep only necessary columns
        final_df = df[['mandi', 'commodity', 'date', 'modal_price', 'arrivals']]
        if 'state' in df.columns:
            final_df['state'] = df['state']
        
        print(f"Successfully processed {len(final_df)} rows.")
        
        # Merge or Overwrite?
        # User said "Use only these data". So Overwrite.
        # But we might want to keep history?
        # Let's Ask user? Or default to Overwrite as implied by "Use only these data".
        # Safe bet: Backup old file and Overwrite.
        
        if os.path.exists(DATA_FILE):
            os.rename(DATA_FILE, DATA_FILE + ".bak")
            print("Backed up old data to mandi_data.csv.bak")
            
        final_df.to_csv(DATA_FILE, index=False)
        print(f"Saved to {DATA_FILE}")
        
        return True

    except Exception as e:
        print(f"Import failed: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python import_agmarknet.py <path_to_downloaded_file>")
    else:
        path = sys.argv[1]
        if import_file(path):
            print("Starting Training...")
            train_models()
            print("Training Complete! The App now uses your Real Data.")
