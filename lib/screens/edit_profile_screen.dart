import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/localization.dart';
import '../services/data_localization.dart';
// import '../main.dart'; // Removed to fix circular dependency
import 'dashboard_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _apiService = MandiApiService();
  final _authService = AuthService();

  Map<String, dynamic> _masterData = {};
  List<String> _states = [];
  List<String> _mandis = [];

  List<String> _availableCrops = [];
  // final List<String> _allCrops = CommodityList.all;
  List<String> _selectedCrops = [];
  String? _selectedState;
  String? _selectedMandi;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOptionsAndUser();
  }

  Future<void> _loadOptionsAndUser() async {
    // Load Master Data
    final data = await _apiService.fetchOptions();
    final user = AuthService.currentUser;

    setState(() {
      _masterData = data;
      _states = _masterData.keys.toList()..sort();

      // Load current user data
      if (user != null) {
        _selectedState = user['state'];

        // Load Mandis for this state
        if (_selectedState != null && _masterData.containsKey(_selectedState)) {
          _mandis =
              (_masterData[_selectedState] as Map<String, dynamic>).keys
                  .toList()
                ..sort();
        }

        _selectedMandi = user['mandi'];
        // Ensure selected mandi is in list (sanity check)
        if (!_mandis.contains(_selectedMandi)) _selectedMandi = null;

        // Load available crops for this mandi
        if (_selectedState != null && _selectedMandi != null) {
          final rawCrops = _masterData[_selectedState]![_selectedMandi] as List;
          _availableCrops = List<String>.from(rawCrops)..sort();
        }

        _selectedCrops = List<String>.from(user['crops']);
      }
    });
  }

  void _onStateChanged(String? val) {
    setState(() {
      _selectedState = val;
      _mandis = (_masterData[val!] as Map<String, dynamic>).keys.toList()
        ..sort();
      _selectedMandi = null;
    });
  }

  void _saveProfile() async {
    final user = AuthService.currentUser;
    if (user == null) return;

    if (_selectedState == null ||
        _selectedMandi == null ||
        _selectedCrops.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => _isLoading = true);
    final success = await _authService.updateProfile(
      name: user['name'], // Using name as ID for this simple demo
      state: _selectedState!,
      mandi: _selectedMandi!,
      crops: _selectedCrops,
    );
    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Profile Updated!")));
      // Navigate back to Dashboard to refresh data
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Update Failed")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: localeNotifier,
      builder: (context, locale, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.get(locale, 'profile')),
            backgroundColor: const Color(0xFF1B5E20), // Dark Green
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  AppLocalizations.get(locale, 'update_profile_desc'),
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: AppLocalizations.get(locale, 'select_state'),
                    border: const OutlineInputBorder(),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedState,
                      isDense: true,
                      hint: Text(AppLocalizations.get(locale, 'select_state')),
                      onChanged: _onStateChanged,
                      items: _states
                          .map(
                            (s) => DropdownMenuItem(
                              value: s,
                              child: Text(DataLocalization.get(s, locale)),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: AppLocalizations.get(locale, 'select_mandi'),
                    border: const OutlineInputBorder(),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedMandi,
                      isDense: true,
                      hint: Text(AppLocalizations.get(locale, 'select_mandi')),
                      onChanged: (val) {
                        setState(() {
                          _selectedMandi = val;
                          if (_selectedState != null && val != null) {
                            final rawCrops =
                                _masterData[_selectedState]![val] as List;
                            _availableCrops = List<String>.from(rawCrops)
                              ..sort();
                          } else {
                            _availableCrops = [];
                          }
                          _selectedCrops.clear();
                        });
                      },
                      items: _mandis
                          .map(
                            (m) => DropdownMenuItem(
                              value: m,
                              child: Text(DataLocalization.get(m, locale)),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_selectedMandi != null) ...[
                  Text(
                    AppLocalizations.get(locale, 'select_crops'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: _availableCrops.map((crop) {
                      final isSelected = _selectedCrops.contains(crop);
                      return FilterChip(
                        label: Text(DataLocalization.get(crop, locale)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCrops.add(crop);
                            } else {
                              _selectedCrops.remove(crop);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20), // Dark Green
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            AppLocalizations.get(locale, 'save').toUpperCase(),
                          ),
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
