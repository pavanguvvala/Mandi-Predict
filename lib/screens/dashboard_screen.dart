import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'chat_screen.dart';

import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/localization.dart';
import '../widgets/side_menu.dart';
import '../widgets/farmer_loader.dart';
import '../widgets/prediction_badge.dart'; // NEW
import '../services/data_localization.dart';
// import '../main.dart'; // For localeNotifier

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String? _error;
  bool _isQuintal = true; // Default to Quintal
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
    // Auto-refresh every 30 minutes for accurate weather
    _timer = Timer.periodic(const Duration(minutes: 30), (timer) {
      _fetchDashboard();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchDashboard() async {
    final user = AuthService.currentUser;
    if (user == null) return;

    final url = Uri.parse('${MandiApiService.baseUrl}/dashboard');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'state': user['state'],
          'mandi': user['mandi'],
          'crops': user['crops'],
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _dashboardData = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        debugPrint(
          "Dashboard Error: ${response.statusCode} - ${response.body}",
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Dashboard Error: $e");
      setState(() {
        _isLoading = false;
        _error = "Network error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: localeNotifier,
      builder: (context, locale, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.get(locale, 'dashboard')),
            backgroundColor: const Color(0xFF1B5E20), // Match Login
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
                    activeTrackColor: Colors.green.shade800,
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

          drawer: const SideMenu(),
          body: _isLoading
              ? const FarmerLoadingWidget(message: "Fetching mandi rates...")
              : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Connection Error',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _fetchDashboard,
                        icon: const Icon(Icons.refresh),
                        label: Text(AppLocalizations.get(locale, 'retry')),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchDashboard,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [_buildDashboardContent()],
                    ),
                  ),
                ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: const Color(0xFF1B5E20), // Match Theme
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            label: Text(
              AppLocalizations.get(locale, 'ask_assistant'),
              style: const TextStyle(color: Colors.white),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatScreen()),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDashboardContent() {
    if (_dashboardData == null) return const SizedBox.shrink();

    final weather = _dashboardData!['weather'];
    final alert = weather['alert'];
    final graphData = _dashboardData!['graph_data'] as List;
    final locale = localeNotifier.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Weather Section - Green Gradient Card (Match Theme)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF1B5E20),
                Color(0xFF43A047),
              ], // Deep Green to Lighter Green
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B5E20).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.get(locale, 'weather'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Icon(
                    Icons.wb_sunny_rounded,
                    color: Colors.yellow,
                    size: 32,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                DataLocalization.get(weather['location'], locale),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "${weather['today']['temp_max']}°C",
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                weather['today']['condition'] == "Sunny"
                    ? (locale == 'hi' ? "साफ़ मौसम" : "Sunny")
                    : weather['today']['condition'] == "Rainy"
                    ? (locale == 'hi' ? "बरसात" : "Rainy")
                    : weather['today']['condition'],
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              if (alert != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          alert,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 30),

        // 2. My Crop Trends
        Text(
          AppLocalizations.get(locale, 'trends'),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildMultiLineChart(graphData),
        const SizedBox(height: 30),

        // 3. Smart Advisory
        Row(
          children: [
            const Icon(Icons.psychology_alt, color: Color(0xFF1B5E20)),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.get(locale, 'smart_advisory'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1B5E20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_dashboardData!['recommendations'] == null ||
            (_dashboardData!['recommendations'] as List).isEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              AppLocalizations.get(locale, 'no_alerts'),
              style: const TextStyle(color: Colors.grey),
            ),
          )
        else
          ...(_dashboardData!['recommendations'] as List).map((rec) {
            return Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(
                  color: Color(0xFF43A047),
                  width: 1,
                ), // Green Border
              ),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFE8F5E9),
                  child: const Icon(
                    Icons.trending_up,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                title: Text(
                  rec['action'] ?? "",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                subtitle: Text(
                  rec['details'] ?? "",
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
            );
          }),

        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildMultiLineChart(List seriesList) {
    if (seriesList.isEmpty) return const Center(child: Text("No Data"));

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: seriesList.length,
      itemBuilder: (ctx, index) {
        final series = seriesList[index];
        final points = series['points'] as List;
        final cropName = series['name'];
        final locale = localeNotifier.value;

        // Label Logic
        String priceLabel = series['current_price_label'] ?? "Not Updated";

        // CONVERSION LOGIC
        double factor = _isQuintal ? 1.0 : 100.0;
        String unit = _isQuintal ? "/Q" : "/kg";

        // Try to parse the label number
        String cleanLabel = priceLabel.replaceAll("(Est)", "").trim();
        if (cleanLabel != "Not Updated" && cleanLabel.startsWith("₹")) {
          try {
            double val = double.parse(cleanLabel.replaceAll("₹", "").trim());
            val = val / factor;
            priceLabel = "₹${val.toStringAsFixed(1)}$unit";
            if (series['current_price_label'].contains("(Est)")) {
              priceLabel += " ${AppLocalizations.get(locale, 'est')}";
            }
          } catch (e) {
            // Keep original
          }
        }

        final isUpdated = !priceLabel.contains("Not Updated");

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: index == 0,
              leading: CircleAvatar(
                backgroundColor: Colors.orange.shade100,
                child: Text(
                  cropName[0],
                  style: const TextStyle(color: Colors.orange),
                ),
              ),
              title: Text(
                DataLocalization.get(cropName, locale),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Row(
                children: [
                  Text(
                    AppLocalizations.get(locale, 'today_label'),
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                  Text(
                    priceLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isUpdated ? Colors.black : Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isUpdated)
                    PredictionBadge(
                      status: series['current_status'] ?? 'unknown',
                      locale: locale,
                    ),
                ],
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    children: [
                      // Warning Box
                      if (priceLabel.contains("Not Updated") ||
                          priceLabel.contains("Est"))
                        Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  AppLocalizations.get(locale, 'not_updated'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.get(locale, 'col_date'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            "${AppLocalizations.get(locale, 'col_price')} (₹${_isQuintal ? '/Q' : '/kg'})",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            AppLocalizations.get(locale, 'col_trend'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      // Data Rows
                      ...points.map((point) {
                        final pIdx = points.indexOf(point);
                        final rawPrice = (point['price'] as num).toDouble();
                        final rawPrevPrice = pIdx > 0
                            ? (points[pIdx - 1]['price'] as num).toDouble()
                            : rawPrice;

                        final price = rawPrice / factor;
                        final prevPrice = rawPrevPrice / factor;

                        IconData trendIcon = Icons.remove;
                        Color trendColor = Colors.grey;

                        if (price > prevPrice) {
                          trendIcon = Icons.trending_up;
                          trendColor = Colors.green;
                        } else if (price < prevPrice) {
                          trendIcon = Icons.trending_down;
                          trendColor = Colors.red;
                        }

                        final dateStr = point['date'];
                        final date = DateTime.parse(dateStr);
                        final formattedDate = "${date.day}/${date.month}";

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(formattedDate),
                              Text(
                                "₹${price.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Icon(trendIcon, color: trendColor, size: 20),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
