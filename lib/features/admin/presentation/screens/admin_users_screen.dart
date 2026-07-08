import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../ticketing/data/plants_repository.dart';
import '../../../ticketing/domain/plant_model.dart';
import '../../data/admin_repository.dart';

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  // Premium design tokens (same as client screens)
  static const _bg = Color(0xFFF4F6F8);
  static const _cardBorder = Color(0xFFE5E7EB);
  static const _teal = Color(0xFF2A8C6E);
  static const _slateDark = Color(0xFF1E293B);
  static const _slateLight = Color(0xFF64748B);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);
    return Scaffold(
      backgroundColor: _bg,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _teal,
        onPressed: () => _showCreateUser(context, ref),
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 20),
        label: const Text('New User', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _topBar(context),
            Expanded(
              child: usersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: _teal)),
                error: (e, _) => _errorView(ref, e),
                data: (users) => RefreshIndicator(
                  color: _teal,
                  onRefresh: () => ref.refresh(adminUsersProvider.future),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: users.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _userCard(context, ref, users[i]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Container(
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
          const Text('User Management',
              style: TextStyle(color: _teal, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
        ],
      ),
    );
  }

  Widget _errorView(WidgetRef ref, Object e) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Could not load users\n$e',
                textAlign: TextAlign.center, style: const TextStyle(color: _slateLight, fontSize: 12)),
            TextButton(
              onPressed: () => ref.refresh(adminUsersProvider),
              child: const Text('Retry', style: TextStyle(color: _teal, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );

  Color _roleColor(String role) {
    switch (role) {
      case 'ADMIN':
        return const Color(0xFF7C3AED);
      case 'VENDOR':
        return const Color(0xFFD97706);
      default:
        return _teal;
    }
  }

  Widget _userCard(BuildContext context, WidgetRef ref, AdminUser u) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder, width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _roleColor(u.role).withValues(alpha: 0.12),
                child: Text(
                  u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                  style: TextStyle(color: _roleColor(u.role), fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(u.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: _slateDark, fontSize: 13.5, fontWeight: FontWeight.w800)),
                        ),
                        const SizedBox(width: 6),
                        _chip(u.role, _roleColor(u.role)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(u.email,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _slateLight, fontSize: 11)),
                  ],
                ),
              ),
              // Enable / disable
              Switch(
                value: u.isActive,
                activeThumbColor: _teal,
                onChanged: (v) async {
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await ref.read(adminRepositoryProvider).setActive(u.id, v);
                    ref.invalidate(adminUsersProvider);
                  } catch (err) {
                    messenger.showSnackBar(SnackBar(
                      backgroundColor: const Color(0xFFEF4444),
                      content: Text(err.toString().replaceFirst('Exception: ', '')),
                    ));
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _stat(Icons.solar_power_rounded, '${u.totalPlants} plants'),
              const SizedBox(width: 16),
              _stat(
                u.isActive ? Icons.check_circle_rounded : Icons.block_rounded,
                u.isActive ? 'Active' : 'Disabled',
                color: u.isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showModules(context, ref, u),
                icon: const Icon(Icons.widgets_rounded, size: 15, color: _teal),
                label: const Text('Features',
                    style: TextStyle(color: _teal, fontSize: 11.5, fontWeight: FontWeight.w700)),
              ),
              TextButton.icon(
                onPressed: () => _showAssignPlants(context, ref, u),
                icon: const Icon(Icons.tune_rounded, size: 15, color: _teal),
                label: const Text('Plants',
                    style: TextStyle(color: _teal, fontSize: 11.5, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(5)),
        child: Text(text, style: TextStyle(color: color, fontSize: 8.5, fontWeight: FontWeight.w800)),
      );

  Widget _stat(IconData icon, String label, {Color color = _slateLight}) => Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      );

  // ── Create user dialog ─────────────────────────────────────────────────────
  void _showCreateUser(BuildContext context, WidgetRef ref) {
    final nameC = TextEditingController();
    final emailC = TextEditingController();
    final passC = TextEditingController();
    final phoneC = TextEditingController();
    String role = 'CLIENT';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Create User',
                  style: TextStyle(color: _slateDark, fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              _field(nameC, 'Full name'),
              const SizedBox(height: 10),
              _field(emailC, 'Email', keyboard: TextInputType.emailAddress),
              const SizedBox(height: 10),
              _field(passC, 'Password', obscure: true),
              const SizedBox(height: 10),
              _field(phoneC, 'Phone (optional)', keyboard: TextInputType.phone),
              const SizedBox(height: 14),
              const Text('ROLE',
                  style: TextStyle(color: _slateLight, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              const SizedBox(height: 8),
              Row(
                children: ['CLIENT', 'VENDOR', 'ADMIN'].map((r) {
                  final active = role == r;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setSheet(() => role = r),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: active ? _teal : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: active ? _teal : _cardBorder),
                        ),
                        child: Text(r,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: active ? Colors.white : _slateLight,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _teal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final navigator = Navigator.of(ctx);
                    final messenger = ScaffoldMessenger.of(ctx);
                    if (nameC.text.trim().isEmpty || emailC.text.trim().isEmpty || passC.text.length < 6) {
                      messenger.showSnackBar(const SnackBar(
                        backgroundColor: Color(0xFFEF4444),
                        content: Text('Name, email and a 6+ char password are required'),
                      ));
                      return;
                    }
                    try {
                      await ref.read(adminRepositoryProvider).createUser(
                            name: nameC.text.trim(),
                            email: emailC.text.trim(),
                            password: passC.text,
                            role: role,
                            phone: phoneC.text.trim(),
                          );
                      navigator.pop();
                      ref.invalidate(adminUsersProvider);
                      messenger.showSnackBar(const SnackBar(
                        backgroundColor: Color(0xFF2A8C6E),
                        content: Text('User created'),
                      ));
                    } catch (e) {
                      messenger.showSnackBar(SnackBar(
                        backgroundColor: const Color(0xFFEF4444),
                        content: Text(e.toString().replaceFirst('Exception: ', '')),
                      ));
                    }
                  },
                  child: const Text('Create', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint,
      {bool obscure = false, TextInputType? keyboard}) {
    return TextField(
      controller: c,
      obscureText: obscure,
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
  }

  // ── Assign plants sheet ────────────────────────────────────────────────────
  void _showAssignPlants(BuildContext context, WidgetRef ref, AdminUser user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _AssignPlantsSheet(user: user),
    );
  }

  // ── Module/feature toggles sheet ───────────────────────────────────────────
  void _showModules(BuildContext context, WidgetRef ref, AdminUser user) {
    // Empty = all allowed → pre-check everything.
    final selected = user.modules.isEmpty ? kAllModules.keys.toSet() : user.modules.toSet();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Feature access — ${user.name}',
                  style: const TextStyle(color: _slateDark, fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Toggle which app modules this user can open',
                  style: TextStyle(color: _slateLight, fontSize: 11.5)),
              const SizedBox(height: 8),
              ...kAllModules.entries.map((e) => CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: _teal,
                    value: selected.contains(e.key),
                    onChanged: (v) => setSheet(() {
                      if (v == true) {
                        selected.add(e.key);
                      } else {
                        selected.remove(e.key);
                      }
                    }),
                    title: Text(e.value,
                        style: const TextStyle(color: _slateDark, fontSize: 13, fontWeight: FontWeight.w700)),
                  )),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _teal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final nav = Navigator.of(ctx);
                    final messenger = ScaffoldMessenger.of(ctx);
                    // All selected → store empty (= all), else the explicit subset.
                    final modules =
                        selected.length == kAllModules.length ? <String>[] : selected.toList();
                    try {
                      await ref.read(adminRepositoryProvider).setUserModules(user.id, modules);
                      nav.pop();
                      ref.invalidate(adminUsersProvider);
                      messenger.showSnackBar(const SnackBar(
                        backgroundColor: Color(0xFF2A8C6E),
                        content: Text('Feature access updated'),
                      ));
                    } catch (e) {
                      messenger.showSnackBar(SnackBar(
                        backgroundColor: const Color(0xFFEF4444),
                        content: Text(e.toString().replaceFirst('Exception: ', '')),
                      ));
                    }
                  },
                  child: const Text('Save', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Stateful sheet: load all plants + user's current plants, multi-select, save.
class _AssignPlantsSheet extends ConsumerStatefulWidget {
  final AdminUser user;
  const _AssignPlantsSheet({required this.user});

  @override
  ConsumerState<_AssignPlantsSheet> createState() => _AssignPlantsSheetState();
}

class _AssignPlantsSheetState extends ConsumerState<_AssignPlantsSheet> {
  static const _teal = Color(0xFF2A8C6E);
  static const _slateDark = Color(0xFF1E293B);
  static const _slateLight = Color(0xFF64748B);

  List<PlantModel> _all = [];
  Set<String> _selected = {};
  Set<String> _owned = {};
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final adminRepo = ref.read(adminRepositoryProvider);
      final all = await ref.read(plantsRepositoryProvider).getPlants();
      final assigned = await adminRepo.getUserPlants(widget.user.id);
      // Owner plants are always accessible and cannot be unassigned here.
      final ownedIds = <String>{
        for (final p in assigned)
          if (p.ownerId == widget.user.id) p.id
      };
      if (!mounted) return;
      setState(() {
        _all = all;
        _selected = assigned.map((p) => p.id).toSet();
        _owned = ownedIds;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      // Only granted (non-owned) plants are managed via setUserPlants.
      final grantIds = _selected.where((id) => !_owned.contains(id)).toList();
      await ref.read(adminRepositoryProvider).setUserPlants(widget.user.id, grantIds);
      ref.invalidate(adminUsersProvider);
      ref.invalidate(userPlantsProvider(widget.user.id));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: const Color(0xFFEF4444),
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Plant access — ${widget.user.name}',
              style: const TextStyle(color: _slateDark, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Select which plants this user can view',
              style: TextStyle(color: _slateLight, fontSize: 11.5)),
          const SizedBox(height: 14),
          if (_loading)
            const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator(color: _teal)))
          else if (_error != null)
            Text('Error: $_error', style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12))
          else ...[
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: ListView(
                shrinkWrap: true,
                children: _all.map((p) {
                  final isOwner = _owned.contains(p.id);
                  final checked = _selected.contains(p.id);
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: _teal,
                    value: checked,
                    onChanged: isOwner
                        ? null // owner plants are locked-on
                        : (v) => setState(() {
                              if (v == true) {
                                _selected.add(p.id);
                              } else {
                                _selected.remove(p.id);
                              }
                            }),
                    title: Text(p.name,
                        style: const TextStyle(color: _slateDark, fontSize: 13, fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      isOwner ? '${p.location} · owner' : p.location,
                      style: const TextStyle(color: _slateLight, fontSize: 11),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _teal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save access', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
