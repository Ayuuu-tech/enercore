import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../../ticketing/data/plants_repository.dart';
import '../../../ticketing/domain/plant_model.dart';
import '../../data/telemetry_repository.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  // Premium Design Tokens (same as other screens)
  static const _bg = Color(0xFFF4F6F8);
  static const _card = Colors.white;
  static const _cardBorder = Color(0xFFE5E7EB);
  static const _teal = Color(0xFF2A8C6E);
  static const _slateDark = Color(0xFF1E293B);
  static const _slateLight = Color(0xFF64748B);

  static const _frequencies = [
    ('DAILY', 'Daily'),
    ('WEEKLY', 'Weekly'),
    ('MONTHLY', 'Monthly'),
    ('YEARLY', 'Yearly'),
  ];

  String _frequency = 'DAILY';
  DateTime _date = DateTime.now().subtract(const Duration(days: 1));
  PlantModel? _selectedPlant;
  bool _generating = false;
  String? _lastFilePath;
  String? _lastFileName;

  String get _periodLabel {
    switch (_frequency) {
      case 'DAILY':
        return '${_date.day}/${_date.month}/${_date.year}';
      case 'WEEKLY':
        final monday = _date.subtract(Duration(days: _date.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        return '${monday.day}/${monday.month} – ${sunday.day}/${sunday.month}/${sunday.year}';
      case 'MONTHLY':
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return '${months[_date.month - 1]} ${_date.year}';
      case 'YEARLY':
        return '${_date.year}';
    }
    return '';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _teal),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _generate() async {
    final plant = _selectedPlant;
    if (plant == null) return;
    setState(() {
      _generating = true;
      _lastFilePath = null;
    });
    try {
      final report = await ref.read(telemetryRepositoryProvider).generateSiteReport(
            plantId: plant.id,
            frequency: _frequency,
            date: _date,
          );
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${report.filename}');
      await file.writeAsBytes(report.bytes);
      if (!mounted) return;
      setState(() {
        _lastFilePath = file.path;
        _lastFileName = report.filename;
      });
      await OpenFilex.open(file.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFEF4444),
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plantsAsync = ref.watch(plantsFutureProvider);
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: plantsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: _teal)),
                error: (e, _) => Center(
                  child: Text('Could not load plants\n$e',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: _slateLight, fontSize: 12)),
                ),
                data: (plants) {
                  _selectedPlant ??= plants.isNotEmpty ? plants.first : null;
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Site Reports',
                          style: TextStyle(color: _slateDark, fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Generate plant analysis reports (Excel) from live Trackso data',
                          style: TextStyle(color: _slateLight, fontSize: 11.5, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 16),
                        _cardBox(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionLabel('PLANT'),
                              const SizedBox(height: 8),
                              _plantSelector(plants),
                              const SizedBox(height: 18),
                              _sectionLabel('REPORT FREQUENCY'),
                              const SizedBox(height: 8),
                              _frequencyChips(),
                              const SizedBox(height: 18),
                              _sectionLabel('PERIOD'),
                              const SizedBox(height: 8),
                              _datePickerTile(),
                              const SizedBox(height: 22),
                              SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: ElevatedButton.icon(
                                  onPressed: _generating || _selectedPlant == null ? null : _generate,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _teal,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: _generating
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                        )
                                      : const Icon(Icons.description_rounded, size: 18),
                                  label: Text(
                                    _generating ? 'Generating…' : 'Generate Report',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_lastFilePath != null) ...[
                          const SizedBox(height: 16),
                          _cardBox(
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD1FAE5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.table_chart_rounded, color: _teal, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _lastFileName ?? '',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: _slateDark, fontSize: 12, fontWeight: FontWeight.w700),
                                      ),
                                      const Text(
                                        'Report downloaded',
                                        style: TextStyle(color: _slateLight, fontSize: 10.5),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => OpenFilex.open(_lastFilePath!),
                                  child: const Text('Open',
                                      style: TextStyle(color: _teal, fontSize: 12, fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
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
          Image.asset('assets/images/logo.png', height: 24, fit: BoxFit.contain),
          const SizedBox(width: 8),
          const Text(
            'Enercore',
            style: TextStyle(color: _teal, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(color: _slateLight, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
    );
  }

  Widget _plantSelector(List<PlantModel> plants) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _cardBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPlant?.id,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _slateLight),
          items: plants
              .map((p) => DropdownMenuItem(
                    value: p.id,
                    child: Text(
                      '${p.name} – ${p.location}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _slateDark, fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ))
              .toList(),
          onChanged: (id) => setState(() {
            _selectedPlant = plants.firstWhere((p) => p.id == id);
          }),
        ),
      ),
    );
  }

  Widget _frequencyChips() {
    return Row(
      children: _frequencies.map((f) {
        final active = _frequency == f.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _frequency = f.$1),
            child: Container(
              margin: EdgeInsets.only(right: f.$1 != 'YEARLY' ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: active ? _teal : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: active ? _teal : _cardBorder),
              ),
              child: Text(
                f.$2,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: active ? Colors.white : _slateLight,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _datePickerTile() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _cardBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_rounded, color: _teal, size: 18),
            const SizedBox(width: 10),
            Text(
              _periodLabel,
              style: const TextStyle(color: _slateDark, fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            const Icon(Icons.keyboard_arrow_down_rounded, color: _slateLight, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _cardBox({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
