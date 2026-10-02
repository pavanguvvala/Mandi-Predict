import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/prediction_response.dart';
import '../services/localization.dart';
// import '../main.dart'; // for localeNotifier

class ResultScreen extends StatefulWidget {
  final Map<String, dynamic>? optimizeResult;
  final PredictionResponse? prediction;
  final bool isQuintal;

  const ResultScreen({
    super.key,
    this.optimizeResult,
    this.prediction,
    this.isQuintal = true,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late bool _isQuintal;

  @override
  void initState() {
    super.initState();
    _isQuintal = widget.isQuintal;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: localeNotifier,
      builder: (context, locale, child) {
        // If optimizeResult exists, show optimization UI.
        if (widget.optimizeResult != null) {
          return _buildOptimizationUI(context, locale);
        }
        // If prediction exists, show Standard UI (Forecast).
        if (widget.prediction != null) {
          return _buildStandardUI(context, locale);
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.get(locale, 'results')),
            backgroundColor: Colors.green,
          ),
          body: const Center(child: Text("No data available.")),
        );
      },
    );
  }

  Widget _buildStandardUI(BuildContext context, String locale) {
    // Map PredictionResponse to the format expected by _buildGenericChart
    final chartData = widget.prediction!.predictions.asMap().entries.map((e) {
      double factor = _isQuintal ? 1.0 : 100.0;
      return {
        'date': e.value.date.toString().substring(0, 10),
        'predicted_price': e.value.predictedPrice / factor,
        'day_offset': e.key,
      };
    }).toList();

    String unit = _isQuintal ? "/Q" : "/kg";

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.prediction!.mandi} - ${widget.prediction!.commodity}',
        ),
        backgroundColor: const Color(0xFF1B5E20), // Dark Green
        foregroundColor: Colors.white,
        actions: [
          Row(
            children: [
              Text(
                _isQuintal
                    ? AppLocalizations.get(locale, 'unit_q')
                    : AppLocalizations.get(locale, 'unit_kg'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Switch(
                value: _isQuintal,
                activeThumbColor: Colors.white,
                onChanged: (val) {
                  setState(() {
                    _isQuintal = val;
                  });
                },
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${AppLocalizations.get(locale, 'market_forecast')} (₹$unit)",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            SizedBox(height: 250, child: _buildGenericChart(chartData)),
            const SizedBox(height: 20),

            Text(
              AppLocalizations.get(locale, 'details'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.prediction!.predictions.length,
              itemBuilder: (ctx, i) {
                final p = widget.prediction!.predictions[i];
                double factor = _isQuintal ? 1.0 : 100.0;
                double price = p.predictedPrice / factor;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFC8E6C9),
                      foregroundColor: const Color(0xFF1B5E20),
                      child: Text("${i + 1}d"),
                    ),
                    title: Text(
                      "${AppLocalizations.get(locale, 'date')}: ${p.date.toString().substring(0, 10)}",
                    ),
                    trailing: Text(
                      "₹${price.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimizationUI(BuildContext context, String locale) {
    final bestAction = widget.optimizeResult!['best_action'];
    final alternatives = widget.optimizeResult!['alternatives'] as List;
    final recText = widget.optimizeResult!['recommendation_text'];
    String unit = _isQuintal ? "q" : "kg";
    double factor = _isQuintal ? 1.0 : 100.0;

    // Handle case where no profitable option found (bestAction might be null)
    if (bestAction == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.get(locale, 'best_profit_calc')),
          backgroundColor: const Color(0xFF1B5E20), // Dark Green
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text("No profitable options found within constraints."),
        ),
      );
    }

    // We need to pass converted data to the chart too
    final chartData = alternatives.map((e) {
      final p = (e['predicted_price'] as num).toDouble();
      return {...e, 'predicted_price': p / factor};
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.get(locale, 'best_profit_calc')),
        backgroundColor: const Color(0xFF1B5E20), // Dark Green
        foregroundColor: Colors.white,
        actions: [
          Row(
            children: [
              Text(
                _isQuintal
                    ? AppLocalizations.get(locale, 'unit_q')
                    : AppLocalizations.get(locale, 'unit_kg'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Switch(
                value: _isQuintal,
                activeThumbColor: Colors.white,
                onChanged: (val) {
                  setState(() {
                    _isQuintal = val;
                  });
                },
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 0. Chart (Restored)
            Text(
              "${AppLocalizations.get(locale, 'price_trend')} (₹/$unit)",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            SizedBox(height: 200, child: _buildGenericChart(chartData)),
            const SizedBox(height: 20),

            // 1. Hero Card: Best Action
            Card(
              color: Colors.green.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: const BorderSide(color: Colors.green, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.verified,
                          color: Colors.green,
                          size: 30,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.get(locale, 'rec_action'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 10),
                    Text(
                      recText, // This comes from backend-generated string, might need backend localization or client logic. Keeping as is for now.
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "${AppLocalizations.get(locale, 'net_profit')}: ₹${bestAction['net_profit']}",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: (bestAction['net_profit'] as num) < 0
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. Alternatives List
            Text(
              AppLocalizations.get(locale, 'details'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: alternatives.length,
              itemBuilder: (ctx, i) {
                final item = alternatives[i];
                final isBest = i == 0;
                final price =
                    (item['predicted_price'] as num).toDouble() / factor;

                return Card(
                  elevation: isBest ? 4 : 1,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isBest
                          ? ((item['net_profit'] as num) < 0
                                ? Colors.red
                                : Colors.green)
                          : Colors.grey.shade300,
                      child: Text(
                        "${item['day_offset']}d",
                        style: TextStyle(
                          color: isBest ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      "${AppLocalizations.get(locale, 'sell_recc')} ${item['date']} @ ₹${price.toStringAsFixed(2)}/$unit",
                    ),
                    subtitle: Text(
                      "${AppLocalizations.get(locale, 'revenue')}: ₹${item['revenue']} - ${AppLocalizations.get(locale, 'costs')}: ₹${item['costs']}",
                    ),
                    trailing: Text(
                      "₹${item['net_profit']}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: (item['net_profit'] as num) < 0
                            ? Colors.red
                            : (isBest ? Colors.green : Colors.black),
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenericChart(List<dynamic> alternatives) {
    // Sort by date/day_offset for plotting
    final sorted = List.from(alternatives)
      ..sort((a, b) => (a['day_offset'] as int).compareTo(b['day_offset']));

    if (sorted.isEmpty) return const Center(child: Text("No Data"));

    final prices = sorted
        .map((e) => (e['predicted_price'] as num).toDouble())
        .toList();
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < sorted.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      "${sorted[index]['day_offset']}d",
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
              interval: 1,
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minY: minPrice * 0.9,
        maxY: maxPrice * 1.1,
        lineBarsData: [
          LineChartBarData(
            spots: sorted.asMap().entries.map((e) {
              return FlSpot(
                e.key.toDouble(),
                (e.value['predicted_price'] as num).toDouble(),
              );
            }).toList(),
            isCurved: true,
            color: const Color(0xFF1B5E20), // Dark Green
            barWidth: 3,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF1B5E20).withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}
