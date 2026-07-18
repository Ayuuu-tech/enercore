import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/telemetry_repository.dart';

/// The plant alarms view — per-site open-alarm counts by category, and the
/// open-alarm records when there are any. Mirrors the portal's Alarms tab.
class AlarmsScreen extends ConsumerWidget {
  const AlarmsScreen({super.key});

  static const _bg = Color(0xFFF4F6F8);
  static const _cardBorder = Color(0xFFE5E7EB);
  static const _teal = Color(0xFF2A8C6E);
  static const _slateDark = Color(0xFF1E293B);
  static const _slateLight = Color(0xFF64748B);
  static const _red = Color(0xFFEF4444);
  static const _amber = Color(0xFFD97706);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(alarmsProvider);
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 56,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: _cardBorder, width: 1)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back_rounded, color: _slateDark, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text('Alarms',
                      style: TextStyle(
                          color: _teal, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
                ],
              ),
            ),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator(color: _teal)),
                error: (e, _) => Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('$e', textAlign: TextAlign.center,
                        style: const TextStyle(color: _slateLight, fontSize: 12)),
                    TextButton(
                      onPressed: () => ref.invalidate(alarmsProvider),
                      child: const Text('Retry',
                          style: TextStyle(color: _teal, fontWeight: FontWeight.w700)),
                    ),
                  ]),
                ),
                data: (report) => RefreshIndicator(
                  color: _teal,
                  onRefresh: () async => ref.invalidate(alarmsProvider),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      _summaryBanner(report),
                      const SizedBox(height: 16),
                      if (report.alarms.isNotEmpty) ...[
                        const Text('Open alarms',
                            style: TextStyle(color: _slateDark, fontSize: 13, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        ...report.alarms.map(_alarmTile),
                        const SizedBox(height: 16),
                      ],
                      const Text('By site',
                          style: TextStyle(color: _slateDark, fontSize: 13, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      ...report.counts.map(_siteCard),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryBanner(AlarmReport report) {
    final open = report.totalOpen;
    final clear = open == 0;
    final color = clear ? _teal : _red;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(clear ? Icons.check_circle_rounded : Icons.warning_amber_rounded, color: color, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(clear ? 'All clear' : '$open open alarm${open == 1 ? '' : 's'}',
                    style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(
                  clear
                      ? 'No open alarms across your plants.'
                      : 'Action may be needed — see the details below.',
                  style: const TextStyle(color: _slateDark, fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _alarmTile(AlarmRecord a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: _red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.name,
                    style: const TextStyle(color: _slateDark, fontSize: 12.5, fontWeight: FontWeight.w800)),
                if (a.location.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(a.location, style: const TextStyle(color: _slateLight, fontSize: 11)),
                ],
              ],
            ),
          ),
          if (a.time.isNotEmpty)
            Text(a.time,
                style: const TextStyle(color: _slateLight, fontSize: 9.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _siteCard(SiteAlarmCount c) {
    final clear = c.total == 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                    color: clear ? _teal : _red, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(c.siteName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _slateDark, fontSize: 13, fontWeight: FontWeight.w800)),
              ),
              Text(clear ? 'OK' : '${c.total}',
                  style: TextStyle(color: clear ? _teal : _red, fontSize: 12, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _countChip('Inverter alarms', c.inverterAlarms),
              _countChip('Not reporting', c.inverterNoData),
              _countChip('Communication', c.communication),
              _countChip('Rule alerts', c.ruleAlerts),
            ],
          ),
        ],
      ),
    );
  }

  Widget _countChip(String label, int n) {
    final color = n == 0 ? _slateLight : _amber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text('$label · $n',
          style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w700)),
    );
  }
}
