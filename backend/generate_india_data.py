import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import random
from master_data import MASTER_DATA

# Configuration
# Generate data ending YESTERDAY so we can predict TODAY onwards
END_DATE = datetime.now() - timedelta(days=1)
# 6 months of history
START_DATE = END_DATE - timedelta(days=180)
DAYS = (END_DATE - START_DATE).days + 1

# Base prices (approximate INR)
BASE_PRICES = {
    "Tomato": 1500, "Onion": 2000, "Green Chilli": 3000, "Red Chilli": 15000, 
    "Banana": 2000, "Rice": 3500, "Groundnut": 5000, "Cotton": 6000,
    "Wheat": 2200, "Paddy": 2000, "Soybean": 4000, "Turmeric": 7000,
    "Potato": 1200, "Maize": 1800, "Mustard": 4500, "Sugarcane": 300,
    "Garlic": 8000, "Ginger": 6000, "Jeera (Cumin)": 25000, "Castor Seed": 5500,
    "Coconut": 2500, "Mango": 4000
}

data = []

print(f"Generating Pan-India data from {START_DATE.date()} to {END_DATE.date()}")

for state, mandis in MASTER_DATA.items():
    print(f"Processing {state}...")
    for mandi, commodities in mandis.items():
        for comm in commodities:
            # Mandi-specific bias 
            mandi_bias = random.uniform(0.9, 1.1)
            # Default to 3000 if commodity not in base list
            base = BASE_PRICES.get(comm, 3000) 
            base_price = base * mandi_bias
            current_price = base_price
            
            for i in range(DAYS):
                date = START_DATE + timedelta(days=i)
                
                # Daily fluctuation
                vol = 0.05 # 5% volatility
                change = random.uniform(-vol, vol)
                current_price = current_price * (1 + change)
                
                # Clip bounds
                current_price = max(base_price * 0.4, min(current_price, base_price * 2.5))
                
                modal_price = round(current_price)
                min_price = round(modal_price * 0.9)
                max_price = round(modal_price * 1.1)
                
                # Random arrivals
                arrivals = random.randint(50, 2000)
                
                data.append({
                    "date": date.strftime("%Y-%m-%d"),
                    "state": state, # New Field
                    "mandi": mandi,
                    "commodity": comm,
                    "min_price": min_price,
                    "max_price": max_price,
                    "modal_price": modal_price,
                    "arrivals": arrivals
                })

df = pd.DataFrame(data)
csv_path = "mandi_data.csv"
df.to_csv(csv_path, index=False)
print(f"Generated {len(df)} rows of data in {csv_path}")
