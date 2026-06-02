import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  int _selectedNav = 3; // Billing tab active
  int _selectedPaymentMethod = 0;

  // Premium Design System
  static const _bg = Color(0xFFF4F6F8);
  static const _card = Colors.white;
  static const _cardBorder = Color(0xFFE5E7EB);
  static const _teal = Color(0xFF2A8C6E); // primary brand green-teal
  static const _slateDark = Color(0xFF1E293B);
  static const _slateLight = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _headerRow(),
                      const SizedBox(height: 16),
                      _statsRow(),
                      const SizedBox(height: 18),
                      _paymentMethods(),
                      const SizedBox(height: 18),
                      _invoiceHistoryCard(),
                      const SizedBox(height: 18),
                      _payableAmountPanel(),
                      const SizedBox(height: 24),
                      _footer(),
                      const SizedBox(height: 12),
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
            onTap: () => context.go('/client-dashboard'),
            child: const Icon(Icons.arrow_back_rounded, color: _slateDark, size: 22),
          ),
          const SizedBox(width: 12),
          const Text(
            'Billing Overview',
            style: TextStyle(
              color: _slateDark,
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: _cardBorder, width: 1),
            ),
            child: const Icon(Icons.info_outline_rounded, color: _slateLight, size: 20),
          ),
        ],
      ),
    );
  }

  // ── Header Row ─────────────────────────────────────────────────────────────
  Widget _headerRow() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            '₹12,400 due',
            style: TextStyle(
              color: Color(0xFFD97706),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  // ── Stats Row ──────────────────────────────────────────────────────────────
  Widget _statsRow() {
    return Row(
      children: [
        // Total Due Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFCA5A5), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Icon(Icons.receipt_long_outlined, color: Color(0xFFDC2626), size: 18),
                    Text(
                      'DUE OCT 31',
                      style: TextStyle(color: Color(0xFFDC2626), fontSize: 9, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Total Due',
                  style: TextStyle(color: _slateLight, fontSize: 10.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                const Text(
                  '₹12,400',
                  style: TextStyle(color: _slateDark, fontSize: 20, fontWeight: FontWeight.w800),
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
                    ),
                    onPressed: () {},
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
              children: const [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                    Text(
                      'SUCCESS',
                      style: TextStyle(color: Color(0xFF10B981), fontSize: 9, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  'Last Payment',
                  style: TextStyle(color: _slateLight, fontSize: 10.5, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4),
                Text(
                  '₹8,200',
                  style: TextStyle(color: _slateDark, fontSize: 20, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 14),
                Text(
                  'Paid on 15 Oct',
                  style: TextStyle(color: _slateLight, fontSize: 10.5, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 22),
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
                      border: Border.all(color: active ? _teal : _slateLight.withValues(alpha: 0.5), width: active ? 5.5 : 1.5),
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
  Widget _invoiceHistoryCard() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'INV-2023-1024',
                  style: TextStyle(color: _slateDark, fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
              ),
              const Expanded(
                child: Text(
                  'Oct 2023',
                  style: TextStyle(color: _slateLight, fontSize: 11.5, fontWeight: FontWeight.w500),
                ),
              ),
              const Expanded(
                child: Text(
                  '₹12,400',
                  style: TextStyle(color: _slateDark, fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Overdue',
                  style: TextStyle(color: Color(0xFFDC2626), fontSize: 9.5, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Payable Amount Panel ───────────────────────────────────────────────────
  Widget _payableAmountPanel() {
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
            child: const Text(
              '₹ 12,400',
              style: TextStyle(color: _slateDark, fontSize: 13, fontWeight: FontWeight.w800),
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
              onPressed: () {},
              icon: const Icon(Icons.lock_outline_rounded, size: 18),
              label: const Text(
                'Pay ₹12,400',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
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
                'Secured by Razorpay',
                style: TextStyle(color: _slateLight, fontSize: 10, fontWeight: FontWeight.w600),
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
