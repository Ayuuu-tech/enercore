import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shared design tokens for the vendor side — mirrors the client/admin UI.
class VendorTheme {
  static const bg = Color(0xFFF4F6F8);
  static const card = Colors.white;
  static const cardBorder = Color(0xFFE5E7EB);
  static const teal = Color(0xFF2A8C6E);
  static const slateDark = Color(0xFF1E293B);
  static const slateLight = Color(0xFF64748B);
  static const amber = Color(0xFFD97706);
  static const red = Color(0xFFEF4444);
  static const green = Color(0xFF10B981);
}

/// Shared top bar with logo, used across vendor screens.
class VendorTopBar extends StatelessWidget {
  final bool showBack;
  const VendorTopBar({super.key, this.showBack = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: VendorTheme.cardBorder, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (showBack && context.canPop()) ...[
            GestureDetector(
              onTap: () => context.pop(),
              child: const Icon(Icons.arrow_back_rounded, color: VendorTheme.slateDark, size: 22),
            ),
            const SizedBox(width: 12),
          ],
          Image.asset('assets/images/logo.png', height: 46, fit: BoxFit.contain),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.storefront_rounded, color: Colors.white, size: 12),
                SizedBox(width: 4),
                Text(
                  'VENDOR',
                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared bottom navigation bar for the vendor side (4 tabs).
class VendorBottomNav extends StatelessWidget {
  final int activeIndex;
  const VendorBottomNav({super.key, required this.activeIndex});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.dashboard_rounded, 'Home', '/vendor-dashboard'),
      (Icons.inventory_2_rounded, 'Products', '/vendor-products'),
      (Icons.receipt_long_rounded, 'Orders', '/vendor-orders'),
      (Icons.storefront_rounded, 'Store', '/vendor-store'),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: VendorTheme.cardBorder, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final active = activeIndex == i;
          return GestureDetector(
            onTap: () {
              if (!active) context.go(items[i].$3);
            },
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    items[i].$1,
                    color: active ? VendorTheme.teal : VendorTheme.slateLight.withValues(alpha: 0.6),
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    items[i].$2,
                    style: TextStyle(
                      color: active ? VendorTheme.teal : VendorTheme.slateLight.withValues(alpha: 0.7),
                      fontSize: 9.5,
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
}

/// Maps an order/product status to a (label, fg, bg) tuple for chips.
({String label, Color fg, Color bg}) statusChip(String status) {
  switch (status.toUpperCase()) {
    case 'PENDING':
      return (label: 'Pending', fg: VendorTheme.amber, bg: const Color(0xFFFEF3C7));
    case 'SHIPPED':
      return (label: 'Shipped', fg: const Color(0xFF2563EB), bg: const Color(0xFFDBEAFE));
    case 'DELIVERED':
      return (label: 'Delivered', fg: VendorTheme.teal, bg: const Color(0xFFD1FAE5));
    case 'CANCELLED':
      return (label: 'Cancelled', fg: VendorTheme.red, bg: const Color(0xFFFEE2E2));
    default:
      return (label: status, fg: VendorTheme.slateLight, bg: const Color(0xFFF1F5F9));
  }
}
