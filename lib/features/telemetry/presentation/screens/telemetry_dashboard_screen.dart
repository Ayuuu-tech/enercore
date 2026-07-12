import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/widgets/user_avatar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../ticketing/data/plants_repository.dart';
import '../../../ticketing/domain/plant_model.dart';
import '../../data/telemetry_repository.dart';
import '../widgets/chart_painters.dart';

class TelemetryDashboardScreen extends ConsumerStatefulWidget {
  const TelemetryDashboardScreen({super.key});

  @override
  ConsumerState<TelemetryDashboardScreen> createState() => _TelemetryDashboardScreenState();
}

class _TelemetryDashboardScreenState extends ConsumerState<TelemetryDashboardScreen> {
  int _selectedNav = 2; // Telemetry tab active
  int _selectedFilter = 0;
  bool _showAlertBanner = true;

  static const _filterHours = [1, 6, 24, 168];

  List<PlantModel> _plants = [];
  PlantModel? _selectedPlant;
  List<TelemetrySeriesPoint> _series = [];
  List<DeviceModel> _devices = [];
  TelemetryDashboardModel? _dashboard;
  bool _loading = true;
  bool _noPlants = false;
  String? _error;
  Timer? _refreshTimer;

  // Premium Design System
  static const _bg = Color(0xFFF4F6F8);
  static const _card = Colors.white;
  static const _cardBorder = Color(0xFFE5E7EB);
  static const _teal = Color(0xFF2A8C6E); // primary brand green-teal
  static const _slateDark = Color(0xFF1E293B);
  static const _slateLight = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _load();
    // Backend syncs Trackso data every 2 minutes; refresh at the same cadence.
    _refreshTimer = Timer.periodic(const Duration(minutes: 2), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      if (_plants.isEmpty) {
        _plants = await ref.read(plantsRepositoryProvider).getPlants();
        if (_plants.isEmpty) {
          if (!mounted) return;
          setState(() {
            _noPlants = true;
            _loading = false;
            _error = null;
          });
          return;
        }
        _selectedPlant ??= _plants.first;
      }
      final telemetryRepo = ref.read(telemetryRepositoryProvider);
      final results = await Future.wait<dynamic>([
        telemetryRepo.getSeries(_selectedPlant!.id, _filterHours[_selectedFilter]),
        telemetryRepo.getDashboard(),
        telemetryRepo.getDevices(_selectedPlant!.id),
      ]);
      if (!mounted) return;
      setState(() {
        _series = results[0] as List<TelemetrySeriesPoint>;
        _dashboard = results[1] as TelemetryDashboardModel;
        _devices = results[2] as List<DeviceModel>;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  TelemetrySeriesPoint? get _latest => _series.isEmpty ? null : _series.last;

  PlantMetricModel? get _plantMetrics {
    final dash = _dashboard;
    final plant = _selectedPlant;
    if (dash == null || plant == null) return null;
    final name = plant.name.toLowerCase();
    if (name.contains('alpha') || name.contains('hollister')) return dash.plants['38124d4420'];
    if (name.contains('beta') || name.contains('caparo')) return dash.plants['d0dd69ac58'];
    return dash.plants.values.isNotEmpty ? dash.plants.values.first : null;
  }

  bool get _hasCriticalAlert => (_dashboard?.alerts ?? []).any((a) => a.type != 'INFO');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: _teal))
                  : _noPlants
                      ? _noPlantsView()
                      : _error != null
                      ? _errorView()
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              if (_showAlertBanner && _hasCriticalAlert) _alertBanner(),
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
                                    _temperatureCard(),
                                    const SizedBox(height: 12),
                                    _generationCard(),
                                    const SizedBox(height: 16),
                                    _phaseCharacteristicsCard(),
                                    const SizedBox(height: 16),
                                    _generationHistogramCard(),
                                    const SizedBox(height: 16),
                                    _sitesStatusCard(),
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

  Widget _noPlantsView() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sensors_off_rounded, color: _slateLight, size: 40),
            SizedBox(height: 12),
            Text('No plants assigned yet',
                style: TextStyle(color: _slateDark, fontSize: 15, fontWeight: FontWeight.w800)),
            SizedBox(height: 6),
            Text(
              'Your administrator has not assigned any plant to your account. Please contact them to get access.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _slateLight, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: _slateLight, size: 36),
            const SizedBox(height: 12),
            Text(
              'Could not load telemetry\n$_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _slateLight, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _load,
              child: const Text('Retry', style: TextStyle(color: _teal, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

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
          GestureDetector(
            onTap: () => context.push('/reports'),
            child: const Padding(
              padding: EdgeInsets.only(right: 14),
              child: Icon(Icons.description_outlined, color: _slateDark, size: 21),
            ),
          ),
          const UserAvatar(size: 32),
        ],
      ),
    );
  }

