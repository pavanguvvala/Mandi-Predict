from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import pandas as pd
import numpy as np
import joblib
import os
import datetime
from model_utils import DataLoader, FeatureEngineer, train_models, MODELS_DIR
from weather_service import get_forecast

from contextlib import asynccontextmanager

# Models cache
loaded_models = {}

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Check if models exist, if not train
    if not os.path.exists(MODELS_DIR) or not os.listdir(MODELS_DIR):
        print("Models not found. Training...")
        try:
            train_models()
        except Exception as e:
            print(f"Model Training Failed: {e}")
    
    # Load models
    try:
        count = 0
        if os.path.exists(MODELS_DIR):
            for filename in os.listdir(MODELS_DIR):
                if filename.endswith(".joblib"):
                    path = os.path.join(MODELS_DIR, filename)
                    parts = filename.replace("model_", "").replace(".joblib", "").split("_")
                    if len(parts) >= 2:
                        key = f"{parts[0]}_{parts[1]}"
                        loaded_models[key] = joblib.load(path)
                        count += 1
        print(f"Loaded {count} models.")
    except Exception as e:
        print(f"Failed to load models: {e}")
        
    yield
    # Shutdown logic if any
    loaded_models.clear()

app = FastAPI(title="Mandi Price Predictor", lifespan=lifespan)

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
def health():
    return {"status": "ok", "models_loaded": len(loaded_models)}

from master_data import MASTER_DATA

@app.get("/options")
def get_options():
    # Dynamic Options: Hybrid of Real Data + Static Master Data
    # This ensures user sees "All Commodities" (from Master) even if Real Data (from CSV) is sparse.
    
    # 1. Start with Master Data
    options = {}
    
    # Deep copy to allow updates
    import copy
    if MASTER_DATA:
        options = copy.deepcopy(MASTER_DATA)
    
    csv_path = os.path.join(os.path.dirname(__file__), "mandi_data.csv")
    if not os.path.exists(csv_path):
        return options
        
    try:
        df = pd.read_csv(csv_path)
        # 2. Merge Real Data
        grouped = df.groupby(['state', 'mandi'])['commodity'].unique()
        
        for (state, mandi), comms in grouped.items():
            if state not in options:
                options[state] = {}
            if mandi not in options[state]:
                options[state][mandi] = []
            
            # Add existing
            current_list = set(options[state][mandi])
            for c in comms:
                current_list.add(c)
            
            options[state][mandi] = sorted(list(current_list))
            
        return options
    except Exception as e:
        print(f"Error generating options: {e}")
        return MASTER_DATA


class PredictRequest(BaseModel):
    mandi: str
    commodity: str

@app.post("/predict")
def predict(request: PredictRequest):
    # Delegate to robust helper function defined below
    # This prevents code duplication and ensures fallback logic is used
    preds = _get_future_prices(request.mandi, request.commodity, days=7)
    return {
        "mandi": request.mandi,
        "commodity": request.commodity,
        "currency": "INR",
        "predictions": preds,
        "meta": {
             "model_name": "smart_model_v2",
             "note": "Generated via ML or Fallback Trend"
        }
    }

# --- FIELD ASSISTANT CHATBOT ---
import google.generativeai as genai
from fastapi import File, UploadFile, Form
from typing import Optional
from PIL import Image
import io

# Configure Gemini from environment variable
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")
if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)

model = genai.GenerativeModel('gemini-flash-latest')

