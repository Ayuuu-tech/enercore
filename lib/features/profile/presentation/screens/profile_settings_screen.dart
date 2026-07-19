import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../auth/domain/user_model.dart';
import '../../application/profile_controller.dart';
import '../../data/profile_repository.dart';
import '../../../../core/http/api_error.dart';

/// [ProfileSettingsScreen] displays the user's profile, security, and
/// appearance settings with real data fetched from the backend.
class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  int _selectedNav = 5;
  int _selectedTab = 0;
  bool _twoFactorEnabled = false;


  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();
  final _postalCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  final _oldPwdCtrl = TextEditingController();
  final _newPwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();

  bool _saving = false;
  bool _changingPwd = false;
  bool _controllersInitialized = false;

  static const _bg = Color(0xFFF4F6F8);
  static const _card = Colors.white;
  static const _cardBorder = Color(0xFFE5E7EB);
  static const _teal = Color(0xFF2A8C6E);
  static const _slateDark = Color(0xFF1E293B);
  static const _slateLight = Color(0xFF64748B);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _companyCtrl.dispose();
    _gstCtrl.dispose();
    _postalCtrl.dispose();
    _addressCtrl.dispose();
    _oldPwdCtrl.dispose();
    _newPwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    super.dispose();
  }

  void _initControllers(UserModel user) {
    if (_controllersInitialized) return;
    _controllersInitialized = true;
    _nameCtrl.text = user.name;
    _emailCtrl.text = user.email;
    _phoneCtrl.text = user.phone ?? '';
    _companyCtrl.text = user.company ?? '';
    _gstCtrl.text = user.gstNumber ?? '';
    _postalCtrl.text = user.postalCode ?? '';
    _addressCtrl.text = user.address ?? '';
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Widget _avatar(double radius, {String? url, String? name}) {
    if (url != null && url.isNotEmpty) {
      final repo = ref.read(profileRepositoryProvider);
      final base = repo.baseUrl.replaceAll('/api', '');
      final fullUrl = url.startsWith('http') ? url : '$base$url';
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(fullUrl),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: _teal,
      child: Text(
        name != null ? _initials(name) : '?',
        style: TextStyle(color: Colors.white, fontSize: radius * 0.6, fontWeight: FontWeight.w700),
      ),
    );
  }

  Future<void> _saveChanges() async {
    setState(() => _saving = true);
    try {
      await ref.read(profileControllerProvider.notifier).updateProfile({
        'name': _nameCtrl.text,
        'email': _emailCtrl.text,
        'phone': _phoneCtrl.text.isEmpty ? null : _phoneCtrl.text,
        'company': _companyCtrl.text.isEmpty ? null : _companyCtrl.text,
        'gstNumber': _gstCtrl.text.isEmpty ? null : _gstCtrl.text,
        'postalCode': _postalCtrl.text.isEmpty ? null : _postalCtrl.text,
        'address': _addressCtrl.text.isEmpty ? null : _addressCtrl.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully'), backgroundColor: _teal),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyMessage(e)), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    final newPwd = _newPwdCtrl.text;
    final confirmPwd = _confirmPwdCtrl.text;
    if (newPwd != confirmPwd) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.red),
      );
      return;
    }
    if (newPwd.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _changingPwd = true);
    try {
      await ref.read(profileControllerProvider.notifier).changePassword(
        _oldPwdCtrl.text,
        newPwd,
      );
      _oldPwdCtrl.clear();
      _newPwdCtrl.clear();
      _confirmPwdCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully'), backgroundColor: _teal),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyMessage(e)), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _changingPwd = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileControllerProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: profileAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: _teal)),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 12),
                      Text('Failed to load profile', style: TextStyle(color: _slateDark)),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => ref.read(profileControllerProvider.notifier).refresh(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (user) {
                  _initControllers(user);
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _userInfoHeader(user),
                          const SizedBox(height: 18),
                          _tabSelector(),
                          const SizedBox(height: 18),
                          if (_selectedTab == 0) _personalInfoCard(),
                          if (_selectedTab == 1) _securityCard(),

                          const SizedBox(height: 20),
                          _logoutButton(),
                          _logoutAllButton(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            _bottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Container(
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
          Image.asset('assets/images/logo.png', height: 46, fit: BoxFit.contain),
          const Spacer(),
          Consumer(builder: (context, ref, _) {
            final user = ref.watch(authControllerProvider).asData?.value;
            return _avatar(16, url: user?.avatarUrl, name: user?.name);
          }),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512);
    if (picked == null) return;
    try {
      await ref.read(profileControllerProvider.notifier).uploadAvatar(picked);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo updated'), backgroundColor: _teal),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _userInfoHeader(UserModel user) {
    return Column(
      children: [
        GestureDetector(onTap: _pickAndUploadAvatar, child: Stack(
          children: [
            _avatar(38, url: user.avatarUrl, name: user.name),
            Positioned(bottom: 0, right: 0,
              child: Container(
                width: 26, height: 26,
                decoration: const BoxDecoration(color: _teal, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
              ),
            ),
          ],
        )),
        const SizedBox(height: 10),
        Text(
          user.name,
          style: const TextStyle(color: _slateDark, fontSize: 16.5, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFD1FAE5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            user.company ?? user.role,
            style: const TextStyle(color: _teal, fontSize: 9.5, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }

  Widget _tabSelector() {
    final tabs = ['Profile', 'Security'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: tabs.asMap().entries.map((e) {
        final active = _selectedTab == e.key;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedTab = e.key),
            child: Container(
              margin: EdgeInsets.only(left: e.key > 0 ? 8 : 0),
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

  Widget _personalInfoCard() {
    return _card_(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Personal Information', style: TextStyle(color: _teal, fontSize: 14.5, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          _fieldLabel('Full Name'),
          const SizedBox(height: 5),
          _textField(_nameCtrl, hint: 'Your full name'),
          const SizedBox(height: 12),
          _fieldLabel('Email Address'),
          const SizedBox(height: 5),
          _textField(_emailCtrl, hint: 'email@example.com'),
          const SizedBox(height: 12),
          _fieldLabel('Phone Number'),
          const SizedBox(height: 5),
          _textField(_phoneCtrl, hint: '+1 (555) 234-5678'),
          const SizedBox(height: 12),
          _fieldLabel('Company'),
          const SizedBox(height: 5),
          _textField(_companyCtrl, hint: 'Your company'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('GST Number'),
                    const SizedBox(height: 5),
                    _textField(_gstCtrl, hint: 'GST22446681'),
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
                    _textField(_postalCtrl, hint: '94103'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _fieldLabel('Address'),
          const SizedBox(height: 5),
          _textField(_addressCtrl, hint: 'Your address', isMultiline: true),
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
              onPressed: _saving ? null : _saveChanges,
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Changes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(label, style: const TextStyle(color: _slateDark, fontSize: 10, fontWeight: FontWeight.w700));
  }

  Widget _textField(TextEditingController ctrl, {bool isMultiline = false, String? hint}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _cardBorder, width: 1),
      ),
      child: TextField(
        controller: ctrl,
        maxLines: isMultiline ? 3 : 1,
        style: const TextStyle(color: _slateDark, fontSize: 12, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: hint,
          hintStyle: const TextStyle(color: _slateLight, fontSize: 12, fontWeight: FontWeight.w400),
        ),
      ),
    );
  }

  Widget _securityCard() {
    return _card_(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Security', style: TextStyle(color: _teal, fontSize: 14.5, fontWeight: FontWeight.w800)),
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
                      Text('Two-Factor Authentication', style: TextStyle(color: _slateDark, fontSize: 12, fontWeight: FontWeight.w700)),
                      SizedBox(height: 2),
                      Text('Secure your account with 2FA.', style: TextStyle(color: _slateLight, fontSize: 10, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _twoFactorEnabled,
                  activeThumbColor: _teal,
                  activeTrackColor: _teal.withValues(alpha: 0.5),
                  onChanged: (val) => setState(() => _twoFactorEnabled = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('CHANGE PASSWORD', style: TextStyle(color: _slateLight, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          const SizedBox(height: 10),
          _fieldLabel('Current Password'),
          const SizedBox(height: 5),
          _pwdField(_oldPwdCtrl, hint: 'Enter current password'),
          const SizedBox(height: 10),
          _fieldLabel('New Password'),
          const SizedBox(height: 5),
          _pwdField(_newPwdCtrl, hint: 'Enter new password'),
          const SizedBox(height: 10),
          _fieldLabel('Confirm New Password'),
          const SizedBox(height: 5),
          _pwdField(_confirmPwdCtrl, hint: 'Confirm new password'),
          const SizedBox(height: 14),
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
              onPressed: _changingPwd ? null : _changePassword,
              child: _changingPwd
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Update Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pwdField(TextEditingController ctrl, {String? hint}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _cardBorder, width: 1),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: true,
        style: const TextStyle(color: _slateDark, fontSize: 12, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          hintText: hint,
          hintStyle: const TextStyle(color: _slateLight, fontSize: 12, fontWeight: FontWeight.w400),
        ),
      ),
    );
  }



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
        onPressed: () async {
          await ref.read(authControllerProvider.notifier).logout();
          if (mounted) context.go('/login');
        },
        icon: const Icon(Icons.logout_rounded, size: 16),
        label: const Text('Logout', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _logoutAllButton() {
    return TextButton.icon(
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        try {
          await ref.read(profileRepositoryProvider).logoutAllDevices();
          await ref.read(authControllerProvider.notifier).logout();
          if (mounted) context.go('/login');
        } catch (e) {
          messenger.showSnackBar(SnackBar(
            content: Text(friendlyMessage(e)),
          ));
        }
      },
      icon: const Icon(Icons.devices_rounded, size: 15, color: Color(0xFF64748B)),
      label: const Text('Sign out of all devices',
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
    );
  }

  Widget _bottomNav() {
    final items = [
      (Icons.home_rounded, 'Home'),
      (Icons.solar_power_rounded, 'Plants'),
      (Icons.sensors_rounded, 'Telemetry'),
      (Icons.receipt_long_rounded, 'Billing'),
      (Icons.confirmation_number_outlined, 'Tickets'),
    ];
    final List<String?> routes = ['/client-dashboard', '/solar-grid', '/telemetry', '/billing', '/tickets'];
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _cardBorder, width: 1)),
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
              padding: active ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6) : const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: active
                  ? BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(16))
                  : null,
              child: active
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(items[i].$1, color: _teal, size: 18),
                        const SizedBox(width: 6),
                        Text(items[i].$2, style: const TextStyle(color: _teal, fontSize: 10, fontWeight: FontWeight.w800)),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(items[i].$1, color: _slateLight.withValues(alpha: 0.6), size: 18),
                        const SizedBox(height: 2),
                        Text(items[i].$2, style: TextStyle(color: _slateLight.withValues(alpha: 0.7), fontSize: 8.5, fontWeight: FontWeight.w500)),
                      ],
                    ),
            ),
          );
        }),
      ),
    );
  }

  Widget _card_({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}
