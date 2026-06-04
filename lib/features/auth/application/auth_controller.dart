import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:enercore_app/features/auth/domain/user_model.dart';
import 'package:enercore_app/features/auth/data/auth_repository.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, UserModel?>(() {
  return AuthController();
});

class AuthController extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    return null;
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final authRepository = ref.read(authRepositoryProvider);
      final user = await authRepository.login(email, password);
      state = AsyncValue.data(user);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    final authRepository = ref.read(authRepositoryProvider);
    await authRepository.logout();
    state = const AsyncValue.data(null);
  }

  Future<void> refreshProfile() async {
    try {
      final repo = ref.read(authRepositoryProvider) as HttpAuthRepository;
      final response = await http.get(
        Uri.parse('${repo.baseUrl}/users/me'),
        headers: {
          'Content-Type': 'application/json',
          if (HttpAuthRepository.token != null)
            'Authorization': 'Bearer ${HttpAuthRepository.token}',
        },
      );
      if (response.statusCode == 200) {
        final user = UserModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
        state = AsyncValue.data(user);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}
