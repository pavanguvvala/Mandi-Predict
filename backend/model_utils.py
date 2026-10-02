import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_absolute_error, mean_squared_error
import joblib
import os

MODELS_DIR = os.path.join(os.path.dirname(__file__), "models")
os.makedirs(MODELS_DIR, exist_ok=True)

class DataLoader:
    _cached_df = None

    def __init__(self, filepath=None):
        if filepath is None:
            self.filepath = os.path.join(os.path.dirname(__file__), "mandi_data.csv")
        else:
            self.filepath = filepath

    def load_data(self):
        if DataLoader._cached_df is not None:
            return DataLoader._cached_df.copy()

        print(f"Loading data from {self.filepath}...")
        df = pd.read_csv(self.filepath)
        df['date'] = pd.to_datetime(df['date'])
        
        # Fill missing modal_price forward
        df.sort_values(by=['mandi', 'commodity', 'date'], inplace=True)
        df['modal_price'] = df.groupby(['mandi', 'commodity'])['modal_price'].ffill()
        
        DataLoader._cached_df = df
        return df.copy()

    def filter_data(self, df, mandi, commodity):
        mask = (df['mandi'] == mandi) & (df['commodity'] == commodity)
        return df[mask].copy()

class FeatureEngineer:
    def create_features(self, df, is_training=True):
        """
        Creates feature set for the model.
        Expects a dataframe sorted by date for a single (mandi, commodity).
        """
        df = df.copy()
        
        # Lags
        # modal_price_t-1, t-2, t-3, t-7
        df['lag_price_1'] = df['modal_price'].shift(1)
        df['lag_price_2'] = df['modal_price'].shift(2)
        df['lag_price_3'] = df['modal_price'].shift(3)
        df['lag_price_7'] = df['modal_price'].shift(7)
        
        # Lag arrivals
        df['lag_arrivals_1'] = df['arrivals'].shift(1)
        df['lag_arrivals_7'] = df['arrivals'].shift(7)
        
        # Rolling averages (computed on shifted data to avoid leakage if we used current row)
        # But usually in timeseries creation row 't' uses history up to t-1.
        # Here target is 'next day price' or 'current day price'?
        # Prompt says: "Target: next day’s modal_price."
        # If target is t+1 price, then features at row t can be current t stats.
        # BUT, if we are predicting for TOMORROW (t+1), we know today's (t) price.
        # So features can be today's price, yesterday's etc.
        # Let's align such that row T contains features known at time T to predict T+1.
        # Or, usually easier: Row T contains features known at T, and target is T.
        # Then for prediction, we construct features for T+1.
        
        # Let's stick to standard Approach:
        # Row has Date D.
        # Features: lags from D-1, D-2... (or D if we know D's price is finalized)
        # Target: Price at D.
        # Wait, if we want to predict Future, we usually train to predict X[t] based on X[t-1]...
        
        # Prompt: "Target: next day’s modal_price."
        # So at row 'date', we have features derived from 'date' and history. Target is 'date + 1' price.
        
        # However, to simplify 'sequential' prediction:
        # It's cleaner to train a model: $P_t = f(P_{t-1}, P_{t-2}, ...)$
        # So row T has target $P_t$ and features $P_{t-1}$ etc.
        # This is exactly what `shift(1)` gives us. `lag_price_1` at row T is Price at T-1.
        # So we can just dropna() and train to predict `modal_price` (which is Price at T) using lags.
        
        # Rolling stats
        # These should be based on previous days.
        # So rolling mean of last 7 days excluding today (if we pretend we are at T and don't know T yet? No, we know T's price when predicting T+1?)
        # Let's assume standard autoregressive:
        # To predict Price(T), we use Price(T-1), Price(T-2)...
        
        df['avg_price_7'] = df['modal_price'].shift(1).rolling(window=7).mean()
        df['avg_price_30'] = df['modal_price'].shift(1).rolling(window=30).mean()
        df['avg_arrivals_7'] = df['arrivals'].shift(1).rolling(window=7).mean()
        
        # Calendar features
        df['day_of_week'] = df['date'].dt.dayofweek
        df['month'] = df['date'].dt.month
        
        # Weather stub - just zeros if not provided or merged later
        # We will assume they are added if available, else 0
        if 'temp_avg' not in df.columns: df['temp_avg'] = 0
        if 'humidity' not in df.columns: df['humidity'] = 0
        if 'rain_mm' not in df.columns: df['rain_mm'] = 0
        
        # Drop rows with NaN created by shifts
        if is_training:
            df.dropna(inplace=True)
            
        return df

    def prepare_features_for_prediction(self, history_df, weather_forecast=None):
        """
        Constructs a SINGLE feature row for the next step prediction.
        history_df: DataFrame containing past data up to T-1.
        weather_forecast: dict with keys 'temp_avg', 'humidity', 'rain_mm' for the target day.
        
        Returns: DataFrame (1 row) with feature columns.
        """
        # We need to construct a row that looks like the training data.
        # To predict T, we need T-1, T-2...
        # history_df should have at least 30 days of data to compute rolling 30.
        
        last_date = history_df['date'].max()
        target_date = last_date + pd.Timedelta(days=1)
        
        # Get last values
        p_last = history_df['modal_price'].iloc[-1]
        p_lag2 = history_df['modal_price'].iloc[-2]
        p_lag3 = history_df['modal_price'].iloc[-3]
        p_lag7 = history_df['modal_price'].iloc[-7] if len(history_df) >= 7 else p_last # fallback
        
        a_last = history_df['arrivals'].iloc[-1]
        a_lag7 = history_df['arrivals'].iloc[-7] if len(history_df) >= 7 else a_last
        
        # Rolling (using tail of history)
        avg_price_7 = history_df['modal_price'].tail(7).mean()
        avg_price_30 = history_df['modal_price'].tail(30).mean()
        avg_arrivals_7 = history_df['arrivals'].tail(7).mean()
        
        row = {
            'lag_price_1': p_last,
            'lag_price_2': p_lag2,
            'lag_price_3': p_lag3,
            'lag_price_7': p_lag7,
            'lag_arrivals_1': a_last,
            'lag_arrivals_7': a_lag7,
            'avg_price_7': avg_price_7,
            'avg_price_30': avg_price_30,
            'avg_arrivals_7': avg_arrivals_7,
            'day_of_week': target_date.dayofweek,
            'month': target_date.month,
            'temp_avg': weather_forecast.get('temp_avg', 0) if weather_forecast else 0,
            'humidity': weather_forecast.get('humidity', 0) if weather_forecast else 0,
            'rain_mm': weather_forecast.get('rain_mm', 0) if weather_forecast else 0,
        }
        
        return pd.DataFrame([row])

