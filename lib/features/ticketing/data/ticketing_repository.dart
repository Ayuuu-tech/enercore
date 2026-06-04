import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/http/http_helper.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/ticket_model.dart';
import '../domain/ticket_comment_model.dart';

final ticketingRepositoryProvider = Provider<TicketingRepository>((ref) {
  final authRepository = ref.read(authRepositoryProvider) as HttpAuthRepository;
  return TicketingRepository(authRepository);
});

class TicketingRepository {
  final HttpAuthRepository _authRepository;

  TicketingRepository(this._authRepository);

  Map<String, String> get _headers {
    final token = HttpAuthRepository.token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<TicketModel>> getTickets() async {
    final response = await httpGet(
      Uri.parse('${_authRepository.baseUrl}/tickets'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => TicketModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch tickets: ${response.statusCode}');
    }
  }

  Future<TicketModel> getTicketById(String id) async {
    final response = await httpGet(
      Uri.parse('${_authRepository.baseUrl}/tickets/$id'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return TicketModel.fromJson(data);
    } else {
      throw Exception('Failed to fetch ticket details: ${response.statusCode}');
    }
  }

  Future<TicketModel> createTicket({
    required String title,
    required String description,
    required String plantId,
    required String priority,
  }) async {
    final response = await httpPost(
      Uri.parse('${_authRepository.baseUrl}/tickets'),
      headers: _headers,
      body: jsonEncode({
        'title': title,
        'description': description,
        'plantId': plantId,
        'priority': priority,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return TicketModel.fromJson(data);
    } else {
      try {
        final err = jsonDecode(response.body);
        throw Exception(err['message'] ?? 'Failed to create ticket');
      } catch (_) {
        throw Exception('Failed to create ticket: ${response.statusCode}');
      }
    }
  }

  Future<List<TicketCommentModel>> getComments(String ticketId) async {
    final response = await httpGet(
      Uri.parse('${_authRepository.baseUrl}/tickets/$ticketId/comments'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => TicketCommentModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch ticket comments: ${response.statusCode}');
    }
  }

  Future<TicketCommentModel> addComment(String ticketId, String message) async {
    final response = await httpPost(
      Uri.parse('${_authRepository.baseUrl}/tickets/$ticketId/comments'),
      headers: _headers,
      body: jsonEncode({'content': message}),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return TicketCommentModel.fromJson(data);
    } else {
      throw Exception('Failed to add comment: ${response.statusCode}');
    }
  }
}