  // ── Alert Banner ───────────────────────────────────────────────────────────
  Widget _alertBanner() {
    final alert = (_dashboard?.alerts ?? []).firstWhere(
      (a) => a.type != 'INFO',
      orElse: () => AlertModel(type: 'INFO', title: '', location: '', time: ''),
    );
    if (alert.title.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      color: const Color(0xFFFEE2E2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${alert.title} (${alert.location})',
              style: const TextStyle(
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
                'Trackso Sync',
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
        Text(
          'Live data from ${_selectedPlant?.name ?? ''}',
          style: const TextStyle(
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
                value: _selectedPlant?.id,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _slateLight, size: 18),
                style: const TextStyle(color: _slateDark, fontSize: 12, fontWeight: FontWeight.w700),
                onChanged: (String? id) {
                  if (id != null) {
                    setState(() => _selectedPlant = _plants.firstWhere((p) => p.id == id));
                    _load();
                  }
                },
                items: _plants
                    .map((p) => DropdownMenuItem(
                          value: p.id,
                          child: Text('${p.name} – ${p.location}', overflow: TextOverflow.ellipsis),
                        ))
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
                    onTap: () {
                      setState(() => _selectedFilter = e.key);
                      _load();
                    },
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

  // Real AC readings aggregated across the plant's inverters (Trackso)
  double get _acVoltage {
    final reporting = _devices.where((d) => d.acVoltage > 0).toList();
    if (reporting.isEmpty) return 0;
    return reporting.map((d) => d.acVoltage).reduce((a, b) => a + b) / reporting.length;
  }

  double get _acCurrent => _devices.fold<double>(0, (s, d) => s + d.acCurrent);

  double get _acFrequency {
    final reporting = _devices.where((d) => d.acFrequency > 0).toList();
    if (reporting.isEmpty) return 0;
    return reporting.map((d) => d.acFrequency).reduce((a, b) => a + b) / reporting.length;
  }

  // ── Card 1: AC Voltage Card ────────────────────────────────────────────────
  Widget _voltageCard() {
    final voltage = _acVoltage;
    final sparkline = _series.map((p) => p.avgVoltage).toList();
    return _card_(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AC VOLTAGE (AVG)',
                style: TextStyle(color: _slateLight, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
              const SizedBox(height: 8),
              Text(
                '${voltage.toStringAsFixed(1)} V',
                style: const TextStyle(color: _slateDark, fontSize: 24, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          SizedBox(
            width: 60,
            height: 35,
            child: CustomPaint(
              painter: SparklinePainter(values: sparkline),
            ),
          ),
        ],
      ),
    );
  }

  // ── Card 2: AC Current Card ────────────────────────────────────────────────
  Widget _currentCard() {
    final current = _acCurrent;
    final generating = _devices.where((d) => d.activePowerKw > 0).length;
    return _card_(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AC CURRENT (TOTAL)',
                style: TextStyle(color: _slateLight, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    current.toStringAsFixed(0),
                    style: const TextStyle(color: _slateDark, fontSize: 24, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'A',
                    style: TextStyle(color: _slateLight, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '$generating of ${_devices.length} devices generating',
                style: const TextStyle(color: _slateLight, fontSize: 10.5, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const Icon(Icons.reorder_rounded, color: _slateLight, size: 20),
        ],
      ),
    );
  }

  // ── Card 3: AC Frequency Card ──────────────────────────────────────────────
  Widget _temperatureCard() {
    final freq = _acFrequency;
    return _card_(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'GRID FREQUENCY',
                style: TextStyle(color: _slateLight, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
              Icon(Icons.reorder_rounded, color: _slateLight, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            freq == 0 ? '—' : '${freq.toStringAsFixed(2)} Hz',
            style: const TextStyle(color: _teal, fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(4)),
            child: LinearProgressIndicator(
              value: freq == 0 ? 0 : ((freq - 49) / 2).clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFF1F5F9),
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
    final metrics = _plantMetrics;
    final livePowerKw = metrics?.livePower ?? ((_latest?.totalGeneration ?? 0) / 1000);
    final dailyEnergy = metrics?.dailyEnergy ?? 0;
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
                'LIVE GENERATION',
                style: TextStyle(color: Color(0xFF92400E), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
              Icon(Icons.remove_red_eye_outlined, color: Color(0xFF92400E), size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${livePowerKw.toStringAsFixed(1)} kW',
            style: const TextStyle(color: Color(0xFF92400E), fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Today: ${dailyEnergy.toStringAsFixed(1)} kWh',
            style: const TextStyle(color: Color(0xFFB45309), fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _timeLabel(DateTime t) {
    if (_filterHours[_selectedFilter] > 24) {
      return '${t.day}/${t.month}';
    }
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  List<String> get _chartTimeLabels {
    if (_series.length < 2) return [];
    const count = 5;
    return List.generate(count, (i) {
      final idx = (i * (_series.length - 1) / (count - 1)).round();
      return _timeLabel(_series[idx].timestamp);
    });
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
            'Voltage (V) vs Current (A) over time',
            style: TextStyle(color: _slateLight, fontSize: 11, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 90,
            width: double.infinity,
            child: _series.length < 2
                ? const Center(
                    child: Text('Not enough data for this window',
                        style: TextStyle(color: _slateLight, fontSize: 11)),
                  )
                : CustomPaint(
                    painter: PhaseChartPainter(
                      voltage: _series.map((p) => p.avgVoltage).toList(),
                      current: _series.map((p) => p.totalCurrent).toList(),
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _chartTimeLabels
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
    // Downsample the series into 8 bars of average generation (kW)
    final bars = <double>[];
    if (_series.isNotEmpty) {
      const barCount = 8;
      final chunk = (_series.length / barCount).ceil().clamp(1, 1 << 30);
      for (int i = 0; i < _series.length; i += chunk) {
        final slice = _series.sublist(i, math.min(i + chunk, _series.length));
        final avg = slice.map((p) => p.totalGeneration).reduce((a, b) => a + b) / slice.length;
        bars.add(avg / 1000); // W -> kW
      }
    }
    final peak = bars.isEmpty ? 0.0 : bars.reduce(math.max);
    final metrics = _plantMetrics;
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
          _histogramChart(bars, peak),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Peak (window)', style: TextStyle(color: _slateLight, fontSize: 10, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('${peak.toStringAsFixed(1)} kW',
                      style: const TextStyle(color: _teal, fontSize: 12, fontWeight: FontWeight.w800)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CUF', style: TextStyle(color: _slateLight, fontSize: 10, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('${(metrics?.cuf ?? 0).toStringAsFixed(1)}%',
                      style: const TextStyle(color: _teal, fontSize: 12, fontWeight: FontWeight.w800)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _histogramChart(List<double> bars, double peak) {
    if (bars.isEmpty) {
      return const SizedBox(
        height: 80,
        child: Center(
          child: Text('No generation data in this window',
              style: TextStyle(color: _slateLight, fontSize: 11)),
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: bars.map((kw) {
        final h = peak == 0 ? 0.05 : (kw / peak).clamp(0.05, 1.0);
        return Container(
          width: 24,
          height: 80 * h,
          decoration: BoxDecoration(
            color: h > 0.6 ? const Color(0xFF2A8C6E) : const Color(0xFF2A8C6E).withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }).toList(),
    );
  }

  // ── Card 7: Sites Status Card ──────────────────────────────────────────────
  Widget _sitesStatusCard() {
    final sites = _dashboard?.plants.values.toList() ?? [];
    return _card_(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Site Status',
            style: TextStyle(color: _slateDark, fontSize: 14, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          if (sites.isEmpty)
            const Text('No site data available',
                style: TextStyle(color: _slateLight, fontSize: 11)),
          ...sites.asMap().entries.map((entry) {
            final idx = entry.key;
            final site = entry.value;
            final online = site.status.toLowerCase() == 'active';
            final color = online ? const Color(0xFF10B981) : const Color(0xFFEF4444);
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
                        color: color.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.solar_power_rounded, color: color, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(site.siteName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: _slateDark, fontSize: 12.5, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 1.5),
                          Text(
                            '${site.livePower.toStringAsFixed(1)} kW · ${site.dailyEnergy.toStringAsFixed(0)} kWh today',
                            style: const TextStyle(color: _slateLight, fontSize: 10, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        site.status.toUpperCase(),
                        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800),
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
    final alerts = _dashboard?.alerts ?? [];
    Color alertColor(String type) {
      switch (type) {
        case 'CRITICAL':
          return const Color(0xFFEF4444);
        case 'WARNING':
          return const Color(0xFFF5A623);
        default:
          return _teal;
      }
    }

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
                'Site Events',
                style: TextStyle(color: _slateDark, fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ),
            // Event List
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (alerts.isEmpty)
                    const Text('No events reported',
                        style: TextStyle(color: _slateLight, fontSize: 11)),
                  ...alerts.asMap().entries.map((entry) {
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
                              decoration: BoxDecoration(color: alertColor(ev.type), shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(ev.title,
                                      style: const TextStyle(color: _slateDark, fontSize: 12, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 2),
                                  Text(ev.location,
                                      style: const TextStyle(color: _slateLight, fontSize: 10.5, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(ev.time, style: const TextStyle(color: _slateLight, fontSize: 10, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    );
                  }),
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
    ];
    final routes = ['/client-dashboard', '/solar-grid', null, '/billing', '/tickets'];
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
