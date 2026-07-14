import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/http/http_helper.dart';
import '../../auth/data/auth_repository.dart';
import '../../vendor/domain/vendor_models.dart';

final marketplaceRepositoryProvider = Provider<MarketplaceRepository>((ref) {
  final authRepository = ref.read(authRepositoryProvider);
  return MarketplaceRepository(authRepository);
});

final marketplaceProductsProvider = FutureProvider<List<VendorProductModel>>((ref) async {
  return ref.read(marketplaceRepositoryProvider).getProducts();
});

final productDetailProvider =
    FutureProvider.family<VendorProductModel, String>((ref, id) async {
  return ref.read(marketplaceRepositoryProvider).getProduct(id);
});

class MarketplaceRepository {
  final AuthRepository _authRepository;

  MarketplaceRepository(this._authRepository);

  Map<String, String> get _headers {
    final token = _authRepository.token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<VendorProductModel>> getProducts() async {
    final response = await httpGet(
      Uri.parse('${_authRepository.baseUrl}/products'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((j) => VendorProductModel.fromJson(j as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to fetch products: ${response.statusCode}');
  }

  /// Places a real order for the given product.
  Future<void> createOrder(String productId, int quantity) =>
      createOrderFromItems({productId: quantity});

  /// Places a single order covering every line in the cart.
  Future<void> createOrderFromItems(Map<String, int> quantityByProductId) async {
    final response = await httpPost(
      Uri.parse('${_authRepository.baseUrl}/orders'),
      headers: _headers,
      body: jsonEncode({
        'items': quantityByProductId.entries
            .map((e) => {'productId': e.key, 'quantity': e.value})
            .toList(),
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      String message = 'Failed to place order: ${response.statusCode}';
      try {
        final err = jsonDecode(response.body);
        if (err['message'] != null) message = err['message'].toString();
      } catch (_) {}
      throw Exception(message);
    }
  }

  Future<VendorProductModel> getProduct(String id) async {
    final response = await httpGet(
      Uri.parse('${_authRepository.baseUrl}/products/$id'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return VendorProductModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to fetch product: ${response.statusCode}');
  }
}

/// Products don't have image URLs in the backend yet; show a stable
/// category-based stock photo until image upload is supported.
String productImageFor(VendorProductModel p) {
  switch (p.category) {
    case 'Solar Panels':
      return 'https://images.unsplash.com/photo-1509391366360-2e959784a276?w=400&fit=crop&q=80';
    case 'Inverters':
      return 'https://images.unsplash.com/photo-1613665813446-82a78c468a1d?w=400&fit=crop&q=80';
    case 'Cables':
      return 'https://images.unsplash.com/photo-1544724569-5f546fd6f2b5?w=400&fit=crop&q=80';
    default:
      return 'https://images.unsplash.com/photo-1508514177221-188b1cf16e9d?w=400&fit=crop&q=80';
  }
}

String formatInr(num value) {
  final s = value.toStringAsFixed(0);
  // Indian digit grouping: 12,34,567
  if (s.length <= 3) return '₹$s';
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final parts = <String>[];
  while (rest.length > 2) {
    parts.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) parts.insert(0, rest);
  return '₹${parts.join(',')},$last3';
}
