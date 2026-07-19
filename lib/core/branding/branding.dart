import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../http/http_helper.dart';
import '../../features/auth/data/auth_repository.dart';

/// The admin-configurable logo URL, or null to use the bundled asset. Fetched
/// once and cached; the admin branding screen invalidates it after a change.
final brandingLogoProvider = FutureProvider<String?>((ref) async {
  final base = ref.read(authRepositoryProvider).baseUrl;
  try {
    final res = await httpGet(Uri.parse('$base/branding'));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final url = data['logoUrl'];
      return (url is String && url.isNotEmpty) ? url : null;
    }
  } catch (_) {
    // Offline or server error — fall back to the bundled asset.
  }
  return null;
});

/// Uploads or clears the branding logo (admin only).
class BrandingRepository {
  final AuthRepository _auth;
  BrandingRepository(this._auth);

  Map<String, String> get _authHeader =>
      {if (_auth.token != null) 'Authorization': 'Bearer ${_auth.token}'};

  Future<void> uploadLogo(List<int> bytes, String filename) async {
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('${_auth.baseUrl}/branding/logo'),
    )
      ..headers.addAll(_authHeader)
      ..files.add(http.MultipartFile.fromBytes('logo', bytes, filename: filename));
    final res = await http.Response.fromStream(await req.send());
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Failed to upload logo');
    }
  }

  Future<void> clearLogo() async {
    final res = await httpDelete(
      Uri.parse('${_auth.baseUrl}/branding/logo'),
      headers: _authHeader,
    );
    if (res.statusCode != 200) throw Exception('Failed to reset logo');
  }
}

final brandingRepositoryProvider = Provider<BrandingRepository>((ref) {
  return BrandingRepository(ref.read(authRepositoryProvider));
});
