import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/admin_repository.dart';

class AdminAuditScreen extends ConsumerWidget {
  const AdminAuditScreen({super.key});

  static const _bg = Color(0xFFF4F6F8);
  static const _cardBorder = Color(0xFFE5E7EB);
  static const _teal = Color(0xFF2A8C6E);
  static const _slateDark = Color(0xFF1E293B);
  static const _slateLight = Color(0xFF64748B);

  Color _actionColor(String action) {
    if (action.startsWith('DELETE') || action.startsWith('DISABLE') || action.contains('CANCEL')) {
      return const Color(0xFFEF4444);
    }
    if (action.startsWith('CREATE') || action.startsWith('ENABLE') || action.contains('RENEW')) {
      return const Color(0xFF10B981);
    }
    return _teal;
  }

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays < 7) return '${d.inDays}d ago';
    return '${t.day}/${t.month}/${t.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminAuditLogsProvider);
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
                  const Text('Audit Log', style: TextStyle(color: _teal, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
                ],
              ),
            ),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator(color: _teal)),
                error: (e, _) => Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('Error: $e', textAlign: TextAlign.center, style: const TextStyle(color: _slateLight, fontSize: 12)),
                    TextButton(onPressed: () => ref.refresh(adminAuditLogsProvider), child: const Text('Retry', style: TextStyle(color: _teal, fontWeight: FontWeight.w700))),
                  ]),
                ),
                data: (logs) {
                  if (logs.isEmpty) return const Center(child: Text('No admin actions logged yet', style: TextStyle(color: _slateLight, fontSize: 12)));
                  return RefreshIndicator(
                    color: _teal,
                    onRefresh: () => ref.refresh(adminAuditLogsProvider.future),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: logs.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final l = logs[i];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: _cardBorder)),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 3),
                                width: 8, height: 8,
                                decoration: BoxDecoration(color: _actionColor(l.action), shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(l.action.replaceAll('_', ' '),
                                        style: TextStyle(color: _actionColor(l.action), fontSize: 12.5, fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${l.actorName}${l.targetType != null ? ' · ${l.targetType}' : ''}${l.detail != null ? ' · ${l.detail}' : ''}',
                                      style: const TextStyle(color: _slateLight, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Text(_ago(l.createdAt), style: const TextStyle(color: _slateLight, fontSize: 10, fontWeight: FontWeight.w600)),
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
