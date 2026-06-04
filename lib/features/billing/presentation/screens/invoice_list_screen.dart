import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/invoice_model.dart';
import '../../application/billing_controller.dart';

class InvoiceListScreen extends ConsumerStatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  ConsumerState<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends ConsumerState<InvoiceListScreen> {
  int _selectedNav = 3; // Billing tab active
  int _selectedPaymentMethod = 0;

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

                  final pendingInvoices = invoices.where((inv) => inv.status != 'PAID').toList();
                  final nextPayableInvoice = pendingInvoices.isNotEmpty ? pendingInvoices.first : null;

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
                            _paymentMethods(),
                            const SizedBox(height: 18),
                            _invoiceHistoryCard(invoices),
                            const SizedBox(height: 18),
                            _payableAmountPanel(nextPayableInvoice),
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
            height: 24,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
          const Text(
            'Enercore',
            style: TextStyle(
              color: _teal,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=80&fit=crop&q=80'),
                fit: BoxFit.cover,
              ),
            ),
          ),
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
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _teal,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: EdgeInsets.zero,
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    onPressed: null, // Lock button, payment triggers from Payable Panel below
                    child: const Text('Pay Now', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
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
  Widget _paymentMethods() {
    final methods = [
      (Icons.account_balance_wallet_outlined, 'UPI', 'PhonePe, GPay, BHIM'),
      (Icons.language_rounded, 'Net Banking', 'All major Indian banks'),
      (Icons.credit_card_rounded, 'Credit / Debit Card', 'Visa, Mastercard, RuPay'),
      (Icons.sync_rounded, 'Auto Debit', 'Setup e-NACH/ECS'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Methods',
          style: TextStyle(color: _slateDark, fontSize: 13, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        ...methods.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final active = _selectedPaymentMethod == idx;
          return GestureDetector(
            onTap: () => setState(() => _selectedPaymentMethod = idx),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: active ? _teal : _cardBorder, width: active ? 1.5 : 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFFD1FAE5) : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.$1, color: active ? _teal : _slateLight, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$2,
                          style: const TextStyle(color: _slateDark, fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.$3,
                          style: const TextStyle(color: _slateLight, fontSize: 10, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: active ? _teal : _slateLight.withAlpha((0.5 * 255).toInt()),
                        width: active ? 5.5 : 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

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
  Widget _payableAmountPanel(InvoiceModel? invoice) {
    if (invoice == null) {
      return _card_(
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No pending payments. All clear! 🎉',
              style: TextStyle(color: _teal, fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      );
    }

    return _card_(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PAYABLE AMOUNT',
            style: TextStyle(color: _slateLight, fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹ ${invoice.amount.toInt()}',
                  style: const TextStyle(color: _slateDark, fontSize: 13, fontWeight: FontWeight.w800),
                ),
                Text(
                  invoice.invoiceNumber,
                  style: const TextStyle(color: _slateLight, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                try {
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Processing secure payment...'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  await ref.read(billingControllerProvider.notifier).payInvoice(invoice.id);
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('Payment Successful!'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (e) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Payment failed: $e'),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.lock_outline_rounded, size: 18),
              label: Text(
                'Pay ₹${invoice.amount.toInt()}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.shield_outlined, color: _slateLight, size: 12),
              SizedBox(width: 4),
              Text(
                'SECURE 256-BIT SSL ENCRYPTED PAYMENT',
                style: TextStyle(color: _slateLight, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.3),
              ),
            ],
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
      (Icons.person_outline_rounded, 'Profile'),
    ];
    final routes = ['/client-dashboard', '/solar-grid', '/telemetry', null, '/tickets', '/profile'];
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