@app.post("/chat")
async def chat_endpoint(
    message: str = Form(...),
    image: Optional[UploadFile] = File(None)
):
    if not os.getenv("GEMINI_API_KEY"):
        raise HTTPException(
            status_code=500,
            detail="GEMINI_API_KEY is not configured. Please set the GEMINI_API_KEY environment variable."
        )
    try:
        system_prompt = """
        You are an expert Indian Farming Assistant (Kisan Sahayak).
        Your goal is to help Indian farmers with practical, accurate advice about crops, fertilizers, pests, weather, and market prices.
        
        CRITICAL INSTRUCTION FOR LANGUAGE:
        - If the user asks in HINDI, reply in HINDI (Devanagari script). Example: "टमाटर उगाने के लिए..."
        - If the user asks in TELUGU, reply in TELUGU script. Example: "టమోటాలు పండించడానికి..."
        - If the user asks in ENGLISH, reply in ENGLISH.
        - Do NOT use Transliteration (Hinglish/Tanglish). Use the native script.
        
        Guidelines:
        - Identify pests/diseases from images if provided.
        - Suggest organic and chemical remedies.
        - Keep answers concise and easy to understand for a farmer.
        """
        
        prompt_parts = [system_prompt, "\nUser Question: " + message]
        
        if image:
            #Read image file
            image_data = await image.read()
            image_parts = [{"mime_type": image.content_type, "data": image_data}]
             # Gemini 1.5 Flash supports image inputs directly via parts
            
            # Convert bytes to PIL Image for the library if needed, but the library often takes bytes directly or via specific setup.
            # For google-generativeai library, we usually pass the image object.
            img = Image.open(io.BytesIO(image_data))
            response = model.generate_content([system_prompt, message, img])
        else:
            response = model.generate_content([system_prompt, message])
            
        return {"response": response.text}
        
    except Exception as e:
        print(f"Chat Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


class OptimizeRequest(BaseModel):
    mandis: list[str]
    commodity: str
    quantity_quintal: float
    storage_days_max: int
    storage_cost_per_quintal_per_day: float
    transport_cost_per_km_per_quintal: float
    distance_to_mandi: dict[str, float]  # Mandi Name -> Distance in KM

@app.post("/optimize")
def optimize(request: OptimizeRequest):
    best_action = None
    max_profit = -float('inf')
    alternatives = []
    
    # Pre-fetch weather once if possible, or inside loop
    # For simplicity, we just predict for each mandi
    
    for mandi in request.mandis:
        # REMOVED strict model check here to allow Fallback logic in _get_future_prices to work.
        
        # 1. Get Predictions
        prices = _get_future_prices(mandi, request.commodity, days=7)
        
        if not prices:
             continue
             
        # 2. Calculate Net Profit for each day
        for day_idx, p_data in enumerate(prices):
            if day_idx > request.storage_days_max:
                break
                
            predicted_price = p_data['predicted_price'] 
            
            revenue = predicted_price * request.quantity_quintal
            storage_cost = request.storage_cost_per_quintal_per_day * request.quantity_quintal * day_idx
            dist = request.distance_to_mandi.get(mandi, 0)
            transport_cost = request.transport_cost_per_km_per_quintal * request.quantity_quintal * dist
            
            net_profit = revenue - storage_cost - transport_cost
            
            action_summary = {
                "mandi": mandi,
                "day_offset": day_idx,
                "date": p_data['date'],
                "predicted_price": predicted_price,
                "revenue": round(revenue, 2),
                "costs": round(storage_cost + transport_cost, 2),
                "net_profit": round(net_profit, 2)
            }
            
            alternatives.append(action_summary)
            
            if net_profit > max_profit:
                max_profit = net_profit
                best_action = action_summary

    # Sort alternatives by profit desc
    alternatives.sort(key=lambda x: x['net_profit'], reverse=True)
    
    # Construct Recommendation Text
    rec_text = "No option found."
    if best_action:
        mandi = best_action['mandi']
        days = best_action['day_offset']
        profit = best_action['net_profit']
        
        if profit >= 0:
            if days == 0:
                rec_text = f"Sell TODAY at {mandi} for best profit of ₹{profit}."
            else:
                rec_text = f"Store for {days} days and sell at {mandi}. Expected profit: ₹{profit}."
        else:
             # Loss Scenario
            if days == 0:
                rec_text = f"Minimize Loss: Sell TODAY at {mandi}. Loss: ₹{abs(profit)}."
            else:
                rec_text = f"Minimize Loss: Store for {days} days and sell at {mandi}. Projected Loss: ₹{abs(profit)}."
            
    return {
        "best_action": best_action,
        "recommendation_text": rec_text,
        "alternatives": alternatives[:5] # Top 5
    }

def _get_future_prices(mandi: str, commodity: str, days: int = 7, weather_cache: list = None):
    # FALLBACK GENERATOR (Ensures we ALWAYS return data)
    def generate_mock(start_price=5000, seed_str=""):
        import random
        # Create a local random instance to ensure deteriminism without affecting global state
        today_str = datetime.date.today().strftime("%Y%m%d")
        full_seed = f"{seed_str}_{today_str}"
        
        # Use a hash of the string as the seed
        rng = random.Random(full_seed)
        
        base = start_price
        mock_preds = []
        today = datetime.date.today()
        for i in range(days):
            date = today + datetime.timedelta(days=i)
            # Random drift using the deterministic RNG
            change = rng.uniform(-start_price*0.02, start_price*0.02) 
            base += change
            mock_preds.append({
                "date": date.strftime("%Y-%m-%d"),
                "predicted_price": round(base, 2),
                "source": "estimated"
            })
        return mock_preds

    try:
        key = f"{mandi}_{commodity}"
        
        # 1. Attempt to get Last Real Price from CSV (For Smart Fallback)
        last_real_price = None
        commodity_avg_price = None
        
        try:
            loader = DataLoader()
            df = loader.load_data()
            
            # Try specific mismatch first
            sub_df = loader.filter_data(df, mandi, commodity)
            if not sub_df.empty:
                last_real_price = sub_df['modal_price'].iloc[-1]
            
            # If no specific price, calculate GLOBAL AVERAGE for this commodity
            # This ensures 'Cotton' defaults to 7000 and 'Banana' to 3000, not 5000.
            if not last_real_price:
                comm_df = df[df['commodity'] == commodity]
                if not comm_df.empty:
                    commodity_avg_price = comm_df['modal_price'].mean()
                    
        except:
            pass
            
        # Hierarchy: Real Last Price > Commodity Average > Generic 4000
        default_price = last_real_price if last_real_price else (commodity_avg_price if commodity_avg_price else 4000)

        # 2. Check Model Existence
        if key not in loaded_models:
            print(f"No model found for {commodity}. using Smart Fallback: {default_price}")
            return generate_mock(default_price, seed_str=f"{mandi}_{commodity}") 


        model_data = loaded_models[key]
        model = model_data['model']
        features_list = model_data['features']
        
        # 2. Load Data
        loader = DataLoader() # Assuming imports exist globally
        df = loader.load_data()
        
        # 3. Filter Data
        sub_df = loader.filter_data(df, mandi, commodity)
        if sub_df.empty:
            print(f"No historical data for {mandi}-{commodity}. Generating fallback.")
            return generate_mock(6000, seed_str=f"{mandi}_{commodity}")

        # 4. Prepare Logic
        preds = []
        current_history = sub_df.copy()
        fe = FeatureEngineer()
        last_date = current_history['date'].max()
        
        # Weather (Mock logic if service fails)
        # Weather (Mock logic if service fails)
        try:
            if weather_cache and len(weather_cache) > 0:
                # Use cached forecast (passed from dashboard to save API calls)
                weather_forecasts = weather_cache
            else:
                coords = {"Lasalgaon": (20.1633, 74.2389), "Azadpur": (28.7090, 77.1816)}
                lat, lon = coords.get(mandi, (20.5937, 78.9629))
                weather_forecasts = get_forecast(lat, lon, days=days+20) 
        except Exception as e:
            print(f"Weather error: {e}. Using empty weather.")
            weather_forecasts = []

        today = pd.Timestamp(datetime.date.today())
        needed = days
        max_steps = 365
        step = 0
        
        # 5. Prediction Loop
        while needed > 0 and step < max_steps:
            step += 1
            target_date = last_date + datetime.timedelta(days=1)
            
            w_day = {}
            if target_date >= today:
                 delta = (target_date - today).days
                 if weather_forecasts and 0 <= delta < len(weather_forecasts):
                     w_day = weather_forecasts[delta]
            
            # Predict
            feat_df = fe.prepare_features_for_prediction(current_history, w_day)
            
            # Ensure features match model expectation
            # Fill missing cols with 0
            for f in features_list:
                if f not in feat_df.columns:
                    feat_df[f] = 0
            
            X = feat_df[features_list]
            pred_price = model.predict(X)[0]
            
            # Update History
            avg_arrivals = current_history['arrivals'].tail(7).mean()
            if pd.isna(avg_arrivals): avg_arrivals = 100 # Default
            
            new_row = {
                "date": target_date, "mandi": mandi, "commodity": commodity,
                "modal_price": pred_price, "arrivals": avg_arrivals,
                "min_price": pred_price, "max_price": pred_price
            }
            current_history = pd.concat([current_history, pd.DataFrame([new_row])], ignore_index=True)
            last_date = target_date
            
            if target_date >= today:
                preds.append({
                    "date": target_date.strftime("%Y-%m-%d"),
                    "predicted_price": round(float(pred_price), 2),
                    "source": "predicted"
                })
                needed -= 1

        return preds

    except Exception as e:
        print(f"CRITICAL ERROR in prediction logic: {e}. Returning fallback.")
        import traceback
        traceback.print_exc()
        # FALLBACK: If ANYTHING fails, return valid mock data
        return generate_mock(5200, seed_str=f"{mandi}_{commodity}")
    
class UpdateProfileRequest(BaseModel):
    name: str # Use name to identify user for simplicity in this demo
    state: str
    mandi: str
    crops: list[str]

@app.post("/update_profile")
def update_profile(req: UpdateProfileRequest):
    updated = False
    rows = []
    
    # Read all rows
    if os.path.exists(FARMERS_FILE):
        with open(FARMERS_FILE, "r") as f:
            reader = csv.DictReader(f)
            for row in reader:
                if row["name"] == req.name:
                    row["state"] = req.state
                    row["mandi"] = req.mandi
                    row["crops"] = "|".join(req.crops)
                    updated = True
                rows.append(row)
    
    if updated:
        with open(FARMERS_FILE, "w", newline="") as f:
            writer = csv.DictWriter(f, fieldnames=["id", "name", "password", "state", "mandi", "crops"])
            writer.writeheader()
            writer.writerows(rows)
        return {"status": "success", "message": "Profile updated"}
        
    raise HTTPException(status_code=404, detail="User not found")


# ... existing code ...

import csv
import uuid
import os

# Robust path resolution for CSV file
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
FARMERS_FILE = os.path.join(BASE_DIR, "farmers_data.csv")

# Ensure farmers file exists
if not os.path.exists(FARMERS_FILE):
    with open(FARMERS_FILE, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["id", "name", "password", "state", "mandi", "crops"])

class RegisterRequest(BaseModel):
    name: str
    password: str
    state: str
    mandi: str
    crops: list[str]

@app.post("/register")
def register(req: RegisterRequest):
    # Check if user exists
    with open(FARMERS_FILE, "r") as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row["name"] == req.name:
                raise HTTPException(status_code=400, detail="User already exists")
    
    user_id = str(uuid.uuid4())
    # Join crops with pipe | to store in CSV
    crops_str = "|".join(req.crops)
    
    with open(FARMERS_FILE, "a", newline="") as f:
        writer = csv.writer(f)
        writer.writerow([user_id, req.name, req.password, req.state, req.mandi, crops_str])
        


    return {"status": "success", "user_id": user_id, "message": "Registration successful"}

class LoginRequest(BaseModel):
    name: str
    password: str

@app.post("/login")
def login(req: LoginRequest):
    with open(FARMERS_FILE, "r") as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row["name"] == req.name and row["password"] == req.password:
                # Parse crops back to list
                row["crops"] = row["crops"].split("|")
                return {"status": "success", "user": row}
                
    raise HTTPException(status_code=401, detail="Invalid credentials")

class DashboardRequest(BaseModel):
    state: str
    mandi: str
    crops: list[str]

@app.post("/dashboard")
def get_dashboard(req: DashboardRequest):
    import traceback
    try:
        # 1. Weather (Mock/Simulated based on State/Mandi)
        # We'll use a simple mapping or default
        # Real app would use a weather API based on lat/lon of the Mandi
        lat, lon = (20.5937, 78.9629) # Default
        if req.state == "Andhra Pradesh": lat, lon = (15.9129, 79.7400)
        elif req.state == "Maharashtra": lat, lon = (19.7515, 75.7139)
        # ... add more rough coords if needed
        
        # Fetch 10-day forecast ONCE for both Today's Card AND Future Predictions
        weather_forecast = get_forecast(lat, lon, days=10)
        
        today_weather = {"temp_max": 30, "condition": "Sunny"} # Default
        if weather_forecast:
            daily = weather_forecast[0]
            # weather_service returns: {date, temp_avg, humidity, rain_mm}
            # We need {temp_max, condition} for the UI
            # prioritizing CURRENT temp if available
            current_temp = daily.get('temp_now', daily.get('temp_avg', 30))
            
            cond = "Sunny"
            if daily.get('rain_mm', 0) > 0.5:
                cond = "Rainy"
            elif daily.get('humidity', 0) > 70:
                cond = "Cloudy"
                
            today_weather = {
                "temp_max": current_temp, # Displays CURRENT temp in the UI card
                "condition": cond,
                "humidity": daily.get('humidity_now', daily.get('humidity', 50)),
                "rain_mm": daily.get('rain_mm', 0)
            }
        
        # Add Disaster Alert (Mock)
        alert = None
        if "rain" in str(today_weather.get("condition", "")).lower():
             alert = "Heavy rains expected. Protect harvested crops."
        
        # 2. Personalized Crop Predictions (Graph Data)
        graph_data = [] 
        recommendations = []
        
        from real_time_data import get_real_time_price
        
        for crop in req.crops:
            # Try to get TODAY'S real price
            real_data = get_real_time_price(req.mandi, crop, req.state)
            
            # Pass cached weather to prevent redundant API calls
            prices = _get_future_prices(req.mandi, crop, days=7, weather_cache=weather_forecast)
            
            # Determine "Today's Display Price" and STATUS
            today_label = "Not Updated"
            today_price_numeric = 0.0
            today_status = "unknown" # verified, predicted, estimated
            
            if real_data:
                 today_label = f"₹{real_data['price']}"
                 today_price_numeric = real_data['price']
                 today_status = "verified"
            elif prices and len(prices) > 0:
                 # Fallback to prediction if real data missing
                 first_pred = prices[0]
                 pred_price = first_pred['predicted_price']
                 
                 today_label = f"₹{pred_price}"
                 today_price_numeric = pred_price
                 today_status = first_pred.get('source', 'estimated')
                 
            series = {
                "name": crop,
                "current_price_label": today_label,
                "current_status": today_status, # NEW FIELD
                "points": [{"date": p["date"], "price": p["predicted_price"], "source": p.get("source", "estimated")} for p in prices]
            }
            graph_data.append(series)
                
            if prices and len(prices) > 0:
                # Simple Recommendation Logic
                # Find the day with the highest predicted price
                max_p = max(prices, key=lambda x: x['predicted_price'])
                
                # Only recommend if the max price is significantly higher (e.g. > 5%) than today?
                # For now, just show the best day to sell.
                recommendations.append({
                    "crop": crop,
                    "action": f"Sell on {max_p['date']}",
                    "best_price": max_p['predicted_price'],
                    "details": f"Price expected to reach ₹{max_p['predicted_price']}",
                    "icon": "trending_up" # Frontend can map this to an icon
                })

        # ... (rest of function)
        return {
            "weather": {
                "location": req.mandi,
                "today": today_weather,
                "alert": alert
            },
            "graph_data": graph_data,
            "recommendations": recommendations # Placeholder
        }
    except Exception as e:
        print(traceback.format_exc())
        raise HTTPException(status_code=500, detail=str(e))



@app.post("/update_data")
def update_data(days: int = 7):
    """
    Triggers manual update from OGD API.
    """
    from ogd_service import OGDService
    try:
        service = OGDService()
        service.update_database(days_history=days)
        return {"status": "success", "message": f"Database updated with last {days} days of data."}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/train")
def trigger_training():
    """
    Triggers model retraining.
    """
    from model_utils import train_models
    try:
        train_models()
        return {"status": "success", "message": "Models retrained successfully."}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    import sys
    try:
        uvicorn.run(app, host="0.0.0.0", port=8000)
    except OSError as e:
        if e.winerror == 10048:
            print("===============================================================")
            print("⚠️  SERVER ALREADY RUNNING  ⚠️")
            print("You tried to start the server, but it's already active.")
            print("You can safely IGNORE this error. Your app will work fine.")
            print("===============================================================")
            pass
        else:
            raise e
    except SystemExit:
        print("Server stopped (Port 8000 was active).")
        pass

