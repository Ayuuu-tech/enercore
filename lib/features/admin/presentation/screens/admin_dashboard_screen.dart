import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../notifications/data/notifications_repository.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../data/admin_repository.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedNav = 0;

  // Exact same design tokens as the client dashboard
  static const _bg = Color(0xFFF4F6F8);
  static const _card = Colors.white;
  static const _cardBorder = Color(0xFFE5E7EB);
  static const _teal = Color(0xFF2A8C6E);
  static const _headerBg = Colors.white;
  static const _slateDark = Color(0xFF1E293B);
  static const _slateLight = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(adminAnalyticsProvider);
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: analyticsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: _teal)),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Failed to load analytics',
                          style: TextStyle(color: _slateDark, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('$err', style: const TextStyle(color: _slateLight, fontSize: 12)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: _teal),
                        onPressed: () => ref.refresh(adminAnalyticsProvider),
                        child: const Text('Retry', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
                data: (a) => RefreshIndicator(
                  onRefresh: () => ref.refresh(adminAnalyticsProvider.future),
                  color: _teal,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        // Header strip with greeting + stats (identical to client)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                          color: _headerBg,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Good morning, ${ref.watch(authControllerProvider).value?.name ?? 'Admin'} ',
                                        style: const TextStyle(
                                            color: _slateDark, fontSize: 16, fontWeight: FontWeight.w700),
                                      ),
                                      const Text('👋', style: TextStyle(fontSize: 16)),
                                    ],
                                  ),
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: _cardBorder, width: 1),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.03),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.notifications_outlined, color: _slateLight, size: 20),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _statsRow(a),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _revenueRow(a),
                              const SizedBox(height: 16),
                              _manageSection(),
                              const SizedBox(height: 16),
                              _recentUsers(a),
                              const SizedBox(height: 16),
                              _recentlyExpired(a),
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
              ),
            ),
            _bottomNav(),
          ],
        ),
      ),
    );
  }

  // ── Top app bar (identical to client) ──────────────────────────────────────
  Widget _topBar() {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _cardBorder, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Image.asset('assets/images/logo.png', height: 24, fit: BoxFit.contain),
          const SizedBox(width: 8),
          const Text(
            'Enercore',
            style: TextStyle(color: _teal, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.3),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.push('/notifications'),
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_none_rounded, color: _slateDark, size: 23),
                  Consumer(
                    builder: (context, ref, _) {
                      final unread = ref.watch(unreadNotificationsCountProvider).value ?? 0;
                      if (unread == 0) return const SizedBox.shrink();
                      return Positioned(
                        right: -3,
                        top: -3,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                          decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                          child: Text('$unread',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800)),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          UserAvatar(size: 32, onTap: () => context.push('/profile')),
        ],
      ),
    );
  }

  // ── Stat cards row (same 2-col grid style) ─────────────────────────────────
  Widget _statsRow(AdminAnalytics a) {
    final tiles = [
      ('Total Users', '${a.totalUsers}', Icons.people_rounded, _teal),
      ('Active Users', '${a.activeUsers}', Icons.check_circle_rounded, const Color(0xFF10B981)),
      ('Inactive', '${a.inactiveUsers}', Icons.block_rounded, const Color(0xFFEF4444)),
      ('Active Subs', '${a.activeSubscriptions}', Icons.verified_rounded, const Color(0xFF7C3AED)),
      ('Expired Subs', '${a.expiredSubscriptions}', Icons.hourglass_bottom_rounded, const Color(0xFFD97706)),
      ('Pending Subs', '${a.pendingSubscriptions}', Icons.pending_rounded, _slateLight),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.6,
      children: tiles.map((t) => _statTile(t.$1, t.$2, t.$3, t.$4)).toList(),
    );
  }

  Widget _statTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: const TextStyle(color: _slateDark, fontSize: 18, fontWeight: FontWeight.w900)),
              Text(label, style: const TextStyle(color: _slateLight, fontSize: 10, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _revenueRow(AdminAnalytics a) {
    return Row(
      children: [
        Expanded(child: _revenueCard('Total Revenue', a.totalRevenue, const Color(0xFF10B981))),
        const SizedBox(width: 10),
        Expanded(child: _revenueCard('This Month', a.monthlyRevenue, _teal)),
      ],
    );
  }

  Widget _revenueCard(String label, num value, Color color) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(color: _slateLight, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Text('₹${value.toStringAsFixed(0)}', style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _manageSection() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Manage', style: TextStyle(color: _slateDark, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _manageRow(Icons.group_rounded, 'User Management', 'Users, roles, plant access', '/admin-users'),
          _divider(),
          _manageRow(Icons.card_membership_rounded, 'Subscriptions & Payments', 'Plans, renewals, history', '/admin-subscriptions'),
          _divider(),
          _manageRow(Icons.solar_power_rounded, 'Plant Management', 'Create, edit, assign plants', '/admin-plants'),
          _divider(),
          _manageRow(Icons.insights_rounded, 'Plant Stats', 'Open plant dashboards & telemetry', '/admin-features'),
          _divider(),
          _manageRow(Icons.confirmation_number_rounded, 'Support Tickets', 'All tickets raised by clients', '/admin-tickets'),
          _divider(),
          _manageRow(Icons.history_rounded, 'Audit Log', 'Trail of admin actions', '/admin-audit'),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(height: 20, color: Color(0xFFF1F5F9));

  Widget _manageRow(IconData icon, String title, String subtitle, String route) {
    return InkWell(
      onTap: () => context.push(route),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: _teal.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: _teal, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _slateDark)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: _slateLight)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: _slateLight),
        ],
      ),
    );
  }

  Widget _recentUsers(AdminAnalytics a) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recently Registered', style: TextStyle(color: _slateDark, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (a.recentUsers.isEmpty)
            const Text('No users yet', style: TextStyle(color: _slateLight, fontSize: 12))
          else
            for (int i = 0; i < a.recentUsers.length; i++) ...[
              if (i > 0) _divider(),
              Builder(builder: (_) {
                final u = a.recentUsers[i];
                final d = DateTime.now().difference(u.createdAt);
                final ago = d.inDays > 0 ? '${d.inDays}d ago' : d.inHours > 0 ? '${d.inHours}h ago' : 'just now';
                return _personRow(
                  u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                  _teal,
                  u.name,
                  '${u.email} · ${u.role}',
                  ago,
                );
              }),
            ],
        ],
      ),
    );
  }

  Widget _recentlyExpired(AdminAnalytics a) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recently Expired', style: TextStyle(color: _slateDark, fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (a.recentlyExpired.isEmpty)
            const Text('No recently expired subscriptions', style: TextStyle(color: _slateLight, fontSize: 12))
          else
            for (int i = 0; i < a.recentlyExpired.length; i++) ...[
              if (i > 0) _divider(),
              Builder(builder: (_) {
                final s = a.recentlyExpired[i];
                return _personRow('!', const Color(0xFFEF4444), s.userName, '${s.plan} plan',
                    'exp ${s.expiryDate.day}/${s.expiryDate.month}');
              }),
            ],
        ],
      ),
    );
  }

  Widget _personRow(String initial, Color color, String title, String subtitle, String trailing) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color.withValues(alpha: 0.12),
          child: Text(initial, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _slateDark, fontSize: 12.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 1),
              Text(subtitle, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _slateLight, fontSize: 10.5)),
            ],
          ),
        ),
        Text(trailing, style: const TextStyle(color: _slateLight, fontSize: 10, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ── Footer (identical to client) ───────────────────────────────────────────
  Widget _footer() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Image.asset('assets/images/logo.png', height: 20)],
        ),
        const SizedBox(height: 6),
        const Text('© 2024 Enercore. All rights reserved.',
            style: TextStyle(color: _slateLight, fontSize: 9.5, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center),
      ],
    );
  }

  // ── Bottom nav (same client style, admin destinations) ─────────────────────
  Widget _bottomNav() {
    final items = [
      (Icons.home_rounded, 'Home'),
      (Icons.group_rounded, 'Users'),
      (Icons.solar_power_rounded, 'Plants'),
      (Icons.card_membership_rounded, 'Billing'),
      (Icons.history_rounded, 'Audit'),
      (Icons.person_outline_rounded, 'Profile'),
    ];
    final routes = [null, '/admin-users', '/admin-plants', '/admin-subscriptions', '/admin-audit', '/profile'];
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _cardBorder, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final active = _selectedNav == i;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedNav = i);
              if (routes[i] != null) context.push(routes[i]!);
            },
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(items[i].$1, color: active ? _teal : _slateLight.withValues(alpha: 0.6), size: 20),
                  const SizedBox(height: 4),
                  Text(items[i].$2,
                      style: TextStyle(
                        color: active ? _teal : _slateLight.withValues(alpha: 0.7),
                        fontSize: 9,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      )),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Card helper (identical to client) ──────────────────────────────────────
  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}
