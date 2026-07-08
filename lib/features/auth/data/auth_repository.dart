import 'dart:convert';
import 'dart:io' show Platform, SocketException;
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return HttpAuthRepository();
});

abstract class AuthRepository {
  String get baseUrl;
  String? get token;

  Future<UserModel> login(String email, String password);
  Future<UserModel> register(
      String email, String password, String name, String role, {String? phone});
  Future<void> logout();
  Future<UserModel> fetchProfile();
  Future<void> forgotPassword(String email);

  /// Restores a previously saved session (token + user), or null if none.
  Future<UserModel?> restoreSession();
}

class HttpAuthRepository implements AuthRepository {
  static String? _token;
  static String? customUrl;
  static String? _workingBase;
  static const _timeout = Duration(seconds: 4);

  // PC's LAN IP (same WiFi) — used when the app runs on a real device.
  // If your PC's IP changes, update this or use the ⚙ gear on the login screen.
  static const _lanApi = 'http://192.168.1.10:3000/api';

  // Persisted-session keys
  static const _kToken = 'auth_token';
  static const _kUser = 'auth_user';
  static const _kBase = 'auth_working_base';

  Future<void> _persistSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, _token ?? '');
    await prefs.setString(_kUser, jsonEncode(user.toJson()));
    if (_workingBase != null) await prefs.setString(_kBase, _workingBase!);
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kUser);
  }

  @override
  Future<UserModel?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_kToken);
    final savedUser = prefs.getString(_kUser);
    if (savedToken == null || savedToken.isEmpty || savedUser == null) {
      return null;
    }
    _token = savedToken;
    _workingBase ??= prefs.getString(_kBase);
    try {
      return UserModel.fromJson(jsonDecode(savedUser) as Map<String, dynamic>);
    } catch (_) {
      await _clearSession();
      return null;
    }
  }

  @override
  String? get token => _token;

  @override
  String get baseUrl {
    if (customUrl != null && customUrl!.isNotEmpty) {
      return customUrl!;
    }
    if (_workingBase != null) return _workingBase!;
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    try {
      if (Platform.isAndroid) {
        // Real device on same WiFi reaches the PC via its LAN IP.
        return _lanApi;
      }
    } catch (_) {}
    return 'http://localhost:3000/api';
  }

  List<String> _candidates() {
    if (customUrl != null && customUrl!.isNotEmpty) {
      return [customUrl!];
    }
    if (_workingBase != null) return [_workingBase!];
    if (kIsWeb) return ['http://localhost:3000/api'];
    try {
      if (Platform.isAndroid) {
        // Try LAN IP first (real device), then emulator alias, then localhost.
        return [
          _lanApi,
          'http://10.0.2.2:3000/api',
          'http://localhost:3000/api',
        ];
      }
    } catch (_) {}
    return ['http://localhost:3000/api'];
  }

  Future<http.Response> _tryPost(
      String endpoint, Map<String, String> headers, Object body) async {
    final urls = _candidates().map((b) => '$b$endpoint').toList();
    Object? lastErr;

    for (final url in urls) {
      try {
        final resp = await http
            .post(Uri.parse(url), headers: headers, body: body)
            .timeout(_timeout);
        _workingBase ??=
            url.replaceAll(RegExp(r'/auth/(login|register)$'), '');
        return resp;
      } catch (e) {
        lastErr = e;
      }
    }
    throw lastErr ?? SocketException('All endpoints unreachable');
  }

  @override
  Future<UserModel> login(String email, String password) async {
    final response = await _tryPost(
      '/auth/login',
      {'Content-Type': 'application/json'},
      jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['accessToken'] as String;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await _persistSession(user);
      return user;
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
  Future<UserModel> register(
      String email, String password, String name, String role, {String? phone}) async {
    final response = await _tryPost(
      '/auth/register',
      {'Content-Type': 'application/json'},
      jsonEncode({
        'email': email,
        'password': password,
        'name': name,
        'role': role.toUpperCase(),
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (role.toLowerCase() == 'vendor') 'companyName': '$name LLC',
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      _token = data['accessToken'] as String;
      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await _persistSession(user);
      return user;
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
  Future<void> forgotPassword(String email) async {
    final response = await _tryPost(
      '/auth/forgot-password',
      {'Content-Type': 'application/json'},
      jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      try {
        final err = jsonDecode(response.body);
        throw Exception(err['message'] ?? 'Failed to send reset OTP');
      } catch (_) {
        throw Exception('Server error: ${response.statusCode}');
      }
    }
  }

  @override
  Future<void> logout() async {
    _token = null;
    await _clearSession();
  }

  @override
  Future<UserModel> fetchProfile() async {
    final base = _workingBase ?? baseUrl;
    final response = await http.get(
      Uri.parse('$base/users/me'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ).timeout(_timeout);

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to fetch profile');
  }
}
