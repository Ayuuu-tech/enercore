import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../notifications/data/notifications_repository.dart';
import '../../../telemetry/data/telemetry_repository.dart';
import '../../../profile/application/profile_controller.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../widgets/plant_map_view.dart';

class ClientDashboardScreen extends ConsumerStatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  ConsumerState<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends ConsumerState<ClientDashboardScreen> {
  int _selectedTimeFilter = 0;
  int _selectedNav = 0;

  @override
  void initState() {
    super.initState();
    // Drop any cached telemetry from a previous session/user so the dashboard
    // always reflects the currently logged-in user's plant access.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(telemetryDashboardProvider);
      ref.invalidate(periodYieldProvider);
      ref.invalidate(combinedGenerationSeriesProvider);
    });
  }

  // Premium Light Theme Design System
  static const _bg = Color(0xFFF4F6F8);
  static const _card = Colors.white;
  static const _cardBorder = Color(0xFFE5E7EB);
  static const _teal = Color(0xFF2A8C6E); // primary brand green-teal
  static const _headerBg = Colors.white;
  static const _slateDark = Color(0xFF1E293B);
  static const _slateLight = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(telemetryDashboardProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: dashboardAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: _teal),
                ),
                error: (err, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Failed to connect to Trackso API',
                        style: TextStyle(color: _slateDark, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('$err', style: const TextStyle(color: _slateLight, fontSize: 12)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: _teal),
                        onPressed: () => ref.refresh(telemetryDashboardProvider),
                        child: const Text('Retry', style: TextStyle(color: Colors.white)),
                      )
                    ],
                  ),
                ),
                data: (data) => RefreshIndicator(
                  onRefresh: () async {
                    // Refresh every dashboard data source so all cards reflect
                    // the current user's plant access, not a stale cache.
                    ref.invalidate(periodYieldProvider);
                    ref.invalidate(combinedGenerationSeriesProvider);
                    ref.invalidate(telemetryDashboardProvider);
                    await ref.read(telemetryDashboardProvider.future);
                  },
                  color: _teal,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
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
                                      Text(
                                        'Good morning, ${ref.watch(authControllerProvider).value?.name ?? 'User'} ',
                                        style: const TextStyle(
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
                              _statsRow(data),
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
                              _plantHealth(data),
                              const SizedBox(height: 16),
                              _performanceRatio(data),
                              const SizedBox(height: 16),
                              _plantLocations(data),
                              const SizedBox(height: 16),
                              _recentAlerts(data),
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
          GestureDetector(
            onTap: () => context.push('/notifications'),
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_none_rounded, color: _slateDark, size: 23),
                  Consumer(
                    builder: (context, ref, _) {
                      final unread = ref.watch(unreadNotificationsCountProvider).value ?? 0;
                      if (unread == 0) return const SizedBox.shrink();
                      return Positioned(
                        right: -3,
                        top: -3,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$unread',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          UserAvatar(
            size: 32,
            onTap: () {
              // Load a fresh profile each time it's opened.
              ref.invalidate(profileControllerProvider);
              context.push('/profile');
            },
          ),
        ],
      ),
    );
  }

  // ── Stats row ──────────────────────────────────────────────────────────────
  Widget _statsRow(TelemetryDashboardModel data) {
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
                    Text(
                      data.totalPower.toStringAsFixed(1),
                      style: const TextStyle(
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
                Consumer(
                  builder: (context, ref, _) {
                    final yieldAsync = ref.watch(periodYieldProvider);
                    // Pick the value for the selected filter (fall back to today's
                    // yield from the dashboard while the period data loads).
                    double kwh = data.todayYield;
                    final py = yieldAsync.value;
                    if (py != null) {
                      kwh = [py.day, py.week, py.month, py.year][_selectedTimeFilter];
                    }
                    const labels = [
                      "Today's Generation",
                      "This Week's Generation",
                      "This Month's Generation",
                      "This Year's Generation",
                    ];
                    // Show MWh for large numbers so the card doesn't overflow.
                    final bool asMwh = kwh >= 10000;
                    final String valueStr =
                        asMwh ? (kwh / 1000).toStringAsFixed(1) : kwh.toStringAsFixed(1);
                    final String unit = asMwh ? 'MWh' : 'kWh';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              valueStr,
                              style: const TextStyle(
                                color: _slateDark,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              unit,
                              style: const TextStyle(
                                color: _slateLight,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (yieldAsync.isLoading) ...[
                              const SizedBox(width: 8),
                              const SizedBox(
                                width: 10,
                                height: 10,
                                child: CircularProgressIndicator(strokeWidth: 1.6, color: _teal),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          labels[_selectedTimeFilter],
                          style: const TextStyle(
                            color: _slateLight,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
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
    return _buildCard(
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
          Consumer(
            builder: (context, ref, _) {
              final seriesAsync = ref.watch(combinedGenerationSeriesProvider);
              return seriesAsync.when(
                loading: () => const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator(color: _teal, strokeWidth: 2)),
                ),
                error: (e, _) => SizedBox(
                  height: 100,
                  child: Center(
                    child: Text('Chart unavailable: $e',
                        style: const TextStyle(color: _slateLight, fontSize: 10)),
                  ),
                ),
                data: (series) {
                  if (series.length < 2) {
                    return const SizedBox(
                      height: 100,
                      child: Center(
                        child: Text('Collecting live data…',
                            style: TextStyle(color: _slateLight, fontSize: 11)),
                      ),
                    );
                  }
                  const labelCount = 5;
                  final labels = List.generate(labelCount, (i) {
                    final idx = (i * (series.length - 1) / (labelCount - 1)).round();
                    final t = series[idx].timestamp;
                    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                  });
                  return Column(
                    children: [
                      SizedBox(
                        height: 100,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _ChartPainter(
                            color: _teal,
                            values: series.map((p) => p.totalGeneration).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: labels
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
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Plant health ───────────────────────────────────────────────────────────
  Widget _plantHealth(TelemetryDashboardModel data) {
    final plants = data.plants.values.toList();
    return _buildCard(
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
          if (plants.isEmpty)
            const Text('No active solar plants.', style: TextStyle(color: _slateLight, fontSize: 12))
          else
            ...plants.asMap().entries.map((entry) {
              final idx = entry.key;
              final p = entry.value;
              
              Color statusColor = const Color(0xFF2DB584); // green
              if (p.status.toLowerCase() == 'attention' || p.status.toLowerCase() == 'warning') {
                statusColor = const Color(0xFFF5A623);
              } else if (p.status.toLowerCase() == 'critical' || p.status.toLowerCase() == 'fault') {
                statusColor = const Color(0xFFEF4444);
              }

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
                            color: statusColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withValues(alpha: 0.4),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.siteName,
                                style: const TextStyle(
                                  color: _slateDark,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Live: ${p.livePower.toStringAsFixed(1)} kW | Today: ${p.dailyEnergy.toStringAsFixed(0)} kWh',
                                style: const TextStyle(
                                  color: _slateLight,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            p.status,
                            style: TextStyle(
                              color: statusColor,
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
  Widget _performanceRatio(TelemetryDashboardModel data) {
    final prValue = data.performanceRatio / 100.0;
    return _buildCard(
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
                  value: prValue,
                  trackColor: const Color(0xFFF1F5F9),
                  fillColor: _teal,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${data.performanceRatio.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: _slateDark,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'CUF / PR',
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
              'Your plants performance metrics are synchronized live from Trackso.',
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
  Widget _plantLocations(TelemetryDashboardModel data) {
    // Build map sites from the user's accessible plants (real coordinates).
    final sites = <PlantSite>[];
    for (final p in data.plants.values) {
      final pos = plantCoordinatesFor(p.siteName);
      if (pos == null) continue;
      sites.add(PlantSite(
        name: p.siteName,
        position: pos,
        active: p.status.toLowerCase() == 'active',
      ));
    }

    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sites Map View',
                style: TextStyle(color: _slateDark, fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const Icon(Icons.satellite_alt_rounded, color: _slateLight, size: 18),
            ],
          ),
          const SizedBox(height: 14),
          if (sites.isEmpty)
            Container(
              height: 120,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _cardBorder, width: 0.8),
              ),
              child: const Text('No site locations available',
                  style: TextStyle(color: _slateLight, fontSize: 12)),
            )
          else
            PlantMapPreview(
              sites: sites,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => PlantMapFullScreen(sites: sites)),
              ),
            ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app_rounded, size: 13, color: _slateLight),
              SizedBox(width: 5),
              Text('Tap the map to explore & zoom',
                  style: TextStyle(color: _slateLight, fontSize: 11, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }


  // ── Recent alerts ──────────────────────────────────────────────────────────
  Widget _recentAlerts(TelemetryDashboardModel data) {
    return _buildCard(
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
          if (data.alerts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('No recent system alerts.', style: TextStyle(color: _slateLight, fontSize: 12)),
            )
          else
            ...data.alerts.map((a) {
              Color alertColor = _teal;
              IconData icon = Icons.info_outline;
              if (a.type == 'WARNING' || a.type == 'CRITICAL') {
                alertColor = a.type == 'CRITICAL' ? const Color(0xFFEF4444) : const Color(0xFFF5A623);
                icon = a.type == 'CRITICAL' ? Icons.flash_off_rounded : Icons.trending_down_rounded;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: alertColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: alertColor.withValues(alpha: 0.15), width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: alertColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: alertColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.title,
                            style: TextStyle(
                              color: alertColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${a.location} • ${a.time}',
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
                      color: alertColor.withValues(alpha: 0.5),
                      size: 12,
                    ),
                  ],
                ),
              );
            }),
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
    return _buildCard(
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
    ];
    final routes = [null, '/solar-grid', '/telemetry', '/billing', '/tickets'];
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
              setState(() => _selectedNav = i);
              if (routes[i] != null) {
                context.push(routes[i]!);
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
  Widget _buildCard({required Widget child}) {
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
  final List<double> values;
  _ChartPainter({required this.color, required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final maxV = values.reduce(math.max);
    final range = maxV <= 0 ? 1.0 : maxV;
    final pts = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      // Baseline at the bottom, peak at 8% from the top
      final y = size.height * (1.0 - 0.92 * (values[i] / range).clamp(0.0, 1.0));
      pts.add(Offset(x, y));
    }

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
  bool shouldRepaint(covariant _ChartPainter old) => old.values != values;
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
