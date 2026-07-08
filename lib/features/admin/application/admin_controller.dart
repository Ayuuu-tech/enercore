import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/http/http_helper.dart';
import '../../auth/data/auth_repository.dart';

final adminStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final authRepository = ref.read(authRepositoryProvider);
  final token = authRepository.token;
  final response = await http.get(
    Uri.parse('${authRepository.baseUrl}/admin/stats'),
    headers: {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    },
  ).timeout(httpTimeout);

  if (response.statusCode == 200) {
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
  throw Exception('Failed to fetch admin stats');
});
