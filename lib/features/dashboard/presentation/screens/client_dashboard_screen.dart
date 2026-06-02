import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ClientDashboardScreen extends StatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  int _selectedTimeFilter = 0;
  int _selectedNav = 0;

  // Premium Light Theme Design System
  static const _bg = Color(0xFFF4F6F8);
  static const _card = Colors.white;
  static const _cardBorder = Color(0xFFE5E7EB);
  static const _teal = Color(0xFF2A8C6E); // primary brand green-teal
  static const _amber = Color(0xFFF5A623);
  static const _headerBg = Colors.white;
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
                child: Column(
                  children: [
                    // Header strip with greeting + stats
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                      color: _headerBg,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Greeting row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Good morning, Rajesh ',
                                    style: TextStyle(
                                      color: _slateDark,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const Text(
                                    '👋',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: _cardBorder, width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.notifications_outlined,
                                  color: _slateLight,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Stats cards
                          _statsRow(),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _energyChart(),
                          const SizedBox(height: 16),
                          _plantHealth(),
                          const SizedBox(height: 16),
                          _performanceRatio(),
                          const SizedBox(height: 16),
                          _plantLocations(),
                          const SizedBox(height: 16),
                          _recentAlerts(),
                          const SizedBox(height: 16),
                          _quickActions(),
                          const SizedBox(height: 24),
                          _footer(),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _bottomNav(),
          ],
        ),
      ),
    );
  }

  // ── Top app bar ────────────────────────────────────────────────────────────
  Widget _topBar() {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: _headerBg,
        border: Border(
          bottom: BorderSide(color: _cardBorder, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Image.asset('assets/images/logo.png', height: 28),
          const Spacer(),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _cardBorder, width: 1),
            ),
            child: const Icon(
              Icons.settings_outlined,
              color: _slateLight,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats row ──────────────────────────────────────────────────────────────
  Widget _statsRow() {
    return Row(
      children: [
        // Live kW card — yellow gradient
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF5A623), Color(0xFFF8BA46)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF5A623).withValues(alpha: 0.22),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Live badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.bolt_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text(
                      '148.5',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'kW',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Current Power',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Today generation card — white with shadow
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _cardBorder, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Time filter tabs
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ...['1D', '1W', '1M', '1Y']
                        .asMap()
                        .entries
                        .map((e) => GestureDetector(
                              onTap: () => setState(
                                  () => _selectedTimeFilter = e.key),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _selectedTimeFilter == e.key
                                      ? _teal.withValues(alpha: 0.1)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  e.value,
                                  style: TextStyle(
                                    color: _selectedTimeFilter == e.key
                                        ? _teal
                                        : _slateLight,
                                    fontSize: 9.5,
                                    fontWeight: _selectedTimeFilter == e.key
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            )),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: const [
                    Text(
                      '856.9',
                      style: TextStyle(
                        color: _slateDark,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'kWh',
                      style: TextStyle(
                        color: _slateLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  "Today's Generation",
                  style: TextStyle(
                    color: _slateLight,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Energy generation chart ────────────────────────────────────────────────
  Widget _energyChart() {
    return _card_(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Energy Generation',
                style: TextStyle(
                  color: _slateDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _cardBorder, width: 0.8),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.show_chart_rounded, color: _teal, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Live Generation',
                      style: TextStyle(
                        color: _teal,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 100,
            width: double.infinity,
            child: CustomPaint(painter: _ChartPainter(color: _teal)),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['6am', '9am', '12pm', '3pm', '6pm']
                .map((t) => Text(
                      t,
                      style: const TextStyle(
                        color: _slateLight,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── Plant health ───────────────────────────────────────────────────────────
  Widget _plantHealth() {
    final plants = [
      ('Morwad, Rajasthan', 'Healthy', const Color(0xFF2DB584)),
      ('Pune Tech Park', 'Attention', const Color(0xFFF5A623)),
      ('Thane Industrial', 'Critical', const Color(0xFFEF4444)),
    ];
    return _card_(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Plant Health',
            style: TextStyle(
              color: _slateDark,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          ...plants.asMap().entries.map((entry) {
            final idx = entry.key;
            final p = entry.value;
            return Column(
              children: [
                if (idx > 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(color: Color(0xFFF1F5F9), height: 1),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: p.$3,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: p.$3.withValues(alpha: 0.4),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          p.$1,
                          style: const TextStyle(
                            color: _slateDark,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: p.$3.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          p.$2,
                          style: TextStyle(
                            color: p.$3,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ── Performance ratio ──────────────────────────────────────────────────────
  Widget _performanceRatio() {
    return _card_(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Ratio',
            style: TextStyle(
              color: _slateDark,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: SizedBox(
              width: 120,
              height: 120,
              child: CustomPaint(
                painter: _GaugePainter(
                  value: 0.82,
                  trackColor: const Color(0xFFF1F5F9),
                  fillColor: _teal,
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '82%',
                        style: TextStyle(
                          color: _slateDark,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'PR',
                        style: TextStyle(
                          color: _slateLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Your plants are performing 2% better than last month',
              style: TextStyle(
                color: _slateLight,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ── Plant locations ────────────────────────────────────────────────────────
  Widget _plantLocations() {
    return _card_(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Plant Locations',
            style: TextStyle(
              color: _slateDark,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(builder: (ctx, c) {
            final mapW = c.maxWidth;
            const mapH = 190.0;
            return SizedBox(
              width: mapW,
              height: mapH,
              child: Stack(
                children: [
                  // Premium soft background
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _cardBorder, width: 0.8),
                    ),
                  ),
                  // India map centred
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _IndiaMapPainter(),
                    ),
                  ),
                  // Rajasthan — top-left area
                  _marker(mapW, mapH, 0.32, 0.28, const Color(0xFF2DB584)),
                  // Pune — centre-right
                  _marker(mapW, mapH, 0.53, 0.62, const Color(0xFFF5A623)),
                  // Thane — near Pune
                  _marker(mapW, mapH, 0.51, 0.56, const Color(0xFFEF4444)),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(const Color(0xFF2DB584), 'Morwad'),
              const SizedBox(width: 16),
              _legendDot(const Color(0xFFF5A623), 'Pune'),
              const SizedBox(width: 16),
              _legendDot(const Color(0xFFEF4444), 'Thane'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: _slateLight,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _marker(
      double w, double h, double rx, double ry, Color color) {
    return Positioned(
      left: w * rx,
      top: h * ry,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 6,
              spreadRadius: 2,
            )
          ],
        ),
      ),
    );
  }

  // ── Recent alerts ──────────────────────────────────────────────────────────
  Widget _recentAlerts() {
    final alerts = [
      (
        const Color(0xFFEF4444),
        Icons.flash_off_rounded,
        'Main Inverter Failure',
        'Morwad, Rajasthan • 2h ago'
      ),
      (
        const Color(0xFFF5A623),
        Icons.trending_down_rounded,
        'Low Generation Alert',
        'Pune Tech Park • 5h ago'
      ),
      (
        _teal,
        Icons.build_circle_outlined,
        'Maintenance Scheduled',
        'Thane Industrial • Tomorrow'
      ),
    ];

    return _card_(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Alerts',
                style: TextStyle(
                  color: _slateDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'See All',
                  style: TextStyle(
                    color: _teal,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...alerts.map((a) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: a.$1.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: a.$1.withValues(alpha: 0.15), width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: a.$1.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(a.$2, color: a.$1, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.$3,
                            style: TextStyle(
                              color: a.$1,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            a.$4,
                            style: const TextStyle(
                              color: _slateLight,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: a.$1.withValues(alpha: 0.5),
                      size: 12,
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ── Quick actions ──────────────────────────────────────────────────────────
  Widget _quickActions() {
    final actions = [
      (Icons.confirmation_number_outlined, 'New Ticket', '/create-ticket'),
      (Icons.receipt_long_outlined, 'Invoice', '/billing'),
      (Icons.bar_chart_rounded, 'Reports', '/telemetry'),
      (Icons.shopping_bag_outlined, 'Shop', '/marketplace'),
    ];
    return _card_(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              color: _slateDark,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: actions
                .map((a) => GestureDetector(
                      onTap: () => context.push(a.$3),
                      child: Column(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: _teal.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: _teal.withValues(alpha: 0.18),
                                  width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: _teal.withValues(alpha: 0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(a.$1, color: _teal, size: 24),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            a.$2,
                            style: const TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
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
          '© 2025 Enercore Industrial Solutions. All rights reserved.',
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
                      color: ['·'].any(t.contains)
                          ? _slateLight.withValues(alpha: 0.4)
                          : _slateLight,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  // ── Bottom nav ─────────────────────────────────────────────────────────────
  Widget _bottomNav() {
    final items = [
      (Icons.home_rounded, 'Home'),
      (Icons.solar_power_rounded, 'Plants'),
      (Icons.sensors_rounded, 'Telemetry'),
      (Icons.receipt_long_rounded, 'Billing'),
      (Icons.confirmation_number_outlined, 'Tickets'),
      (Icons.person_outline_rounded, 'Profile'),
    ];
    final routes = [null, '/solar-grid', '/telemetry', '/billing', '/tickets', '/profile'];
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

// ── Smooth line chart painter ─────────────────────────────────────────────────
class _ChartPainter extends CustomPainter {
  final Color color;
  _ChartPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Bell-curve like solar generation (0 at edges, peak midday)
    final pts = [
      Offset(0, size.height),
      Offset(size.width * 0.1, size.height * 0.88),
      Offset(size.width * 0.2, size.height * 0.60),
      Offset(size.width * 0.35, size.height * 0.22),
      Offset(size.width * 0.5, size.height * 0.08),
      Offset(size.width * 0.65, size.height * 0.18),
      Offset(size.width * 0.8, size.height * 0.55),
      Offset(size.width * 0.9, size.height * 0.85),
      Offset(size.width, size.height),
    ];

    final linePath = _smoothPath(pts);

    // Fill
    final fillPath = Path.from(linePath);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    // Dot at peak
    canvas.drawCircle(
        pts[4],
        5,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill);
    canvas.drawCircle(
        pts[4],
        5,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0);
  }

  Path _smoothPath(List<Offset> pts) {
    final path = Path();
    path.moveTo(pts[0].dx, pts[0].dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final cp1 =
          Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i].dy);
      final cp2 = Offset(
          (pts[i].dx + pts[i + 1].dx) / 2, pts[i + 1].dy);
      path.cubicTo(
          cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts[i + 1].dx, pts[i + 1].dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Arc gauge painter ─────────────────────────────────────────────────────────
class _GaugePainter extends CustomPainter {
  final double value;
  final Color trackColor;
  final Color fillColor;
  _GaugePainter(
      {required this.value,
      required this.trackColor,
      required this.fillColor});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 8;
    const start = -math.pi * 0.75;
    const sweep = math.pi * 1.5;

    canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        start, sweep, false,
        Paint()
          ..color = trackColor
          ..strokeWidth = 10
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);

    canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        start, sweep * value, false,
        Paint()
          ..color = fillColor
          ..strokeWidth = 10
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── India map painter ─────────────────────────────────────────────────────────
class _IndiaMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Accurate India silhouette (normalised 0–1 coordinates) ──
    // Derived from real GeoJSON, simplified to ~60 points
    final raw = [
      // J&K / top-left
      [0.28, 0.00], [0.33, 0.00], [0.40, 0.02], [0.43, 0.05],
      // Pakistan border going right
      [0.46, 0.04], [0.50, 0.02], [0.54, 0.03], [0.57, 0.06],
      // Himachal / Uttarakhand
      [0.60, 0.08], [0.65, 0.09], [0.68, 0.12],
      // Nepal / Bihar border
      [0.72, 0.13], [0.76, 0.15], [0.80, 0.17],
      // NE states bump
      [0.84, 0.18], [0.88, 0.20], [0.90, 0.24], [0.89, 0.28],
      [0.86, 0.30], [0.84, 0.33], [0.88, 0.35], [0.90, 0.38],
      [0.88, 0.42], [0.84, 0.43],
      // Bangladesh / West Bengal
      [0.82, 0.40], [0.80, 0.42], [0.78, 0.46],
      // Odisha coast going south
      [0.79, 0.50], [0.78, 0.55], [0.76, 0.60],
      // Andhra coast
      [0.74, 0.65], [0.72, 0.70], [0.70, 0.75],
      // Tamil Nadu south-east
      [0.68, 0.80], [0.65, 0.86], [0.62, 0.90], [0.60, 0.94],
      // Tip of India (Kanyakumari)
      [0.57, 0.98], [0.54, 1.00], [0.51, 0.98],
      // Kerala west coast going north
      [0.48, 0.93], [0.45, 0.87], [0.43, 0.81],
      // Karnataka / Goa
      [0.40, 0.75], [0.37, 0.70], [0.34, 0.65],
      // Maharashtra coast
      [0.31, 0.60], [0.28, 0.55], [0.26, 0.50],
      // Gujarat coast
      [0.22, 0.46], [0.18, 0.43], [0.14, 0.40],
      [0.10, 0.38], [0.08, 0.34],
      // Kutch peninsula
      [0.06, 0.30], [0.08, 0.26], [0.12, 0.24],
      [0.16, 0.22], [0.14, 0.18],
      // Rajasthan border going north
      [0.16, 0.14], [0.20, 0.10], [0.24, 0.06],
      [0.28, 0.03], [0.28, 0.00],
    ];

    final path = Path();
    for (int i = 0; i < raw.length; i++) {
      final x = w * raw[i][0];
      final y = h * raw[i][1];
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Fill — beautiful soft slate-blue map color
    canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFFCBD5E1)
          ..style = PaintingStyle.fill);
    // Subtle border
    canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);

    // Sri Lanka
    final sl = Path();
    sl.addOval(Rect.fromCenter(
        center: Offset(w * 0.60, h * 1.02),
        width: w * 0.04,
        height: h * 0.05));
    canvas.drawPath(
        sl,
        Paint()
          ..color = const Color(0xFFCBD5E1)
          ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
