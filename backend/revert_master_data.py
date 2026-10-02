
import csv
import json
import os

def revert_dataset():
    # 1. Read 'mandi_data.csv' to find available Mandi-Commodity pairs
    csv_path = 'c:/flutter_learning/mandipredict/backend/mandi_data.csv'
    if not os.path.exists(csv_path):
        print("Error: mandi_data.csv not found")
        return

    available_data = {} # State -> {Mandi -> set(Crops)}

    with open(csv_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            state = row['state']
            mandi = row['mandi']
            commodity = row['commodity']
            
            if state not in available_data:
                available_data[state] = {}
            if mandi not in available_data[state]:
                available_data[state][mandi] = set()
            
            available_data[state][mandi].add(commodity)

    # 2. Convert to dictionary structure for master_data.py
    final_master_data = {}
    
    for state, mandis in available_data.items():
        final_master_data[state] = {}
        for mandi, crops in mandis.items():
            final_master_data[state][mandi] = sorted(list(crops))

    # 3. Write to master_data.py
    output_path = 'c:/flutter_learning/mandipredict/backend/master_data.py'
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write("# Auto-generated: Reverted to only Historical Data Candidates\n\n")
        f.write("MASTER_DATA = " + json.dumps(final_master_data, indent=4))
        f.write("\n")
    
    print(f"Successfully reverted master_data.py. Contains {len(final_master_data)} states.")

if __name__ == "__main__":
    revert_dataset()
