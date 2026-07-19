import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/user_model.dart';
import '../../../core/http/api_error.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return HttpAuthRepository();
});

abstract class AuthRepository {
  String get baseUrl;
  String? get token;

  /// Replaces the stored access token (e.g. the fresh one returned after a
  /// password change) so the session keeps working with the new credentials.
  Future<void> updateToken(String newToken);

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

  // Production/staging API URL baked in at build time:
  //   flutter build apk --release --dart-define=API_URL=https://api.yourdomain.com/api
  // When set, it overrides every dev fallback below, so release builds always
  // hit the hosted backend regardless of platform.
  static const _envApi = String.fromEnvironment('API_URL');

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
  Future<void> updateToken(String newToken) async {
    _token = newToken;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, newToken);
  }

  @override
  String get baseUrl {
    if (customUrl != null && customUrl!.isNotEmpty) {
      return customUrl!;
    }
    if (_envApi.isNotEmpty) return _envApi;
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
    if (_envApi.isNotEmpty) return [_envApi];
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
    // Every candidate URL failed to connect — this is a connectivity problem,
    // not a server rejection, so surface it as one.
    throw NetworkException(lastErr?.toString() ?? 'unreachable');
  }

  /// Turns a non-success response into a typed ApiException, pulling the
  /// server's `message` when the body is JSON. Parsing failures don't mask the
  /// real status the way a swallowing try/catch did.
  Never _throwApiError(http.Response response) {
    String? serverMessage;
    try {
      final err = jsonDecode(response.body);
      final m = err is Map ? err['message'] : null;
      if (m is String) serverMessage = m;
      if (m is List && m.isNotEmpty) serverMessage = m.first.toString();
    } catch (_) {
      // Body wasn't JSON; fall back to a status-based message below.
    }
    throw ApiException(response.statusCode, serverMessage ?? 'Request failed');
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
      _throwApiError(response);
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
      _throwApiError(response);
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
      _throwApiError(response);
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
