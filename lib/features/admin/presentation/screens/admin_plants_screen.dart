import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/admin_repository.dart';

class AdminPlantsScreen extends ConsumerStatefulWidget {
  const AdminPlantsScreen({super.key});

  @override
  ConsumerState<AdminPlantsScreen> createState() => _AdminPlantsScreenState();
}

class _AdminPlantsScreenState extends ConsumerState<AdminPlantsScreen> {
  static const _bg = Color(0xFFF4F6F8);
  static const _cardBorder = Color(0xFFE5E7EB);
  static const _teal = Color(0xFF2A8C6E);
  static const _slateDark = Color(0xFF1E293B);
  static const _slateLight = Color(0xFF64748B);

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: error ? const Color(0xFFEF4444) : _teal,
      content: Text(msg.replaceFirst('Exception: ', '')),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminPlantsProvider);
    return Scaffold(
      backgroundColor: _bg,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _teal,
        onPressed: () => _showPlantForm(),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Plant', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator(color: _teal)),
                error: (e, _) => Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('Error: $e', textAlign: TextAlign.center, style: const TextStyle(color: _slateLight, fontSize: 12)),
                    TextButton(onPressed: () => ref.refresh(adminPlantsProvider), child: const Text('Retry', style: TextStyle(color: _teal, fontWeight: FontWeight.w700))),
                  ]),
                ),
                data: (plants) {
                  if (plants.isEmpty) return const Center(child: Text('No plants yet', style: TextStyle(color: _slateLight, fontSize: 12)));
                  return RefreshIndicator(
                    color: _teal,
                    onRefresh: () => ref.refresh(adminPlantsProvider.future),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: plants.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) => _plantCard(plants[i]),
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

  Widget _topBar() {
    return Container(
      height: 56,
      decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: _cardBorder, width: 1))),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(onTap: () => context.pop(), child: const Icon(Icons.arrow_back_rounded, color: _slateDark, size: 22)),
          const SizedBox(width: 12),
          const Text('Plant Management', style: TextStyle(color: _teal, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
        ],
      ),
    );
  }

  Widget _plantCard(AdminPlant p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: _cardBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: _teal.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.solar_power_rounded, color: _teal, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, style: const TextStyle(color: _slateDark, fontSize: 13.5, fontWeight: FontWeight.w800)),
                    Text(p.location, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _slateLight, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(6)),
                child: Text('${p.peakCapacity.toStringAsFixed(0)}kW', style: const TextStyle(color: _teal, fontSize: 9.5, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _meta(Icons.person_rounded, 'Owner: ${p.ownerName}'),
              const SizedBox(width: 14),
              _meta(Icons.group_rounded, '${p.grantedUsers} shared'),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _actionBtn('Edit', _teal, () => _showPlantForm(plant: p)),
              _actionBtn('Transfer', const Color(0xFF7C3AED), () => _showTransfer(p)),
              _actionBtn('Delete', const Color(0xFFEF4444), () => _confirmDelete(p)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _meta(IconData i, String t) => Row(children: [
        Icon(i, size: 14, color: _slateLight),
        const SizedBox(width: 4),
        Flexible(child: Text(t, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _slateLight, fontSize: 11, fontWeight: FontWeight.w600))),
      ]);

  Widget _actionBtn(String label, Color color, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(left: 6),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(7)),
            child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
          ),
        ),
      );

  // ── Create / edit form ──────────────────────────────────────────────────────
  void _showPlantForm({AdminPlant? plant}) {
    final nameC = TextEditingController(text: plant?.name ?? '');
    final locC = TextEditingController(text: plant?.location ?? '');
    final capC = TextEditingController(text: plant != null ? plant.peakCapacity.toStringAsFixed(0) : '');
    final editing = plant != null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(editing ? 'Edit plant' : 'New plant', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _slateDark)),
            const SizedBox(height: 16),
            _field(nameC, 'Plant name'),
            const SizedBox(height: 10),
            _field(locC, 'Location'),
            const SizedBox(height: 10),
            _field(capC, 'Peak capacity (kW)', keyboard: const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity, height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _teal, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () async {
                  final nav = Navigator.of(ctx);
                  final name = nameC.text.trim();
                  final loc = locC.text.trim();
                  final cap = num.tryParse(capC.text) ?? 0;
                  if (name.isEmpty || loc.isEmpty || cap <= 0) {
                    _snack('Name, location and a valid capacity are required', error: true);
                    return;
                  }
                  try {
                    final repo = ref.read(adminRepositoryProvider);
                    if (editing) {
                      await repo.updatePlant(plant.id, name: name, location: loc, peakCapacity: cap);
                    } else {
                      await repo.createPlant(name: name, location: loc, peakCapacity: cap);
                    }
                    nav.pop();
                    ref.invalidate(adminPlantsProvider);
                    _snack(editing ? 'Plant updated' : 'Plant created');
                  } catch (e) {
                    _snack(e.toString(), error: true);
                  }
                },
                child: Text(editing ? 'Save' : 'Create', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String hint, {TextInputType? keyboard}) => TextField(
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

  // ── Transfer ownership ──────────────────────────────────────────────────────
  Future<void> _showTransfer(AdminPlant plant) async {
    final users = await ref.read(adminRepositoryProvider).listUsers();
    if (!mounted) return;
    showModalBottomSheet(
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Transfer "${plant.name}" to…', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _slateDark)),
              ),
              Expanded(
                child: ListView(
                  children: users.where((u) => u.id != plant.ownerId).map((u) => ListTile(
                        title: Text(u.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _slateDark)),
                        subtitle: Text('${u.email} · ${u.role}', style: const TextStyle(fontSize: 11, color: _slateLight)),
                        onTap: () async {
                          final nav = Navigator.of(ctx);
                          try {
                            await ref.read(adminRepositoryProvider).transferOwnership(plant.id, u.id);
                            nav.pop();
                            ref.invalidate(adminPlantsProvider);
                            _snack('Ownership transferred to ${u.name}');
                          } catch (e) {
                            _snack(e.toString(), error: true);
                          }
                        },
                      )).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(AdminPlant plant) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete plant?'),
        content: Text('This permanently deletes "${plant.name}" and its panels, telemetry and access grants.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: _slateLight))),
          TextButton(
            onPressed: () async {
              final nav = Navigator.of(ctx);
              try {
                await ref.read(adminRepositoryProvider).deletePlant(plant.id);
                nav.pop();
                ref.invalidate(adminPlantsProvider);
                _snack('Plant deleted');
              } catch (e) {
                nav.pop();
                _snack(e.toString(), error: true);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
