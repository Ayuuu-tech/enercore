import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/http/http_helper.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/plant_model.dart';

final plantsRepositoryProvider = Provider<PlantsRepository>((ref) {
  final authRepository = ref.read(authRepositoryProvider) as HttpAuthRepository;
  return PlantsRepository(authRepository);
});

final plantsFutureProvider = FutureProvider<List<PlantModel>>((ref) async {
  return ref.read(plantsRepositoryProvider).getPlants();
});

class PlantsRepository {
  final HttpAuthRepository _authRepository;

  PlantsRepository(this._authRepository);

  Map<String, String> get _headers {
    final token = HttpAuthRepository.token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<PlantModel>> getPlants() async {
    final response = await httpGet(
      Uri.parse('${_authRepository.baseUrl}/solar-plants'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => PlantModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch plants: ${response.statusCode}');
    }
  }
}
