import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SolarGridScreen extends StatefulWidget {
  const SolarGridScreen({super.key});

  @override
  State<SolarGridScreen> createState() => _SolarGridScreenState();
}

class _SolarGridScreenState extends State<SolarGridScreen> {
  int _selectedNav = 1; // Plants tab active
  final List<int> _panelStatuses = [];

  // Premium Design Tokens
  static const _bg = Color(0xFFF4F6F8);
  static const _card = Colors.white;
  static const _cardBorder = Color(0xFFE5E7EB);
  static const _teal = Color(0xFF2A8C6E); // primary brand green-teal
  static const _slateDark = Color(0xFF1E293B);
  static const _slateLight = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _initPanelStatuses();
  }

  void _initPanelStatuses() {
    final rand = math.Random(42); // Seeded random for consistent layout matching screenshot
    for (int i = 0; i < 256; i++) {
      // 88% active, 7% fault, 5% offline
      int r = rand.nextInt(100);
      if (r < 88) {
        _panelStatuses.add(0); // Active
      } else if (r < 94) {
        _panelStatuses.add(1); // Fault
      } else {
        _panelStatuses.add(2); // Offline
      }
    }
  }

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
                    _breadcrumbs(),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _plantOverviewCard(),
                          const SizedBox(height: 16),
                          _panelLayoutCard(),
                          const SizedBox(height: 16),
                          _liveTelemetryCard(),
                          const SizedBox(height: 16),
                          _voltageCurrentChart(),
                          const SizedBox(height: 16),
                          _faultHistoryCard(),
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
        color: Colors.white,
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

  // ── Breadcrumbs ────────────────────────────────────────────────────────────
  Widget _breadcrumbs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/client-dashboard'),
            child: const Text(
              'Dashboard',
              style: TextStyle(
                color: _slateLight,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Text('  >  ', style: TextStyle(color: _slateLight, fontSize: 11.5)),
          const Text(
            'Plants',
            style: TextStyle(
              color: _slateLight,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Text('  >  ', style: TextStyle(color: _slateLight, fontSize: 11.5)),
          const Text(
            'Plant Alpha – Pune',
            style: TextStyle(
              color: _teal,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── Plant Overview Card ────────────────────────────────────────────────────
  Widget _plantOverviewCard() {
    return _card_(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.location_on_rounded, color: _teal, size: 18),
              SizedBox(width: 6),
              Text(
                'Plant Alpha – Pune',
                style: TextStyle(
                  color: _slateDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _badgeChip('800kW', const Color(0xFFFEF3C7), const Color(0xFFD97706)),
              const SizedBox(width: 8),
              _badgeChip('Operational', const Color(0xFFD1FAE5), _teal),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              _overviewStat('CAPACITY', '800kW', false),
              _overviewStat('LAST SYNC', '3m ago', false),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _overviewStat('UPTIME', '99.8%', true),
              _overviewStat('TODAY', '1.2MWh', true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badgeChip(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textCol,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _overviewStat(String label, String value, bool isGreen) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _slateLight,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: isGreen ? const Color(0xFF10B981) : _slateDark,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ── Panel Layout Card ──────────────────────────────────────────────────────
  Widget _panelLayoutCard() {
    return _card_(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Panel Layout – 256 units',
                style: TextStyle(
                  color: _slateDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(Icons.grid_view_rounded, color: _slateLight, size: 18),
            ],
          ),
          const SizedBox(height: 16),
          // 16x16 grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 16,
              crossAxisSpacing: 3,
              mainAxisSpacing: 3,
            ),
            itemCount: 256,
            itemBuilder: (context, idx) {
              final status = _panelStatuses[idx];
              Color col = const Color(0xFF6EE7B7); // Active (Teal)
              if (status == 1) {
                col = const Color(0xFFFCA5A5); // Fault (Red)
              } else if (status == 2) {
                col = const Color(0xFFCBD5E1); // Off-line (Gray)
              }
              return Container(
                decoration: BoxDecoration(
                  color: col,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // Legend row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendIndicator(const Color(0xFF6EE7B7), 'Active'),
              const SizedBox(width: 16),
              _legendIndicator(const Color(0xFFFCA5A5), 'Fault'),
              const SizedBox(width: 16),
              _legendIndicator(const Color(0xFFCBD5E1), 'Off-line'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendIndicator(Color col, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: col, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: _slateLight,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── Live Telemetry Card ────────────────────────────────────────────────────
  Widget _liveTelemetryCard() {
    return _card_(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Live Telemetry',
                style: TextStyle(
                  color: _slateDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'MQTT Connected',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Voltage progress
          _telemetryProgress('Voltage', '285V', 0.57),
          const SizedBox(height: 14),
          // Current progress
          _telemetryProgress('Current', '350A', 0.70),
          const SizedBox(height: 14),
          // Frequency progress
          _telemetryProgress('Frequency', '50.0Hz', 0.83, isAmber: true),
          const SizedBox(height: 18),
          // Sub-cards row
          Row(
            children: [
              Expanded(child: _statusSubcard('Grid Health', 'Excellent')),
              const SizedBox(width: 10),
              Expanded(child: _statusSubcard('Inverter Status', 'Online')),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'Power Factor\n0.98',
                style: TextStyle(
                  color: _slateDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              Text(
                'Updated 3s ago',
                style: TextStyle(
                  color: _slateLight,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _telemetryProgress(String label, String val, double progress, {bool isAmber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: _slateDark, fontSize: 11, fontWeight: FontWeight.w700),
            ),
            Text(
              val,
              style: const TextStyle(color: _slateDark, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFFF1F5F9),
            color: isAmber ? const Color(0xFF92400E) : _teal,
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _statusSubcard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _cardBorder, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _slateLight,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF10B981),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ── Voltage & Current Chart ────────────────────────────────────────────────
  Widget _voltageCurrentChart() {
    return _card_(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Voltage & Current',
            style: TextStyle(
              color: _slateDark,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 90,
            width: double.infinity,
            child: CustomPaint(
              painter: _TelemetryChartPainter(),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _chartLegendIndicator(true, 'Voltage (V)'),
              const SizedBox(width: 20),
              _chartLegendIndicator(false, 'Current (A)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chartLegendIndicator(bool isSolid, String label) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          child: CustomPaint(
            size: const Size(20, 3),
            painter: _LineLegendPainter(isSolid: isSolid, color: _teal),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: _slateLight,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── Fault History Card ─────────────────────────────────────────────────────
  Widget _faultHistoryCard() {
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
            // Dark Navy Header Bar
            Container(
              width: double.infinity,
              color: const Color(0xFF0F172A),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: const Text(
                'Fault History',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            // Table content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Headers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Expanded(
                        child: Text(
                          'Panel ID',
                          style: TextStyle(color: _slateLight, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Type',
                          style: TextStyle(color: _slateLight, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        'Status',
                        style: TextStyle(color: _slateLight, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: Color(0xFFF1F5F9), height: 1),
                  const SizedBox(height: 8),
                  // Row 1
                  _faultRow('P-214', 'Voltage Surge', 'Resolved', const Color(0xFFEF4444)),
                  const SizedBox(height: 8),
                  const Divider(color: Color(0xFFF1F5F9), height: 1),
                  const SizedBox(height: 8),
                  // Row 2
                  _faultRow('P-045', 'Current Failure', 'Pending', const Color(0xFFD97706)),
                  const SizedBox(height: 8),
                  const Divider(color: Color(0xFFF1F5F9), height: 1),
                  const SizedBox(height: 8),
                  // Row 3
                  _faultRow('P-189', 'Efficiency Drop', 'Resolved', const Color(0xFFEF4444)),
                  const SizedBox(height: 14),
                  // View Full Logs link
                  GestureDetector(
                    onTap: () {},
                    child: const Text(
                      'View Full Logs',
                      style: TextStyle(
                        color: _teal,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
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

  Widget _faultRow(String id, String type, String status, Color statusCol) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              id,
              style: const TextStyle(color: _slateDark, fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Text(
              type,
              style: const TextStyle(color: _slateLight, fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            status,
            style: TextStyle(color: statusCol, fontSize: 11.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────
  Widget _footer() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', height: 20),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          '© 2024 Enercore. All rights reserved.',
          style: TextStyle(
            color: _slateLight,
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Legal', style: TextStyle(color: _slateLight, fontSize: 10, fontWeight: FontWeight.w500)),
            Container(
              width: 1,
              height: 8,
              color: _slateLight.withValues(alpha: 0.3),
              margin: const EdgeInsets.symmetric(horizontal: 10),
            ),
            const Text('Privacy', style: TextStyle(color: _slateLight, fontSize: 10, fontWeight: FontWeight.w500)),
          ],
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
    final routes = ['/client-dashboard', null, '/telemetry', '/billing', '/tickets', '/profile'];
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

// ── Telemetry Chart Painter ──────────────────────────────────────────────────
class _TelemetryChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Voltage Curve (Solid Teal)
    final vPts = [
      Offset(0, h * 0.70),
      Offset(w * 0.15, h * 0.40),
      Offset(w * 0.35, h * 0.60),
      Offset(w * 0.50, h * 0.20),
      Offset(w * 0.70, h * 0.85),
      Offset(w * 0.85, h * 0.90),
      Offset(w, h * 0.20),
    ];
    final vPath = _smoothPath(vPts);
    final vPaint = Paint()
      ..color = const Color(0xFF2A8C6E)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(vPath, vPaint);

    // Current Curve (Dotted Teal)
    final cPts = [
      Offset(0, h * 0.80),
      Offset(w * 0.15, h * 0.55),
      Offset(w * 0.35, h * 0.72),
      Offset(w * 0.50, h * 0.35),
      Offset(w * 0.70, h * 0.95),
      Offset(w * 0.85, h * 0.95),
      Offset(w, h * 0.32),
    ];
    final cPath = _smoothPath(cPts);
    final cPaint = Paint()
      ..color = const Color(0xFF2A8C6E).withValues(alpha: 0.6)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Drawing dotted path
    _drawDashedPath(canvas, cPath, cPaint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double distance = 0.0;
    for (final pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        canvas.drawPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
      distance = 0.0;
    }
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

// ── Line Legend Painter ──────────────────────────────────────────────────────
class _LineLegendPainter extends CustomPainter {
  final bool isSolid;
  final Color color;
  _LineLegendPainter({required this.isSolid, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    if (isSolid) {
      canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
    } else {
      // Dashed
      canvas.drawLine(Offset(0, size.height / 2), Offset(4, size.height / 2), paint);
      canvas.drawLine(Offset(8, size.height / 2), Offset(12, size.height / 2), paint);
      canvas.drawLine(Offset(16, size.height / 2), Offset(20, size.height / 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
