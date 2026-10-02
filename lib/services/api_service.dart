import 'dart:convert';

import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/prediction_response.dart';

class MandiApiService {
  // Use 10.0.2.2 for Android Emulator to access host localhost
  // Use 10.0.2.2 for Android Emulator, OR your PC's IP for real device
  // Use 10.0.2.2 for Android Emulator to access host localhost
  // Use 10.188.160.2 for Real Mobile Device (Wi-Fi LAN)
  // static const String baseUrl = 'http://10.0.2.2:8000';
  static const String baseUrl = 'http://10.213.34.2:8000'; // Real Wi-Fi IP

  // ... (previous methods fetchOptions, fetchPrediction, optimizeProfile)

  Future<String> sendChat(String message, String? imagePath) async {
    final url = Uri.parse('$baseUrl/chat');
    try {
      final request = http.MultipartRequest('POST', url);
      request.fields['message'] = message;

      if (imagePath != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            imagePath,
            contentType: MediaType('image', 'jpeg'), // Assuming jpeg/png
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['response'];
      } else {
        throw Exception('Chat failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint("Chat Error: $e");
      throw Exception('Failed to send message: $e');
    }
  }

  Future<Map<String, dynamic>> fetchOptions() async {
    final url = Uri.parse('$baseUrl/options');
    debugPrint('Fetching options from: $url');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load options: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching options: $e');
      throw Exception('Connection error: $e');
    }
  }

  Future<PredictionResponse> fetchPrediction({
    required String mandi,
    required String commodity,
  }) async {
    final url = Uri.parse('$baseUrl/predict');
    debugPrint('Fetching prediction from: $url');
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'mandi': mandi, 'commodity': commodity}),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return PredictionResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load prediction: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching prediction: $e');
      throw Exception('Connection error: $e');
    }
  }

  Future<Map<String, dynamic>> optimizeProfile({
    required List<String> mandis,
    required String commodity,
    required double quantityQuintal,
    required int storageDaysMax,
    required double storageCost,
    required double transportCost,
    required Map<String, double> distanceToMandi, // Mandi -> KM
  }) async {
    final url = Uri.parse('$baseUrl/optimize');
    debugPrint('Optimizing profile: $url');
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'mandis': mandis,
              'commodity': commodity,
              'quantity_quintal': quantityQuintal,
              'storage_days_max': storageDaysMax,
              'storage_cost_per_quintal_per_day': storageCost,
              'transport_cost_per_km_per_quintal': transportCost,
              'distance_to_mandi': distanceToMandi,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to optimize: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error optimizing: $e');
      throw Exception('Optimization error: $e');
    }
  }
}
