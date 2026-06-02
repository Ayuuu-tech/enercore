import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    }
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    final authRepository = ref.read(authRepositoryProvider);
    await authRepository.logout();
    state = const AsyncValue.data(null);
  }
}
