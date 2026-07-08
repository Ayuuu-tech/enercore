import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/vendor_controller.dart';
import '../../domain/vendor_models.dart';
import '../widgets/vendor_chrome.dart';

class VendorOrdersScreen extends ConsumerStatefulWidget {
  const VendorOrdersScreen({super.key});

  @override
  ConsumerState<VendorOrdersScreen> createState() => _VendorOrdersScreenState();
}

class _VendorOrdersScreenState extends ConsumerState<VendorOrdersScreen> {
  int _filter = 0;
  final _tabs = ['All', 'Pending', 'Shipped', 'Delivered', 'Cancelled'];

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(vendorOrdersProvider);

    return Scaffold(
      backgroundColor: VendorTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            const VendorTopBar(showBack: false),
            Expanded(
              child: ordersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: VendorTheme.teal)),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $e', style: const TextStyle(color: VendorTheme.red)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: VendorTheme.teal),
                        onPressed: () => ref.read(vendorOrdersProvider.notifier).refresh(),
                        child: const Text('Retry', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
                data: (orders) {
                  final filtered = orders.where((o) {
                    if (_filter == 0) return true;
                    return o.status.toUpperCase() == _tabs[_filter].toUpperCase();
                  }).toList();

                  return RefreshIndicator(
                    color: VendorTheme.teal,
                    onRefresh: () => ref.read(vendorOrdersProvider.notifier).refresh(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Orders',
                            style: TextStyle(
                              color: VendorTheme.slateDark,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Track and fulfil orders that include your products.',
                            style: TextStyle(color: VendorTheme.slateLight, fontSize: 12.5, fontWeight: FontWeight.w500, height: 1.4),
                          ),
                          const SizedBox(height: 16),
                          _filterTabs(),
                          const SizedBox(height: 16),
                          if (filtered.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 48),
                              alignment: Alignment.center,
                              child: const Text('No orders found.',
                                  style: TextStyle(color: VendorTheme.slateLight, fontSize: 13, fontWeight: FontWeight.w500)),
                            )
                          else
                            ...filtered.map((o) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _orderCard(o),
                                )),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const VendorBottomNav(activeIndex: 2),
          ],
        ),
      ),
    );
  }

  Widget _filterTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _tabs.asMap().entries.map((e) {
          final active = _filter == e.key;
          return GestureDetector(
            onTap: () => setState(() => _filter = e.key),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active ? VendorTheme.teal : const Color(0xFFE2E8F0).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: active ? VendorTheme.teal : VendorTheme.cardBorder, width: 1),
              ),
              child: Text(
                e.value,
                style: TextStyle(
                  color: active ? Colors.white : VendorTheme.slateLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _orderCard(VendorOrderModel o) {
    final chip = statusChip(o.status);
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
              Text(o.orderNumber,
                  style: const TextStyle(color: VendorTheme.teal, fontSize: 12.5, fontWeight: FontWeight.w800)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: chip.bg, borderRadius: BorderRadius.circular(6)),
                child: Text(chip.label, style: TextStyle(color: chip.fg, fontSize: 10, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _metaItem(Icons.inventory_2_outlined, '${o.totalUnits} unit(s)'),
              const SizedBox(width: 18),
              _metaItem(Icons.calendar_today_rounded, _fmtDate(o.createdAt)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                const Text('Order Total', style: TextStyle(color: VendorTheme.slateLight, fontSize: 12, fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('₹${o.totalAmount}', style: const TextStyle(color: VendorTheme.slateDark, fontSize: 16, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _statusActions(o),
        ],
      ),
    );
  }

  Widget _metaItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: VendorTheme.slateLight, size: 14),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: VendorTheme.slateDark, fontSize: 11.5, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _statusActions(VendorOrderModel o) {
    final status = o.status.toUpperCase();
    // Next allowed transition + a cancel option.
    String? nextStatus;
    String? nextLabel;
    if (status == 'PENDING') {
      nextStatus = 'SHIPPED';
      nextLabel = 'Mark as Shipped';
    } else if (status == 'SHIPPED') {
      nextStatus = 'DELIVERED';
      nextLabel = 'Mark as Delivered';
    }

    if (nextStatus == null && status != 'PENDING') {
      // Delivered or Cancelled — terminal, no actions.
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (nextStatus != null)
          Expanded(
            child: SizedBox(
              height: 40,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: VendorTheme.teal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _changeStatus(o.id, nextStatus!),
                child: Text(nextLabel!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        if (status == 'PENDING') ...[
          const SizedBox(width: 10),
          SizedBox(
            height: 40,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.2),
                foregroundColor: VendorTheme.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _changeStatus(o.id, 'CANCELLED'),
              child: const Text('Cancel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _changeStatus(String id, String status) async {
    try {
      await ref.read(vendorOrdersProvider.notifier).updateStatus(id, status);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order marked as ${status.toLowerCase()}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}
