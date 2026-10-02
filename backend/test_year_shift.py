import sys
import os
sys.path.append(os.getcwd())
from backend.ogd_service import OGDService
import datetime

service = OGDService()
# Test 2024
date_2024 = "13/12/2024" 
print(f"Testing Fetch for {date_2024}...")
records = service.fetch_data(date_str=date_2024, limit=10)

print(f"Records found: {len(records)}")
if records:
    print("Sample:", records[0])
