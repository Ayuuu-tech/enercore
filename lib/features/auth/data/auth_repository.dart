import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user_model.dart';

// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // Replace with real backend service later (e.g., Dio/http client)
  return FakeAuthRepository(); 
});

abstract class AuthRepository {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(String email, String password, String name, String role);
  Future<void> logout();
}

// Temporary fake implementation for UI
class FakeAuthRepository implements AuthRepository {
  @override
  Future<UserModel> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    if (email == 'admin@enercore.com' && password == 'password') {
       return UserModel(id: '1', email: email, name: 'Admin User', role: 'ADMIN');
    }
    return UserModel(id: '2', email: email, name: 'Client User', role: 'CLIENT');
  }

  @override
  Future<UserModel> register(String email, String password, String name, String role) async {
    await Future.delayed(const Duration(seconds: 1));
    return UserModel(id: '3', email: email, name: name, role: role);
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
