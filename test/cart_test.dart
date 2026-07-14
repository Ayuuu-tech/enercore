import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:enercore_app/features/marketplace/application/cart_controller.dart';
import 'package:enercore_app/features/vendor/domain/vendor_models.dart';

VendorProductModel product({String id = 'p1', num price = 100, int stock = 10}) {
  return VendorProductModel(
    id: id,
    title: 'Panel $id',
    brand: 'Enercore',
    spec: '550W',
    rating: 4.5,
    reviewsCount: 10,
    price: price,
    originalPrice: null,
    isAssured: true,
    category: 'Solar Panels',
    stock: stock,
    vendorId: 'v1',
  );
}

void main() {
  late ProviderContainer c;
  setUp(() => c = ProviderContainer());
  tearDown(() => c.dispose());

  CartController cart() => c.read(cartProvider.notifier);

  test('starts empty', () {
    expect(c.read(cartProvider), isEmpty);
    expect(c.read(cartCountProvider), 0);
    expect(c.read(cartTotalProvider), 0);
  });

  test('adding the same product twice merges into one line', () {
    cart().add(product());
    cart().add(product());

    expect(c.read(cartProvider), hasLength(1));
    expect(c.read(cartProvider).single.quantity, 2);
    expect(c.read(cartCountProvider), 2);
  });

  test('totals the lines', () {
    cart().add(product(id: 'a', price: 100), quantity: 2);
    cart().add(product(id: 'b', price: 250));

    expect(c.read(cartTotalProvider), 450); // 2×100 + 250
    expect(c.read(cartCountProvider), 3);
  });

  // The vendor can't ship what they don't have, so the cart must not let the
  // customer order it — the order would fail at the backend anyway.
  test('never exceeds available stock', () {
    cart().add(product(stock: 3), quantity: 10);
    expect(c.read(cartProvider).single.quantity, 3);

    cart().setQuantity('p1', 99);
    expect(c.read(cartProvider).single.quantity, 3);
  });

  test('an out-of-stock product cannot be added at all', () {
    cart().add(product(stock: 0));
    expect(c.read(cartProvider), isEmpty);
  });

  test('setting a quantity to zero removes the line', () {
    cart().add(product());
    cart().setQuantity('p1', 0);

    expect(c.read(cartProvider), isEmpty);
  });

  test('remove and clear', () {
    cart().add(product(id: 'a'));
    cart().add(product(id: 'b'));

    cart().remove('a');
    expect(c.read(cartProvider), hasLength(1));

    cart().clear();
    expect(c.read(cartProvider), isEmpty);
  });
}
