import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  // Use 10.0.2.2 for Android Emulator, use your LAN IP for physical device
  static const String baseUrl = "http://10.0.2.2:8000";
  static final ApiService _instance = ApiService._internal();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  Future<Map<String, dynamic>?> login(String username) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storage.write(key: 'user_id', value: data['user_id']);
        await _storage.write(key: 'session_token', value: data['token']);
        // Store Phone Number
        if (data['phone_number'] != null) {
          await _storage.write(
            key: 'phone_number',
            value: data['phone_number'],
          );
        }
        return data;
      } else {
        debugPrint("Login failed: ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("Login error: $e");
      return null;
    }
  }

  Future<void> registerFcmToken(String token) async {
    final userId = await _storage.read(key: 'user_id');
    if (userId == null) return;

    try {
      await http.post(
        Uri.parse('$baseUrl/register_fcm'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId, 'fcm_token': token}),
      );
    } catch (e) {
      debugPrint("FCM Register Error: $e");
    }
  }

  Future<Map<String, dynamic>?> triggerCall(String targetNumber) async {
    final userId = await _storage.read(key: 'user_id');
    if (userId == null) return null;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/trigger_call'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'caller_id': userId, 'target_number': targetNumber}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint("Trigger Call Call failed: ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("Trigger Call Error: $e");
      return null;
    }
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: 'user_id');
  }

  Future<String?> getPhoneNumber() async {
    return await _storage.read(key: 'phone_number');
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }
}
