import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Lets an admin open any client-side feature. Admins have access to every
/// plant, so these screens work as the single source of truth for testing.
class AdminFeaturesScreen extends StatelessWidget {
  const AdminFeaturesScreen({super.key});

  static const _bg = Color(0xFFF4F6F8);
  static const _cardBorder = Color(0xFFE5E7EB);
  static const _teal = Color(0xFF2A8C6E);
  static const _slateDark = Color(0xFF1E293B);
  static const _slateLight = Color(0xFF64748B);

  static const _features = <(IconData, String, String, String)>[
    (Icons.home_rounded, 'Fleet Dashboard', 'Fleet overview & generation', '/client-dashboard'),
    (Icons.solar_power_rounded, 'Plants / Solar Grid', 'Per-plant devices & panels', '/solar-grid'),
    (Icons.sensors_rounded, 'Telemetry', 'Real-time inverter data', '/telemetry'),
    (Icons.description_rounded, 'Reports', 'Daily/weekly/monthly reports', '/reports'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 56,
              decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: _cardBorder, width: 1))),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GestureDetector(onTap: () => context.pop(), child: const Icon(Icons.arrow_back_rounded, color: _slateDark, size: 22)),
                  const SizedBox(width: 12),
                  const Text('Plant Stats', style: TextStyle(color: _teal, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Open any plant dashboard or telemetry view',
                      style: TextStyle(color: _slateLight, fontSize: 12)),
                  const SizedBox(height: 14),
                  ..._features.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () => context.push(f.$4),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: _cardBorder)),
                            child: Row(
                              children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(color: _teal.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                                  child: Icon(f.$1, color: _teal, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(f.$2, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: _slateDark)),
                                      const SizedBox(height: 2),
                                      Text(f.$3, style: const TextStyle(fontSize: 11, color: _slateLight)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: _slateLight),
                              ],
                            ),
                          ),
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
