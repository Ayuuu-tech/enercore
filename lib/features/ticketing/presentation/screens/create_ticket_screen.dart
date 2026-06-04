import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../application/ticketing_controller.dart';
import '../../data/plants_repository.dart';
import '../../domain/plant_model.dart';

class CreateTicketScreen extends ConsumerStatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  ConsumerState<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen> {
  int _selectedPriority = 1; // Medium priority selected by default
  String? _selectedPlantId;
  String _selectedCategory = 'Fault';

  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;

  // Premium Design System
  static const _bg = Color(0xFFF4F6F8);
  static const _card = Colors.white;
  static const _cardBorder = Color(0xFFE5E7EB);
  static const _teal = Color(0xFF2A8C6E); // primary brand green-teal
  static const _slateDark = Color(0xFF1E293B);
  static const _slateLight = Color(0xFF64748B);

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plantsState = ref.watch(plantsFutureProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Raise Support Ticket',
                        style: TextStyle(
                          color: _slateDark,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Submit details about your industrial asset issues. Our support team will review it shortly.',
                        style: TextStyle(
                          color: _slateLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _inputForm(plantsState),
                      const SizedBox(height: 16),
                      _infoCardsList(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
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

  // ── Form Card ──────────────────────────────────────────────────────────────
  Widget _inputForm(AsyncValue<List<PlantModel>> plantsState) {
    return _card_(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Plant Selector
          _fieldLabel('PLANT SELECTOR'),
          const SizedBox(height: 6),
          _plantDropdownField(plantsState),
          const SizedBox(height: 16),

          // Issue Category
          _fieldLabel('ISSUE CATEGORY'),
          const SizedBox(height: 6),
          _dropdownField(
            icon: Icons.warning_amber_rounded,
            value: _selectedCategory,
            items: ['Fault', 'Warning', 'Billing', 'Inquiry'],
            onChanged: (val) {
              if (val != null) setState(() => _selectedCategory = val);
            },
          ),
          const SizedBox(height: 16),

          // Subject
          _fieldLabel('SUBJECT'),
          const SizedBox(height: 6),
          _textField(hint: 'Brief summary of the issue', controller: _subjectController),
          const SizedBox(height: 16),

          // Description
          _fieldLabel('DESCRIPTION'),
          const SizedBox(height: 6),
          _textField(hint: 'Please provide detailed technical logs or observation notes...', controller: _descriptionController, isMultiline: true),
          const SizedBox(height: 16),

          // Priority Level
          _fieldLabel('PRIORITY LEVEL'),
          const SizedBox(height: 8),
          _prioritySelector(),
          const SizedBox(height: 18),

          // Attachments upload box
          _fieldLabel('ATTACHMENTS'),
          const SizedBox(height: 8),
          _uploadContainer(),
          const SizedBox(height: 20),

          // Action row note + button
          Row(
            children: const [
              Icon(Icons.access_time_rounded, color: _slateLight, size: 14),
              SizedBox(width: 6),
              Text(
                'Standard response time: 2 hours',
                style: TextStyle(color: _slateLight, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _isSubmitting ? null : _submitTicket,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, size: 16),
              label: Text(
                _isSubmitting ? 'Submitting...' : 'Submit Ticket',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(color: _slateLight, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5),
    );
  }

  Widget _plantDropdownField(AsyncValue<List<PlantModel>> plantsState) {
    return plantsState.when(
      data: (plants) {
        if (plants.isEmpty) {
          return Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _cardBorder, width: 1),
            ),
            child: const Text('No facilities available', style: TextStyle(color: _slateLight, fontSize: 12)),
          );
        }
        
        if (_selectedPlantId == null || !plants.any((p) => p.id == _selectedPlantId)) {
          _selectedPlantId = plants.first.id;
        }

        return Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _cardBorder, width: 1),
          ),
          child: Row(
            children: [
              const Icon(Icons.apartment_rounded, color: _slateLight, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPlantId,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _slateLight, size: 18),
                    style: const TextStyle(color: _slateDark, fontSize: 12, fontWeight: FontWeight.w600),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedPlantId = val);
                    },
                    items: plants.map((p) => DropdownMenuItem(
                      value: p.id,
                      child: Text('${p.name} – ${p.location.split(',')[0]}'),
                    )).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _cardBorder, width: 1),
        ),
        child: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: _teal),
        ),
      ),
      error: (err, stack) => Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.redAccent.withAlpha((0.1 * 255).toInt()), width: 1),
        ),
        child: Text('Error loading facilities: $err', style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
      ),
    );
  }

  Widget _dropdownField({required IconData icon, required String value, required List<String> items, required void Function(String?) onChanged}) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _cardBorder, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: _slateLight, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _slateLight, size: 18),
                style: const TextStyle(color: _slateDark, fontSize: 12, fontWeight: FontWeight.w600),
                onChanged: onChanged,
                items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textField({required String hint, required TextEditingController controller, bool isMultiline = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _cardBorder, width: 1),
      ),
      child: TextField(
        controller: controller,
        maxLines: isMultiline ? 4 : 1,
        style: const TextStyle(color: _slateDark, fontSize: 12, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _slateLight, fontSize: 12, fontWeight: FontWeight.w500),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _prioritySelector() {
    final priorities = ['Low', 'Medium', 'High'];
    return Row(
      children: priorities.asMap().entries.map((e) {
        final active = _selectedPriority == e.key;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedPriority = e.key),
            child: Container(
              margin: EdgeInsets.only(
                left: e.key > 0 ? 8 : 0,
              ),
              height: 38,
              decoration: BoxDecoration(
                color: active ? const Color(0xFFD1FAE5) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: active ? _teal : _cardBorder, width: 1),
              ),
              child: Center(
                child: Text(
                  e.value,
                  style: TextStyle(
                    color: active ? _teal : _slateDark,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _uploadContainer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder, width: 1),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: _slateLight.withAlpha((0.2 * 255).toInt()), width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: const [
            Icon(Icons.cloud_upload_outlined, color: _teal, size: 24),
            SizedBox(height: 6),
            Text(
              'Drop files or click to upload',
              style: TextStyle(color: _slateDark, fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 4),
            Text(
              'Maximum file size 50MB. Formats: JPG, PNG, PDF, DOC.',
              style: TextStyle(color: _slateLight, fontSize: 9.5, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Info Cards ─────────────────────────────────────────────────────────────
  Widget _infoCardsList() {
    final info = [
      (
        Icons.headset_mic_rounded,
        'Direct Support',
        'Talk to an engineer for critical grid emergencies.',
        const Color(0xFFD1FAE5),
        _teal
      ),
      (
        Icons.menu_book_rounded,
        'Documentation',
        'Browse our industrial troubleshooting guides.',
        const Color(0xFFF1F5F9),
        _slateLight
      ),
      (
        Icons.history_rounded,
        'Ticket History',
        'View status updates on your existing requests.',
        const Color(0xFFF1F5F9),
        _slateLight
      ),
    ];

    return Column(
      children: info.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: item.$4,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _cardBorder.withAlpha((0.5 * 255).toInt()), width: 0.8),
          ),
          child: Row(
            children: [
              Icon(item.$1, color: item.$5, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.$2,
                      style: TextStyle(color: item.$5 == _teal ? _teal : _slateDark, fontSize: 12.5, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.$3,
                      style: const TextStyle(color: _slateLight, fontSize: 10.5, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Submit Ticket Function ──────────────────────────────────────────────────
  Future<void> _submitTicket() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    if (_selectedPlantId == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please select a facility.'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    
    final subject = _subjectController.text.trim();
    if (subject.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please enter a ticket subject.'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Please enter an issue description.'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final priorityStr = _selectedPriority == 0 ? 'LOW' : (_selectedPriority == 1 ? 'MEDIUM' : 'HIGH');
      final finalTitle = '[$_selectedCategory] $subject';

      await ref.read(ticketingControllerProvider.notifier).createTicket(
        title: finalTitle,
        description: description,
        plantId: _selectedPlantId!,
        priority: priorityStr,
      );

      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Ticket created successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (mounted) {
        context.pop(true); // Return true to signal that list needs refreshing
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to submit ticket: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // ── Card Helper ────────────────────────────────────────────────────────────
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
