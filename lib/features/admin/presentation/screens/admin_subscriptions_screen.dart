import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/admin_repository.dart';

class AdminSubscriptionsScreen extends ConsumerStatefulWidget {
  const AdminSubscriptionsScreen({super.key});

  @override
  ConsumerState<AdminSubscriptionsScreen> createState() => _AdminSubscriptionsScreenState();
}

class _AdminSubscriptionsScreenState extends ConsumerState<AdminSubscriptionsScreen> {
  static const _bg = Color(0xFFF4F6F8);
  static const _cardBorder = Color(0xFFE5E7EB);
  static const _teal = Color(0xFF2A8C6E);
  static const _slateDark = Color(0xFF1E293B);
  static const _slateLight = Color(0xFF64748B);

  int _tab = 0; // 0 = subscriptions, 1 = payments

  Color _statusColor(String s) {
    switch (s) {
      case 'ACTIVE':
      case 'SUCCESS':
        return const Color(0xFF10B981);
      case 'EXPIRED':
      case 'FAILED':
        return const Color(0xFFEF4444);
      case 'PENDING':
        return const Color(0xFFD97706);
      case 'SUSPENDED':
      case 'CANCELLED':
        return _slateLight;
      case 'REFUNDED':
        return const Color(0xFF7C3AED);
      default:
        return _slateLight;
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: error ? const Color(0xFFEF4444) : _teal,
      content: Text(msg.replaceFirst('Exception: ', '')),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _teal,
        onPressed: _tab == 0 ? _showCreateSubscription : _showRecordPayment,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(_tab == 0 ? 'New Subscription' : 'Record Payment',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            _tabBar(),
            Expanded(child: _tab == 0 ? _subscriptionsList() : _paymentsList()),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Container(
      height: 56,
      decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: _cardBorder, width: 1))),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(onTap: () => context.pop(), child: const Icon(Icons.arrow_back_rounded, color: _slateDark, size: 22)),
          const SizedBox(width: 12),
          const Text('Subscriptions & Payments',
              style: TextStyle(color: _teal, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
        ],
      ),
    );
  }

  Widget _tabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          _tabChip('Subscriptions', 0),
          const SizedBox(width: 8),
          _tabChip('Payments', 1),
        ],
      ),
    );
  }

  Widget _tabChip(String label, int idx) {
    final active = _tab == idx;
    return GestureDetector(
      onTap: () => setState(() => _tab = idx),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? _teal : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? _teal : _cardBorder),
        ),
        child: Text(label,
            style: TextStyle(color: active ? Colors.white : _slateLight, fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
        child: Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800)),
      );

  // ── Subscriptions ─────────────────────────────────────────────────────────
  Widget _subscriptionsList() {
    final async = ref.watch(adminSubscriptionsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: _teal)),
      error: (e, _) => _errorView(e, () => ref.refresh(adminSubscriptionsProvider)),
      data: (subs) {
        if (subs.isEmpty) return _emptyView('No subscriptions yet');
        return RefreshIndicator(
          color: _teal,
          onRefresh: () => ref.refresh(adminSubscriptionsProvider.future),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: subs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _subCard(subs[i]),
          ),
        );
      },
    );
  }

  Widget _subCard(SubscriptionModel s) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: _cardBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.userName, style: const TextStyle(color: _slateDark, fontSize: 13.5, fontWeight: FontWeight.w800)),
                    Text(s.userEmail, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _slateLight, fontSize: 11)),
                  ],
                ),
              ),
              _chip(s.status, _statusColor(s.status)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _meta(Icons.card_membership_rounded, s.plan),
              const SizedBox(width: 14),
              _meta(Icons.payments_rounded, '₹${s.amount.toStringAsFixed(0)}'),
              const SizedBox(width: 14),
              _meta(Icons.event_rounded, 'exp ${s.expiryDate.day}/${s.expiryDate.month}/${s.expiryDate.year}'),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _actionBtn('Renew', const Color(0xFF10B981), () => _renew(s.id)),
              if (s.status != 'SUSPENDED')
                _actionBtn('Suspend', const Color(0xFFD97706), () => _setStatus(s.id, 'SUSPENDED')),
              if (s.status != 'ACTIVE')
                _actionBtn('Activate', _teal, () => _setStatus(s.id, 'ACTIVE')),
              if (s.status != 'CANCELLED')
                _actionBtn('Cancel', const Color(0xFFEF4444), () => _setStatus(s.id, 'CANCELLED')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _meta(IconData i, String t) => Row(children: [
        Icon(i, size: 14, color: _slateLight),
        const SizedBox(width: 4),
        Text(t, style: const TextStyle(color: _slateLight, fontSize: 11, fontWeight: FontWeight.w600)),
      ]);

  Widget _actionBtn(String label, Color color, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(left: 6),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(7)),
            child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
          ),
        ),
      );

  Future<void> _renew(String id) async {
    try {
      await ref.read(adminRepositoryProvider).renewSubscription(id);
      ref.invalidate(adminSubscriptionsProvider);
      ref.invalidate(adminAnalyticsProvider);
      _snack('Subscription renewed');
    } catch (e) {
      _snack(e.toString(), error: true);
    }
  }

  Future<void> _setStatus(String id, String status) async {
    try {
      await ref.read(adminRepositoryProvider).setSubscriptionStatus(id, status);
      ref.invalidate(adminSubscriptionsProvider);
      ref.invalidate(adminAnalyticsProvider);
      _snack('Subscription $status');
    } catch (e) {
      _snack(e.toString(), error: true);
    }
  }

  // ── Payments ──────────────────────────────────────────────────────────────
  Widget _paymentsList() {
    final async = ref.watch(adminPaymentsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator(color: _teal)),
      error: (e, _) => _errorView(e, () => ref.refresh(adminPaymentsProvider)),
      data: (payments) {
        if (payments.isEmpty) return _emptyView('No payments recorded yet');
        return RefreshIndicator(
          color: _teal,
          onRefresh: () => ref.refresh(adminPaymentsProvider.future),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _payCard(payments[i]),
          ),
        );
      },
    );
  }

  Widget _payCard(PaymentModel p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: _cardBorder)),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: _statusColor(p.status).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9)),
            child: Icon(Icons.receipt_long_rounded, color: _statusColor(p.status), size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.userName, style: const TextStyle(color: _slateDark, fontSize: 12.5, fontWeight: FontWeight.w700)),
                Text('${p.method ?? 'manual'} · ${p.createdAt.day}/${p.createdAt.month}/${p.createdAt.year}',
                    style: const TextStyle(color: _slateLight, fontSize: 10.5)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${p.amount.toStringAsFixed(0)}', style: const TextStyle(color: _slateDark, fontSize: 14, fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              GestureDetector(
                onTap: () => _showPaymentStatusMenu(p),
                child: _chip(p.status, _statusColor(p.status)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPaymentStatusMenu(PaymentModel p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Update payment status', style: TextStyle(color: _slateDark, fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            ...['SUCCESS', 'PENDING', 'FAILED', 'REFUNDED'].map((s) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.circle, size: 12, color: _statusColor(s)),
                  title: Text(s, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _slateDark)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      await ref.read(adminRepositoryProvider).updatePaymentStatus(p.id, s);
                      ref.invalidate(adminPaymentsProvider);
                      ref.invalidate(adminAnalyticsProvider);
                      _snack('Payment marked $s');
                    } catch (e) {
                      _snack(e.toString(), error: true);
                    }
                  },
                )),
          ],
        ),
      ),
    );
  }

  // ── Create subscription / record payment sheets ────────────────────────────
  Future<AdminUser?> _pickUser() async {
    final users = await ref.read(adminRepositoryProvider).listUsers();
    if (!mounted) return null;
    return showModalBottomSheet<AdminUser>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Select user', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _slateDark)),
              ),
              Expanded(
                child: ListView(
                  children: users
                      .map((u) => ListTile(
                            title: Text(u.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _slateDark)),
                            subtitle: Text('${u.email} · ${u.role}', style: const TextStyle(fontSize: 11, color: _slateLight)),
                            onTap: () => Navigator.pop(ctx, u),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateSubscription() async {
    final user = await _pickUser();
    if (user == null || !mounted) return;
    String plan = 'MONTHLY';
    final amountC = TextEditingController(text: '999');
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('New subscription — ${user.name}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _slateDark)),
              const SizedBox(height: 16),
              Row(
                children: ['MONTHLY', 'YEARLY'].map((p) {
                  final active = plan == p;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setSheet(() => plan = p),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: active ? _teal : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: active ? _teal : _cardBorder),
                        ),
                        child: Text(p, textAlign: TextAlign.center, style: TextStyle(color: active ? Colors.white : _slateLight, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              _amountField(amountC),
              const SizedBox(height: 18),
              _primaryBtn('Create & Activate', () async {
                final amount = num.tryParse(amountC.text) ?? 0;
                final nav = Navigator.of(ctx);
                try {
                  await ref.read(adminRepositoryProvider).createSubscription(userId: user.id, plan: plan, amount: amount, activate: true);
                  nav.pop();
                  ref.invalidate(adminSubscriptionsProvider);
                  ref.invalidate(adminAnalyticsProvider);
                  _snack('Subscription created');
                } catch (e) {
                  _snack(e.toString(), error: true);
                }
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRecordPayment() async {
    final user = await _pickUser();
    if (user == null || !mounted) return;
    String status = 'SUCCESS';
    final amountC = TextEditingController(text: '999');
    final methodC = TextEditingController(text: 'UPI');
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Record payment — ${user.name}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _slateDark)),
              const SizedBox(height: 16),
              _amountField(amountC),
              const SizedBox(height: 10),
              _textField(methodC, 'Method (UPI, Card, Cash...)'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: ['SUCCESS', 'PENDING', 'FAILED', 'REFUNDED'].map((s) {
                  final active = status == s;
                  return GestureDetector(
                    onTap: () => setSheet(() => status = s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: active ? _statusColor(s) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: active ? _statusColor(s) : _cardBorder),
                      ),
                      child: Text(s, style: TextStyle(color: active ? Colors.white : _slateLight, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              _primaryBtn('Record Payment', () async {
                final amount = num.tryParse(amountC.text) ?? 0;
                final nav = Navigator.of(ctx);
                try {
                  await ref.read(adminRepositoryProvider).recordPayment(userId: user.id, amount: amount, status: status, method: methodC.text.trim());
                  nav.pop();
                  ref.invalidate(adminPaymentsProvider);
                  ref.invalidate(adminAnalyticsProvider);
                  _snack('Payment recorded');
                } catch (e) {
                  _snack(e.toString(), error: true);
                }
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _amountField(TextEditingController c) => _textField(c, 'Amount (₹)', keyboard: const TextInputType.numberWithOptions(decimal: true));

  Widget _textField(TextEditingController c, String hint, {TextInputType? keyboard}) => TextField(
        controller: c,
        keyboardType: keyboard,
        style: const TextStyle(color: _slateDark, fontSize: 13, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _slateLight, fontSize: 12.5),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _cardBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _cardBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _teal)),
        ),
      );

  Widget _primaryBtn(String label, VoidCallback onTap) => SizedBox(
        width: double.infinity,
        height: 46,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _teal, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          onPressed: onTap,
          child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ),
      );

  Widget _errorView(Object e, VoidCallback retry) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Error: $e', textAlign: TextAlign.center, style: const TextStyle(color: _slateLight, fontSize: 12)),
          TextButton(onPressed: retry, child: const Text('Retry', style: TextStyle(color: _teal, fontWeight: FontWeight.w700))),
        ]),
      );

  Widget _emptyView(String msg) => Center(child: Text(msg, style: const TextStyle(color: _slateLight, fontSize: 12)));
}
