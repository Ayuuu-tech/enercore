import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../vendor/data/kyc_repository.dart';
import '../../../vendor/domain/kyc_models.dart';
import '../../../../core/http/api_error.dart';

/// Enercore reviews a vendor's PAN, GST, bank details and statutory documents
/// here, and approves or rejects them. A vendor cannot be paid until approved.
class AdminKycScreen extends ConsumerWidget {
  const AdminKycScreen({super.key});

  static const _bg = Color(0xFFF4F6F8);
  static const _cardBorder = Color(0xFFE5E7EB);
  static const _teal = Color(0xFF2A8C6E);
  static const _slateDark = Color(0xFF1E293B);
  static const _slateLight = Color(0xFF64748B);

  static Color statusColor(String s) => switch (s) {
        'APPROVED' => _teal,
        'PENDING' => const Color(0xFFD97706),
        'REJECTED' => const Color(0xFFEF4444),
        _ => _slateLight,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminKycQueueProvider);

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
                  const Text('Vendor KYC',
                      style: TextStyle(
                          color: _teal, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
                ],
              ),
            ),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator(color: _teal)),
                error: (e, _) => Center(
                  child: Text('$e',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: _slateLight, fontSize: 12)),
                ),
                data: (vendors) {
                  if (vendors.isEmpty) {
                    return const Center(
                      child: Text('No vendors yet',
                          style: TextStyle(color: _slateLight, fontSize: 12)),
                    );
                  }
                  return RefreshIndicator(
                    color: _teal,
                    onRefresh: () async => ref.invalidate(adminKycQueueProvider),
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: vendors.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => _row(context, vendors[i]),
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

  Widget _row(BuildContext context, VendorKycSummary v) {
    final color = statusColor(v.status);
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _KycReviewSheet(vendorId: v.vendorId),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _cardBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v.companyName,
                      style: const TextStyle(
                          color: _slateDark, fontSize: 13, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text('${v.contactName} · ${v.email}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _slateLight, fontSize: 11)),
                  const SizedBox(height: 6),
                  Text('${v.documentCount}/${v.requiredCount} documents',
                      style: TextStyle(
                          color: v.documentCount == v.requiredCount ? _teal : _slateLight,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(v.status.replaceAll('_', ' '),
                  style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: _slateLight, size: 20),
          ],
        ),
      ),
    );
  }
}

class _KycReviewSheet extends ConsumerStatefulWidget {
  final String vendorId;
  const _KycReviewSheet({required this.vendorId});

  @override
  ConsumerState<_KycReviewSheet> createState() => _KycReviewSheetState();
}

class _KycReviewSheetState extends ConsumerState<_KycReviewSheet> {
  static const _cardBorder = Color(0xFFE5E7EB);
  static const _teal = Color(0xFF2A8C6E);
  static const _slateDark = Color(0xFF1E293B);
  static const _slateLight = Color(0xFF64748B);
  static const _red = Color(0xFFEF4444);

  bool _busy = false;

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: error ? _red : _teal,
      content: Text(msg),
    ));
  }

  Future<void> _act(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(adminKycQueueProvider);
      if (mounted) Navigator.of(context).pop();
      _toast(done);
    } catch (e) {
      _toast(friendlyMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject KYC', style: TextStyle(fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'What does the vendor need to fix?',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Reject', style: TextStyle(color: _red)),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;
    await _act(
      () => ref.read(kycRepositoryProvider).reject(widget.vendorId, reason),
      'Vendor notified',
    );
  }

  Future<void> _openDoc(VendorDocType type) async {
    try {
      final url =
          await ref.read(kycRepositoryProvider).vendorDocumentUrl(widget.vendorId, type);
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      _toast(friendlyMessage(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(FutureProvider((ref) =>
        ref.read(kycRepositoryProvider).getVendorKyc(widget.vendorId)));

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: async.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator(color: _teal)),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(30),
          child: Text('$e', style: const TextStyle(color: _slateLight, fontSize: 12)),
        ),
        data: (kyc) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                      color: _cardBorder, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(kyc.companyName,
                  style: const TextStyle(
                      color: _slateDark, fontSize: 17, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),

              _kv('PAN', kyc.pan),
              _kv('GSTIN', kyc.gstin),
              const Divider(height: 20, color: _cardBorder),
              _kv('Account holder', kyc.bankAccountName),
              // The admin needs the real number — this is who gets paid.
              _kv('Account number', kyc.bankAccountNumber ?? kyc.bankAccountNumberMasked),
              _kv('IFSC', kyc.bankIfsc),
              _kv('Bank', kyc.bankName),

              const SizedBox(height: 16),
              const Text('Documents',
                  style: TextStyle(color: _slateDark, fontSize: 13, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              for (final t in VendorDocType.values) _docRow(kyc, t),

              const SizedBox(height: 20),
              if (!kyc.readyForReview)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Submission is incomplete — cannot approve yet.',
                    style: TextStyle(color: Color(0xFFD97706), fontSize: 11.5, fontWeight: FontWeight.w700),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _red, width: 1.2),
                        foregroundColor: _red,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      onPressed: _busy ? null : _reject,
                      child: const Text('REJECT',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _teal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      onPressed: _busy || !kyc.readyForReview
                          ? null
                          : () => _act(
                                () => ref.read(kycRepositoryProvider).approve(widget.vendorId),
                                'Vendor approved',
                              ),
                      child: const Text('APPROVE',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _kv(String k, String? v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(k, style: const TextStyle(color: _slateLight, fontSize: 11.5)),
          ),
          Expanded(
            child: Text(v?.isNotEmpty == true ? v! : '—',
                style: const TextStyle(
                    color: _slateDark, fontSize: 12.5, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _docRow(VendorKyc kyc, VendorDocType type) {
    final doc = kyc.documentFor(type);
    final has = doc != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(has ? Icons.check_circle_rounded : Icons.remove_circle_outline_rounded,
              size: 16, color: has ? _teal : _slateLight),
          const SizedBox(width: 8),
          Expanded(
            child: Text(type.label,
                style: const TextStyle(
                    color: _slateDark, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          if (has)
            TextButton(
              onPressed: () => _openDoc(type),
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6), minimumSize: Size.zero),
              child: const Text('View',
                  style: TextStyle(color: _teal, fontSize: 11.5, fontWeight: FontWeight.w800)),
            )
          else
            const Text('Missing',
                style: TextStyle(color: _slateLight, fontSize: 11)),
        ],
      ),
    );
  }
}
