import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import random

# Configuration
# Generate data ending YESTERDAY so we can predict TODAY onwards
END_DATE = datetime.now() - timedelta(days=1)
# 6 months of history
START_DATE = END_DATE - timedelta(days=180)
DAYS = (END_DATE - START_DATE).days + 1

MANDIS = [
    "Adoni", "Anantapur", "Madanapalle", "Guntur", "Vijayawada", 
    "Rajahmundry", "Ongole", "Tirupati", "Kadapa", "Eluru"
]

COMMODITIES = [
    "Tomato", "Onion", "Green Chilli", "Red Chilli", 
    "Banana", "Rice", "Groundnut", "Cotton"
]

# Base prices (approximate INR)
BASE_PRICES = {
    "Tomato": 1500, # Per Quintal (15/kg)
    "Onion": 2000,
    "Green Chilli": 3000,
    "Red Chilli": 15000, 
    "Banana": 2000,
    "Rice": 3500,
    "Groundnut": 5000,
    "Cotton": 6000
}

# Volatility factors
VOLATILITY = {
    "Tomato": 0.2, 
    "Onion": 0.1,
    "Green Chilli": 0.15,
    "Red Chilli": 0.05,
    "Banana": 0.05,
    "Rice": 0.02, 
    "Groundnut": 0.03,
    "Cotton": 0.04
}

data = []

print(f"Generating data from {START_DATE.date()} to {END_DATE.date()}")

# Generate Data
for mandi in MANDIS:
    for comm in COMMODITIES:
        # Mandi-specific bias 
        mandi_bias = random.uniform(0.9, 1.1)
        base_price = BASE_PRICES[comm] * mandi_bias
        current_price = base_price
        
        for i in range(DAYS):
            date = START_DATE + timedelta(days=i)
            
            # Daily fluctuation
            vol = VOLATILITY[comm]
            change = random.uniform(-vol, vol)
            current_price = current_price * (1 + change)
            
            # Clip bounds
            current_price = max(base_price * 0.2, min(current_price, base_price * 3.0))
            
            modal_price = round(current_price)
            min_price = round(modal_price * 0.9)
            max_price = round(modal_price * 1.1)
            
            # Random arrivals
            arrivals = random.randint(100, 1000)
            
            data.append({
                "date": date.strftime("%Y-%m-%d"),
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
