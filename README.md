# 🌾 MandiPredict - Smart Agricultural Price Forecasting

**MandiPredict** is an AI-powered application designed to empower Indian farmers by providing accurate, real-time market price predictions for their crops. 

By combining historical data analysis with machine learning, MandiPredict helps farmers make informed decisions about **when** and **where** to sell their produce to maximize profits. It also features a Generative AI assistant to answer farming-related queries in local languages.

## ✨ Key Features

*   **📈 Price Prediction**: Powered by a robust **Random Forest Regression model**, this feature forecasts crop prices for the next 7 days by analyzing historical price trends, potential yield, and seasonality.
*   **🤖 AI Kisan Sahayak**: A built-in chatbot powered by **Google Gemini AI** that answers farmers' questions about crop diseases, fertilizers, and techniques in **Hindi, Telugu, and English**.
*   **📍 Mandi Optimization**: unique logic that calculates the "Best Mandi to Sell" by analyzing current prices, transport costs, and storage costs to recommend the most profitable option.
*   **🌦️ Weather Integration**: Real-time 10-day weather forecasts to help plan harvesting and storage.
*   **📊 Interactive Dashboard**: Visual graphs and charts (Line & Bar) to track price trends easily.
*   **📱 Multi-Language Support**: Designed to be accessible to farmers across different regions.

## 🛠️ Technology Stack

This project is built using a robust modern tech stack:

### **Mobile App (Frontend)**
*   **Framework**: [Flutter](https://flutter.dev/) (Dart) - for a beautiful, native cross-platform experience.
*   **State Management**: Provider / Riverpod.
*   **Charts**: `fl_chart` for visualizing price trends.
*   **HTTP**: `dio` / `http` for API communication.

### **Backend & AI**
*   **Framework**: [FastAPI](https://fastapi.tiangolo.com/) (Python) - High-performance backend.
*   **Machine Learning**: **Random Forest Regression** (`scikit-learn`) for high-accuracy price forecasting.
*   **GenAI**: **Google Gemini 1.5 Flash** for the conversational assistant.
*   **Data Source**: Scraping capabilities for **Agmarknet** (Government of India) data.
