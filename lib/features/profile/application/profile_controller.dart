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
    final authState = ref.read(authControllerProvider);
    final user = authState.asData?.value;
    if (user != null) {
      return user;
    }
    try {
      final repo = ref.read(profileRepositoryProvider);
      return await repo.getProfile();
    } catch (e) {
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

  Future<void> uploadAvatar(String filePath) async {
    final currentUser = state.asData?.value;
    if (currentUser == null) throw Exception('No profile loaded');
    final repo = ref.read(profileRepositoryProvider);
    final updatedUser = await repo.uploadAvatar(currentUser.id, filePath);
    state = AsyncValue.data(updatedUser);
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
