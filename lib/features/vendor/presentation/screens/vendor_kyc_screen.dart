import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/kyc_repository.dart';
import '../../domain/kyc_models.dart';
import '../../../../core/http/api_error.dart';

/// Where a vendor gives Enercore the details and documents needed to pay them:
/// PAN, GST, bank account, cancelled cheque, MOA and AOA.
class VendorKycScreen extends ConsumerStatefulWidget {
  const VendorKycScreen({super.key});

  @override
  ConsumerState<VendorKycScreen> createState() => _VendorKycScreenState();
}

class _VendorKycScreenState extends ConsumerState<VendorKycScreen> {
  static const _bg = Color(0xFFF4F6F8);
  static const _cardBorder = Color(0xFFE5E7EB);
  static const _teal = Color(0xFF2A8C6E);
  static const _slateDark = Color(0xFF1E293B);
  static const _slateLight = Color(0xFF64748B);
  static const _red = Color(0xFFEF4444);
  static const _amber = Color(0xFFD97706);

  final _form = GlobalKey<FormState>();
  final _pan = TextEditingController();
  final _gstin = TextEditingController();
  final _accName = TextEditingController();
  final _accNumber = TextEditingController();
  final _ifsc = TextEditingController();
  final _bankName = TextEditingController();

  bool _saving = false;
  bool _prefilled = false;
  VendorDocType? _uploading;

  @override
  void dispose() {
    for (final c in [_pan, _gstin, _accName, _accNumber, _ifsc, _bankName]) {
      c.dispose();
    }
    super.dispose();
  }

  void _prefill(VendorKyc kyc) {
    if (_prefilled) return;
    _prefilled = true;
    _pan.text = kyc.pan ?? '';
    _gstin.text = kyc.gstin ?? '';
    _accName.text = kyc.bankAccountName ?? '';
    _ifsc.text = kyc.bankIfsc ?? '';
    _bankName.text = kyc.bankName ?? '';
    // The account number is only ever sent back masked, so it can't be
    // prefilled — the vendor re-enters it if they want to change it.
  }