def train_models():
    print("Loading data...")
    loader = DataLoader()
    df = loader.load_data()
    
    # Get all unique pairs
    pairs = df[['mandi', 'commodity']].drop_duplicates().values.tolist()
    
    fe = FeatureEngineer()
    
    for mandi, commodity in pairs:
        print(f"Processing {mandi} - {commodity}...")
        sub_df = loader.filter_data(df, mandi, commodity)
        
        if sub_df.empty:
            print("No data found, skipping.")
            continue
            
        # Add stub weather for training if missing in CSV
        sub_df['temp_avg'] = 0
        sub_df['humidity'] = 0
        sub_df['rain_mm'] = 0
        
        train_df = fe.create_features(sub_df)
        
        if len(train_df) < 10:
            print("Not enough data to train.")
            continue
        
        features = ['lag_price_1', 'lag_price_2', 'lag_price_3', 'lag_price_7',
                    'lag_arrivals_1', 'lag_arrivals_7', 
                    'avg_price_7', 'avg_price_30', 'avg_arrivals_7',
                    'day_of_week', 'month', 'temp_avg', 'humidity', 'rain_mm']
        
        target = 'modal_price'
        
        # Split by date
        split_idx = int(len(train_df) * 0.8)
        train = train_df.iloc[:split_idx]
        test = train_df.iloc[split_idx:]
        
        X_train = train[features]
        y_train = train[target]
        X_test = test[features]
        y_test = test[target]
        
        if len(X_train) == 0 or len(X_test) == 0:
            print("Split resulted in empty set.")
            continue
            
        model = RandomForestRegressor(n_estimators=100, random_state=42)
        model.fit(X_train, y_train)
        
        # Eval
        preds = model.predict(X_test)
        mae = mean_absolute_error(y_test, preds)
        rmse = np.sqrt(mean_squared_error(y_test, preds))
        
        print(f"Model {mandi}-{commodity}: MAE={mae:.2f}, RMSE={rmse:.2f}")
        
        # Save info
        # Sanitize names to remove slashes/invalid chars
        safe_mandi = mandi.replace("/", "_").replace("\\", "_").replace(":", "_")
        safe_commodity = commodity.replace("/", "_").replace("\\", "_").replace(":", "_")
        
        model_path = os.path.join(MODELS_DIR, f"model_{safe_mandi}_{safe_commodity}.joblib")
        
        joblib.dump({
            'model': model,
            'mae': mae,
            'rmse': rmse,
            'features': features
        }, model_path)

if __name__ == "__main__":
    train_models()
