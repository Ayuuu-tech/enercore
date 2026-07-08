import 'package:cross_file/cross_file.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/domain/user_model.dart';
import '../../auth/application/auth_controller.dart';
import '../data/profile_repository.dart';

final profileControllerProvider = AsyncNotifierProvider<ProfileController, UserModel>(() {
  return ProfileController();
});

class ProfileController extends AsyncNotifier<UserModel> {
  @override
  Future<UserModel> build() async {
    // Always load fresh from the server so the profile reflects the currently
    // logged-in user, not a cached/previous session. Fall back to the session
    // user only if the network call fails.
    try {
      final repo = ref.read(profileRepositoryProvider);
      return await repo.getProfile();
    } catch (e) {
      final user = ref.read(authControllerProvider).asData?.value;
      if (user != null) return user;
      throw Exception('Failed to load profile: $e');
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final currentUser = state.asData?.value;
    if (currentUser == null) throw Exception('No profile loaded');
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(profileRepositoryProvider);
      final updatedUser = await repo.updateProfile(currentUser.id, data);
      state = AsyncValue.data(updatedUser);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> uploadAvatar(XFile file) async {
    final currentUser = state.asData?.value;
    if (currentUser == null) throw Exception('No profile loaded');
    final repo = ref.read(profileRepositoryProvider);
    final updatedUser = await repo.uploadAvatar(currentUser.id, file);
    state = AsyncValue.data(updatedUser);
    await ref.read(authControllerProvider.notifier).refreshProfile();
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    final repo = ref.read(profileRepositoryProvider);
    await repo.changePassword(oldPassword, newPassword);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(profileRepositoryProvider);
      final user = await repo.getProfile();
      state = AsyncValue.data(user);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}
