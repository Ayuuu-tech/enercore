import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/http/http_helper.dart';
import '../domain/user_model.dart';

// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return HttpAuthRepository(); 
});

abstract class AuthRepository {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(String email, String password, String name, String role);
  Future<void> logout();
}

class HttpAuthRepository implements AuthRepository {
  static String? token;
  static String? customUrl;

  String get baseUrl {
    if (customUrl != null && customUrl!.isNotEmpty) {
      return customUrl!;
    }
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    try {
      if (Platform.isAndroid) {
        // Default to host computer's active Wi-Fi IP address.
        return 'http://192.168.1.19:3000/api';
      }
    } catch (_) {}
    return 'http://localhost:3000/api';
  }

  @override
  Future<UserModel> login(String email, String password) async {
    final response = await httpPost(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      token = data['accessToken'] as String;
      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    } else {
      try {
        final err = jsonDecode(response.body);
        throw Exception(err['message'] ?? 'Failed to sign in');
      } catch (_) {
        throw Exception('Server error: ${response.statusCode}');
      }
    }
  }

  @override
  Future<UserModel> register(String email, String password, String name, String role) async {
    final response = await httpPost(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'name': name,
        'role': role.toUpperCase(), // CLIENT, VENDOR, ADMIN
        if (role.toLowerCase() == 'vendor') 'companyName': '$name LLC',
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      token = data['accessToken'] as String;
      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    } else {
      try {
        final err = jsonDecode(response.body);
        throw Exception(err['message'] ?? 'Failed to register');
      } catch (_) {
        throw Exception('Server error: ${response.statusCode}');
      }
    }
  }

  @override
  Future<void> logout() async {
    token = null;
  }
}
