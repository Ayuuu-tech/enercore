import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/widgets/user_avatar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/billing_repository.dart';
import '../../domain/invoice_model.dart';
import '../../application/billing_controller.dart';

class InvoiceListScreen extends ConsumerStatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  ConsumerState<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends ConsumerState<InvoiceListScreen> {
  int _selectedNav = 3; // Billing tab active
  String? _downloadingId;

  /// Fetches the bill PDF and hands it to the device's PDF viewer.
  Future<void> _downloadBill(String invoiceId) async {
    setState(() => _downloadingId = invoiceId);
    try {
      final bill = await ref.read(billingRepositoryProvider).downloadBillPdf(invoiceId);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${bill.filename}');
      await file.writeAsBytes(bill.bytes);
      await OpenFilex.open(file.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFEF4444),
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _downloadingId = null);
    }
  }

  // Premium Design System
  static const _bg = Color(0xFFF4F6F8);
  static const _card = Colors.white;
  static const _cardBorder = Color(0xFFE5E7EB);
  static const _teal = Color(0xFF2A8C6E); // primary brand green-teal
  static const _slateDark = Color(0xFF1E293B);
  static const _slateLight = Color(0xFF64748B);

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final invoicesState = ref.watch(billingControllerProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: invoicesState.when(
                data: (invoices) {
                  // Compute stats dynamically from real database data
                  final totalDue = invoices
                      .where((inv) => inv.status != 'PAID')
                      .fold<double>(0.0, (sum, inv) => sum + inv.amount);

                  final paidInvoices = invoices.where((inv) => inv.status == 'PAID').toList();
                  paidInvoices.sort((a, b) => b.dueDate.compareTo(a.dueDate));
                  
                  final lastPayment = paidInvoices.isNotEmpty ? paidInvoices.first.amount : 0.0;
                  final lastPaymentDate = paidInvoices.isNotEmpty
                      ? 'Paid on ${_formatDate(paidInvoices.first.paidAt ?? paidInvoices.first.dueDate)}'
                      : 'No payments';


                  return RefreshIndicator(
                    onRefresh: () => ref.read(billingControllerProvider.notifier).fetchInvoices(),
                    color: _teal,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _headerRow(totalDue),
                            const SizedBox(height: 16),
                            _statsRow(totalDue, lastPayment, lastPaymentDate),
                            const SizedBox(height: 18),
                            _invoiceHistoryCard(invoices),
                            const SizedBox(height: 24),
                            _footer(),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: _teal),
                ),
                error: (err, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $err', style: const TextStyle(color: Colors.redAccent)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: _teal),
                        onPressed: () => ref.read(billingControllerProvider.notifier).fetchInvoices(),
                        child: const Text('Retry', style: TextStyle(color: Colors.white)),
                      ),
                    ],
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

  // ── Header Row ─────────────────────────────────────────────────────────────
  Widget _headerRow(double totalDue) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: totalDue > 0 ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            totalDue > 0 ? '₹${totalDue.toInt()} due' : 'Fully Paid',
            style: TextStyle(
              color: totalDue > 0 ? const Color(0xFFD97706) : _teal,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  // ── Stats Row ──────────────────────────────────────────────────────────────
  Widget _statsRow(double totalDue, double lastPayment, String lastPaymentDate) {
    return Row(
      children: [
        // Total Due Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: totalDue > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: totalDue > 0 ? const Color(0xFFFCA5A5) : const Color(0xFFA7F3D0),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      color: totalDue > 0 ? const Color(0xFFDC2626) : _teal,
                      size: 18,
                    ),
                    if (totalDue > 0)
                      const Text(
                        'PENDING',
                        style: TextStyle(color: Color(0xFFDC2626), fontSize: 9, fontWeight: FontWeight.w800),
                      )
                    else
                      const Text(
                        'PAID',
                        style: TextStyle(color: _teal, fontSize: 9, fontWeight: FontWeight.w800),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Total Due',
                  style: TextStyle(color: _slateLight, fontSize: 10.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${totalDue.toInt()}',
                  style: const TextStyle(color: _slateDark, fontSize: 20, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Last Payment Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD1FAE5), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Icon(Icons.check_circle_outline_rounded, color: _teal, size: 18),
                    Text(
                      'SUCCESS',
                      style: TextStyle(color: _teal, fontSize: 9, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Last Payment',
                  style: TextStyle(color: _slateLight, fontSize: 10.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${lastPayment.toInt()}',
                  style: const TextStyle(color: _slateDark, fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((0.6 * 255).toInt()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    lastPaymentDate,
                    style: const TextStyle(color: _slateLight, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Payment Methods ────────────────────────────────────────────────────────
  // ── Invoice History Card ───────────────────────────────────────────────────
  Widget _invoiceHistoryCard(List<InvoiceModel> invoices) {
    return _card_(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Invoice History',
                style: TextStyle(color: _slateDark, fontSize: 13, fontWeight: FontWeight.w800),
              ),
              Text(
                'View All >',
                style: TextStyle(color: _teal, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Expanded(
                child: Text(
                  'INVOICE #',
                  style: TextStyle(color: _slateLight, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
              Expanded(
                child: Text(
                  'PERIOD',
                  style: TextStyle(color: _slateLight, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
              Expanded(
                child: Text(
                  'AMOUNT',
                  style: TextStyle(color: _slateLight, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                'STATUS',
                style: TextStyle(color: _slateLight, fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 8),
          if (invoices.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No invoices found.',
                style: TextStyle(color: _slateLight, fontSize: 12),
              ),
            )
          else
            ...invoices.map((invoice) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          invoice.invoiceNumber,
                          style: const TextStyle(color: _slateDark, fontSize: 11.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          invoice.period,
                          style: const TextStyle(color: _slateLight, fontSize: 11.5, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '₹${invoice.amount.toInt()}',
                          style: const TextStyle(color: _slateDark, fontSize: 11.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                      _statusBadge(invoice.status),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _downloadingId == invoice.id ? null : () => _downloadBill(invoice.id),
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: _downloadingId == invoice.id
                              ? const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: CircularProgressIndicator(strokeWidth: 2, color: _teal),
                                )
                              : const Icon(Icons.download_rounded, size: 18, color: _teal),
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bg;
    Color text;
    String label;

    switch (status.toUpperCase()) {
      case 'PAID':
        bg = const Color(0xFFD1FAE5);
        text = const Color(0xFF047857);
        label = 'Paid';
        break;
      case 'OVERDUE':
        bg = const Color(0xFFFEE2E2);
        text = const Color(0xFFDC2626);
        label = 'Overdue';
        break;
      default:
        bg = const Color(0xFFFEF3C7);
        text = const Color(0xFFD97706);
        label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: text, fontSize: 9.5, fontWeight: FontWeight.w800),
      ),
    );
  }

  // ── Payable Amount Panel ───────────────────────────────────────────────────
  // ── Footer ─────────────────────────────────────────────────────────────────
  Widget _footer() {
    return Column(
      children: [
        const Text(
          '© 2025 Enercore Billing Systems. All rights reserved.',
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
                      color: ['·'].any(t.contains) ? _slateLight.withAlpha((0.4 * 255).toInt()) : _slateLight,
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
    final routes = ['/client-dashboard', '/solar-grid', '/telemetry', null, '/tickets'];
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
              if (routes[i] != null) {
                context.push(routes[i]!);
              } else {
                setState(() => _selectedNav = i);
              }
            },
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    items[i].$1,
                    color: active ? _teal : _slateLight.withAlpha((0.6 * 255).toInt()),
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    items[i].$2,
                    style: TextStyle(
                      color: active ? _teal : _slateLight.withAlpha((0.7 * 255).toInt()),
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
            color: Colors.black.withAlpha((0.03 * 255).toInt()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
