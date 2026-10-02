import requests
import datetime

def get_forecast(lat, lon, days=7):
    """
    Fetches 7-day forecast from Open-Meteo (Free, No Key).
    Returns a list of dicts: { "date": "YYYY-MM-DD", "temp_avg": float, "humidity": float, "rain_mm": float }
    """
    forecast = []
    try:
        # Open-Meteo API (Free for non-commercial use, excellent for this demo)
        # Added &current=...
        url = f"https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&current=temperature_2m,relative_humidity_2m,weather_code&daily=temperature_2m_max,relative_humidity_2m_mean,precipitation_sum&timezone=auto&forecast_days={days}"
        
        response = requests.get(url, timeout=5)
        response.raise_for_status()
        data = response.json()
        
        # 1. Parse Current Weather
        current = data.get("current", {})
        temp_now = current.get("temperature_2m", 0.0)
        hum_now = current.get("relative_humidity_2m", 0.0)
        code_now = current.get("weather_code", 0)

        # 2. Parse Daily
        daily = data.get("daily", {})
        dates = daily.get("time", [])
        temps = daily.get("temperature_2m_max", [])
        hums = daily.get("relative_humidity_2m_mean", []) 
        if not hums: hums = [50] * len(dates)
        rains = daily.get("precipitation_sum", [])
        
        for i in range(len(dates)):
            day_data = {
                "date": dates[i],
                "temp_max": temps[i] if i < len(temps) else 30.0, # Renamed key for clarity, but keeping compat logic below
                "temp_avg": temps[i] if i < len(temps) else 30.0, # Keeping old key for compatibility
                "humidity": hums[i] if i < len(hums) else 50.0,
                "rain_mm": rains[i] if i < len(rains) else 0.0
            }
            # Inject Current Temp into TODAY (first element)
            if i == 0:
                day_data["temp_now"] = temp_now
                day_data["humidity_now"] = hum_now
                day_data["code_now"] = code_now
            
            forecast.append(day_data)
            
    except Exception as e:
        print(f"Open-Meteo failed: {e}")
        # Fallback
        today = datetime.date.today()
        for i in range(days):
            date = today + datetime.timedelta(days=i)
            forecast.append({
                "date": date.strftime("%Y-%m-%d"),
                "temp_avg": 25.0, 
                "temp_max": 25.0,
                "temp_now": 25.0 if i == 0 else None,
                "humidity": 50.0,
                "rain_mm": 0.0
            })
            
    return forecast
