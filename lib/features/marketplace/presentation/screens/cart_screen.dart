import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../application/cart_controller.dart';
import '../../data/marketplace_repository.dart';
import '../../domain/pricing.dart';
import '../../../../core/http/api_error.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _placing = false;

  static const _bg = Color(0xFFF4F6F8);
  static const _cardBorder = Color(0xFFE5E7EB);
  static const _teal = Color(0xFF2A8C6E);
  static const _slateDark = Color(0xFF1E293B);
  static const _slateLight = Color(0xFF64748B);

  Future<void> _checkout() async {
    final lines = ref.read(cartProvider);
    if (lines.isEmpty) return;

    setState(() => _placing = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(marketplaceRepositoryProvider).createOrderFromItems({
        for (final l in lines) l.product.id: l.quantity,
      });
      ref.read(cartProvider.notifier).clear();
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(
        backgroundColor: _teal,
        content: Text('Order placed successfully'),
      ));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        backgroundColor: const Color(0xFFEF4444),
        content: Text(friendlyMessage(e)),
      ));
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lines = ref.watch(cartProvider);
    final price = ref.watch(cartPriceProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 56,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: _cardBorder, width: 1)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back_rounded, color: _slateDark, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text('Cart',
                      style: TextStyle(
                          color: _teal, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
                  const Spacer(),
                  if (lines.isNotEmpty)
                    TextButton(
                      onPressed: () => ref.read(cartProvider.notifier).clear(),
                      child: const Text('Clear',
                          style: TextStyle(color: _slateLight, fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: lines.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shopping_cart_outlined, size: 44, color: _slateLight),
                          const SizedBox(height: 10),
                          const Text('Your cart is empty',
                              style: TextStyle(color: _slateLight, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 14),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: _teal, width: 1.2),
                              foregroundColor: _teal,
                            ),
                            onPressed: () => context.pop(),
                            child: const Text('Browse products',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: lines.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _line(lines[i]),
                    ),
            ),
            if (lines.isNotEmpty) _checkoutBar(price),
          ],
        ),
      ),
    );
  }

  Widget _line(CartLine l) {
    final p = l.product;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: _slateDark, fontSize: 13, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(p.brand, style: const TextStyle(color: _slateLight, fontSize: 11)),
                const SizedBox(height: 8),
                Text('₹${displayPrice(p.price).toStringAsFixed(0)}  ×  ${l.quantity}',
                    style: const TextStyle(color: _slateLight, fontSize: 11.5)),
                const SizedBox(height: 2),
                Text('₹${l.lineTotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: _teal, fontSize: 14, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => ref.read(cartProvider.notifier).remove(p.id),
                child: const Icon(Icons.close_rounded, size: 18, color: _slateLight),
              ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: _cardBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _qtyButton(Icons.remove_rounded,
                        () => ref.read(cartProvider.notifier).setQuantity(p.id, l.quantity - 1)),
                    SizedBox(
                      width: 30,
                      child: Text('${l.quantity}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: _slateDark, fontSize: 13, fontWeight: FontWeight.w800)),
                    ),
                    // Never let the cart exceed what the vendor actually has.
                    _qtyButton(
                      Icons.add_rounded,
                      l.quantity >= p.stock
                          ? null
                          : () => ref.read(cartProvider.notifier).setQuantity(p.id, l.quantity + 1),
                    ),
                  ],
                ),
              ),
              if (l.quantity >= p.stock) ...[
                const SizedBox(height: 4),
                Text('Only ${p.stock} in stock',
                    style: const TextStyle(color: Color(0xFFD97706), fontSize: 9.5, fontWeight: FontWeight.w700)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, num amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: _slateLight, fontSize: 12, fontWeight: FontWeight.w600)),
        Text('₹${amount.toStringAsFixed(2)}',
            style: const TextStyle(color: _slateDark, fontSize: 12.5, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 15, color: onTap == null ? _cardBorder : _slateDark),
      ),
    );
  }

  Widget _checkoutBar(PriceBreakdown price) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _cardBorder, width: 1)),
      ),
      child: Column(
        children: [
          // The commission is already inside these prices and is deliberately
          // not itemised — neither the customer nor the vendor sees it.
          _priceRow('Subtotal', price.taxable),
          const SizedBox(height: 4),
          _priceRow('GST (18%)', price.gst),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: _cardBorder),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total',
                  style: TextStyle(color: _slateDark, fontSize: 13, fontWeight: FontWeight.w800)),
              Text('₹${price.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: _slateDark, fontSize: 20, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _placing ? null : _checkout,
              child: _placing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('PLACE ORDER',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
            ),
          ),
        ],
      ),
    );
  }
}
