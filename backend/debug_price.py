import sys
import os
sys.path.append(os.getcwd())
from backend.main import _get_future_prices, loaded_models
import pandas as pd
import os

print("--- DEBUG START ---")
# Ensure we are in correct dir for relative paths
os.chdir('c:/flutter_learning/mandipredict')

# Force clear models to test fallback
loaded_models.clear()

import joblib
import os

model_path = 'backend/models/model_Rajkot_Cotton.joblib'
if os.path.exists(model_path):
    data = joblib.load(model_path)
    print(f"Model: Rajkot Cotton")
    print(f"MAE: {data.get('mae')}")
    print(f"RMSE: {data.get('rmse')}")
else:
    print("Model not found.")
