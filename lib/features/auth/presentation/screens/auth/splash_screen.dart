import 'dart:math' as math;
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
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _spinController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    // Slow, continuous turbine rotation for the background scene.
    _spinController = AnimationController(
        vsync: this, duration: const Duration(seconds: 9))
      ..repeat();
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
  // else straight to login.
  Future<void> _decideNextRoute() async {
    await Future.delayed(const Duration(seconds: 2));
    while (mounted && ref.read(authControllerProvider).isLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if (!mounted) return;

    final user = ref.read(authControllerProvider).asData?.value;
    if (user == null) {
      context.go('/login');
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
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Matches the native launch screen so the OS→Flutter hand-off has no flash.
      backgroundColor: const Color(0xFFEAF6F1),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Soft sky wash behind the renewable-energy scene.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFFFFF), Color(0xFFEAF6F1), Color(0xFFD8EEE4)],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),
          // Sun, wind turbines, hills and solar arrays — animated in with the logo.
          FadeTransition(
            opacity: _fadeAnim,
            child: AnimatedBuilder(
              animation: _spinController,
              builder: (context, _) => CustomPaint(
                painter: _RenewableScenePainter(spin: _spinController.value),
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/logo.png', width: 240),
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
        ],
      ),
    );
  }
}

const _teal = Color(0xFF2A8C6E);
const _sun = Color(0xFFF5A623);

/// Decorative renewable-energy scene: a sun, rolling hills, wind turbines and
/// rows of solar panels. Kept low-contrast so the logo stays the focal point.
class _RenewableScenePainter extends CustomPainter {
  /// Turbine blade rotation, in turns.
  final double spin;
  const _RenewableScenePainter({required this.spin});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Sun with a soft halo, top-right
    final sunC = Offset(w * 0.80, h * 0.16);
    for (final r in [78.0, 56.0, 36.0]) {
      canvas.drawCircle(
        sunC, r,
        Paint()..color = _sun.withValues(alpha: r > 70 ? 0.06 : (r > 50 ? 0.10 : 0.16)),
      );
    }
    // Sun rays
    final ray = Paint()
      ..color = _sun.withValues(alpha: 0.20)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      canvas.drawLine(
        sunC + Offset(math.cos(a) * 46, math.sin(a) * 46),
        sunC + Offset(math.cos(a) * 60, math.sin(a) * 60),
        ray,
      );
    }

    // ── Rolling hills
    final hillFar = Path()
      ..moveTo(0, h * 0.74)
      ..quadraticBezierTo(w * 0.25, h * 0.66, w * 0.52, h * 0.73)
      ..quadraticBezierTo(w * 0.78, h * 0.80, w, h * 0.70)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(hillFar, Paint()..color = _teal.withValues(alpha: 0.07));

    final hillNear = Path()
      ..moveTo(0, h * 0.84)
      ..quadraticBezierTo(w * 0.30, h * 0.76, w * 0.62, h * 0.84)
      ..quadraticBezierTo(w * 0.84, h * 0.89, w, h * 0.82)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(hillNear, Paint()..color = _teal.withValues(alpha: 0.11));

    // ── Wind turbines on the far hill
    _turbine(canvas, Offset(w * 0.16, h * 0.71), 78, spin);
    _turbine(canvas, Offset(w * 0.33, h * 0.735), 56, spin + 0.35);
    _turbine(canvas, Offset(w * 0.88, h * 0.715), 46, spin + 0.7);

    // ── Solar panel rows along the bottom
    _panelRow(canvas, Offset(w * 0.10, h * 0.935), 78, 34, 0.16);
    _panelRow(canvas, Offset(w * 0.52, h * 0.905), 62, 27, 0.13);
    _panelRow(canvas, Offset(w * 0.80, h * 0.955), 86, 37, 0.17);
  }

  void _turbine(Canvas canvas, Offset base, double height, double spin) {
    final hubR = height * 0.055;
    final hub = Offset(base.dx, base.dy - height);
    final mast = Paint()
      ..color = _teal.withValues(alpha: 0.22)
      ..strokeWidth = height * 0.035
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(base, hub, mast);

    final blade = Paint()
      ..color = _teal.withValues(alpha: 0.28)
      ..strokeWidth = height * 0.045
      ..strokeCap = StrokeCap.round;
    final bladeLen = height * 0.42;
    for (int i = 0; i < 3; i++) {
      final a = spin * 2 * math.pi + i * 2 * math.pi / 3;
      canvas.drawLine(hub, hub + Offset(math.cos(a) * bladeLen, math.sin(a) * bladeLen), blade);
    }
    canvas.drawCircle(hub, hubR, Paint()..color = _teal.withValues(alpha: 0.35));
  }

  /// A tilted solar array: a panel face split into cells, on short legs.
  void _panelRow(Canvas canvas, Offset center, double width, double height, double alpha) {
    final face = Path()
      ..moveTo(center.dx - width / 2, center.dy)
      ..lineTo(center.dx - width / 2 + width * 0.18, center.dy - height)
      ..lineTo(center.dx + width / 2, center.dy - height)
      ..lineTo(center.dx + width / 2 - width * 0.18, center.dy)
      ..close();
    canvas.drawPath(face, Paint()..color = _teal.withValues(alpha: alpha));
    canvas.drawPath(
      face,
      Paint()
        ..color = _teal.withValues(alpha: alpha + 0.14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Cell dividers
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    for (int i = 1; i < 3; i++) {
      final t = i / 3;
      canvas.drawLine(
        Offset(center.dx - width / 2 + width * 0.18 * t + (width * t) * 0.82, center.dy - height),
        Offset(center.dx - width / 2 + (width * t) * 0.82, center.dy),
        grid,
      );
    }
    canvas.drawLine(
      Offset(center.dx - width / 2 + width * 0.09, center.dy - height / 2),
      Offset(center.dx + width / 2 - width * 0.09, center.dy - height / 2),
      grid,
    );

    // Legs
    final leg = Paint()
      ..color = _teal.withValues(alpha: alpha + 0.10)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx - width * 0.22, center.dy),
      Offset(center.dx - width * 0.22, center.dy + height * 0.28),
      leg,
    );
    canvas.drawLine(
      Offset(center.dx + width * 0.22, center.dy),
      Offset(center.dx + width * 0.22, center.dy + height * 0.28),
      leg,
    );
  }

  @override
  bool shouldRepaint(_RenewableScenePainter old) => old.spin != spin;
}
