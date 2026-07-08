import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/http/http_helper.dart';
import '../../auth/data/auth_repository.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  final authRepository = ref.read(authRepositoryProvider);
  return NotificationsRepository(authRepository);
});

final notificationsProvider = FutureProvider<List<NotificationModel>>((ref) async {
  return ref.read(notificationsRepositoryProvider).getNotifications();
});

final unreadNotificationsCountProvider = FutureProvider<int>((ref) async {
  final notifications = await ref.watch(notificationsProvider.future);
  return notifications.where((n) => !n.read).length;
});

class NotificationsRepository {
  final AuthRepository _authRepository;

  NotificationsRepository(this._authRepository);

  Map<String, String> get _headers {
    final token = _authRepository.token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<NotificationModel>> getNotifications() async {
    final response = await httpGet(
      Uri.parse('${_authRepository.baseUrl}/notifications'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((j) => NotificationModel.fromJson(j as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to fetch notifications: ${response.statusCode}');
  }

  Future<void> markRead(String id) async {
    final response = await httpPut(
      Uri.parse('${_authRepository.baseUrl}/notifications/$id/read'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to mark notification read: ${response.statusCode}');
    }
  }

  Future<void> markAllRead() async {
    final response = await httpPut(
      Uri.parse('${_authRepository.baseUrl}/notifications/read-all'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to mark all read: ${response.statusCode}');
    }
  }
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final bool read;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.read,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      read: json['read'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
    );
  }
}
