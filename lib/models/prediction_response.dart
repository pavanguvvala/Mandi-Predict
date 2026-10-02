class PredictionPoint {
  final DateTime date;
  final double predictedPrice;

  PredictionPoint({required this.date, required this.predictedPrice});

  factory PredictionPoint.fromJson(Map<String, dynamic> json) {
    return PredictionPoint(
      date: DateTime.parse(json['date']),
      predictedPrice: (json['predicted_price'] as num).toDouble(),
    );
  }
}

class PredictionResponse {
  final String mandi;
  final String commodity;
  final String currency;
  final List<PredictionPoint> predictions;
  final Map<String, dynamic> meta;

  PredictionResponse({
    required this.mandi,
    required this.commodity,
    required this.currency,
    required this.predictions,
    required this.meta,
  });

  factory PredictionResponse.fromJson(Map<String, dynamic> json) {
    var list = json['predictions'] as List;
    List<PredictionPoint> predictionList = list
        .map((i) => PredictionPoint.fromJson(i))
        .toList();

    return PredictionResponse(
      mandi: json['mandi'],
      commodity: json['commodity'],
      currency: json['currency'],
      predictions: predictionList,
      meta: json['meta'],
    );
  }

  double get minPredictedPrice {
    if (predictions.isEmpty) return 0;
    return predictions
        .map((p) => p.predictedPrice)
        .reduce((a, b) => a < b ? a : b);
  }

  double get maxPredictedPrice {
    if (predictions.isEmpty) return 0;
    return predictions
        .map((p) => p.predictedPrice)
        .reduce((a, b) => a > b ? a : b);
  }
}
