// Simple Auth Service that works with backend API
// Replaces Firebase auth with simple OTP-based authentication

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../../core/services/api_service.dart';
import '../../core/constants/api_endpoints.dart';

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Logger _logger = Logger();
  final ApiService _apiService = ApiService();

  // Store OTP verification ID
  String? _verificationId;

  bool get isLoggedIn => false; // Will be implemented

  /// Send OTP to phone number
  Future<bool> sendOTP(String phoneNumber) async {
    try {
      _logger.i('Sending OTP to: $phoneNumber');

      // For now, simulate OTP sending (backend endpoint would be: /auth/send-otp)
      // TODO: Replace with actual API call when backend auth is ready
      await Future.delayed(const Duration(seconds: 1));
      
      // Generate a fake verification ID for demo
      _verificationId = 'demo_${DateTime.now().millisecondsSinceEpoch}';
      
      _logger.i('OTP sent successfully (demo mode)');
      return true;
    } catch (e) {
      _logger.e('Error sending OTP: $e');
      return false;
    }
  }

  /// Verify OTP
  Future<Map<String, dynamic>?> verifyOTP(String otp) async {
    try {
      if (_verificationId == null) {
        throw Exception('Verification ID is null. Please request OTP first.');
      }

      _logger.i('Verifying OTP: $otp');

      // For demo, accept any 6-digit OTP
      if (otp.length == 6) {
        // Simulate successful verification
        final userData = {
          'uid': 'demo_user_123',
          'phone': '+911234567890',
          'role': 'admin',
          'constituency_id': 'AC001',
          'constituency_name': 'Bhongir',
          'name': 'Demo MLA',
        };

        // Store user data
        await _storage.write(key: 'auth_token', value: 'demo_token_${DateTime.now().millisecondsSinceEpoch}');
        await _storage.write(key: 'user_id', value: userData['uid'] as String);
        await _storage.write(key: 'user_role', value: userData['role'] as String);
        await _storage.write(key: 'user_constituency', value: userData['constituency_id'] as String);
        await _storage.write(key: 'user_name', value: userData['name'] as String);

        _logger.i('OTP verified successfully');
        return userData;
      } else {
        throw Exception('Invalid OTP format');
      }
    } catch (e) {
      _logger.e('OTP verification failed: $e');
      throw Exception('Invalid OTP. Please try again.');
    }
  }

  /// Check if user is logged in
  Future<bool> checkLoginStatus() async {
    final token = await _storage.read(key: 'auth_token');
    return token != null;
  }

  /// Get current user data
  Future<Map<String, String?>> getCurrentUser() async {
    return {
      'uid': await _storage.read(key: 'user_id'),
      'role': await _storage.read(key: 'user_role'),
      'constituency_id': await _storage.read(key: 'user_constituency'),
      'name': await _storage.read(key: 'user_name'),
    };
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _storage.deleteAll();
      _verificationId = null;
      _logger.i('User logged out successfully');
    } catch (e) {
      _logger.e('Error during logout: $e');
    }
  }
}
