from ogd_service import OGDService
import time

print("Starting 365-Day Historical Data Download...")
print("This process will run in the background. You can close this window if run via valid shell, but here we are in a script.")
print("Data is saved incrementally to mandi_data.csv")

service = OGDService()
# Fetch last 365 days
# logic: update_database(days_history=365) iterates 0 to 364 days back.
try:
    service.update_database(days_history=365)
    print("Download Complete!")
except Exception as e:
    print(f"Download Interrupted: {e}")
