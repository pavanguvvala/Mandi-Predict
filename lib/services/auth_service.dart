import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  // Use MandiApiService.baseUrl for consistency
  final String baseUrl = MandiApiService.baseUrl;

  // Simple in-memory session (use SharedPreferences for persistence in real app)
  static Map<String, dynamic>? currentUser;

  Future<bool> login(String name, String password) async {
    final url = Uri.parse('$baseUrl/login');
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'name': name, 'password': password}),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          currentUser = data['user'];
          await _saveSession(currentUser!);
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint("Login error: $e");
      rethrow;
    }
  }

  Future<void> _saveSession(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', json.encode(user));
  }

  Future<Map<String, dynamic>?> checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      try {
        currentUser = json.decode(userData);
        return currentUser;
      } catch (e) {
        debugPrint("Session decode error: $e");
      }
    }
    return null;
  }

  Future<bool> register({
    required String name,
    required String password,
    required String state,
    required String mandi,
    required List<String> crops,
  }) async {
    final url = Uri.parse('$baseUrl/register');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'password': password,
          'state': state,
          'mandi': mandi,
          'crops': crops,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Register error: $e");
      return false;
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String state,
    required String mandi,
    required List<String> crops,
  }) async {
    final url = Uri.parse('$baseUrl/update_profile');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'state': state,
          'mandi': mandi,
          'crops': crops,
        }),
      );

      if (response.statusCode == 200) {
        // Update local session
        if (currentUser != null) {
          currentUser!['state'] = state;
          currentUser!['mandi'] = mandi;
          currentUser!['crops'] = crops;
          await _saveSession(currentUser!);
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Update Profile error: $e");
      return false;
    }
  }

  Future<void> logout() async {
    currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
  }
}
