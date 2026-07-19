import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/branding/branding.dart';
import '../../../../core/http/api_error.dart';
import '../../../../core/widgets/app_logo.dart';

/// Lets an admin set the app-wide logo shown in every header, or reset to the
/// bundled default. Replaces what used to be a hardcoded asset.
class AdminBrandingScreen extends ConsumerStatefulWidget {
  const AdminBrandingScreen({super.key});

  @override
  ConsumerState<AdminBrandingScreen> createState() => _AdminBrandingScreenState();
}

class _AdminBrandingScreenState extends ConsumerState<AdminBrandingScreen> {
  static const _bg = Color(0xFFF4F6F8);
  static const _cardBorder = Color(0xFFE5E7EB);
  static const _teal = Color(0xFF2A8C6E);
  static const _slateDark = Color(0xFF1E293B);
  static const _slateLight = Color(0xFF64748B);

  bool _busy = false;

  void _toast(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: error ? const Color(0xFFEF4444) : _teal,
      content: Text(message),
    ));
  }

  Future<void> _uploadLogo() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
    );
    final file = picked?.files.singleOrNull;
    if (file == null) return;

    setState(() => _busy = true);
    try {
      final bytes = await file.readAsBytes();
      await ref.read(brandingRepositoryProvider).uploadLogo(bytes, file.name);
      ref.invalidate(brandingLogoProvider);
      _toast('Logo updated');
    } catch (e) {
      _toast(friendlyMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetLogo() async {
    setState(() => _busy = true);
    try {
      await ref.read(brandingRepositoryProvider).clearLogo();
      ref.invalidate(brandingLogoProvider);
      _toast('Reset to the default logo');
    } catch (e) {
      _toast(friendlyMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  const Text('Branding',
                      style: TextStyle(
                          color: _teal, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _cardBorder),
                    ),
                    child: Column(
                      children: [
                        const Text('Current logo',
                            style: TextStyle(color: _slateLight, fontSize: 12, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _bg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const AppLogo(height: 56),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'This logo appears in the header of every dashboard. PNG with a '
                    'transparent background works best. Max 5 MB.',
                    style: TextStyle(color: _slateLight, fontSize: 11.5, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 46,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _teal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _busy ? null : _uploadLogo,
                      icon: _busy
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.upload_rounded, size: 18),
                      label: const Text('Upload new logo',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _busy ? null : _resetLogo,
                    child: const Text('Reset to default',
                        style: TextStyle(color: _slateLight, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
