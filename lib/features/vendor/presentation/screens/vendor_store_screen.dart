import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/application/auth_controller.dart';
import '../../data/vendor_repository.dart';
import '../widgets/vendor_chrome.dart';

class VendorStoreScreen extends ConsumerWidget {
  const VendorStoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;

    return Scaffold(
      backgroundColor: VendorTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            const VendorTopBar(showBack: false),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Store Settings',
                      style: TextStyle(
                        color: VendorTheme.slateDark,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _storeHeader(context, ref, user?.company, user?.name, user?.email),
                    const SizedBox(height: 20),
                    _sectionTitle('Account'),
                    const SizedBox(height: 10),
                    _infoRow(Icons.person_outline_rounded, 'Name', user?.name ?? '—'),
                    _infoRow(Icons.email_outlined, 'Email', user?.email ?? '—'),
                    _infoRow(Icons.phone_outlined, 'Phone', user?.phone ?? '—'),
                    if (user?.gstNumber?.isNotEmpty == true)
                      _infoRow(Icons.receipt_long_outlined, 'GST', user!.gstNumber!),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.2),
                          foregroundColor: VendorTheme.red,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => ref.read(authControllerProvider.notifier).logout(),
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: const Text('Sign Out', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            const VendorBottomNav(activeIndex: 3),
          ],
        ),
      ),
    );
  }

  Widget _storeHeader(BuildContext context, WidgetRef ref, String? company, String? name, String? email) {
    final displayName = (company?.isNotEmpty == true) ? company! : (name ?? 'Your Store');
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
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email ?? '',
                      style: const TextStyle(color: Color(0xFFA7F3D0), fontSize: 12, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 38,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF065F46),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _editCompany(context, ref, company ?? ''),
              icon: const Icon(Icons.edit_rounded, size: 14),
              label: const Text('Edit Company Name', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editCompany(BuildContext context, WidgetRef ref, String current) async {
    final controller = TextEditingController(text: current);
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Company Name', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter company name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: VendorTheme.teal, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved == true && controller.text.trim().isNotEmpty) {
      try {
        await ref.read(vendorRepositoryProvider).updateStore(companyName: controller.text.trim());
        await ref.read(authControllerProvider.notifier).refreshProfile();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Store updated')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
        }
      }
    }
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(color: VendorTheme.slateDark, fontSize: 15, fontWeight: FontWeight.w900),
      );

  Widget _infoRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VendorTheme.cardBorder, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: VendorTheme.slateLight, size: 18),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: VendorTheme.slateLight, fontSize: 12.5, fontWeight: FontWeight.w600)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: VendorTheme.slateDark, fontSize: 12.5, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
