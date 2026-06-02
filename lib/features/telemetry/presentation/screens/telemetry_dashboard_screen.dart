import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TelemetryDashboardScreen extends StatefulWidget {
  const TelemetryDashboardScreen({super.key});

  @override
  State<TelemetryDashboardScreen> createState() => _TelemetryDashboardScreenState();
}

class _TelemetryDashboardScreenState extends State<TelemetryDashboardScreen> {
  int _selectedNav = 2; // Telemetry tab active
  int _selectedFilter = 0;
  String _selectedArray = 'Helios North Array';
  bool _showAlertBanner = true;

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
                child: Column(
                  children: [
                    if (_showAlertBanner) _alertBanner(),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _headerRow(),
                          const SizedBox(height: 16),
                          _selectorRow(),
                          const SizedBox(height: 16),
                          _voltageCard(),
                          const SizedBox(height: 12),
                          _currentCard(),
                          const SizedBox(height: 12),
                          _frequencyCard(),
                          const SizedBox(height: 12),
                          _generationCard(),
                          const SizedBox(height: 16),
                          _phaseCharacteristicsCard(),
                          const SizedBox(height: 16),
                          _generationHistogramCard(),
                          const SizedBox(height: 16),
                          _inverterStatusCard(),
                          const SizedBox(height: 16),
                          _gridEventsLogCard(),
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
          const Icon(Icons.sensors_rounded, color: _teal, size: 24),
          const SizedBox(width: 8),
          const Text(
            'Enercore Telemetry',
            style: TextStyle(
              color: _teal,
              fontSize: 16,
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
            child: const Icon(Icons.notifications_outlined, color: _slateLight, size: 20),
          ),
          const SizedBox(width: 8),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _cardBorder, width: 1),
            ),
            child: const Icon(Icons.menu_rounded, color: _slateLight, size: 20),
          ),
        ],
      ),
    );
  }

  // ── Alert Banner ───────────────────────────────────────────────────────────
  Widget _alertBanner() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFEE2E2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Panel B-12 fault detected. Ticket auto-created.',
              style: TextStyle(
                color: Color(0xFF991B1B),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _showAlertBanner = false),
            child: const Icon(Icons.close_rounded, color: Color(0xFF991B1B), size: 18),
          ),
        ],
      ),
    );
  }

  // ── Header Row ─────────────────────────────────────────────────────────────
  Widget _headerRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Real-Time Telemetry',
              style: TextStyle(
                color: _slateDark,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Connected via MQTT',
                style: TextStyle(
                  color: _teal,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Live stream from Helios North Array',
          style: TextStyle(
            color: _slateLight,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── Selector Dropdown & Filter Row ─────────────────────────────────────────
  Widget _selectorRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _cardBorder, width: 1),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedArray,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _slateLight, size: 18),
                style: const TextStyle(color: _slateDark, fontSize: 12, fontWeight: FontWeight.w700),
                onChanged: (String? val) {
                  if (val != null) setState(() => _selectedArray = val);
                },
                items: ['Helios North Array', 'Morwad South Array', 'Pune Tech Array']
                    .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                    .toList(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Row(
          children: ['1H', '6H', '24H', '7D']
              .asMap()
              .entries
              .map((e) => GestureDetector(
                    onTap: () => setState(() => _selectedFilter = e.key),
                    child: Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedFilter == e.key ? _teal : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _selectedFilter == e.key ? _teal : _cardBorder, width: 1),
                      ),
                      child: Text(
                        e.value,
                        style: TextStyle(
                          color: _selectedFilter == e.key ? Colors.white : _slateLight,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  // ── Card 1: Voltage Card ───────────────────────────────────────────────────
  Widget _voltageCard() {
    return _card_(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'VOLTAGE',
                style: TextStyle(color: _slateLight, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
              SizedBox(height: 8),
              Text(
                '240 V',
                style: TextStyle(color: _slateDark, fontSize: 24, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          SizedBox(
            width: 60,
            height: 35,
            child: CustomPaint(
              painter: _SparklinePainter(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Card 2: Current Card ───────────────────────────────────────────────────
  Widget _currentCard() {
    return _card_(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CURRENT',
                style: TextStyle(color: _slateLight, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: const [
                  Text(
                    '15',
                    style: TextStyle(color: _slateDark, fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'A',
                    style: TextStyle(color: _slateLight, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: const [
                  Icon(Icons.trending_up_rounded, color: Color(0xFF10B981), size: 12),
                  SizedBox(width: 2),
                  Text(
                    '+1.2% from avg',
                    style: TextStyle(color: Color(0xFF10B981), fontSize: 10.5, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
          const Icon(Icons.reorder_rounded, color: _slateLight, size: 20),
        ],
      ),
    );
  }

  // ── Card 3: Frequency Card ─────────────────────────────────────────────────
  Widget _frequencyCard() {
    return _card_(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'FREQUENCY',
                style: TextStyle(color: _slateLight, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
              Icon(Icons.reorder_rounded, color: _slateLight, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '50.2 Hz',
            style: TextStyle(color: _teal, fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          const ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(4)),
            child: LinearProgressIndicator(
              value: 0.83,
              backgroundColor: Color(0xFFF1F5F9),
              color: _teal,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  // ── Card 4: Generation Card (Amber Background) ─────────────────────────────
  Widget _generationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDE68A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF5A623).withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'GENERATION',
                style: TextStyle(color: Color(0xFF92400E), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
              Icon(Icons.remove_red_eye_outlined, color: Color(0xFF92400E), size: 18),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '3.8 kW',
            style: TextStyle(color: Color(0xFF92400E), fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Peak output achieved',
            style: TextStyle(color: Color(0xFFB45309), fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ── Card 5: Phase Characteristics Card ─────────────────────────────────────
  Widget _phaseCharacteristicsCard() {
    return _card_(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Phase Characteristics',
                style: TextStyle(color: _slateDark, fontSize: 14, fontWeight: FontWeight.w800),
              ),
              Row(
                children: [
                  _legendIndicator(const Color(0xFF0D9488), 'Voltage'),
                  const SizedBox(width: 10),
                  _legendIndicator(const Color(0xFF2A8C6E).withValues(alpha: 0.5), 'Current'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Live Voltage (V) vs Current (A) correlation',
            style: TextStyle(color: _slateLight, fontSize: 11, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 90,
            width: double.infinity,
            child: CustomPaint(
              painter: _PhaseChartPainter(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['11:00', '11:15', '11:30', '11:45', '12:00']
                .map((t) => Text(t, style: const TextStyle(color: _slateLight, fontSize: 10, fontWeight: FontWeight.w500)))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _legendIndicator(Color col, String label) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: col, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: _slateLight, fontSize: 9.5, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ── Card 6: Generation Histogram Card ──────────────────────────────────────
  Widget _generationHistogramCard() {
    return _card_(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Generation',
            style: TextStyle(color: _slateDark, fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          const Text(
            'Power output (kW) per interval',
            style: TextStyle(color: _slateLight, fontSize: 11, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 18),
          _histogramChart(),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Peak Today', style: TextStyle(color: _slateLight, fontSize: 10, fontWeight: FontWeight.w600)),
                  SizedBox(height: 2),
                  Text('4.2 kW', style: TextStyle(color: _teal, fontSize: 12, fontWeight: FontWeight.w800)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Avg Efficiency', style: TextStyle(color: _slateLight, fontSize: 10, fontWeight: FontWeight.w600)),
                  SizedBox(height: 2),
                  Text('94.8%', style: TextStyle(color: _teal, fontSize: 12, fontWeight: FontWeight.w800)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _histogramChart() {
    final heights = [0.25, 0.45, 0.30, 0.65, 0.55, 0.40, 0.80, 0.20];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: heights
          .map((h) => Container(
                width: 24,
                height: 80 * h,
                decoration: BoxDecoration(
                  color: h > 0.6 ? const Color(0xFF2A8C6E) : const Color(0xFF2A8C6E).withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ))
          .toList(),
    );
  }

  // ── Card 7: Inverter Status Card ───────────────────────────────────────────
  Widget _inverterStatusCard() {
    final inverters = [
      ('INV-Alpha-01', 'SN: 26023-EC', 'ONLINE', const Color(0xFF10B981)),
      ('INV-Alpha-02', 'SN: 26024-EC', 'ONLINE', const Color(0xFF10B981)),
      ('INV-Beta-03', 'SN: 26027-EC', 'OFFLINE', const Color(0xFFEF4444)),
    ];
    return _card_(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Inverter Status',
            style: TextStyle(color: _slateDark, fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          ...inverters.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            return Column(
              children: [
                if (idx > 0) const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(color: Color(0xFFF1F5F9), height: 1),
                ),
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: item.$4.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.solar_power_rounded, color: item.$4, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.$1, style: const TextStyle(color: _slateDark, fontSize: 12.5, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 1.5),
                          Text(item.$2, style: const TextStyle(color: _slateLight, fontSize: 10, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: item.$4.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.$3,
                        style: TextStyle(color: item.$4, fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ── Card 8: Grid Events Log Card ───────────────────────────────────────────
  Widget _gridEventsLogCard() {
    final events = [
      (
        const Color(0xFFEF4444),
        'Critical: Voltage Drop',
        'Phase 3 voltage fell below 210V threshold for 2.4s',
        '15:45:01'
      ),
      (
        const Color(0xFFF5A623),
        'Warning: High Temperature',
        'Inverter temperature reached 78°C. Thermal throttling enabled.',
        '12:20:15'
      ),
      (
        _teal,
        'Info: MQTT Resync',
        'Broker connection re-established successfully.',
        '10:14:44'
      ),
    ];
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: _card,
          border: Border.all(color: _cardBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              color: const Color(0xFFF8FAFC),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: const Text(
                'Grid Events Log',
                style: TextStyle(color: _slateDark, fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ),
            // Event List
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ...events.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final ev = entry.value;
                    return Column(
                      children: [
                        if (idx > 0) const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(color: Color(0xFFF1F5F9), height: 1),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 3),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: ev.$1, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(ev.$2, style: const TextStyle(color: _slateDark, fontSize: 12, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 2),
                                  Text(ev.$3, style: const TextStyle(color: _slateLight, fontSize: 10.5, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(ev.$4, style: const TextStyle(color: _slateLight, fontSize: 10, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 14),
                  // Button
                  Container(
                    width: double.infinity,
                    height: 38,
                    decoration: BoxDecoration(
                      border: Border.all(color: _teal.withValues(alpha: 0.3), width: 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'View All Event Logs',
                        style: TextStyle(color: _teal, fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────
  Widget _footer() {
    return Column(
      children: [
        const Text(
          '© 2025 Enercore Telemetry Systems. All rights reserved.',
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
    final routes = ['/client-dashboard', '/solar-grid', null, '/billing', '/tickets', '/profile'];
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

// ── Phase Chart Painter ──────────────────────────────────────────────────────
class _PhaseChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Voltage Curve (Teal)
    final vPts = [
      Offset(0, h * 0.50),
      Offset(w * 0.25, h * 0.40),
      Offset(w * 0.50, h * 0.60),
      Offset(w * 0.75, h * 0.45),
      Offset(w, h * 0.55),
    ];
    final vPath = _smoothPath(vPts);
    final vPaint = Paint()
      ..color = const Color(0xFF0D9488)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(vPath, vPaint);

    // Current Curve (Light Teal)
    final cPts = [
      Offset(0, h * 0.70),
      Offset(w * 0.25, h * 0.55),
      Offset(w * 0.50, h * 0.75),
      Offset(w * 0.75, h * 0.60),
      Offset(w, h * 0.70),
    ];
    final cPath = _smoothPath(cPts);
    final cPaint = Paint()
      ..color = const Color(0xFF2A8C6E).withValues(alpha: 0.5)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(cPath, cPaint);
  }

  Path _smoothPath(List<Offset> pts) {
    final path = Path();
    path.moveTo(pts[0].dx, pts[0].dy);
    for (int i = 0; i < pts.length - 1; i++) {
      final cp1 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i].dy);
      final cp2 = Offset((pts[i].dx + pts[i + 1].dx) / 2, pts[i + 1].dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts[i + 1].dx, pts[i + 1].dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Sparkline Painter ────────────────────────────────────────────────────────
class _SparklinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0D9488)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final heights = [0.35, 0.55, 0.45, 0.80, 0.65, 0.95, 0.85];
    final spacing = size.width / (heights.length - 1);

    for (int i = 0; i < heights.length; i++) {
      final x = i * spacing;
      final y = size.height * (1.0 - heights[i]);
      canvas.drawLine(Offset(x, size.height), Offset(x, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
