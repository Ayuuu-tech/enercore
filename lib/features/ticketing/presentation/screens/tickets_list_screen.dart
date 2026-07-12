import 'package:flutter/material.dart';
import '../../../../core/widgets/user_avatar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../application/ticketing_controller.dart';
import '../../data/plants_repository.dart';

class TicketsListScreen extends ConsumerStatefulWidget {
  const TicketsListScreen({super.key});

  @override
  ConsumerState<TicketsListScreen> createState() => _TicketsListScreenState();
}

class _TicketsListScreenState extends ConsumerState<TicketsListScreen> {
  int _selectedNav = 4; // Tickets tab active
  int _selectedFilter = 0; // "All" tab active

  // Premium Design System
  static const _bg = Color(0xFFF4F6F8);
  static const _cardBorder = Color(0xFFE5E7EB);
  static const _teal = Color(0xFF2A8C6E); // primary brand green-teal
  static const _slateDark = Color(0xFF1E293B);
  static const _slateLight = Color(0xFF64748B);

  String _formatRelativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()} years ago';
    } else if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()} months ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} days ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hours ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketsState = ref.watch(ticketingControllerProvider);
    final plantsState = ref.watch(plantsFutureProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: ticketsState.when(
                data: (tickets) {
                  return plantsState.when(
                    data: (plants) {
                      final plantsMap = {for (var p in plants) p.id: p};
                      
                      // Filter tickets
                      final filteredTickets = tickets.where((ticket) {
                        if (_selectedFilter == 0) return true; // All
                        if (_selectedFilter == 1) return ticket.status.toUpperCase() == 'OPEN';
                        if (_selectedFilter == 2) return ticket.status.toUpperCase() == 'IN_PROGRESS';
                        if (_selectedFilter == 3) return ticket.status.toUpperCase() == 'RESOLVED';
                        return true;
                      }).toList();

                      return RefreshIndicator(
                        onRefresh: () => ref.read(ticketingControllerProvider.notifier).fetchTickets(),
                        color: _teal,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'My Support Tickets',
                                  style: TextStyle(
                                    color: _slateDark,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Monitor and manage your industrial energy asset service requests and technical inquiries.',
                                  style: TextStyle(
                                    color: _slateLight,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _raiseTicketButton(),
                                const SizedBox(height: 20),
                                _filterTabs(),
                                const SizedBox(height: 16),
                                if (filteredTickets.isEmpty)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 40),
                                    alignment: Alignment.center,
                                    child: const Text(
                                      'No tickets found.',
                                      style: TextStyle(color: _slateLight, fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                  )
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: filteredTickets.length,
                                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final ticket = filteredTickets[index];
                                      final plant = plantsMap[ticket.plantId];
                                      final plantName = plant != null ? '${plant.name} – ${plant.location.split(',')[0]}' : 'Facility';
                                      
                                      // Status mapping
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

                                      // Priority mapping
                                      Color priorityColor;
                                      String priorityLabel;
                                      switch (ticket.priority.toUpperCase()) {
                                        case 'LOW':
                                          priorityColor = const Color(0xFF10B981);
                                          priorityLabel = 'Low Priority';
                                          break;
                                        case 'MEDIUM':
                                          priorityColor = const Color(0xFFD97706);
                                          priorityLabel = 'Medium Priority';
                                          break;
                                        case 'HIGH':
                                          priorityColor = const Color(0xFFEF4444);
                                          priorityLabel = 'High Priority';
                                          break;
                                        default:
                                          priorityColor = _slateLight;
                                          priorityLabel = '${ticket.priority} Priority';
                                      }

                                      return _ticketCard(
                                        actualId: ticket.id,
                                        id: ticket.ticketNumber.contains('-') ? '#${ticket.ticketNumber.split('-')[0]}' : '#${ticket.ticketNumber}',
                                        plant: plantName,
                                        status: statusLabel,
                                        statusColor: statusColor,
                                        statusBg: statusBg,
                                        priority: priorityLabel,
                                        priorityColor: priorityColor,
                                        title: ticket.title,
                                        lastUpdate: ticket.lastUpdateMessage ?? 'Ticket raised successfully.',
                                        created: _formatRelativeTime(ticket.createdAt),
                                      );
                                    },
                                  ),
                                const SizedBox(height: 16),
                                _promoCard(),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: _teal),
                    ),
                    error: (err, stack) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Error loading facilities: $err', style: const TextStyle(color: Colors.redAccent)),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: _teal),
                ),
                error: (err, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $err', style: const TextStyle(color: Colors.redAccent)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: _teal),
                        onPressed: () => ref.read(ticketingControllerProvider.notifier).fetchTickets(),
                        child: const Text('Retry', style: TextStyle(color: Colors.white)),
                      ),
                    ],
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
            height: 46,
            fit: BoxFit.contain,
          ),
          const Spacer(),
          const UserAvatar(size: 32),
        ],
      ),
    );
  }

  // ── Raise Ticket Button ────────────────────────────────────────────────────
  Widget _raiseTicketButton() {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: _teal,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: () async {
          final result = await context.push('/create-ticket');
          if (result == true) {
            ref.read(ticketingControllerProvider.notifier).fetchTickets();
          }
        },
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text(
          'Raise New Ticket',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // ── Filter Tabs ────────────────────────────────────────────────────────────
  Widget _filterTabs() {
    final tabs = ['All', 'Open', 'In Progress', 'Resolved'];
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _cardBorder, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: tabs.asMap().entries.map((e) {
          final active = _selectedFilter == e.key;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = e.key),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: active ? _teal : Colors.transparent, width: 2.5),
                ),
              ),
              child: Text(
                e.value,
                style: TextStyle(
                  color: active ? _teal : _slateLight,
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Ticket Card Component ──────────────────────────────────────────────────
  Widget _ticketCard({
    required String actualId,
    required String id,
    required String plant,
    required String status,
    required Color statusColor,
    required Color statusBg,
    required String priority,
    required Color priorityColor,
    required String title,
    required String lastUpdate,
    required String created,
  }) {
    return GestureDetector(
      onTap: () => context.push('/ticket-detail?id=$actualId'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  id,
                  style: const TextStyle(
                    color: _teal,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.solar_power_rounded, color: Colors.white, size: 10),
                      const SizedBox(width: 4),
                      Text(
                        plant,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(color: priorityColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      priority,
                      style: const TextStyle(
                        color: _slateLight,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: _slateDark,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history_toggle_off_rounded, color: _slateLight, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Last update: "$lastUpdate"',
                      style: const TextStyle(
                        color: _slateDark,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Created $created',
                  style: const TextStyle(
                    color: _slateLight,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                    border: Border.all(color: _cardBorder, width: 0.8),
                  ),
                  child: const Icon(Icons.arrow_forward_ios_rounded, color: _slateDark, size: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Premium Support Promo Card ─────────────────────────────────────────────
  Widget _promoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF065F46),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Premium Support\nFeatures',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upgrade to Enterprise Support for 15-minute response times and dedicated technical support managers.',
            style: TextStyle(
              color: Color(0xFFA7F3D0),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF065F46),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {},
              child: const Text(
                'Learn More',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
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
    final List<String?> routes = ['/client-dashboard', '/solar-grid', '/telemetry', '/billing', null];
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
}
