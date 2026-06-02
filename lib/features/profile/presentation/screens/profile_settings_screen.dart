import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  int _selectedNav = 5; // Profile tab active
  int _selectedTab = 0; // Profile tab selected
  bool _twoFactorEnabled = true;
  int _selectedTheme = 0; // Light selected

  // Premium Design System
  static const _bg = Color(0xFFF4F6F8);
  static const _card = Colors.white;
  static const _cardBorder = Color(0xFFE5E7EB);
  static const _teal = Color(0xFF2A8C6E); // primary brand green-teal
  static const _slateDark = Color(0xFF1E293B);
  static const _slateLight = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _userInfoHeader(),
                      const SizedBox(height: 18),
                      _tabSelector(),
                      const SizedBox(height: 18),
                      _personalInfoCard(),
                      const SizedBox(height: 16),
                      _securityCard(),
                      const SizedBox(height: 16),
                      _appearanceCard(),
                      const SizedBox(height: 20),
                      _logoutButton(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            _bottomNav(),
          ],
        ),
      ),
    );
  }

  // ── Top Bar ────────────────────────────────────────────────────────────────
  Widget _topBar() {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: _cardBorder, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.menu_rounded, color: _slateDark, size: 22),
          const SizedBox(width: 12),
          const Text(
            'Verdant Precision',
            style: TextStyle(
              color: _teal,
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=80&fit=crop&q=80'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── User Info Header Block ─────────────────────────────────────────────────
  Widget _userInfoHeader() {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _teal, width: 2),
            image: const DecorationImage(
              image: NetworkImage('https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&fit=crop&q=80'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Solar Admin',
          style: TextStyle(color: _slateDark, fontSize: 16.5, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFD1FAE5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'Verdant Energy Corp',
            style: TextStyle(color: _teal, fontSize: 9.5, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  // ── Tab Selector ───────────────────────────────────────────────────────────
  Widget _tabSelector() {
    final tabs = ['Profile', 'Security', 'Billing'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: tabs.asMap().entries.map((e) {
        final active = _selectedTab == e.key;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedTab = e.key),
            child: Container(
              margin: EdgeInsets.only(
                left: e.key > 0 ? 8 : 0,
              ),
              height: 36,
              decoration: BoxDecoration(
                color: active ? const Color(0xFF86EFAC) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  e.value,
                  style: TextStyle(
                    color: active ? const Color(0xFF065F46) : _slateLight,
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Personal Info Card ─────────────────────────────────────────────────────
  Widget _personalInfoCard() {
    return _card_(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal Information',
            style: TextStyle(color: _teal, fontSize: 14.5, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          _fieldLabel('Full Name'),
          const SizedBox(height: 5),
          _textField('Solar Admin'),
          const SizedBox(height: 12),

          _fieldLabel('Email Address'),
          const SizedBox(height: 5),
          _textField('admin@verdantenergy.corp'),
          const SizedBox(height: 12),

          _fieldLabel('Phone Number'),
          const SizedBox(height: 5),
          _textField('+1(555) 234-5678'),
          const SizedBox(height: 12),

          _fieldLabel('Company'),
          const SizedBox(height: 5),
          _textField('Verdant Energy Corp'),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('GST Number'),
                    const SizedBox(height: 5),
                    _textField('GST22446681'),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Postal Code'),
                    const SizedBox(height: 5),
                    _textField('94103'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _fieldLabel('Address'),
          const SizedBox(height: 5),
          _textField('455 Renewable Way, Silicon Valley, CA', isMultiline: true),
          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {},
              child: const Text('Save Changes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(color: _slateDark, fontSize: 10, fontWeight: FontWeight.w700),
    );
  }

  Widget _textField(String initialValue, {bool isMultiline = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _cardBorder, width: 1),
      ),
      child: TextField(
        maxLines: isMultiline ? 3 : 1,
        controller: TextEditingController(text: initialValue),
        style: const TextStyle(color: _slateDark, fontSize: 12, fontWeight: FontWeight.w600),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  // ── Security Card ──────────────────────────────────────────────────────────
  Widget _securityCard() {
    return _card_(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Security',
            style: TextStyle(color: _teal, fontSize: 14.5, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Two-Factor Authentication',
                        style: TextStyle(color: _slateDark, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Secure your account with 2FA.',
                        style: TextStyle(color: _slateLight, fontSize: 10, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _twoFactorEnabled,
                  activeColor: _teal,
                  onChanged: (val) => setState(() => _twoFactorEnabled = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'ACTIVE SESSIONS',
            style: TextStyle(color: _slateLight, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.5),
          ),
          const SizedBox(height: 10),
          _sessionItem(Icons.phone_iphone_rounded, 'iPhone 15 Pro', 'San Francisco, CA • Now'),
          const Divider(color: Color(0xFFF1F5F9), height: 16),
          _sessionItem(Icons.laptop_chromebook_rounded, 'MacBook Pro 16"', 'San Francisco, CA • 2h ago'),
        ],
      ),
    );
  }

  Widget _sessionItem(IconData icon, String device, String loc) {
    return Row(
      children: [
        Icon(icon, color: _slateLight, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                device,
                style: const TextStyle(color: _slateDark, fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                loc,
                style: const TextStyle(color: _slateLight, fontSize: 10, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        const Text(
          'Revoke',
          style: TextStyle(color: Color(0xFFEF4444), fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  // ── Appearance Card ────────────────────────────────────────────────────────
  Widget _appearanceCard() {
    return _card_(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Appearance',
            style: TextStyle(color: _teal, fontSize: 14.5, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _themeOption(0, 'Light', true),
              const SizedBox(width: 10),
              _themeOption(1, 'Dark', false),
              const SizedBox(width: 10),
              _themeOption(2, 'System', false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _themeOption(int idx, String title, bool isSelected) {
    final active = _selectedTheme == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTheme = idx),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? _teal : _cardBorder, width: active ? 1.5 : 1),
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _cardBorder, width: 0.8),
                  gradient: LinearGradient(
                    colors: idx == 0
                        ? [Colors.white, const Color(0xFFF1F5F9)]
                        : (idx == 1 ? [const Color(0xFF1E293B), const Color(0xFF0F172A)] : [Colors.white, const Color(0xFF0F172A)]),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: active ? _teal : _slateDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Logout Button ──────────────────────────────────────────────────────────
  Widget _logoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFEE2E2),
          foregroundColor: const Color(0xFFEF4444),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () {},
        icon: const Icon(Icons.logout_rounded, size: 16),
        label: const Text(
          'Logout',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // ── Bottom Nav ─────────────────────────────────────────────────────────────
  Widget _bottomNav() {
    final items = [
      (Icons.home_rounded, 'Home'),
      (Icons.solar_power_rounded, 'Plants'),
      (Icons.sensors_rounded, 'Telemetry'),
      (Icons.receipt_long_rounded, 'Billing'),
      (Icons.confirmation_number_outlined, 'Tickets'),
      (Icons.person_outline_rounded, 'Profile'),
    ];
    final routes = ['/client-dashboard', '/solar-grid', '/telemetry', '/billing', '/tickets', null];
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: _cardBorder, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final active = _selectedNav == i;
          return GestureDetector(
            onTap: () {
              if (routes[i] != null) {
                context.push(routes[i]!);
              } else {
                setState(() => _selectedNav = i);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: active 
                  ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
                  : const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: active 
                  ? BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(16),
                    )
                  : null,
              child: active 
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          items[i].$1,
                          color: _teal,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          items[i].$2,
                          style: const TextStyle(
                            color: _teal,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          items[i].$1,
                          color: _slateLight.withValues(alpha: 0.6),
                          size: 18,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          items[i].$2,
                          style: TextStyle(
                            color: _slateLight.withValues(alpha: 0.7),
                            fontSize: 8.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
            ),
          );
        }),
      ),
    );
  }

  // ── Card Helper ────────────────────────────────────────────────────────────
  Widget _card_({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
