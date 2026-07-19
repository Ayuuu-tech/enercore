import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A simple reader for the app's Privacy Policy and Terms of Service. The text
/// is intentionally plain boilerplate that Enercore can refine later — the point
/// is that the footer links open real, readable content instead of doing
/// nothing.
class LegalScreen extends StatelessWidget {
  final String title;
  final List<(String, String)> sections;

  const LegalScreen({super.key, required this.title, required this.sections});

  static const _teal = Color(0xFF2A8C6E);
  static const _slateDark = Color(0xFF1E293B);
  static const _slateLight = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 56,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back_rounded, color: _slateDark, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(title,
                      style: const TextStyle(
                          color: _teal, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.3)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  for (final (heading, body) in sections) ...[
                    Text(heading,
                        style: const TextStyle(
                            color: _slateDark, fontSize: 14, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(body,
                        style: const TextStyle(color: _slateLight, fontSize: 12.5, height: 1.5)),
                    const SizedBox(height: 18),
                  ],
                  const SizedBox(height: 8),
                  const Text('© 2025 Enercore Operations. All rights reserved.',
                      style: TextStyle(color: _slateLight, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const privacyPolicySections = <(String, String)>[
  (
    'Overview',
    'This Privacy Policy explains how Enercore collects, uses, and protects the '
        'information you provide when you use the Enercore application.'
  ),
  (
    'Information we collect',
    'We collect the account details you give us — your name, email, phone number, '
        'and, for vendors, business and bank details — along with usage data needed '
        'to operate the service, such as the plants and orders associated with your '
        'account.'
  ),
  (
    'How we use it',
    'Your information is used to provide the service: to authenticate you, show '
        'your plant data and orders, process payments to vendors, and support you. '
        'We do not sell your personal information.'
  ),
  (
    'Data security',
    'Access is protected by authentication and transport encryption (HTTPS). '
        'Sensitive documents are stored in private storage and shared only as '
        'needed to operate the service.'
  ),
  (
    'Contact',
    'For any privacy question or a request to access or delete your data, contact '
        'Enercore Operations through your account administrator.'
  ),
];

const termsSections = <(String, String)>[
  (
    'Acceptance',
    'By creating an account or using the Enercore application you agree to these '
        'Terms of Service.'
  ),
  (
    'Your account',
    'You are responsible for keeping your login credentials secure and for '
        'activity under your account. Provide accurate information and keep it up '
        'to date.'
  ),
  (
    'Acceptable use',
    'Use the service only for its intended purpose. Do not attempt to disrupt it, '
        'access data you are not authorised to, or misuse another user\'s account.'
  ),
  (
    'Orders and payments',
    'Orders placed in the marketplace are subject to availability and vendor '
        'confirmation. Prices shown include applicable charges as displayed at '
        'checkout.'
  ),
  (
    'Changes',
    'We may update these terms as the service evolves. Continued use after an '
        'update means you accept the revised terms.'
  ),
];
