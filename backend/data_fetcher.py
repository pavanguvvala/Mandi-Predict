import requests
from bs4 import BeautifulSoup
import pandas as pd
import datetime
import time
import random
import os

# Base URL for Agmarknet Price/Arrivals
BASE_URL = "https://agmarknet.gov.in/PriceAndArrivals/CommodityDailyArrivalPrice.aspx"

class AgmarknetScraper:
    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.5'
        })
        
    def _get_viewstate(self, soup):
        viewstate = soup.select_one("#__VIEWSTATE")['value']
        viewstate_gen = soup.select_one("#__VIEWSTATEGENERATOR")['value']
        event_validation = soup.select_one("#__EVENTVALIDATION")['value']
        return viewstate, viewstate_gen, event_validation

    def fetch_data(self, state, commodity, date_from, date_to):
        try:
            print(f"Fetching {commodity} in {state} ({date_from} to {date_to})...")
            
            # Step 1: GET the page to get ViewStates
            response = self.session.get(BASE_URL, timeout=30)
            if response.status_code != 200:
                print(f"Failed to load page: {response.status_code}")
                return pd.DataFrame()
            
            soup = BeautifulSoup(response.content, 'html.parser')
            vs, vsg, ev = self._get_viewstate(soup)
            
            # Step 2: Prepare Form Data
            # Note: IDs might change, but usually standardized in ASP.NET
            # We assume the user wants 'All Markets' in the state for the commodity
            
            # Need to find value for State and Commodity dropdowns?
            # Creating a robust mapping is hard without scraping dropdowns first.
            # OR we can try to pass text if the backend accepts it (unlikely for ASP.NET).
            
            # Simplified approach: Return empty for now as we need to scrape Dropdown IDs first.
            # FOR DEMONSTRATION/MVP: We will implement a function that parses correct IDs if possible,
            # or uses a simpler 'Search' query parameter approach if discovered.
            
            # CHECK: Agmarknet has a GET accessible Search Page?
            # https://agmarknet.gov.in/SearchCmmMkt.aspx?Tx_Commodity=24&Tx_State=AP&...
            # The 'SearchCmmMkt.aspx' is often easier.
            
            search_url = "https://agmarknet.gov.in/SearchCmmMkt.aspx"
            params = {
                'Tx_Commodity': self._get_comm_id(commodity), 
                'Tx_State': self._get_state_id(state),
                'Tx_District': '0', # All
                'Tx_Market': '0', # All
                'DateFrom': date_from,
                'DateTo': date_to,
                'Fr_Date': date_from,
                'To_Date': date_to,
                'Tx_Trend': '0',
                'Tx_CommodityHead': commodity,
                'Tx_StateHead': state,
                'Tx_DistrictHead': 'Select',
                'Tx_MarketHead': 'Select'
            }
            
            # Note: This GET method works on some Agmarknet versions.
            resp = self.session.get(search_url, params=params, timeout=30)
            
            if "No Data Found" in resp.text:
                return pd.DataFrame()
                
            # Parse Table
            # The table usually has id 'cphBody_GridPriceData'
            dfs = pd.read_html(resp.content)
            for df in dfs:
                if 'Min Price' in str(df.columns) or 'Modal Price' in str(df.columns):
                    return self._clean_df(df, state, commodity)
                    
            return pd.DataFrame()

        except Exception as e:
            print(f"Error fetching data: {e}")
            return pd.DataFrame()

    def _get_state_id(self, state_name):
        # MAPPING (Partial/Example - would need full scrape to be perfect)
        # Using codes observed from Agmarknet URLs
        mapping = {
            "Andhra Pradesh": "AP",
            "Telangana": "TG",
            "Maharashtra": "MH",
            "Karnataka": "KK",
            "Uttar Pradesh": "UP",
            "Punjab": "PB",
            "Madhya Pradesh": "MP",
            "Gujarat": "GJ",
            "Tamil Nadu": "TN",
            "West Bengal": "WB",
            "Rajasthan": "RJ"
        }
        return mapping.get(state_name, "AP")

    def _get_comm_id(self, comm_name):
        # MAPPING (Top Commodities)
        # 23=Onion, 24=Potato, 17=Cotton? No, standard IDs needed.
        # Ideally we fetch these from the main page dropdown once.
        # For now, we will leave this placeholder or return '0' to fail gracefully 
        # until we write the dropdown scraper.
        
        # Hardcoding a few common ones for testing:
        # Check specific IDs online or via browser tool later.
        mapping = {
            "Onion": "23",
            "Tomato": "78",
            "Potato": "24",
            "Cotton": "17",
            "Wheat": "1",
            "Rice": "3",
            "Paddy": "4", # Paddy(Dhan)
            # ... Add more as discovered
        }
        return mapping.get(comm_name, "23") # Default Onion

    def _clean_df(self, df, state, commodity):
        # Rename columns standard
        # Agmarknet cols: Slab, District Name, Market Name, Commodity, Variety, Grade, Min Price, Max Price, Modal Price, Price Date
        try:
            # Flatten multi-index if present
            if isinstance(df.columns, pd.MultiIndex):
                df.columns = df.columns.map(' '.join).str.strip()
                
            # Normalize names
            df.columns = [c.lower().replace(" ", "_") for c in df.columns]
            
            # Select/Rename
            rename_map = {
                'market_name': 'mandi',
                'min_price_(rs./quintal)': 'min_price',
                'max_price_(rs./quintal)': 'max_price',
                'modal_price_(rs./quintal)': 'modal_price',
                'price_date': 'date'
            }
            
            # Handle variations in column names via flexible search
            final_cols = {}
            for col in df.columns:
                if 'market' in col: final_cols[col] = 'mandi'
                elif 'min' in col and 'price' in col: final_cols[col] = 'min_price'
                elif 'max' in col and 'price' in col: final_cols[col] = 'max_price'
                elif 'modal' in col: final_cols[col] = 'modal_price'
                elif 'date' in col: final_cols[col] = 'date'
                
            df.rename(columns=final_cols, inplace=True)
            
            # Add missing
            df['state'] = state
            df['commodity'] = commodity
            if 'arrivals' not in df.columns:
                df['arrivals'] = 0 # Agmarknet 'Price' report might not have arrivals. 'Arrivals' report is separate.
                
            # Clean Types
            df['modal_price'] = pd.to_numeric(df['modal_price'], errors='coerce')
            df.dropna(subset=['modal_price'], inplace=True)
            
            # Date parse
            try:
                df['date'] = pd.to_datetime(df['date'])
            except:
                pass
                
            return df[['state', 'mandi', 'commodity', 'date', 'min_price', 'max_price', 'modal_price', 'arrivals']]
            
        except Exception as e:
            print(f"Error cleaning DF: {e}")
            return pd.DataFrame()

# Standalone run
if __name__ == "__main__":
    scraper = AgmarknetScraper()
    # Test fetch
    df = scraper.fetch_data("Maharashtra", "Onion", "01-Jan-2025", "10-Jan-2025") # Future date just to check structure/fail
    print(df.head())
    print(f"Fetched {len(df)} rows.")
