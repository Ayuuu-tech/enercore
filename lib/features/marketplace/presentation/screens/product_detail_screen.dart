import 'package:flutter/material.dart';
import '../../../../core/widgets/user_avatar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../vendor/domain/vendor_models.dart';
import '../../data/marketplace_repository.dart';
import '../../application/cart_controller.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String? productId;
  const ProductDetailScreen({super.key, this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _quantity = 1;
  final int _selectedNav = -1; // Sub-marketplace navigation

  // Premium Design System
  static const _bg = Color(0xFFF4F6F8);
  static const _card = Colors.white;
  static const _cardBorder = Color(0xFFE5E7EB);
  static const _teal = Color(0xFF2A8C6E); // primary brand green-teal
  static const _slateDark = Color(0xFF1E293B);
  static const _slateLight = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final id = widget.productId;
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: id == null
                  ? const Center(
                      child: Text('No product selected',
                          style: TextStyle(color: _slateLight, fontSize: 12)),
                    )
                  : ref.watch(productDetailProvider(id)).when(
                        loading: () => const Center(child: CircularProgressIndicator(color: _teal)),
                        error: (e, _) => Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Could not load product\n$e',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: _slateLight, fontSize: 12)),
                              TextButton(
                                onPressed: () => ref.refresh(productDetailProvider(id)),
                                child: const Text('Retry',
                                    style: TextStyle(color: _teal, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ),
                        data: (product) => SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _breadcrumbs(product),
                                const SizedBox(height: 12),
                                _productImageSection(product),
                                const SizedBox(height: 16),
                                _productInfoCard(product),
                                const SizedBox(height: 16),
                                _checkoutPanel(product),
                                const SizedBox(height: 16),
                                _descriptionCard(product),
                                const SizedBox(height: 16),
                                _reviewsCard(product),
                                const SizedBox(height: 16),
                                _sellerCard(product),
                                const SizedBox(height: 18),
                                _recommendationsCard(product),
                                const SizedBox(height: 24),
                                _footer(),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ),
                      ),
            ),
            _bottomNav(),
          ],
        ),
      ),
    );
  }

  // ── Top Bar ────────────────────────────────────────────────────────────────
  Widget _topBar() {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: _cardBorder, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const Icon(Icons.arrow_back_rounded, color: _slateDark, size: 22),
          ),
          const SizedBox(width: 12),
          Image.asset(
            'assets/images/logo.png',
            height: 46,
            fit: BoxFit.contain,
          ),
          const Spacer(),
          const UserAvatar(size: 32),
        ],
      ),
    );
  }

  // ── Breadcrumbs ────────────────────────────────────────────────────────────
  Widget _breadcrumbs(VendorProductModel product) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          const Text('Marketplace', style: TextStyle(color: _slateLight, fontSize: 11, fontWeight: FontWeight.w600)),
          const Text('  ›  ', style: TextStyle(color: _slateLight, fontSize: 11)),
          Text(product.category, style: const TextStyle(color: _slateLight, fontSize: 11, fontWeight: FontWeight.w600)),
          const Text('  ›  ', style: TextStyle(color: _slateLight, fontSize: 11)),
          Text(product.title, style: const TextStyle(color: _teal, fontSize: 11, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  // ── Product Images Section ─────────────────────────────────────────────────
  Widget _productImageSection(VendorProductModel product) {
    return _card_(
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image: NetworkImage(productImageFor(product)),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  // ── Product Info Card ──────────────────────────────────────────────────────
  Widget _productInfoCard(VendorProductModel product) {
    final inStock = product.stock > 0;
    return _card_(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.title,
            style: const TextStyle(color: _slateDark, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.4),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                product.brand,
                style: const TextStyle(color: _slateDark, fontSize: 12, fontWeight: FontWeight.w800),
              ),
              if (product.isAssured) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Platform Assured',
                    style: TextStyle(color: _teal, fontSize: 9, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ...List.generate(
                5,
                (index) => Icon(
                  index < product.rating.round() ? Icons.star_rounded : Icons.star_border_rounded,
                  color: const Color(0xFFF5A623),
                  size: 14,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${product.rating.toStringAsFixed(1)} (${product.reviewsCount} Reviews)',
                style: const TextStyle(color: _slateLight, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    formatInr(product.price),
                    style: const TextStyle(color: _slateDark, fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  if (product.originalPrice != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      formatInr(product.originalPrice!),
                      style: const TextStyle(
                          color: _slateLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.lineThrough),
                    ),
                  ],
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: inStock ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: inStock ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA), width: 0.8),
                ),
                child: Text(
                  inStock ? 'In Stock (${product.stock})' : 'Out of Stock',
                  style: TextStyle(
                      color: inStock ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 14),
          // Short specs grid — real fields from the product record
          _shortSpecRow('Brand', product.brand),
          _shortSpecRow('Category', product.category),
          _shortSpecRow('Specification', product.spec),
          _shortSpecRow('Stock', '${product.stock} units'),
        ],
      ),
    );
  }

  Widget _shortSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: _slateLight, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            value,
            style: const TextStyle(color: _slateDark, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // ── Quantity & Add to Cart Panel ───────────────────────────────────────────
  Widget _checkoutPanel(VendorProductModel product) {
    return _card_(
      child: Column(
        children: [
          Row(
            children: [
              // Quantity Selector
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _cardBorder, width: 1.2),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_rounded, color: _slateDark, size: 16),
                      onPressed: () {
                        if (_quantity > 1) setState(() => _quantity--);
                      },
                    ),
                    Text(
                      '$_quantity',
                      style: const TextStyle(color: _slateDark, fontSize: 13, fontWeight: FontWeight.w800),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_rounded, color: _slateDark, size: 16),
                      onPressed: () {
                        if (_quantity < product.stock) setState(() => _quantity++);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Add to Cart Button
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _teal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: product.stock <= 0
                        ? null
                        : () {
                            // Respect the quantity the user picked above.
                            ref.read(cartProvider.notifier).add(product, quantity: _quantity);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: _teal,
                                duration: const Duration(seconds: 2),
                                content: Text('$_quantity × ${product.title} added to cart'),
                                action: SnackBarAction(
                                  textColor: Colors.white,
                                  label: 'VIEW CART',
                                  onPressed: () => context.push('/cart'),
                                ),
                              ),
                            );
                          },
                    icon: const Icon(Icons.shopping_cart_outlined, size: 16),
                    label: Text(product.stock <= 0 ? 'OUT OF STOCK' : 'ADD TO CART',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Buy Now button — places a real order via the backend
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _teal, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                foregroundColor: _teal,
              ),
              onPressed: product.stock <= 0
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await ref
                            .read(marketplaceRepositoryProvider)
                            .createOrder(product.id, _quantity);
                        messenger.showSnackBar(SnackBar(
                          backgroundColor: _teal,
                          content: Text('Order placed: $_quantity × ${product.title}'),
                        ));
                      } catch (e) {
                        messenger.showSnackBar(SnackBar(
                          backgroundColor: const Color(0xFFEF4444),
                          content: Text(e.toString().replaceFirst('Exception: ', '')),
                        ));
                      }
                    },
              child: const Text('Buy Now', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.local_shipping_outlined, color: _slateLight, size: 14),
              SizedBox(width: 6),
              Text(
                'Standard delivery: 3-5 days.',
                style: TextStyle(color: _slateLight, fontSize: 10.5, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Product Description ────────────────────────────────────────────────────
  Widget _descriptionCard(VendorProductModel product) {
    return _card_(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product Description',
            style: TextStyle(color: _slateDark, fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            '${product.title} by ${product.brand}. ${product.spec}.',
            style: const TextStyle(color: _slateDark, fontSize: 12, fontWeight: FontWeight.w500, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ── Customer Reviews ───────────────────────────────────────────────────────
  Widget _reviewsCard(VendorProductModel product) {
    return _card_(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customer Reviews',
            style: TextStyle(color: _slateDark, fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          if (product.reviewsCount == 0)
            const Text(
              'No reviews yet',
              style: TextStyle(color: _slateLight, fontSize: 11.5),
            )
          else
            Row(
              children: [
                ...List.generate(
                  5,
                  (index) => Icon(
                    index < product.rating.round() ? Icons.star_rounded : Icons.star_border_rounded,
                    color: const Color(0xFFF5A623),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${product.rating.toStringAsFixed(1)} · ${product.reviewsCount} review${product.reviewsCount == 1 ? '' : 's'}',
                  style: const TextStyle(color: _slateDark, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ── Seller Card ────────────────────────────────────────────────────────────
  Widget _sellerCard(VendorProductModel product) {
    return _card_(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFD1FAE5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.storefront_rounded, color: _teal, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.brand,
                  style: const TextStyle(color: _slateDark, fontSize: 13, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  product.isAssured ? 'Platform assured seller' : 'Marketplace seller',
                  style: const TextStyle(color: _slateLight, fontSize: 10.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── recommendations Card ───────────────────────────────────────────────────
  Widget _recommendationsCard(VendorProductModel product) {
    final productsAsync = ref.watch(marketplaceProductsProvider);
    final related = productsAsync.value
            ?.where((p) => p.id != product.id)
            .toList() ??
        [];
    // Same-category products first
    related.sort((a, b) => (b.category == product.category ? 1 : 0)
        .compareTo(a.category == product.category ? 1 : 0));
    if (related.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'You May Also Like',
          style: TextStyle(color: _slateDark, fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (final p in related.take(5)) ...[
                GestureDetector(
                  onTap: () => context.push('/product-detail', extra: p.id),
                  child: _recomCard(p.title, formatInr(p.price), productImageFor(p)),
                ),
                const SizedBox(width: 12),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _recomCard(String title, String price, String img) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 90,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(img),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _slateDark, fontSize: 11.5, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            price,
            style: const TextStyle(color: _teal, fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────
  Widget _footer() {
    return Column(
      children: [
        const Text(
          '© 2025 SolarMarket Operations. All rights reserved.',
          style: TextStyle(
            color: _slateLight,
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.center,
          children: ['Terms of Service', '  ·  ', 'Privacy Policy', '  ·  ', 'Support']
              .map((t) => Text(
                    t,
                    style: TextStyle(
                      color: ['·'].any(t.contains) ? _slateLight.withValues(alpha: 0.4) : _slateLight,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  // ── Bottom Nav ─────────────────────────────────────────────────────────────
  Widget _bottomNav() {
    final items = [
      (Icons.home_rounded, 'Home'),
      (Icons.solar_power_rounded, 'Plants'),
      (Icons.sensors_rounded, 'Telemetry'),
      (Icons.receipt_long_rounded, 'Billing'),
      (Icons.confirmation_number_outlined, 'Tickets'),
    ];
    final routes = ['/client-dashboard', '/solar-grid', '/telemetry', '/billing', '/tickets'];
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: _cardBorder, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final active = _selectedNav == i;
          return GestureDetector(
            onTap: () {
              context.push(routes[i]);
            },
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    items[i].$1,
                    color: active ? _teal : _slateLight.withValues(alpha: 0.6),
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    items[i].$2,
                    style: TextStyle(
                      color: active ? _teal : _slateLight.withValues(alpha: 0.7),
                      fontSize: 9,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Card helper ────────────────────────────────────────────────────────────
  Widget _card_({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
