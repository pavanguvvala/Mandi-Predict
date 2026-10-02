# Mandi Price Prediction Backend

## Setup

1. Navigate to `backend` folder.
2. Create virtual environment (optional): `python -m venv venv`
3. Activate venv: `.\venv\Scripts\activate` (Windows)
4. Install dependencies:
   ```
   pip install -r requirements.txt
   ```
5. Create `.env` file (optional) with `OPENWEATHER_API_KEY=your_key` if you want real weather data.

> **Note**: The repository does not include the large `mandi_data.csv` historical dataset. The system is designed to use **Smart Fallback (Mock Data)** if real data is missing, so it will work immediately out of the box for demonstration purposes. To get real predictions, you would need to populate `mandi_data.csv` using the included `data_fetcher.py` script or import your own Agmarknet data.

## Running

Start the server:

```bash
uvicorn main:app --reload
```

## Endpoints

- `GET /health`
- `GET /options`
- `POST /predict` body: `{"mandi": "Lasalgaon", "commodity": "Onion"}`

## Training

Models are trained automatically on startup if not found. To retrain, delete the `models/` directory and restart.
