import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/http/http_helper.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/kyc_models.dart';

final kycRepositoryProvider = Provider<KycRepository>((ref) {
  return KycRepository(ref.read(authRepositoryProvider));
});

/// The vendor's own KYC.
final myKycProvider = FutureProvider<VendorKyc>((ref) async {
  return ref.read(kycRepositoryProvider).getMyKyc();
});

/// Every vendor's KYC, for the admin review queue.
final adminKycQueueProvider = FutureProvider<List<VendorKycSummary>>((ref) async {
  return ref.read(kycRepositoryProvider).getQueue();
});

class KycRepository {
  final AuthRepository _auth;
  KycRepository(this._auth);

  String get _base => _auth.baseUrl;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_auth.token != null) 'Authorization': 'Bearer ${_auth.token}',
      };

  Never _fail(http.Response r, String what) {
    String message = '$what failed (${r.statusCode})';
    try {
      final err = jsonDecode(r.body);
      if (err['message'] != null) message = err['message'].toString();
    } catch (_) {}
    throw Exception(message);
  }

  Future<VendorKyc> getMyKyc() async {
    final r = await httpGet(Uri.parse('$_base/vendors/kyc/me'), headers: _headers);
    if (r.statusCode != 200) _fail(r, 'Loading KYC');
    return VendorKyc.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<VendorKyc> saveDetails({
    required String pan,
    required String gstin,
    required String bankAccountName,
    required String bankAccountNumber,
    required String bankIfsc,
    required String bankName,
  }) async {
    final r = await httpPut(
      Uri.parse('$_base/vendors/kyc/me'),
      headers: _headers,
      body: jsonEncode({
        'pan': pan,
        'gstin': gstin,
        'bankAccountName': bankAccountName,
        'bankAccountNumber': bankAccountNumber,
        'bankIfsc': bankIfsc,
        'bankName': bankName,
      }),
    );
    if (r.statusCode != 200) _fail(r, 'Saving details');
    return VendorKyc.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  /// Uploads one document. [bytes] keeps this working on web too, where a
  /// picked file has no path.
  Future<VendorKyc> uploadDocument({
    required VendorDocType type,
    required List<int> bytes,
    required String fileName,
  }) async {
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('$_base/vendors/kyc/me/documents/${type.api}'),
    );
    if (_auth.token != null) req.headers['Authorization'] = 'Bearer ${_auth.token}';
    req.files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName));

    final streamed = await req.send().timeout(const Duration(seconds: 90));
    final r = await http.Response.fromStream(streamed);
    if (r.statusCode != 200 && r.statusCode != 201) _fail(r, 'Upload');
    return VendorKyc.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  /// A short-lived link to a document. The file itself is private.
  Future<String> myDocumentUrl(VendorDocType type) async {
    final r = await httpGet(
      Uri.parse('$_base/vendors/kyc/me/documents/${type.api}/url'),
      headers: _headers,
    );
    if (r.statusCode != 200) _fail(r, 'Opening document');
    return (jsonDecode(r.body) as Map<String, dynamic>)['url'] as String;
  }

  // ── Admin ────────────────────────────────────────────────────────────────

  Future<List<VendorKycSummary>> getQueue() async {
    final r = await httpGet(Uri.parse('$_base/vendors/kyc'), headers: _headers);
    if (r.statusCode != 200) _fail(r, 'Loading KYC queue');
    return (jsonDecode(r.body) as List<dynamic>)
        .map((v) => VendorKycSummary.fromJson(v as Map<String, dynamic>))
        .toList();
  }

  Future<VendorKyc> getVendorKyc(String vendorId) async {
    final r = await httpGet(Uri.parse('$_base/vendors/kyc/$vendorId'), headers: _headers);
    if (r.statusCode != 200) _fail(r, 'Loading vendor KYC');
    return VendorKyc.fromJson(jsonDecode(r.body) as Map<String, dynamic>);
  }

  Future<String> vendorDocumentUrl(String vendorId, VendorDocType type) async {
    final r = await httpGet(
      Uri.parse('$_base/vendors/kyc/$vendorId/documents/${type.api}/url'),
      headers: _headers,
    );
    if (r.statusCode != 200) _fail(r, 'Opening document');
    return (jsonDecode(r.body) as Map<String, dynamic>)['url'] as String;
  }

  Future<void> approve(String vendorId) async {
    final r = await httpPost(
      Uri.parse('$_base/vendors/kyc/$vendorId/approve'),
      headers: _headers,
    );
    if (r.statusCode != 200 && r.statusCode != 201) _fail(r, 'Approval');
  }

  Future<void> reject(String vendorId, String reason) async {
    final r = await httpPost(
      Uri.parse('$_base/vendors/kyc/$vendorId/reject'),
      headers: _headers,
      body: jsonEncode({'reason': reason}),
    );
    if (r.statusCode != 200 && r.statusCode != 201) _fail(r, 'Rejection');
  }
}
