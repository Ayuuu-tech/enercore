import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/ticketing_repository.dart';
import '../../domain/ticket_model.dart';
import '../../domain/ticket_comment_model.dart';
import '../../../auth/application/auth_controller.dart';

final ticketDetailProvider = AsyncNotifierProvider.family.autoDispose<TicketDetailNotifier, TicketModel, String>((ticketId) {
  return TicketDetailNotifier(ticketId);
});

class TicketDetailNotifier extends AsyncNotifier<TicketModel> {
  final String ticketId;
  TicketDetailNotifier(this.ticketId);

  Timer? _timer;

  @override
  Future<TicketModel> build() async {
    ref.onDispose(() {
      _timer?.cancel();
    });

    // Poll every 30 seconds for ticket updates (status, last update, etc.)
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      pollDetail();
    });

    return ref.read(ticketingRepositoryProvider).getTicketById(ticketId);
  }

  Future<void> pollDetail() async {
    try {
      final ticket = await ref.read(ticketingRepositoryProvider).getTicketById(ticketId);
      if (ticket.id.isNotEmpty) {
        state = AsyncValue.data(ticket);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final ticketCommentsProvider = AsyncNotifierProvider.family.autoDispose<TicketCommentsNotifier, List<TicketCommentModel>, String>((ticketId) {
  return TicketCommentsNotifier(ticketId);
});

class TicketCommentsNotifier extends AsyncNotifier<List<TicketCommentModel>> {
  final String ticketId;
  TicketCommentsNotifier(this.ticketId);

  Timer? _timer;

  @override
  Future<List<TicketCommentModel>> build() async {
    ref.onDispose(() {
      _timer?.cancel();
    });

    // Poll every 30 seconds for new comments to keep discussion thread live
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      pollComments();
    });

    return ref.read(ticketingRepositoryProvider).getComments(ticketId);
  }

  Future<void> pollComments() async {
    try {
      final comments = await ref.read(ticketingRepositoryProvider).getComments(ticketId);
      state = AsyncValue.data(comments);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> addComment(String message) async {
    await ref.read(ticketingRepositoryProvider).addComment(ticketId, message);
    final comments = await ref.read(ticketingRepositoryProvider).getComments(ticketId);
    state = AsyncValue.data(comments);
  }
}

class TicketsDetailScreen extends ConsumerStatefulWidget {
  final String ticketId;
  const TicketsDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<TicketsDetailScreen> createState() => _TicketsDetailScreenState();
}

class _TicketsDetailScreenState extends ConsumerState<TicketsDetailScreen> {
  int _selectedNav = 4; // Tickets tab active
  final _messageController = TextEditingController();
  bool _isSending = false;

  // Premium Design System
  static const _bg = Color(0xFFF4F6F8);
  static const _card = Colors.white;
  static const _cardBorder = Color(0xFFE5E7EB);
  static const _teal = Color(0xFF2A8C6E); // primary brand green-teal
  static const _slateDark = Color(0xFF1E293B);
  static const _slateLight = Color(0xFF64748B);

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final ticketState = ref.watch(ticketDetailProvider(widget.ticketId));
    final commentsState = ref.watch(ticketCommentsProvider(widget.ticketId));
    final userState = ref.watch(authControllerProvider);
    final currentUserId = userState.value?.id ?? '';

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: ticketState.when(
                data: (ticket) {
                  // Priority Mapping
                  Color priorityColor;
                  String priorityLabel;
                  IconData priorityIcon;
                  switch (ticket.priority.toUpperCase()) {
                    case 'LOW':
                      priorityColor = const Color(0xFF10B981);
                      priorityLabel = 'Low Priority';
                      priorityIcon = Icons.info_outline;
                      break;
                    case 'MEDIUM':
                      priorityColor = const Color(0xFFD97706);
                      priorityLabel = 'Medium Priority';
                      priorityIcon = Icons.warning_amber_rounded;
                      break;
                    case 'HIGH':
                      priorityColor = const Color(0xFFEF4444);
                      priorityLabel = 'High Priority';
                      priorityIcon = Icons.warning_amber_rounded;
                      break;
                    default:
                      priorityColor = _slateLight;
                      priorityLabel = '${ticket.priority} Priority';
                      priorityIcon = Icons.info_outline;
                  }

                  // Status Mapping
                  Color statusColor;
                  Color statusBg;
                  String statusLabel;
                  switch (ticket.status.toUpperCase()) {
                    case 'OPEN':
                      statusColor = _teal;
                      statusBg = const Color(0xFFD1FAE5);
                      statusLabel = 'Open';
                      break;
                    case 'IN_PROGRESS':
                      statusColor = const Color(0xFFD97706);
                      statusBg = const Color(0xFFFEF3C7);
                      statusLabel = 'In Progress';
                      break;
                    case 'RESOLVED':
                      statusColor = _slateLight;
                      statusBg = const Color(0xFFF1F5F9);
                      statusLabel = 'Resolved';
                      break;
                    default:
                      statusColor = _slateLight;
                      statusBg = const Color(0xFFF1F5F9);
                      statusLabel = ticket.status;
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(ticketDetailProvider(widget.ticketId));
                      ref.invalidate(ticketCommentsProvider(widget.ticketId));
                    },
                    color: _teal,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _breadcrumbs(ticket.ticketNumber),
                            const SizedBox(height: 8),
                            Text(
                              ticket.title,
                              style: const TextStyle(
                                color: _slateDark,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _badgeChip(statusLabel, statusBg, statusColor, isDot: true),
                                const SizedBox(width: 10),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_month_outlined, color: _slateLight, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Created ${_formatDate(ticket.createdAt)}',
                                      style: const TextStyle(color: _slateLight, fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(priorityIcon, color: priorityColor, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  priorityLabel,
                                  style: const TextStyle(color: _slateLight, fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _descriptionBox(ticket.description),
                            const SizedBox(height: 16),
                            _actionButtonsRow(),
                            const SizedBox(height: 20),
                            _conversationBox(commentsState, currentUserId),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: _teal)),
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error loading ticket: $err', style: const TextStyle(color: Colors.redAccent)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: _teal),
                          onPressed: () => ref.invalidate(ticketDetailProvider(widget.ticketId)),
                          child: const Text('Retry', style: TextStyle(color: Colors.white)),
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

  // ── Top Bar ────────────────────────────────────────────────────────────────
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
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=80&fit=crop&q=80'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Breadcrumbs ────────────────────────────────────────────────────────────
  Widget _breadcrumbs(String ticketNumber) {
    final numStr = ticketNumber.contains('-') ? ticketNumber.split('-')[0] : ticketNumber;
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.go('/tickets'),
          child: const Text(
            'Tickets',
            style: TextStyle(color: _slateLight, fontSize: 11.5, fontWeight: FontWeight.w600),
          ),
        ),
        const Text('  >  ', style: TextStyle(color: _slateLight, fontSize: 11.5)),
        Text(
          '#$numStr',
          style: const TextStyle(color: _teal, fontSize: 11.5, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _badgeChip(String text, Color bg, Color textCol, {bool isDot = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          if (isDot) ...[
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: textCol, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: TextStyle(
              color: textCol,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ── Description Box ────────────────────────────────────────────────────────
  Widget _descriptionBox(String description) {
    return _card_(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ISSUE DESCRIPTION',
            style: TextStyle(color: _slateLight, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: _slateDark,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ── Share & Update Status Row ──────────────────────────────────────────────
  Widget _actionButtonsRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _teal, width: 1.2),
            ),
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ticket details link copied to clipboard'), behavior: SnackBarBehavior.floating),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.share_outlined, color: _teal, size: 16),
                  SizedBox(width: 8),
                  Text('Share', style: TextStyle(color: _teal, fontSize: 12, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 40,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Status updates are handled by Enercore operators.'), behavior: SnackBarBehavior.floating),
                );
              },
              icon: const Icon(Icons.edit_note_rounded, size: 18),
              label: const Text('Update Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ],
    );
  }

  // ── Conversation Card ──────────────────────────────────────────────────────
  Widget _conversationBox(AsyncValue<List<TicketCommentModel>> commentsState, String currentUserId) {
    return _card_(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CONVERSATION HISTORY',
            style: TextStyle(color: _slateLight, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
          const SizedBox(height: 16),
          commentsState.when(
            data: (comments) {
              if (comments.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No conversation messages yet. Send a message below to start.',
                      style: TextStyle(color: _slateLight, fontSize: 11.5, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return Column(
                children: comments.map((comment) {
                  final isMe = comment.userId == currentUserId;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: isMe ? _userBubble(comment) : _agentBubble(comment),
                  );
                }).toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(color: _teal)),
            ),
            error: (err, stack) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('Error loading comments: $err', style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
            ),
          ),
          const SizedBox(height: 8),
          // Type input row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _cardBorder, width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.message_rounded, color: _slateLight, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: _slateDark, fontSize: 12, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: TextStyle(color: _slateLight, fontSize: 12, fontWeight: FontWeight.w500),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isSending ? null : _sendMessage,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: _teal,
                      shape: BoxShape.circle,
                    ),
                    child: _isSending
                        ? const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _agentBubble(TicketCommentModel comment) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: _teal,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              'A',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  comment.message,
                  style: const TextStyle(
                    color: _slateDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Support Agent • ${_formatTime(comment.createdAt)}',
                style: const TextStyle(color: _slateLight, fontSize: 9.5, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _userBubble(TicketCommentModel comment) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _teal,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  comment.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'You • ${_formatTime(comment.createdAt)}',
                style: const TextStyle(color: _slateLight, fontSize: 9.5, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Color(0xFFE2E8F0),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_rounded, color: _slateLight, size: 16),
        ),
      ],
    );
  }

  // ── Send Message Function ──────────────────────────────────────────────────
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => _isSending = true);

    try {
      await ref.read(ticketCommentsProvider(widget.ticketId).notifier).addComment(message);
      
      // Clear input
      _messageController.clear();
      
      // Invalidate detail to show updated lastUpdateMessage
      ref.invalidate(ticketDetailProvider(widget.ticketId));
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
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
    final List<String?> routes = ['/client-dashboard', '/solar-grid', '/telemetry', '/billing', null, '/profile'];
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
                    color: active ? _teal : _slateLight.withAlpha((0.6 * 255).toInt()),
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    items[i].$2,
                    style: TextStyle(
                      color: active ? _teal : _slateLight.withAlpha((0.7 * 255).toInt()),
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
            color: Colors.black.withAlpha((0.03 * 255).toInt()),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}