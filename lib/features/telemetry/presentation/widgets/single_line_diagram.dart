import 'package:flutter/material.dart';
import '../../data/telemetry_repository.dart';

/// A single-line diagram of the plant: the solar array feeding its inverters,
/// then the day's generation, with any diesel gensets alongside. Every value
/// shown is measured — nothing here is inferred.
class SingleLineDiagram extends StatelessWidget {
  final double capacityKwp;
  final List<DeviceModel> devices;

  const SingleLineDiagram({
    super.key,
    required this.capacityKwp,
    required this.devices,
  });

  static const _teal = Color(0xFF2A8C6E);
  static const _slateDark = Color(0xFF1E293B);
  static const _slateLight = Color(0xFF64748B);
  static const _amber = Color(0xFFD97706);
  static const _red = Color(0xFFEF4444);
  static const _line = Color(0xFFCBD5E1);

  bool _active(DeviceModel d) => d.status == 'ACTIVE';

  Color _statusColor(String s) => switch (s) {
        'ACTIVE' => _teal,
        'ERROR' => _red,
        _ => _slateLight,
      };

  @override
  Widget build(BuildContext context) {
    final inverters = devices.where((d) => d.type == 'INVERTER').toList();
    final gensets = devices.where((d) => d.type == 'OTHER').toList();

    final liveKw = inverters.fold<double>(0, (s, d) => s + d.activePowerKw);
    final todayKwh = inverters.fold<double>(0, (s, d) => s + d.dailyEnergyKwh);
    final utilisation = capacityKwp > 0 ? (liveKw / capacityKwp * 100).clamp(0, 100) : 0.0;

    return Column(
      children: [
        // ── Solar plant
        _plantBox(liveKw, utilisation.toDouble()),
        _connector(down: 22),
        // ── Inverters
        _busbar(inverters.length),
        Row(
          children: [
            for (int i = 0; i < inverters.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: _inverterBox(inverters[i])),
            ],
          ],
        ),
        _connector(down: 22),
        // ── Generation output today
        _outputBox(todayKwh, liveKw),
        // ── Diesel gensets (Hella), if any
        if (gensets.isNotEmpty) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              for (int i = 0; i < gensets.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: _gensetBox(gensets[i])),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _connector({required double down}) => SizedBox(
        height: down,
        child: Center(
          child: Container(width: 2, color: _line),
        ),
      );

  /// The horizontal bus line that fans out to the inverters.
  Widget _busbar(int n) {
    if (n <= 1) return const SizedBox(height: 0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(height: 2, color: _line),
    );
  }

  Widget _box({
    required Color color,
    required Widget child,
    Color? fill,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fill ?? color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.4),
      ),
      child: child,
    );
  }

  Widget _plantBox(double liveKw, double utilisation) {
    return _box(
      color: _amber,
      fill: _amber.withValues(alpha: 0.08),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.solar_power_rounded, color: _amber, size: 20),
              const SizedBox(width: 8),
              Text('SOLAR PLANT',
                  style: TextStyle(
                      color: _amber, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 2),
          Text('${capacityKwp.toStringAsFixed(0)} kWp capacity',
              style: const TextStyle(color: _slateLight, fontSize: 10)),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(children: [
              TextSpan(
                text: liveKw >= 1000
                    ? (liveKw / 1000).toStringAsFixed(2)
                    : liveKw.toStringAsFixed(1),
                style: const TextStyle(color: _slateDark, fontSize: 26, fontWeight: FontWeight.w900),
              ),
              TextSpan(
                text: liveKw >= 1000 ? ' MW' : ' kW',
                style: const TextStyle(color: _slateLight, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          _utilisationBar(utilisation),
        ],
      ),
    );
  }

  Widget _utilisationBar(double pct) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('UTILISATION',
                style: TextStyle(color: _slateLight, fontSize: 8.5, fontWeight: FontWeight.w700)),
            Text('${pct.toStringAsFixed(0)}%',
                style: const TextStyle(color: _amber, fontSize: 9, fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: pct / 100,
            minHeight: 5,
            backgroundColor: _amber.withValues(alpha: 0.15),
            valueColor: const AlwaysStoppedAnimation(_amber),
          ),
        ),
      ],
    );
  }

  Widget _inverterBox(DeviceModel d) {
    final color = _statusColor(d.status);
    return _box(
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.electrical_services_rounded, color: color, size: 16),
          const SizedBox(height: 3),
          Text(d.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _slateDark, fontSize: 9.5, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('${d.activePowerKw.toStringAsFixed(1)} kW',
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(d.status,
                style: TextStyle(color: color, fontSize: 7.5, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _outputBox(double todayKwh, double liveKw) {
    return _box(
      color: _teal,
      fill: _teal.withValues(alpha: 0.06),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, color: _teal, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('GENERATION TODAY',
                    style: TextStyle(color: _slateLight, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                const SizedBox(height: 2),
                Text(
                  todayKwh >= 1000
                      ? '${(todayKwh / 1000).toStringAsFixed(2)} MWh'
                      : '${todayKwh.toStringAsFixed(0)} kWh',
                  style: const TextStyle(color: _slateDark, fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('EXPORTING',
                  style: TextStyle(color: _slateLight, fontSize: 8, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('${liveKw.toStringAsFixed(1)} kW',
                  style: const TextStyle(color: _teal, fontSize: 13, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _gensetBox(DeviceModel d) {
    final on = _active(d) && d.activePowerKw > 0;
    final color = on ? _amber : _slateLight;
    return _box(
      color: color,
      child: Column(
        children: [
          Icon(Icons.propane_tank_rounded, color: color, size: 15),
          const SizedBox(height: 3),
          Text(d.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _slateDark, fontSize: 9, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(on ? '${d.activePowerKw.toStringAsFixed(1)} kW' : 'OFF',
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
