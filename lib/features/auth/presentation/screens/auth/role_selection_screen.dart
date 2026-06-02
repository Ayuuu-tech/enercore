import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedRole;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

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
    _animController.dispose();
    super.dispose();
  }

  void _proceed() {
    if (_selectedRole == null) return;
    context.push('/login?role=$_selectedRole');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            children: [
              // ── Top bar (same as login) ─────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset('assets/images/logo.png', height: 28),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Icon(Icons.help_outline,
                          color: Colors.grey, size: 17),
                    ),
                  ],
                ),
              ),

              // ── Scrollable body ─────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo
                        Center(
                          child: Image.asset(
                            'assets/images/logo.png',
                            height: 54,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Heading
                        Text(
                          'Who are you?',
                          style: TextStyle(
                            color: Colors.grey.shade900,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Select your role to continue',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ── User card ─────────────────────────────────
                        _RoleCard(
                          role: 'user',
                          selectedRole: _selectedRole,
                          icon: Icons.person_outline_rounded,
                          title: 'User / Client',
                          subtitle:
                              'Monitor solar plants, analytics & billing',
                          teal: _teal,
                          onTap: () =>
                              setState(() => _selectedRole = 'user'),
                        ),
                        const SizedBox(height: 14),

                        // ── Vendor card ───────────────────────────────
                        _RoleCard(
                          role: 'vendor',
                          selectedRole: _selectedRole,
                          icon: Icons.storefront_outlined,
                          title: 'Vendor / Supplier',
                          subtitle:
                              'Manage orders, inventory & fulfilment',
                          teal: _teal,
                          onTap: () =>
                              setState(() => _selectedRole = 'vendor'),
                        ),
                        const SizedBox(height: 28),

                        // ── Continue button ───────────────────────────
                        AnimatedOpacity(
                          opacity: _selectedRole != null ? 1.0 : 0.4,
                          duration: const Duration(milliseconds: 200),
                          child: SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed:
                                  _selectedRole != null ? _proceed : null,
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
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Continue',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Footer (same as login) ──────────────────────────────
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
                        _footerLink('Privacy Policy'),
                        Text('·',
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 13)),
                        _footerLink('Terms of Service'),
                        Text('·',
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 13)),
                        _footerLink('System Status'),
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

  Widget _footerLink(String label) => GestureDetector(
        onTap: () {},
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

// ── Role Card Widget ──────────────────────────────────────────────────────────
class _RoleCard extends StatelessWidget {
  final String role;
  final String? selectedRole;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color teal;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.selectedRole,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.teal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedRole == role;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? teal.withValues(alpha: 0.06)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? teal : Colors.grey.shade300,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon box
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? teal.withValues(alpha: 0.12)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? teal : Colors.grey.shade400,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.grey.shade900
                          : Colors.grey.shade800,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Radio circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSelected ? teal : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? teal : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
