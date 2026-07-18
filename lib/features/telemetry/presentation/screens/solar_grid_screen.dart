import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/widgets/user_avatar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../ticketing/data/plants_repository.dart';
import '../../../ticketing/domain/plant_model.dart';
import '../../data/telemetry_repository.dart';
import '../../../../core/widgets/grouped_bar_chart.dart';
import '../widgets/chart_painters.dart';

class SolarGridScreen extends ConsumerStatefulWidget {
  const SolarGridScreen({super.key});

  @override
  ConsumerState<SolarGridScreen> createState() => _SolarGridScreenState();
}

class _SolarGridScreenState extends ConsumerState<SolarGridScreen> {
  int _selectedNav = 1; // Plants tab active

  List<PlantModel> _plants = [];
  PlantModel? _plant;
  List<DeviceModel> _devices = [];
  List<TelemetrySeriesPoint> _series = [];
  DeviceDailySeries? _deviceDaily;
  bool _loading = true;
  bool _noPlants = false;
  String? _error;
  Timer? _refreshTimer;

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
    _load();
    // Backend syncs Trackso data every 2 minutes; refresh at the same cadence.
    _refreshTimer = Timer.periodic(const Duration(minutes: 2), (_) => _load());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(plantsRepositoryProvider);
      if (_plants.isEmpty) {
        _plants = await repo.getPlants();
        if (_plants.isEmpty) {
          // New/unassigned account: show a friendly empty state, not an error.
          if (!mounted) return;
          setState(() {
            _noPlants = true;
            _loading = false;
            _error = null;
          });
          return;
        }
      }
      final plant = _plant ?? _plants.first;
      final telemetryRepo = ref.read(telemetryRepositoryProvider);
      final results = await Future.wait<dynamic>([
        telemetryRepo.getSeries(plant.id, 6),
        telemetryRepo.getDevices(plant.id),
        telemetryRepo.getDeviceDaily(plant.id, days: 14),
      ]);
      if (!mounted) return;
      setState(() {
        _plant = plant;
        _series = results[0] as List<TelemetrySeriesPoint>;
        _devices = results[1] as List<DeviceModel>;
        _deviceDaily = results[2] as DeviceDailySeries;
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

  String _relativeTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            if (_loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator(color: _teal)),
              )
            else if (_noPlants)
              const Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.solar_power_outlined, color: _slateLight, size: 40),
                        SizedBox(height: 12),
                        Text(
                          'No plants assigned yet',
                          style: TextStyle(color: _slateDark, fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Your administrator has not assigned any plant to your account. Please contact them to get access.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _slateLight, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_rounded, color: _slateLight, size: 36),
                        const SizedBox(height: 12),
                        Text(
                          'Could not load plant data\n$_error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: _slateLight, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            setState(() => _loading = true);
                            _load();
                          },
                          child: const Text('Retry', style: TextStyle(color: _teal, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
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
                          _plantSelector(),
                          const SizedBox(height: 16),
                          _plantOverviewCard(),
                          const SizedBox(height: 16),
                          _panelLayoutCard(),
                          const SizedBox(height: 16),
                          _liveTelemetryCard(),
                          const SizedBox(height: 16),
                          _voltageCurrentChart(),
                          const SizedBox(height: 16),
                          _generationByDeviceCard(),
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
          Expanded(
            child: Text(
              _plant != null ? '${_plant!.name} – ${_plant!.location}' : '',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _teal,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Plant Selector ─────────────────────────────────────────────────────────
  Widget _plantSelector() {
    if (_plants.length < 2) return const SizedBox.shrink();
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.solar_power_rounded, color: _teal, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _plant?.id,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _slateLight, size: 20),
                style: const TextStyle(color: _slateDark, fontSize: 13, fontWeight: FontWeight.w700),
                items: _plants
                    .map((p) => DropdownMenuItem(
                          value: p.id,
                          child: Text('${p.name} – ${p.location}', overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (id) {
                  if (id == null || id == _plant?.id) return;
                  setState(() => _plant = _plants.firstWhere((p) => p.id == id));
                  // Keep showing current data until the new plant's data arrives
                  _load();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Plant Overview Card ────────────────────────────────────────────────────
  Widget _plantOverviewCard() {
    final plant = _plant!;
    final capacity = plant.peakCapacity >= 1000
        ? '${(plant.peakCapacity / 1000).toStringAsFixed(1)}MW'
        : '${plant.peakCapacity.toStringAsFixed(0)}kW';
    // Device (inverter) health: ERROR/UNKNOWN count against uptime; INACTIVE at
    // night is normal for solar and does not.
    final errorDevices = _devices.where((d) => d.status == 'ERROR' || d.status == 'UNKNOWN').length;
    final uptime = _devices.isEmpty ? 0.0 : (_devices.length - errorDevices) / _devices.length * 100;
    final totalPowerKw = _devices.fold<double>(0, (sum, d) => sum + d.activePowerKw);
    final generation = totalPowerKw >= 1000
        ? '${(totalPowerKw / 1000).toStringAsFixed(2)}MW'
        : '${totalPowerKw.toStringAsFixed(1)}kW';
    // Real last-reading time, from the telemetry we actually recorded.
    final lastSync = _series.isEmpty ? '—' : _relativeTime(_series.last.timestamp);

    return _card_(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: _teal, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${plant.name} – ${plant.location}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _slateDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _badgeChip(capacity, const Color(0xFFFEF3C7), const Color(0xFFD97706)),
              const SizedBox(width: 8),
              _badgeChip(plant.status, const Color(0xFFD1FAE5), _teal),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              _overviewStat('CAPACITY', capacity, false),
              _overviewStat('LAST SYNC', lastSync, false),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _overviewStat('DEVICE UPTIME', '${uptime.toStringAsFixed(0)}%', true),
              _overviewStat('LIVE OUTPUT', generation, true),
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

  // Colour for a device status
  Color _deviceColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return const Color(0xFF10B981); // green
      case 'ERROR':
        return const Color(0xFFEF4444); // red
      case 'INACTIVE':
        return const Color(0xFFCBD5E1); // gray (idle / night)
      default:
        return const Color(0xFFF5A623); // amber (unknown)
    }
  }

  // ── Device Layout Card ─────────────────────────────────────────────────────
  Widget _panelLayoutCard() {
    final inverters = _devices.where((d) => d.type == 'INVERTER').toList();
    final meters = _devices.where((d) => d.type == 'METER').toList();
    final others = _devices.where((d) => d.type == 'OTHER').toList();

    return _card_(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Devices – ${_devices.length} total',
                style: const TextStyle(
                  color: _slateDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Icon(Icons.electrical_services_rounded, color: _slateLight, size: 18),
            ],
          ),
          const SizedBox(height: 14),
          // Type summary tiles
          Row(
            children: [
              Expanded(child: _typeTile('Inverters', inverters.length, Icons.solar_power_rounded)),
              const SizedBox(width: 10),
              Expanded(child: _typeTile('Meters', meters.length, Icons.speed_rounded)),
              if (others.isNotEmpty) ...[
                const SizedBox(width: 10),
                Expanded(child: _typeTile('Other', others.length, Icons.settings_input_component_rounded)),
              ],
            ],
          ),
          const SizedBox(height: 18),
          if (_devices.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('No devices reported for this site',
                    style: TextStyle(color: _slateLight, fontSize: 11.5)),
              ),
            ),
          if (inverters.isNotEmpty) _deviceGroup('INVERTERS', inverters),
          if (meters.isNotEmpty) _deviceGroup('METERS', meters),
          if (others.isNotEmpty) _deviceGroup('OTHER EQUIPMENT', others),
          if (_devices.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendIndicator(const Color(0xFF10B981), 'Active'),
                const SizedBox(width: 14),
                _legendIndicator(const Color(0xFFEF4444), 'Error'),
                const SizedBox(width: 14),
                _legendIndicator(const Color(0xFFCBD5E1), 'Idle'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _typeTile(String label, int count, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _cardBorder, width: 0.8),
      ),
      child: Row(
        children: [
          Icon(icon, color: _teal, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$count', style: const TextStyle(color: _slateDark, fontSize: 16, fontWeight: FontWeight.w900)),
              Text(label, style: const TextStyle(color: _slateLight, fontSize: 9.5, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _deviceGroup(String title, List<DeviceModel> devices) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: Text(
            '$title (${devices.length})',
            style: const TextStyle(
                color: _slateLight, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
        ),
        for (final entry in devices.asMap().entries) ...[
          if (entry.key > 0) const Divider(color: Color(0xFFF1F5F9), height: 18),
          _deviceRow(entry.value),
        ],
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _deviceRow(DeviceModel device) {
    final color = _deviceColor(device.status);
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                device.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _slateDark, fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                'Today: ${device.dailyEnergyKwh.toStringAsFixed(1)} kWh',
                style: const TextStyle(color: _slateLight, fontSize: 10.5, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${device.activePowerKw.toStringAsFixed(1)} kW',
              style: const TextStyle(color: _slateDark, fontSize: 12, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              device.status,
              style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ],
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
    // Real AC readings from inverters that are currently reporting voltage
    final reportingV = _devices.where((d) => d.acVoltage > 0).toList();
    final avgVoltage = reportingV.isEmpty
        ? 0.0
        : reportingV.map((d) => d.acVoltage).reduce((a, b) => a + b) / reportingV.length;
    final totalCurrent = _devices.fold<double>(0, (s, d) => s + d.acCurrent);
    final freqs = _devices.where((d) => d.acFrequency > 0).toList();
    final avgFrequency = freqs.isEmpty
        ? 0.0
        : freqs.map((d) => d.acFrequency).reduce((a, b) => a + b) / freqs.length;
    // Device-level health (real Trackso inverter status)
    final deviceCount = _devices.length;
    final activeDevices = _devices.where((d) => d.status == 'ACTIVE').length;
    final erroredDevices = _devices.where((d) => d.status == 'ERROR' || d.status == 'UNKNOWN').length;
    final generating = _devices.any((d) => d.activePowerKw > 0);
    final lastSync = _series.isEmpty ? null : _series.last.timestamp;

    // Grid health from real device errors; night idle is not a fault
    final String health;
    final Color healthColor;
    if (deviceCount > 0 && erroredDevices > deviceCount * 0.3) {
      health = 'Degraded';
      healthColor = const Color(0xFFEF4444);
    } else if (erroredDevices > 0) {
      health = 'Attention';
      healthColor = const Color(0xFFF5A623);
    } else if (!generating) {
      health = 'Idle (no sun)';
      healthColor = _slateLight;
    } else {
      health = 'Excellent';
      healthColor = const Color(0xFF10B981);
    }
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
                    'Live Sync',
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
          // Real AC voltage from inverters (grid ~230V/phase nominal)
          _telemetryProgress('AC Voltage (avg)', '${avgVoltage.toStringAsFixed(1)} V', (avgVoltage / 260).clamp(0.0, 1.0)),
          const SizedBox(height: 14),
          // Real total AC current across inverters
          _telemetryProgress('AC Current (total)', '${totalCurrent.toStringAsFixed(1)} A', (totalCurrent / (deviceCount * 200 + 1)).clamp(0.0, 1.0)),
          const SizedBox(height: 14),
          // Real grid frequency (50Hz nominal in India)
          _telemetryProgress('AC Frequency', '${avgFrequency.toStringAsFixed(2)} Hz', avgFrequency == 0 ? 0 : ((avgFrequency - 49) / 2).clamp(0.0, 1.0), isAmber: true),
          const SizedBox(height: 18),
          // Sub-cards row
          Row(
            children: [
              Expanded(child: _statusSubcard('Grid Health', health, healthColor)),
              const SizedBox(width: 10),
              Expanded(
                child: _statusSubcard(
                  'Devices Active',
                  '$activeDevices / $deviceCount',
                  activeDevices > 0 ? const Color(0xFF10B981) : _slateLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Devices in Error\n$erroredDevices',
                style: TextStyle(
                  color: erroredDevices > 0 ? const Color(0xFFEF4444) : _slateDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              Text(
                lastSync != null ? 'Updated ${_relativeTime(lastSync)}' : '',
                style: const TextStyle(
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

  Widget _statusSubcard(String label, String value, Color valueColor) {
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
            style: TextStyle(
              color: valueColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ── Voltage & Current Chart ────────────────────────────────────────────────
  Widget _generationByDeviceCard() {
    final data = _deviceDaily;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final days = (data?.series ?? []).map((s) {
      final p = s.day.split('-'); // YYYY-MM-DD
      final label = p.length == 3 ? '${int.parse(p[2])} ${months[int.parse(p[1]) - 1]}' : s.day;
      return GroupedBarDay(label: label, values: s.values);
    }).toList();

    return _card_(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Generation by inverter',
                  style: TextStyle(color: _slateDark, fontSize: 14, fontWeight: FontWeight.w700)),
              const Text('kWh / day',
                  style: TextStyle(color: _slateLight, fontSize: 10, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          if (data == null)
            const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator(color: _teal, strokeWidth: 2)),
            )
          else
            GroupedBarChart(series: data.devices, days: days, unit: 'kWh', height: 180),
        ],
      ),
    );
  }

  Widget _voltageCurrentChart() {
    return _card_(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Voltage & Current (6h)',
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
            child: _series.length < 2
                ? const Center(
                    child: Text('Not enough data yet — collecting live telemetry',
                        style: TextStyle(color: _slateLight, fontSize: 11)),
                  )
                : CustomPaint(
                    painter: TelemetryChartPainter(
                      voltage: _series.map((p) => p.avgVoltage).toList(),
                      current: _series.map((p) => p.totalCurrent).toList(),
                    ),
                  ),
          ),
          if (_series.length >= 2) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (i) {
                final idx = (i * (_series.length - 1) / 4).round();
                final t = _series[idx].timestamp;
                return Text(
                  '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: _slateLight, fontSize: 10, fontWeight: FontWeight.w500),
                );
              }),
            ),
          ],
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
            painter: LineLegendPainter(isSolid: isSolid, color: _teal),
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
    final faultyDevices =
        _devices.where((d) => d.status == 'ERROR' || d.status == 'UNKNOWN').toList();
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
              child: Text(
                'Device Faults (${faultyDevices.length})',
                style: const TextStyle(
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
                        flex: 3,
                        child: Text(
                          'Device',
                          style: TextStyle(color: _slateLight, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Today',
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
                  if (faultyDevices.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        'No device faults — all inverters reporting',
                        style: TextStyle(color: _slateLight, fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                  for (final entry in faultyDevices.take(8).toList().asMap().entries) ...[
                    if (entry.key > 0) ...[
                      const SizedBox(height: 8),
                      const Divider(color: Color(0xFFF1F5F9), height: 1),
                      const SizedBox(height: 8),
                    ],
                    _faultRow(
                      entry.value.name,
                      '${entry.value.dailyEnergyKwh.toStringAsFixed(0)} kWh',
                      entry.value.status == 'ERROR' ? 'Error' : 'Unknown',
                      const Color(0xFFEF4444),
                    ),
                  ],
                  if (faultyDevices.length > 8) ...[
                    const SizedBox(height: 10),
                    Text(
                      '+ ${faultyDevices.length - 8} more',
                      style: const TextStyle(color: _slateLight, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
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
            flex: 3,
            child: Text(
              id,
              overflow: TextOverflow.ellipsis,
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
    ];
    final routes = ['/client-dashboard', null, '/telemetry', '/billing', '/tickets'];
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
