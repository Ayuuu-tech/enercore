import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/auth_controller.dart';
import '../data/vendor_repository.dart';
import '../domain/vendor_models.dart';

/// Vendor dashboard statistics.
final vendorStatsProvider = FutureProvider.autoDispose<VendorStats>((ref) async {
  return ref.read(vendorRepositoryProvider).getStats();
});

/// Products owned by the currently logged-in vendor.
final vendorProductsProvider =
    AsyncNotifierProvider.autoDispose<VendorProductsController, List<VendorProductModel>>(() {
  return VendorProductsController();
});

class VendorProductsController extends AsyncNotifier<List<VendorProductModel>> {
  @override
  Future<List<VendorProductModel>> build() async {
    return _fetch();
  }

  Future<List<VendorProductModel>> _fetch() async {
    final user = ref.read(authControllerProvider).value;
    if (user == null) return [];
    return ref.read(vendorRepositoryProvider).getMyProducts(user.id);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> createProduct({
    required String title,
    required String brand,
    required String spec,
    required String category,
    required num price,
    num? originalPrice,
    int stock = 0,
    bool isAssured = false,
  }) async {
    await ref.read(vendorRepositoryProvider).createProduct(
          title: title,
          brand: brand,
          spec: spec,
          category: category,
          price: price,
          originalPrice: originalPrice,
          stock: stock,
          isAssured: isAssured,
        );
    await refresh();
  }

  Future<void> updateProduct(
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
    await ref.read(vendorRepositoryProvider).updateProduct(
          id,
          title: title,
          brand: brand,
          spec: spec,
          category: category,
          price: price,
          originalPrice: originalPrice,
          stock: stock,
          isAssured: isAssured,
        );
    await refresh();
  }

  Future<void> deleteProduct(String id) async {
    await ref.read(vendorRepositoryProvider).deleteProduct(id);
    await refresh();
  }
}

/// Orders containing the vendor's products.
final vendorOrdersProvider =
    AsyncNotifierProvider.autoDispose<VendorOrdersController, List<VendorOrderModel>>(() {
  return VendorOrdersController();
});

class VendorOrdersController extends AsyncNotifier<List<VendorOrderModel>> {
  @override
  Future<List<VendorOrderModel>> build() async {
    return ref.read(vendorRepositoryProvider).getOrders();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(vendorRepositoryProvider).getOrders());
  }

  Future<void> updateStatus(String id, String status) async {
    await ref.read(vendorRepositoryProvider).updateOrderStatus(id, status);
    await refresh();
  }
}
