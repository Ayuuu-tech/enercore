import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../branding/branding.dart';

/// The app logo, shown everywhere the brand mark appears. Prefers the
/// admin-configured logo (served from storage) and falls back to the bundled
/// asset while loading, offline, or when none is set.
class AppLogo extends ConsumerWidget {
  final double height;
  final BoxFit fit;

  const AppLogo({super.key, this.height = 46, this.fit = BoxFit.contain});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logo = ref.watch(brandingLogoProvider).asData?.value;
    if (logo != null) {
      return Image.network(
        logo,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => _asset(),
      );
    }
    return _asset();
  }

  Widget _asset() =>
      Image.asset('assets/images/logo.png', height: height, fit: fit);
}
