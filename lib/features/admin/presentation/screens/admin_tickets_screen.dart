import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../ticketing/data/ticketing_repository.dart';
import '../../../ticketing/domain/ticket_model.dart';

/// Every support ticket raised by any client. The backend already returns the
/// full list (unscoped) when the caller is an ADMIN.
final adminTicketsProvider = FutureProvider<List<TicketModel>>((ref) async {
  return ref.read(ticketingRepositoryProvider).getTickets();
});

class AdminTicketsScreen extends ConsumerWidget {
  const AdminTicketsScreen({super.key});

  static const _bg = Color(0xFFF4F6F8);
  static const _cardBorder = Color(0xFFE5E7EB);
  static const _teal = Color(0xFF2A8C6E);
  static const _slateDark = Color(0xFF1E293B);
  static const _slateLight = Color(0xFF64748B);

  Color _statusColor(String status) {
    switch (status) {
      case 'OPEN':
        return const Color(0xFFEF4444);
      case 'IN_PROGRESS':
        return const Color(0xFFF5A623);
      default:
        return const Color(0xFF10B981);
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'HIGH':
        return const Color(0xFFEF4444);
      case 'MEDIUM':
        return const Color(0xFFF5A623);
      default:
        return _slateLight;
    }
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
    final async = ref.watch(adminTicketsProvider);
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
                  const Text('Support Tickets',
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
                      onPressed: () => ref.refresh(adminTicketsProvider),
                      child: const Text('Retry',
                          style: TextStyle(color: _teal, fontWeight: FontWeight.w700)),
                    ),
                  ]),
                ),
                data: (tickets) {
                  if (tickets.isEmpty) {
                    return const Center(
                      child: Text('No tickets raised yet',
                          style: TextStyle(color: _slateLight, fontSize: 12)),
                    );
                  }
                  return RefreshIndicator(
                    color: _teal,
                    onRefresh: () => ref.refresh(adminTicketsProvider.future),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: tickets.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final t = tickets[i];
                        return GestureDetector(
                          onTap: () => context.push('/ticket-detail?id=${t.id}'),
                          child: Container(
                            padding: const EdgeInsets.all(12),
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
                                    Expanded(
                                      child: Text(t.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              color: _slateDark,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800)),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _statusColor(t.status).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        t.status.replaceAll('_', ' '),
                                        style: TextStyle(
                                            color: _statusColor(t.status),
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(t.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: _slateLight, fontSize: 11)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(t.ticketNumber,
                                        style: const TextStyle(
                                            color: _teal, fontSize: 10, fontWeight: FontWeight.w800)),
                                    const SizedBox(width: 10),
                                    Icon(Icons.flag_rounded,
                                        size: 11, color: _priorityColor(t.priority)),
                                    const SizedBox(width: 3),
                                    Text(t.priority,
                                        style: TextStyle(
                                            color: _priorityColor(t.priority),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700)),
                                    const Spacer(),
                                    Text(_ago(t.createdAt),
                                        style: const TextStyle(
                                            color: _slateLight,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
                            ),
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
