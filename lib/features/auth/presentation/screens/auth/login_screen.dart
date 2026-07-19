import '../../../../../core/http/api_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String role;
  const LoginScreen({super.key, this.role = 'user'});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  bool get _isVendor => widget.role == 'vendor';

  // Brand teal colour matching the photo
  static const _teal = Color(0xFF2A8C6E);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await ref.read(authControllerProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );
    } catch (e) {
      if (mounted) {
        _showError(friendlyMessage(e, context: 'login'));
      }
      return;
    }
    // Navigation is handled centrally by the router's redirect (which reacts to
    // the auth state change). Navigating manually here as well caused a
    // double-navigation that rebuilt the whole app on login.
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              // ── Top bar ────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Enercore logo
                    Image.asset(
                      'assets/images/logo.png',
                      height: 28,
                    ),
                  ],
                ),
              ),

              // ── Scrollable body ────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      children: [
                        // Enercore logo
                        Image.asset(
                          'assets/images/logo.png',
                          height: 56,
                        ),
                        const SizedBox(height: 18),

                        // Welcome back
                        Text(
                          'Welcome back',
                          style: TextStyle(
                            color: Colors.grey.shade900,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isVendor
                              ? 'Sign in to your vendor dashboard'
                              : 'Sign in to your operational dashboard',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ── Form ─────────────────────────────────────
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Email label
                              _label('Email Address'),
                              const SizedBox(height: 8),
                              AutofillGroup(
                                child: Column(
                                  children: [
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                textInputAction: TextInputAction.next,
                                style: TextStyle(
                                    color: Colors.grey.shade800,
                                    fontSize: 14),
                                decoration: _inputDecoration(
                                  hint: 'operator@enercore.com',
                                  icon: Icons.email_outlined,
                                ),
                                validator: (v) =>
                                    v == null || v.isEmpty
                                        ? 'Required'
                                        : null,
                              ),
                              const SizedBox(height: 20),

                              // Password label + Forgot
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _label('Password'),
                                  GestureDetector(
                                    onTap: () =>
                                        context.push('/forgot-password'),
                                    child: const Text(
                                      'Forgot password?',
                                      style: TextStyle(
                                        color: _teal,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                autofillHints: const [AutofillHints.password],
                                textInputAction: TextInputAction.done,
                                style: TextStyle(
                                    color: Colors.grey.shade800,
                                    fontSize: 14),
                                decoration: _inputDecoration(
                                  hint: '••••••••',
                                  icon: Icons.lock_outline,
                                  suffix: GestureDetector(
                                    onTap: () => setState(() =>
                                        _obscurePassword =
                                            !_obscurePassword),
                                    child: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons
                                              .visibility_off_outlined,
                                      color: Colors.grey.shade400,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                validator: (v) =>
                                    v == null || v.isEmpty
                                        ? 'Required'
                                        : null,
                              ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 26),

                        // ── Secure Sign In button ─────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _teal,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  _teal.withValues(alpha: 0.5),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2),
                                  )
                                : Text(
                                    _isVendor
                                        ? 'Vendor Sign In'
                                        : 'Secure Sign In',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Sign up button ────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () => context.push('/register'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _teal,
                              side: BorderSide(
                                  color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Sign up',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Footer ─────────────────────────────────────────────
              Divider(color: Colors.grey.shade200, height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 14),
                child: Column(
                  children: [
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 6,
                      children: [
                        _footerLink('Privacy Policy', () => context.push('/privacy')),
                        Text('·',
                            style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 13)),
                        _footerLink('Terms of Service', () => context.push('/terms')),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '© 2025 Enercore Operations. All rights reserved. Secure Environment.',
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────

  Widget _label(String text) => Text(
        text,
        style: TextStyle(
          color: Colors.grey.shade700,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      );

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            const BorderSide(color: Color(0xFF2A8C6E), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide:
            const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      errorStyle:
          const TextStyle(color: Colors.redAccent, fontSize: 12),
    );
  }

  Widget _footerLink(String label, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
}
