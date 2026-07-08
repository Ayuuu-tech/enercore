import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../application/vendor_controller.dart';
import '../../domain/vendor_models.dart';
import '../widgets/vendor_chrome.dart';

/// Create or edit a product. Pass an existing [VendorProductModel] via
/// GoRouter `extra` to edit; otherwise it creates a new listing.
class VendorAddProductScreen extends ConsumerStatefulWidget {
  final VendorProductModel? existing;
  const VendorAddProductScreen({super.key, this.existing});

  @override
  ConsumerState<VendorAddProductScreen> createState() => _VendorAddProductScreenState();
}

class _VendorAddProductScreenState extends ConsumerState<VendorAddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _brand;
  late final TextEditingController _spec;
  late final TextEditingController _price;
  late final TextEditingController _originalPrice;
  late final TextEditingController _stock;

  final _categories = ['Solar Panels', 'Inverters', 'Cables', 'Batteries', 'Accessories'];
  late String _category;
  late bool _isAssured;
  bool _submitting = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _brand = TextEditingController(text: e?.brand ?? '');
    _spec = TextEditingController(text: e?.spec ?? '');
    _price = TextEditingController(text: e?.price.toString() ?? '');
    _originalPrice = TextEditingController(text: e?.originalPrice?.toString() ?? '');
    _stock = TextEditingController(text: e?.stock.toString() ?? '0');
    _category = (e != null && _categories.contains(e.category)) ? e.category : _categories.first;
    _isAssured = e?.isAssured ?? false;
  }

  @override
  void dispose() {
    _title.dispose();
    _brand.dispose();
    _spec.dispose();
    _price.dispose();
    _originalPrice.dispose();
    _stock.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final notifier = ref.read(vendorProductsProvider.notifier);
    final price = num.tryParse(_price.text.trim()) ?? 0;
    final origRaw = _originalPrice.text.trim();
    final orig = origRaw.isEmpty ? null : num.tryParse(origRaw);
    final stock = int.tryParse(_stock.text.trim()) ?? 0;
    try {
      if (_isEdit) {
        await notifier.updateProduct(
          widget.existing!.id,
          title: _title.text.trim(),
          brand: _brand.text.trim(),
          spec: _spec.text.trim(),
          category: _category,
          price: price,
          originalPrice: orig,
          stock: stock,
          isAssured: _isAssured,
        );
      } else {
        await notifier.createProduct(
          title: _title.text.trim(),
          brand: _brand.text.trim(),
          spec: _spec.text.trim(),
          category: _category,
          price: price,
          originalPrice: orig,
          stock: stock,
          isAssured: _isAssured,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'Product updated' : 'Product listed')),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VendorTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            const VendorTopBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEdit ? 'Edit Product' : 'List New Product',
                        style: const TextStyle(
                          color: VendorTheme.slateDark,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Provide accurate specifications so buyers can make informed decisions.',
                        style: TextStyle(color: VendorTheme.slateLight, fontSize: 12.5, fontWeight: FontWeight.w500, height: 1.4),
                      ),
                      const SizedBox(height: 20),
                      _label('Product Title'),
                      _field(_title, hint: 'e.g. 550W Monocrystalline PV Module', validator: _required),
                      _label('Brand'),
                      _field(_brand, hint: 'e.g. LUMOS ENERGY', validator: _required),
                      _label('Specification'),
                      _field(_spec, hint: 'e.g. 22.5% Efficiency | Half-cut Cell Tech', validator: _required, maxLines: 2),
                      _label('Category'),
                      _categoryDropdown(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('Price (₹)'),
                                _field(_price, hint: '18450', keyboard: TextInputType.number, validator: _positiveNum),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _label('MRP (optional)'),
                                _field(_originalPrice, hint: '21000', keyboard: TextInputType.number),
                              ],
                            ),
                          ),
                        ],
                      ),
                      _label('Stock Quantity'),
                      _field(_stock, hint: '0', keyboard: TextInputType.number, validator: _nonNegativeInt),
                      const SizedBox(height: 8),
                      _assuredToggle(),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: VendorTheme.teal,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _submitting ? null : _submit,
                          child: _submitting
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  _isEdit ? 'Save Changes' : 'Publish Listing',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                                ),
                        ),
                      ),
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

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;
  String? _positiveNum(String? v) {
    final n = num.tryParse(v?.trim() ?? '');
    if (n == null || n <= 0) return 'Enter a valid amount';
    return null;
  }

  String? _nonNegativeInt(String? v) {
    final n = int.tryParse(v?.trim() ?? '');
    if (n == null || n < 0) return 'Enter a valid quantity';
    return null;
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 14),
        child: Text(text, style: const TextStyle(color: VendorTheme.slateDark, fontSize: 12.5, fontWeight: FontWeight.w800)),
      );

  Widget _field(
    TextEditingController c, {
    String? hint,
    String? Function(String?)? validator,
    TextInputType? keyboard,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: c,
      validator: validator,
      keyboardType: keyboard,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: VendorTheme.slateDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: VendorTheme.slateLight, fontSize: 12.5, fontWeight: FontWeight.w400),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: VendorTheme.cardBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: VendorTheme.cardBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: VendorTheme.teal, width: 1.5)),
      ),
    );
  }

  Widget _categoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: VendorTheme.cardBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _category,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: VendorTheme.slateLight),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: VendorTheme.slateDark),
          items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => setState(() => _category = v ?? _category),
        ),
      ),
    );
  }

  Widget _assuredToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: VendorTheme.cardBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, color: VendorTheme.teal, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Platform Assured',
              style: TextStyle(color: VendorTheme.slateDark, fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
          Switch(
            value: _isAssured,
            activeTrackColor: VendorTheme.teal,
            onChanged: (v) => setState(() => _isAssured = v),
          ),
        ],
      ),
    );
  }
}
