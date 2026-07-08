import 'dart:convert';
import 'package:cross_file/cross_file.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/http/http_helper.dart';
import '../../auth/domain/user_model.dart';
import '../../auth/data/auth_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final authRepository = ref.read(authRepositoryProvider);
  return ProfileRepository(authRepository);
});

class ProfileRepository {
  final AuthRepository _authRepository;

  ProfileRepository(this._authRepository);

  String get baseUrl => _authRepository.baseUrl;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authRepository.token != null)
      'Authorization': 'Bearer ${_authRepository.token}',
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

  Future<UserModel> uploadAvatar(String userId, XFile file) async {
    final uri = Uri.parse('$baseUrl/users/$userId/avatar');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer ${_authRepository.token}';
    final bytes = await file.readAsBytes();
    request.files.add(http.MultipartFile.fromBytes(
      'avatar', bytes,
      filename: file.name,
    ));
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
