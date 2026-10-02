import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _passController = TextEditingController();

  final _apiService = MandiApiService();
  final _authService = AuthService();

  Map<String, dynamic> _masterData = {};
  List<String> _states = [];
  List<String> _mandis = [];

  List<String> _availableCrops = [];
  final List<String> _selectedCrops = [];

  String? _selectedState;
  String? _selectedMandi;

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    try {
      final data = await _apiService.fetchOptions();
      setState(() {
        _masterData = data;
        _states = _masterData.keys.toList()..sort();
      });
    } catch (e) {
      // Handle error
    }
  }

  void _onStateChanged(String? val) {
    setState(() {
      _selectedState = val;
      _mandis = (_masterData[val!] as Map<String, dynamic>).keys.toList()
        ..sort();
      _selectedMandi = null;
    });
  }

  void _register() async {
    if (_nameController.text.isEmpty ||
        _passController.text.isEmpty ||
        _selectedState == null ||
        _selectedMandi == null ||
        _selectedCrops.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => _isLoading = true);
    final success = await _authService.register(
      name: _nameController.text,
      password: _passController.text,
      state: _selectedState!,
      mandi: _selectedMandi!,
      crops: _selectedCrops,
    );
    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration Successful! Please Login.")),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Registration Failed")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Create Account",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          // Background Curve
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 250,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(60),
                  bottomRight: Radius.circular(60),
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            "Join Mandi Predict",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: "Full Name",
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedState,
                          decoration: const InputDecoration(
                            labelText: "Select State",
                            prefixIcon: Icon(Icons.map),
                          ),
                          onChanged: _onStateChanged,
                          items: _states
                              .map(
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedMandi,
                          decoration: const InputDecoration(
                            labelText: "Select Mandi",
                            prefixIcon: Icon(Icons.store),
                          ),
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
                                (m) =>
                                    DropdownMenuItem(value: m, child: Text(m)),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 24),
                        if (_selectedMandi != null) ...[
                          const Text(
                            "Select Your Crops:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _availableCrops.map((crop) {
                              final isSelected = _selectedCrops.contains(crop);
                              return FilterChip(
                                label: Text(crop),
                                selected: isSelected,
                                selectedColor: const Color(0xFFE8F5E9),
                                checkmarkColor: const Color(0xFF1B5E20),
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? const Color(0xFF1B5E20)
                                      : Colors.black87,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
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
                            onPressed: _isLoading ? null : _register,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text("REGISTER NOW"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
