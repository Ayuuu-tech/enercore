import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/http/http_helper.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/vendor_models.dart';

final vendorRepositoryProvider = Provider<VendorRepository>((ref) {
  final authRepository = ref.read(authRepositoryProvider);
  return VendorRepository(authRepository);
});

class VendorRepository {
  final AuthRepository _authRepository;

  VendorRepository(this._authRepository);

  Map<String, String> get _headers {
    final token = _authRepository.token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  String get _base => _authRepository.baseUrl;

  // ── Stats ──────────────────────────────────────────────────────────────
  Future<VendorStats> getStats() async {
    final response = await httpGet(
      Uri.parse('$_base/vendors/stats'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return VendorStats.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to fetch vendor stats: ${response.statusCode}');
  }

  // ── Products ───────────────────────────────────────────────────────────
  Future<List<VendorProductModel>> getMyProducts(String vendorId) async {
    final response = await httpGet(
      Uri.parse('$_base/products?vendorId=$vendorId'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((j) => VendorProductModel.fromJson(j as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to fetch products: ${response.statusCode}');
  }

  Future<VendorProductModel> createProduct({
    required String title,
    required String brand,
    required String spec,
    required String category,
    required num price,
    num? originalPrice,
    int stock = 0,
    bool isAssured = false,
  }) async {
    final response = await httpPost(
      Uri.parse('$_base/products'),
      headers: _headers,
      body: jsonEncode({
        'title': title,
        'brand': brand,
        'spec': spec,
        'category': category,
        'price': price,
        'originalPrice': ?originalPrice,
        'stock': stock,
        'isAssured': isAssured,
      }),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return VendorProductModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    _throwError(response.body, 'Failed to create product', response.statusCode);
  }

  Future<VendorProductModel> updateProduct(
    String id, {
    String? title,
    String? brand,
    String? spec,
    String? category,
    num? price,
    num? originalPrice,
    int? stock,
    bool? isAssured,
  }) async {
    final response = await httpPut(
      Uri.parse('$_base/products/$id'),
      headers: _headers,
      body: jsonEncode({
        'title': ?title,
        'brand': ?brand,
        'spec': ?spec,
        'category': ?category,
        'price': ?price,
        'originalPrice': ?originalPrice,
        'stock': ?stock,
        'isAssured': ?isAssured,
      }),
    );
    if (response.statusCode == 200) {
      return VendorProductModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    _throwError(response.body, 'Failed to update product', response.statusCode);
  }

  Future<void> deleteProduct(String id) async {
    final response = await httpDelete(
      Uri.parse('$_base/products/$id'),
      headers: _headers,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      _throwError(response.body, 'Failed to delete product', response.statusCode);
    }
  }

  // ── Orders ─────────────────────────────────────────────────────────────
  Future<List<VendorOrderModel>> getOrders() async {
    final response = await httpGet(
      Uri.parse('$_base/orders'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((j) => VendorOrderModel.fromJson(j as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to fetch orders: ${response.statusCode}');
  }

  Future<VendorOrderModel> updateOrderStatus(String id, String status) async {
    final response = await httpPut(
      Uri.parse('$_base/orders/$id/status'),
      headers: _headers,
      body: jsonEncode({'status': status}),
    );
    if (response.statusCode == 200) {
      return VendorOrderModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    _throwError(response.body, 'Failed to update order status', response.statusCode);
  }

  // ── Store profile ──────────────────────────────────────────────────────
  Future<void> updateStore({required String companyName}) async {
    final response = await httpPut(
      Uri.parse('$_base/vendors/me'),
      headers: _headers,
      body: jsonEncode({'companyName': companyName}),
    );
    if (response.statusCode != 200) {
      _throwError(response.body, 'Failed to update store profile', response.statusCode);
    }
  }

  Never _throwError(String body, String fallback, int statusCode) {
    try {
      final err = jsonDecode(body);
      throw Exception(err['message'] ?? '$fallback ($statusCode)');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('$fallback: $statusCode');
    }
  }
}
