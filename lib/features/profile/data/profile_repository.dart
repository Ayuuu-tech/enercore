import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/http/http_helper.dart';
import '../../auth/domain/user_model.dart';
import '../../auth/data/auth_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

class ProfileRepository {
  String get baseUrl {
    if (HttpAuthRepository.customUrl != null && HttpAuthRepository.customUrl!.isNotEmpty) {
      return HttpAuthRepository.customUrl!;
    }
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://192.168.1.19:3000/api';
      }
    } catch (_) {}
    return 'http://localhost:3000/api';
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (HttpAuthRepository.token != null)
      'Authorization': 'Bearer ${HttpAuthRepository.token}',
  };

  Future<UserModel> getProfile() async {
    final response = await httpGet(
      Uri.parse('$baseUrl/users/me'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      try {
        final err = jsonDecode(response.body);
        throw Exception(err['message'] ?? 'Failed to fetch profile');
      } catch (_) {
        throw Exception('Server error: ${response.statusCode}');
      }
    }
  }

  Future<UserModel> updateProfile(String userId, Map<String, dynamic> data) async {
    final response = await httpPut(
      Uri.parse('$baseUrl/users/$userId'),
      headers: _headers,
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      try {
        final err = jsonDecode(response.body);
        throw Exception(err['message'] ?? 'Failed to update profile');
      } catch (_) {
        throw Exception('Server error: ${response.statusCode}');
      }
    }
  }

  Future<UserModel> uploadAvatar(String userId, String filePath) async {
    final uri = Uri.parse('$baseUrl/users/$userId/avatar');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer ${HttpAuthRepository.token}';
    request.files.add(await http.MultipartFile.fromPath('avatar', filePath));
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed).timeout(httpTimeout);

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } else {
      try {
        final err = jsonDecode(response.body);
        throw Exception(err['message'] ?? 'Failed to upload avatar');
      } catch (_) {
        throw Exception('Server error: ${response.statusCode}');
      }
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    final response = await httpPut(
      Uri.parse('$baseUrl/auth/change-password'),
      headers: _headers,
      body: jsonEncode({
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      try {
        final err = jsonDecode(response.body);
        throw Exception(err['message'] ?? 'Failed to change password');
      } catch (_) {
        throw Exception('Server error: ${response.statusCode}');
      }
    }
  }
}
