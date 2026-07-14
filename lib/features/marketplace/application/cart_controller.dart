import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../vendor/domain/vendor_models.dart';
import '../domain/pricing.dart';

/// A product in the cart, with the quantity the user picked.
class CartLine {
  final VendorProductModel product;
  final int quantity;

  const CartLine({required this.product, required this.quantity});

  /// What the vendor is paid for this line.
  num get lineSubtotal => product.price * quantity;

  /// What the customer pays for this line — commission and GST included.
  num get lineTotal => priceBreakdown(lineSubtotal).total;

  CartLine copyWith({int? quantity}) =>
      CartLine(product: product, quantity: quantity ?? this.quantity);
}

final cartProvider = NotifierProvider<CartController, List<CartLine>>(CartController.new);

/// The cart lives in memory for the session: it is not persisted, and it is
/// emptied once the order is placed.
class CartController extends Notifier<List<CartLine>> {
  @override
  List<CartLine> build() => const [];

  /// Adds to the cart, merging with an existing line for the same product.
  /// Never lets the cart exceed what the vendor actually has in stock.
  void add(VendorProductModel product, {int quantity = 1}) {
    if (product.stock <= 0) return;

    final index = state.indexWhere((l) => l.product.id == product.id);
    final wanted = (index == -1 ? 0 : state[index].quantity) + quantity;
    final capped = wanted.clamp(1, product.stock);

    state = index == -1
        ? [...state, CartLine(product: product, quantity: capped)]
        : [
            for (final l in state)
              if (l.product.id == product.id) l.copyWith(quantity: capped) else l,
          ];
  }

  void setQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      remove(productId);
      return;
    }
    state = [
      for (final l in state)
        if (l.product.id == productId)
          l.copyWith(quantity: quantity.clamp(1, l.product.stock))
        else
          l,
    ];
  }

  void remove(String productId) {
    state = state.where((l) => l.product.id != productId).toList();
  }

  void clear() => state = const [];
}

/// Number of items in the cart — drives the badge on the cart icon.
final cartCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).fold<int>(0, (s, l) => s + l.quantity);
});

/// Full breakdown for the cart. Computed on the summed vendor subtotal, exactly
/// as the backend does — summing per-line totals could differ by rounding.
final cartPriceProvider = Provider<PriceBreakdown>((ref) {
  final subtotal =
      ref.watch(cartProvider).fold<num>(0, (s, l) => s + l.lineSubtotal);
  return priceBreakdown(subtotal);
});

/// What the customer pays for the whole cart.
final cartTotalProvider = Provider<num>((ref) => ref.watch(cartPriceProvider).total);
