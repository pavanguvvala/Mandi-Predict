
import csv
import json
import os

def parse_csv_and_update():
    csv_path = 'c:/flutter_learning/mandipredict/backend/full data.csv'
    
    if not os.path.exists(csv_path):
        print(f"Error: File not found at {csv_path}")
        return

    master_data = {}
    
    with open(csv_path, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        try:
            header = next(reader) # Skip header
        except StopIteration:
            print("Error: Empty CSV file")
            return
            
        # Indices based on expected format: id,State name,District,Mandi,Commodity Group,Commodity Name
        # 0, 1, 2, 3, 4, 5
        
        count = 0
        for row in reader:
            if len(row) < 6:
                continue
                
            state = row[1].strip()
            mandi = row[3].strip()
            commodities_str = row[5].strip()
            
            if not state or not mandi or not commodities_str:
                continue
                
            if state not in master_data:
                master_data[state] = {}
                
            if mandi not in master_data[state]:
                master_data[state][mandi] = set()
            
            # Add the commodity string directly
            master_data[state][mandi].add(commodities_str)
            count += 1
            
    print(f"Processed {count} rows.")

    # Convert sets to lists and sort
    final_data = {}
    for state, mandis in master_data.items():
        final_data[state] = {}
        for mandi, crops in mandis.items():
            sorted_crops = sorted(list(crops))
            final_data[state][mandi] = sorted_crops
            
    # Write to master_data.py
    output_path = 'c:/flutter_learning/mandipredict/backend/master_data.py'
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write("# Auto-generated from full data.csv\n\n")
        f.write("MASTER_DATA = " + json.dumps(final_data, indent=4))
        f.write("\n")
        
    print(f"Successfully updated {output_path} with {len(final_data)} states.")

if __name__ == "__main__":
    parse_csv_and_update()
