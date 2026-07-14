import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/application/auth_controller.dart';
import '../../application/vendor_controller.dart';
import '../../domain/vendor_models.dart';
import '../widgets/vendor_chrome.dart';
import '../../data/kyc_repository.dart';

class VendorDashboardScreen extends ConsumerWidget {
  const VendorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(vendorStatsProvider);
    final ordersAsync = ref.watch(vendorOrdersProvider);
    final user = ref.watch(authControllerProvider).value;

    return Scaffold(
      backgroundColor: VendorTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            const VendorTopBar(showBack: false),
            Expanded(
              child: RefreshIndicator(
                color: VendorTheme.teal,
                onRefresh: () async {
                  ref.invalidate(vendorStatsProvider);
                  await ref.read(vendorOrdersProvider.notifier).refresh();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: TextStyle(
                          color: VendorTheme.slateLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.company?.isNotEmpty == true ? user!.company! : (user?.name ?? 'Vendor'),
                        style: const TextStyle(
                          color: VendorTheme.slateDark,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Manage your catalog, fulfil orders and track your store performance.',
                        style: TextStyle(
                          color: VendorTheme.slateLight,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const _KycBanner(),
                      statsAsync.when(
                        loading: () => const _StatsSkeleton(),
                        error: (e, _) => _errorBox('Failed to load stats: $e'),
                        data: (stats) => _statsGrid(stats),
                      ),
                      const SizedBox(height: 24),
                      _addProductButton(context, ref),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Orders',
                            style: TextStyle(
                              color: VendorTheme.slateDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go('/vendor-orders'),
                            child: const Text(
                              'View all',
                              style: TextStyle(
                                color: VendorTheme.teal,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ordersAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator(color: VendorTheme.teal)),
                        ),
                        error: (e, _) => _errorBox('Failed to load orders: $e'),
                        data: (orders) {
                          if (orders.isEmpty) return _emptyBox('No orders yet.');
                          final recent = orders.take(5).toList();
                          return Column(
                            children: [
                              for (final o in recent) ...[
                                _orderTile(context, o),
                                const SizedBox(height: 10),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
            const VendorBottomNav(activeIndex: 0),
          ],
        ),
      ),
    );
  }

  Widget _statsGrid(VendorStats stats) {
    final cards = [
      (_StatCardData('Pending Orders', '${stats.pendingOrders}', Icons.shopping_bag_rounded, VendorTheme.amber)),
      (_StatCardData('Total Products', '${stats.totalProducts}', Icons.inventory_2_rounded, const Color(0xFF2563EB))),
      (_StatCardData('Out of Stock', '${stats.outOfStock}', Icons.warning_amber_rounded, VendorTheme.red)),
      (_StatCardData('Revenue', '₹${stats.monthlyRevenue}', Icons.account_balance_wallet_rounded, VendorTheme.teal)),
    ];
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.55,
      children: cards.map((c) => _statCard(c)).toList(),
    );
  }

  Widget _statCard(_StatCardData d) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VendorTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VendorTheme.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: d.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(d.icon, color: d.color, size: 18),
          ),
          const Spacer(),
          Text(
            d.value,
            style: const TextStyle(color: VendorTheme.slateDark, fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            d.title,
            style: const TextStyle(color: VendorTheme.slateLight, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _addProductButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: VendorTheme.teal,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () async {
          final result = await context.push('/vendor-add-product');
          if (result == true) {
            ref.invalidate(vendorStatsProvider);
            ref.read(vendorProductsProvider.notifier).refresh();
          }
        },
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('List New Product', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _orderTile(BuildContext context, VendorOrderModel o) {
    final chip = statusChip(o.status);
    return GestureDetector(
      onTap: () => context.go('/vendor-orders'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: VendorTheme.cardBorder, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.receipt_rounded, color: VendorTheme.slateDark, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    o.orderNumber,
                    style: const TextStyle(color: VendorTheme.slateDark, fontSize: 13, fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${o.totalUnits} item(s) · ₹${o.totalAmount}',
                    style: const TextStyle(color: VendorTheme.slateLight, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: chip.bg, borderRadius: BorderRadius.circular(6)),
              child: Text(
                chip.label,
                style: TextStyle(color: chip.fg, fontSize: 10, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorBox(String msg) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(msg, style: const TextStyle(color: VendorTheme.red, fontSize: 12, fontWeight: FontWeight.w600)),
      );

  Widget _emptyBox(String msg) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        alignment: Alignment.center,
        child: Text(msg, style: const TextStyle(color: VendorTheme.slateLight, fontSize: 13, fontWeight: FontWeight.w500)),
      );
}

class _StatCardData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  _StatCardData(this.title, this.value, this.icon, this.color);
}

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.55,
      children: List.generate(
        4,
        (_) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: VendorTheme.cardBorder, width: 1),
          ),
          child: const Center(child: CircularProgressIndicator(color: VendorTheme.teal, strokeWidth: 2)),
        ),
      ),
    );
  }
}


/// Surfaces KYC on the vendor's home screen: they can't be paid until Enercore
/// has their PAN, GST, bank details and statutory documents, so a vendor who
/// hasn't submitted needs to be told, not left to find the screen.
class _KycBanner extends ConsumerWidget {
  const _KycBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myKycProvider);
    return async.maybeWhen(
      orElse: () => const SizedBox.shrink(),
      data: (kyc) {
        // Nothing to nag about once they're verified.
        if (kyc.status == 'APPROVED') return const SizedBox.shrink();

        final (color, title, body) = switch (kyc.status) {
          'PENDING' => (
              const Color(0xFFD97706),
              kyc.readyForReview ? 'KYC under review' : 'KYC incomplete',
              kyc.readyForReview
                  ? 'Enercore is reviewing your details.'
                  : 'Add your remaining documents to finish.',
            ),
          'REJECTED' => (
              const Color(0xFFEF4444),
              'KYC needs attention',
              kyc.rejectReason ?? 'Please review and resubmit.',
            ),
          _ => (
              VendorTheme.teal,
              'Complete your KYC',
              'Add your PAN, GST, bank details and documents to get paid.',
            ),
        };

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: GestureDetector(
            onTap: () => context.push('/vendor-kyc'),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified_user_outlined, color: color, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: TextStyle(
                                color: color, fontSize: 13, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 2),
                        Text(body,
                            style: const TextStyle(
                                color: VendorTheme.slateDark, fontSize: 11.5, height: 1.3)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: color, size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