  void _toast(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: error ? _red : _teal,
      content: Text(message),
    ));
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(kycRepositoryProvider).saveDetails(
            pan: _pan.text.trim().toUpperCase(),
            gstin: _gstin.text.trim().toUpperCase(),
            bankAccountName: _accName.text.trim(),
            bankAccountNumber: _accNumber.text.trim(),
            bankIfsc: _ifsc.text.trim().toUpperCase(),
            bankName: _bankName.text.trim(),
          );
      ref.invalidate(myKycProvider);
      _toast('Details saved');
    } catch (e) {
      _toast(friendlyMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickAndUpload(VendorDocType type) async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    final file = picked?.files.singleOrNull;
    if (file == null) return;

    setState(() => _uploading = type);
    try {
      // readAsBytes() works on every platform, including web (where a picked
      // file has no path), and streams rather than holding the whole file.
      final bytes = await file.readAsBytes();
      await ref.read(kycRepositoryProvider).uploadDocument(
            type: type,
            bytes: bytes,
            fileName: file.name,
          );
      ref.invalidate(myKycProvider);
      _toast('${type.label} uploaded');
    } catch (e) {
      _toast(friendlyMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _uploading = null);
    }
  }

  Future<void> _view(VendorDocType type) async {
    try {
      final url = await ref.read(kycRepositoryProvider).myDocumentUrl(type);
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      _toast(friendlyMessage(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(myKycProvider);

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
                  const Text('Business & Bank Details',
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
                    Text('$e', textAlign: TextAlign.center,
                        style: const TextStyle(color: _slateLight, fontSize: 12)),
                    TextButton(
                      onPressed: () => ref.invalidate(myKycProvider),
                      child: const Text('Retry',
                          style: TextStyle(color: _teal, fontWeight: FontWeight.w700)),
                    ),
                  ]),
                ),
                data: (kyc) {
                  _prefill(kyc);
                  return RefreshIndicator(
                    color: _teal,
                    onRefresh: () async => ref.invalidate(myKycProvider),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        _statusBanner(kyc),
                        const SizedBox(height: 16),
                        _detailsCard(kyc),
                        const SizedBox(height: 16),
                        _documentsCard(kyc),
                        const SizedBox(height: 24),
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

  Widget _statusBanner(VendorKyc kyc) {
    late final Color color;
    late final IconData icon;
    late final String title;
    late final String body;

    switch (kyc.status) {
      case 'APPROVED':
        color = _teal;
        icon = Icons.verified_rounded;
        title = 'Verified';
        body = 'Your details are verified. You can be paid for orders.';
      case 'PENDING':
        color = _amber;
        icon = Icons.hourglass_top_rounded;
        title = 'Under review';
        body = kyc.readyForReview
            ? 'Enercore is reviewing your details. We\'ll let you know once it\'s done.'
            : 'Add the remaining documents below to complete your submission.';
      case 'REJECTED':
        color = _red;
        icon = Icons.error_outline_rounded;
        title = 'Needs attention';
        body = kyc.rejectReason ?? 'Please review and resubmit your details.';
      default:
        color = _slateLight;
        icon = Icons.info_outline_rounded;
        title = 'Not submitted';
        body = 'Enercore needs these details before you can be paid for orders.';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(body, style: const TextStyle(color: _slateDark, fontSize: 11.5, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(color: _slateDark, fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
    List<TextInputFormatter>? formatters,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        validator: validator,
        inputFormatters: formatters,
        keyboardType: keyboard,
        style: const TextStyle(fontSize: 13, color: _slateDark, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: _slateLight, fontSize: 12),
          hintStyle: const TextStyle(color: _cardBorder, fontSize: 12),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _teal, width: 1.4),
          ),
        ),
      ),
    );
  }

  Widget _detailsCard(VendorKyc kyc) {
    final upper = [FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')), _UpperCase()];

    return Form(
      key: _form,
      child: _card(
        title: 'Business & bank details',
        children: [
          _field(
            controller: _pan,
            label: 'PAN',
            hint: 'ABCDE1234F',
            formatters: [...upper, LengthLimitingTextInputFormatter(10)],
            validator: (v) => RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(v?.toUpperCase() ?? '')
                ? null
                : 'Must look like ABCDE1234F',
          ),
          _field(
            controller: _gstin,
            label: 'GSTIN',
            hint: '06AAACC6423G3ZZ',
            formatters: [...upper, LengthLimitingTextInputFormatter(15)],
            validator: (v) => (v?.length ?? 0) == 15 ? null : 'Must be 15 characters',
          ),
          const Divider(height: 24, color: _cardBorder),
          _field(
            controller: _accName,
            label: 'Account holder name',
            hint: 'As printed on the cheque',
            validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
          ),
          _field(
            controller: _accNumber,
            label: kyc.bankAccountNumberMasked == null
                ? 'Bank account number'
                : 'Bank account number (saved: ${kyc.bankAccountNumberMasked})',
            hint: '9–18 digits',
            keyboard: TextInputType.number,
            formatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(18),
            ],
            validator: (v) => RegExp(r'^[0-9]{9,18}$').hasMatch(v ?? '')
                ? null
                : 'Must be 9–18 digits',
          ),
          _field(
            controller: _ifsc,
            label: 'IFSC',
            hint: 'HDFC0001234',
            formatters: [...upper, LengthLimitingTextInputFormatter(11)],
            validator: (v) => RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(v?.toUpperCase() ?? '')
                ? null
                : 'Must look like HDFC0001234',
          ),
          _field(
            controller: _bankName,
            label: 'Bank name',
            hint: 'HDFC Bank',
          ),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('SAVE DETAILS',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _documentsCard(VendorKyc kyc) {
    return _card(
      title: 'Documents',
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('PDF, JPG or PNG · up to 10 MB each',
              style: TextStyle(color: _slateLight, fontSize: 11)),
        ),
        for (final type in VendorDocType.values) _documentRow(kyc, type),
      ],
    );
  }

  Widget _documentRow(VendorKyc kyc, VendorDocType type) {
    final doc = kyc.documentFor(type);
    final busy = _uploading == type;
    final has = doc != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: has ? _teal.withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: has ? _teal.withValues(alpha: 0.3) : _cardBorder),
        ),
        child: Row(
          children: [
            Icon(has ? Icons.check_circle_rounded : Icons.upload_file_rounded,
                color: has ? _teal : _slateLight, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(type.label,
                      style: const TextStyle(
                          color: _slateDark, fontSize: 12.5, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 1),
                  Text(
                    has ? doc.fileName : type.hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _slateLight, fontSize: 10.5),
                  ),
                ],
              ),
            ),
            if (busy)
              const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _teal))
            else ...[
              if (has)
                GestureDetector(
                  onTap: () => _view(type),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.visibility_outlined, size: 18, color: _slateLight),
                  ),
                ),
              TextButton(
                onPressed: () => _pickAndUpload(type),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                ),
                child: Text(has ? 'Replace' : 'Upload',
                    style: const TextStyle(
                        color: _teal, fontSize: 11.5, fontWeight: FontWeight.w800)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// PAN, GSTIN and IFSC are uppercase everywhere they're printed.
class _UpperCase extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue _, TextEditingValue next) {
    return next.copyWith(text: next.text.toUpperCase());
  }
}
