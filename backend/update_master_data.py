import pandas as pd
import json
import os

DATA_FILE = os.path.join(os.path.dirname(__file__), "mandi_data.csv")
MASTER_FILE = os.path.join(os.path.dirname(__file__), "master_data.py")

def update_master():
    print("Reading real data...")
    if not os.path.exists(DATA_FILE):
        print("Error: mandi_data.csv not found.")
        return

    df = pd.read_csv(DATA_FILE)
    
    # Structure: State -> Mandi -> [Commodities]
    master_tree = {}
    
    # Optimize by grouping
    # Get unique combinations
    unique_combos = df[['state', 'mandi', 'commodity']].drop_duplicates()
    
    print(f"Found {len(unique_combos)} unique State-Mandi-Commodity Links.")
    
    for _, row in unique_combos.iterrows():
        state = row['state']
        mandi = row['mandi']
        commodity = row['commodity']
        
        if pd.isna(state) or pd.isna(mandi) or pd.isna(commodity):
            continue
            
        if state not in master_tree:
            master_tree[state] = {}
        
        if mandi not in master_tree[state]:
            master_tree[state][mandi] = []
            
        if commodity not in master_tree[state][mandi]:
            master_tree[state][mandi].append(commodity)
            
    # Sort for neatness
    sorted_tree = {}
    for state in sorted(master_tree.keys()):
        sorted_tree[state] = {}
        for mandi in sorted(master_tree[state].keys()):
            sorted_tree[state][mandi] = sorted(master_tree[state][mandi])
            
    # --- HYBRID MERGE: Add Hardcoded Extras ---
    # The real OGD data can be sparse. users expect common crops.
    # We inject them here. If they don't have real data, the app uses 'Smart Fallback'.
    
    # 1. Define Hardcoded Extras (The "Expert Knowledge" Base)
    extras = {
        "Andhra Pradesh": {
            "Adoni APMC": ["Cotton", "Groundnut", "Sunflower"],
            "Anantapur APMC": ["Banana", "Groundnut", "Tomato", "Mousambi(Sweet Lime)"],
            "Guntur APMC": ["Cotton", "Red Chilli", "Turmeric", "Dry Chillies"],
            "Madanapalle APMC": ["Groundnut", "Mango", "Tomato"],
            "Vijayawada APMC": ["Banana", "Black Gram", "Rice"],
            "Rajahmundry APMC": ["Banana", "Coconut", "Paddy"],
            "Ongole APMC": ["Bengal Gram", "Red Chilli", "Tobacco"],
            "Tirupati APMC": ["Groundnut", "Mango", "Tomato"],
            "Kadapa APMC": ["Banana", "Onion", "Turmeric"],
            "Eluru APMC": ["Coconut", "Lemon", "Paddy"],
            "Chittoor APMC": ["Gur(Jaggery)", "Mango", "Groundnut"]
        },
        "Maharashtra": {
            "Lasalgaon APMC": ["Onion", "Soybean", "Wheat"],
            "Pune APMC": ["Onion", "Pomegranate", "Potato", "Tomato"],
            "Nagpur APMC": ["Cotton", "Orange", "Soybean"],
            "Nashik APMC": ["Grape", "Onion", "Tomato"],
            "Solapur APMC": ["Jowar", "Pomegranate", "Tur"],
            "Kolhapur APMC": ["Groundnut", "Jaggery", "Soybean"],
            "Mumbai APMC": ["Onion", "Potato", "Vegetables"],
            "Aurangabad APMC": ["Bajra", "Cotton", "Maize"]
        },
        "Uttar Pradesh": {
            "Agra APMC": ["Mustard", "Potato", "Wheat"],
            "Kanpur APMC": ["Potato", "Rice", "Wheat"],
            "Lucknow APMC": ["Mango", "Vegetables", "Wheat"],
            "Varanasi APMC": ["Peas", "Potato", "Tomato"],
            "Prayagraj APMC": ["Guava", "Potato", "Wheat"],
            "Meerut APMC": ["Potato", "Sugarcane", "Wheat"],
            "Bareilly APMC": ["Mentha Oil", "Rice", "Wheat"]
        },
        "Punjab": {
            "Khanna APMC": ["Maize", "Paddy", "Wheat"],
            "Ludhiana APMC": ["Paddy", "Potato", "Wheat"],
            "Amritsar APMC": ["Basmati Rice", "Peas", "Wheat"],
            "Bhatinda APMC": ["Cotton", "Mustard", "Wheat"],
            "Jalandhar APMC": ["Maize", "Potato", "Wheat"],
            "Patiala APMC": ["Paddy", "Vegetables", "Wheat"]
        },
        "Karnataka": {
            "Bengaluru APMC": ["Beans", "Onion", "Potato", "Tomato"],
            "Mysuru APMC": ["Banana", "Coconut", "Rice"],
            "Hubballi APMC": ["Cotton", "Dry Chilli", "Groundnut"],
            "Belagavi APMC": ["Maize", "Sugarcane", "Vegetables"],
            "Kolar APMC": ["Mango", "Silk Cocoon", "Tomato"],
            "Shivamogga APMC": ["Arecanut", "Ginger", "Paddy"],
            "Bagalkot APMC": ["Jowar", "Maize", "Sunflower"]
        },
        "Telangana": {
            "Hyderabad APMC": ["Fruits", "Onion", "Vegetables"],
            "Warangal APMC": ["Cotton", "Red Chilli", "Turmeric"],
            "Nizamabad APMC": ["Maize", "Soybean", "Turmeric"],
            "Khammam APMC": ["Cotton", "Groundnut", "Red Chilli"],
            "Karimnagar APMC": ["Cotton", "Maize", "Paddy"]
        },
        "Madhya Pradesh": {
            "Indore APMC": ["Onion", "Potato", "Soybean", "Wheat"],
            "Bhopal APMC": ["Soybean", "Vegetables", "Wheat"],
            "Ujjain APMC": ["Gram", "Soybean", "Wheat"],
            "Mandsaur APMC": ["Garlic", "Soybean", "Wheat"]
        },
        "Gujarat": {
            "Ahmedabad APMC": ["Castor Seed", "Cotton", "Vegetables"],
            "Surat APMC": ["Banana", "Sugarcane", "Vegetables"],
            "Rajkot APMC": ["Cotton", "Cummin", "Groundnut"],
            "Unjha APMC": ["Fennel", "Isabgol", "Jeera (Cumin)"]
        }
    }
    
    print("Merging Hardcoded Extras...")
    for state, mandis in extras.items():
        if state not in sorted_tree:
            sorted_tree[state] = {}
        for mandi, crops in mandis.items():
            # Fuzzy match mandi name in real data? Or just add exact?
            # Let's try to add to existing keys if close match, else add new.
            target_key = mandi
            
            # Simple direct add for now
            if target_key not in sorted_tree[state]:
                sorted_tree[state][target_key] = []
            
            for crop in crops:
                if crop not in sorted_tree[state][target_key]:
                    sorted_tree[state][target_key].append(crop)
            
            sorted_tree[state][target_key].sort()
    
    # Generate Python File Content
    content = f"# Auto-generated from mandi_data.csv + Hybrid Extras\n# Contains {len(sorted_tree)} States and {sum(len(m) for m in sorted_tree.values())} Mandis\n\n"
    content += "MASTER_DATA = " + json.dumps(sorted_tree, indent=4)
    
    with open(MASTER_FILE, "w", encoding="utf-8") as f:
        f.write(content)
        
    print(f"Successfully updated master_data.py with full coverage!")

if __name__ == "__main__":
    update_master()
