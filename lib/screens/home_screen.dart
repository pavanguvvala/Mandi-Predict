import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/localization.dart';
import '../services/data_localization.dart';
// import '../main.dart'; // for localeNotifier
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MandiApiService _apiService = MandiApiService();

  // Master Data: {State: {Mandi: [Commodities]}}
  Map<String, dynamic> _masterData = {};

  List<String> _states = [];
  List<String> _mandis = [];
  List<String> _commodities = [];

  String? _selectedState;
  String? _selectedMandi;
  String? _selectedCommodity;

  // New Controller Fields - Empty by default
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _storageController = TextEditingController();
  final TextEditingController _storageCostController = TextEditingController();
  final TextEditingController _transportCostController =
      TextEditingController();
  final TextEditingController _distController = TextEditingController();

  bool _isLoadingOptions = true;
  String? _error;
  bool _isQuintal = true;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    setState(() {
      _isLoadingOptions = true;
      _error = null;
    });

    try {
      final options = await _apiService.fetchOptions();
      setState(() {
        _masterData = options;
        _states = _masterData.keys.toList();
        _states.sort();

        if (_states.isNotEmpty) {
          _selectedState = _states[0];
          _updateMandis();
        }

        _isLoadingOptions = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingOptions = false;
      });
    }
  }

  void _updateMandis() {
    if (_selectedState == null) return;
    final mandisMap = _masterData[_selectedState] as Map<String, dynamic>;
    _mandis = mandisMap.keys.toList();
    _mandis.sort();

    if (_mandis.isNotEmpty) {
      _selectedMandi = _mandis[0];
      _updateCommodities();
    } else {
      _selectedMandi = null;
      _commodities = [];
      _selectedCommodity = null;
    }
  }

  void _updateCommodities() {
    if (_selectedState == null || _selectedMandi == null) return;
    final commoditiesList = _masterData[_selectedState][_selectedMandi] as List;
    _commodities = commoditiesList.cast<String>();
    _commodities.sort();

    if (_commodities.isNotEmpty) {
      _selectedCommodity = _commodities[0];
    } else {
      _selectedCommodity = null;
    }
  }

  // Action 1: Price Forecast Only
  void _getForecast() async {
    if (_selectedMandi == null || _selectedCommodity == null) return;

    _showLoading();
    try {
      final prediction = await _apiService.fetchPrediction(
        mandi: _selectedMandi!,
        commodity: _selectedCommodity!,
      );
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ResultScreen(prediction: prediction, isQuintal: _isQuintal),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showError(e.toString());
    }
  }

  // Action 2: Profit Optimization
  void _getOptimizedPlan() async {
    if (_selectedMandi == null || _selectedCommodity == null) {
      _showError("Please select Mandi and Commodity");
      return;
    }

    // Quick validation
    if (_qtyController.text.isEmpty ||
        _storageController.text.isEmpty ||
        _transportCostController.text.isEmpty) {
      _showError(
        "Please fill in farmer profile details (Quantity, Storage, Costs) to calculate profit.",
      );
      return;
    }

    _showLoading();

    try {
      double qVal = double.tryParse(_qtyController.text) ?? 10;
      if (!_isQuintal) {
        qVal = qVal / 100.0;
      }
      final optimizeResult = await _apiService.optimizeProfile(
        mandis: [_selectedMandi!],
        commodity: _selectedCommodity!,
        quantityQuintal: qVal,
        storageDaysMax: int.tryParse(_storageController.text) ?? 3,
        storageCost: double.tryParse(_storageCostController.text) ?? 5,
        transportCost: double.tryParse(_transportCostController.text) ?? 5,
        distanceToMandi: {
          _selectedMandi!: double.tryParse(_distController.text) ?? 10,
        },
      );

      if (!mounted) return;
      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            optimizeResult: optimizeResult,
            isQuintal: _isQuintal,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showError(e.toString());
    }
  }

  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: localeNotifier,
      builder: (context, locale, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.get(locale, 'farmer_advisor')),
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
          body: _isLoadingOptions
              ? const Center(child: CircularProgressIndicator())
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
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- SELECTION CARD ---
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              // State Dropdown
                              InputDecorator(
                                decoration: InputDecoration(
                                  labelText: AppLocalizations.get(
                                    locale,
                                    'select_state',
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedState,
                                    isDense: true,
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedState = val;
                                        _updateMandis();
                                      });
                                    },
                                    items: _states.map((s) {
                                      return DropdownMenuItem(
                                        value: s,
                                        child: Text(
                                          DataLocalization.get(s, locale),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Mandi Dropdown
                              InputDecorator(
                                decoration: InputDecoration(
                                  labelText: AppLocalizations.get(
                                    locale,
                                    'select_mandi',
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedMandi,
                                    isDense: true,
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedMandi = val;
                                        _updateCommodities();
                                      });
                                    },
                                    items: _mandis.map((m) {
                                      return DropdownMenuItem(
                                        value: m,
                                        child: Text(
                                          DataLocalization.get(m, locale),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Commodity Dropdown
                              InputDecorator(
                                decoration: InputDecoration(
                                  labelText: AppLocalizations.get(
                                    locale,
                                    'select_commodity',
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedCommodity,
                                    isDense: true,
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedCommodity = val;
                                      });
                                    },
                                    items: _commodities.map((c) {
                                      return DropdownMenuItem(
                                        value: c,
                                        child: Text(
                                          DataLocalization.get(c, locale),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- BUTTON: PRICE FORECAST ---
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(
                              0xFF1B5E20,
                            ), // Dark Green
                            side: const BorderSide(color: Color(0xFF1B5E20)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: _getForecast,
                          icon: const Icon(Icons.trending_up),
                          label: const Text(
                            "Get 7-Day Price Forecast",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),

                      // --- OPTIMIZATION SECTION HEADER ---
                      Text(
                        AppLocalizations.get(locale, 'farmer_profile_opt'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        AppLocalizations.get(locale, 'enter_details'),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),

                      // --- PROFILE INPUT GRID ---
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        childAspectRatio: 2.5,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        children: [
                          // Quantity
                          TextField(
                            controller: _qtyController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.get(
                                locale,
                                'quantity_q',
                              ), // Quantity (Quintals)
                              prefixIcon: const Icon(
                                Icons.scale,
                                color: Colors.green,
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          // Max Storage
                          TextField(
                            controller: _storageController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.get(
                                locale,
                                'max_storage',
                              ), // Max Storage (Days)
                              prefixIcon: const Icon(
                                Icons.calendar_today,
                                color: Colors.green,
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          // Storage Cost
                          TextField(
                            controller: _storageCostController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.get(
                                locale,
                                'storage_cost',
                              ), // Storage Cost/Day
                              prefixIcon: const Icon(
                                Icons.money,
                                color: Colors.green,
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          // Transport Cost
                          TextField(
                            controller: _transportCostController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.get(
                                locale,
                                'transport_cost',
                              ), // Transport Cost/km
                              prefixIcon: const Icon(
                                Icons.local_shipping,
                                color: Colors.green,
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Distance (Full Width)
                      TextField(
                        controller: _distController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.get(
                            locale,
                            'distance_km',
                          ), // Distance to Mandi (Km)
                          prefixIcon: const Icon(
                            Icons.map,
                            color: Colors.green,
                            size: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- BUTTON: CALCULATE PROFIT ---
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          onPressed: _getOptimizedPlan,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF1B5E20,
                            ), // Dark Green
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 5,
                          ),
                          icon: const Icon(Icons.rocket_launch),
                          label: Text(
                            AppLocalizations.get(locale, 'calculate_profit'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
