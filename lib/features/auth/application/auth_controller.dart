import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:enercore_app/features/auth/domain/user_model.dart';
import 'package:enercore_app/features/auth/data/auth_repository.dart';

final authControllerProvider = AsyncNotifierProvider<AuthController, UserModel?>(() {
  return AuthController();
});

class AuthController extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    // Restore a saved session on startup so the user stays logged in
    // across app restarts.
    final authRepository = ref.read(authRepositoryProvider);
    return authRepository.restoreSession();
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

  Future<void> register(String email, String password, String name, String role, {String? phone}) async {
    state = const AsyncValue.loading();
    try {
      final authRepository = ref.read(authRepositoryProvider);
      final user = await authRepository.register(email, password, name, role, phone: phone);
      state = AsyncValue.data(user);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  Future<void> refreshProfile() async {
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.fetchProfile();
      state = AsyncValue.data(user);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}
