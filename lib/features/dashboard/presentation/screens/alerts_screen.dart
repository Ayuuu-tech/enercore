import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../telemetry/data/telemetry_repository.dart';

/// Full list of system alerts across every plant the user can access.
/// The dashboard card shows only the most recent few and links here.
class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  static const _bg = Color(0xFFF4F6F8);
  static const _cardBorder = Color(0xFFE5E7EB);
  static const _teal = Color(0xFF2A8C6E);
  static const _slateDark = Color(0xFF1E293B);
  static const _slateLight = Color(0xFF64748B);
  static const _red = Color(0xFFEF4444);
  static const _amber = Color(0xFFF5A623);

  ({Color color, IconData icon}) _style(String type) {
    switch (type) {
      case 'CRITICAL':
        return (color: _red, icon: Icons.flash_off_rounded);
      case 'WARNING':
        return (color: _amber, icon: Icons.trending_down_rounded);
      default:
        return (color: _teal, icon: Icons.info_outline);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(telemetryDashboardProvider);
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
                  const Text('All Alerts',
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
                    Text('Error: $e',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: _slateLight, fontSize: 12)),
                    TextButton(
                      onPressed: () => ref.refresh(telemetryDashboardProvider),
                      child: const Text('Retry',
                          style: TextStyle(color: _teal, fontWeight: FontWeight.w700)),
                    ),
                  ]),
                ),
                data: (data) {
                  if (data.alerts.isEmpty) {
                    return const Center(
                      child: Text('No system alerts.',
                          style: TextStyle(color: _slateLight, fontSize: 12)),
                    );
                  }
                  return RefreshIndicator(
                    color: _teal,
                    onRefresh: () => ref.refresh(telemetryDashboardProvider.future),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: data.alerts.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final a = data.alerts[i];
                        final s = _style(a.type);
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _cardBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: s.color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(s.icon, color: s.color, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(a.title,
                                        style: const TextStyle(
                                            color: _slateDark,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700)),
                                    if (a.location.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(a.location,
                                          style: const TextStyle(color: _slateLight, fontSize: 11)),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(a.time,
                                  style: const TextStyle(
                                      color: _slateLight, fontSize: 10, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
