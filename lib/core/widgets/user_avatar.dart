import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/data/auth_repository.dart';

/// Resolves a stored avatar path to a loadable URL. Uploaded avatars are stored
/// as a relative path like `/uploads/avatars/x.jpg`, so prepend the server
/// origin (baseUrl without the trailing `/api`).
String? resolveAvatarUrl(WidgetRef ref, String? avatarUrl) {
  if (avatarUrl == null || avatarUrl.isEmpty) return null;
  if (avatarUrl.startsWith('http')) return avatarUrl;
  final base = ref.read(authRepositoryProvider).baseUrl; // e.g. http://host:3000/api
  final origin = base.endsWith('/api') ? base.substring(0, base.length - 4) : base;
  return avatarUrl.startsWith('/') ? '$origin$avatarUrl' : '$origin/$avatarUrl';
}

/// Shows the logged-in user's real profile photo, or their initial on a teal
/// circle when no photo has been uploaded. Used across every screen's top bar.
class UserAvatar extends ConsumerWidget {
  final double size;
  final VoidCallback? onTap;
  const UserAvatar({super.key, this.size = 32, this.onTap});

  static const _teal = Color(0xFF2A8C6E);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    final url = resolveAvatarUrl(ref, user?.avatarUrl);
    final name = user?.name ?? '';
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    Widget initialsCircle() => Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _teal.withValues(alpha: 0.14),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          ),
          child: Text(
            initial,
            style: TextStyle(color: _teal, fontWeight: FontWeight.w800, fontSize: size * 0.42),
          ),
        );

    final Widget avatar = url == null
        ? initialsCircle()
        : ClipOval(
            child: Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              // If the photo fails to load, show initials instead of a blank.
              errorBuilder: (_, _, _) => initialsCircle(),
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : initialsCircle(),
            ),
          );

    return onTap != null ? GestureDetector(onTap: onTap, child: avatar) : avatar;
  }
}
