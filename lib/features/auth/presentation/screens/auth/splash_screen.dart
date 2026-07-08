import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/auth_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim =
        CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();

    _decideNextRoute();
  }

  // Wait for the branding animation and the startup session-restore to finish,
  // then route: a restored user goes straight to their dashboard, everyone
  // else to role selection.
  Future<void> _decideNextRoute() async {
    await Future.delayed(const Duration(seconds: 2));
    while (mounted && ref.read(authControllerProvider).isLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (!mounted) return;

    final user = ref.read(authControllerProvider).asData?.value;
    if (user == null) {
      context.go('/role-selection');
    } else {
      final role = user.role.toUpperCase();
      if (role == 'ADMIN') {
        context.go('/admin-dashboard');
      } else if (role == 'VENDOR') {
        context.go('/vendor-dashboard');
      } else {
        context.go('/client-dashboard');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Real Enercore logo
                Image.asset(
                  'assets/images/logo.png',
                  width: 240,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: const Color(0xFF2A8C6E).withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
