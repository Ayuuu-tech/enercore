import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../application/vendor_controller.dart';
import '../../domain/vendor_models.dart';
import '../widgets/vendor_chrome.dart';

class VendorProductsScreen extends ConsumerWidget {
  const VendorProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(vendorProductsProvider);

    return Scaffold(
      backgroundColor: VendorTheme.bg,
      floatingActionButton: FloatingActionButton(
        backgroundColor: VendorTheme.teal,
        onPressed: () async {
          final result = await context.push('/vendor-add-product');
          if (result == true) ref.read(vendorProductsProvider.notifier).refresh();
        },
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const VendorTopBar(showBack: false),
            Expanded(
              child: RefreshIndicator(
                color: VendorTheme.teal,
                onRefresh: () => ref.read(vendorProductsProvider.notifier).refresh(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'My Products',
                        style: TextStyle(
                          color: VendorTheme.slateDark,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Manage the equipment listings in your storefront catalog.',
                        style: TextStyle(
                          color: VendorTheme.slateLight,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      productsAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 60),
                          child: Center(child: CircularProgressIndicator(color: VendorTheme.teal)),
                        ),
                        error: (e, _) => _errorBox(context, ref, '$e'),
                        data: (products) {
                          if (products.isEmpty) {
                            return _emptyState(context, ref);
                          }
                          return Column(
                            children: [
                              for (final p in products) ...[
                                _productCard(context, ref, p),
                                const SizedBox(height: 12),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
            const VendorBottomNav(activeIndex: 1),
          ],
        ),
      ),
    );
  }

  Widget _productCard(BuildContext context, WidgetRef ref, VendorProductModel p) {
    final outOfStock = p.stock == 0;
    final lowStock = p.stock > 0 && p.stock <= 5;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VendorTheme.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(4)),
                child: Text(
                  p.brand,
                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                child: Text(
                  p.category,
                  style: const TextStyle(color: VendorTheme.slateLight, fontSize: 9.5, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            p.title,
            style: const TextStyle(color: VendorTheme.slateDark, fontSize: 14.5, fontWeight: FontWeight.w800, letterSpacing: -0.2),
          ),
          const SizedBox(height: 4),
          Text(
            p.spec,
            style: const TextStyle(color: VendorTheme.slateLight, fontSize: 11, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('₹${p.price}', style: const TextStyle(color: VendorTheme.slateDark, fontSize: 18, fontWeight: FontWeight.w900)),
              if (p.originalPrice != null) ...[
                const SizedBox(width: 6),
                Text(
                  '₹${p.originalPrice}',
                  style: const TextStyle(
                    color: VendorTheme.slateLight,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: outOfStock
                      ? const Color(0xFFFEE2E2)
                      : lowStock
                          ? const Color(0xFFFEF3C7)
                          : const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  outOfStock ? 'Out of stock' : '${p.stock} in stock',
                  style: TextStyle(
                    color: outOfStock
                        ? VendorTheme.red
                        : lowStock
                            ? VendorTheme.amber
                            : VendorTheme.teal,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: VendorTheme.teal, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      foregroundColor: VendorTheme.teal,
                    ),
                    onPressed: () async {
                      final result = await context.push('/vendor-add-product', extra: p);
                      if (result == true) ref.read(vendorProductsProvider.notifier).refresh();
                    },
                    icon: const Icon(Icons.edit_outlined, size: 14),
                    label: const Text('Edit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 38,
                width: 44,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () => _confirmDelete(context, ref, p),
                  child: const Icon(Icons.delete_outline_rounded, size: 16, color: VendorTheme.red),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, VendorProductModel p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete product?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Text('“${p.title}” will be permanently removed from your catalog.',
            style: const TextStyle(fontSize: 13, color: VendorTheme.slateLight)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: VendorTheme.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ref.read(vendorProductsProvider.notifier).deleteProduct(p.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
        }
      }
    }
  }

  Widget _emptyState(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VendorTheme.cardBorder, width: 1),
      ),
      child: Column(
        children: [
          const Icon(Icons.inventory_2_outlined, color: VendorTheme.slateLight, size: 40),
          const SizedBox(height: 12),
          const Text('No products yet', style: TextStyle(color: VendorTheme.slateDark, fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text(
            'List your first product to start selling on the marketplace.',
            textAlign: TextAlign.center,
            style: TextStyle(color: VendorTheme.slateLight, fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 42,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: VendorTheme.teal,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final result = await context.push('/vendor-add-product');
                if (result == true) ref.read(vendorProductsProvider.notifier).refresh();
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('List New Product', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorBox(BuildContext context, WidgetRef ref, String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text('Error: $msg', style: const TextStyle(color: VendorTheme.red, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: VendorTheme.teal),
            onPressed: () => ref.read(vendorProductsProvider.notifier).refresh(),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
