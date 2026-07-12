import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/http/http_helper.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/invoice_model.dart';

final billingRepositoryProvider = Provider<BillingRepository>((ref) {
  final authRepository = ref.read(authRepositoryProvider);
  return BillingRepository(authRepository);
});

class BillingRepository {
  final AuthRepository _authRepository;

  BillingRepository(this._authRepository);

  Future<List<InvoiceModel>> getInvoices() async {
    final token = _authRepository.token;
    final response = await httpGet(
      Uri.parse('${_authRepository.baseUrl}/billing'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => InvoiceModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch invoices: ${response.statusCode}');
    }
  }

  /// Downloads the solar bill of supply for an invoice. Returns file bytes+name.
  Future<({List<int> bytes, String filename})> downloadBillPdf(String id) async {
    final token = _authRepository.token;
    final response = await httpGet(
      Uri.parse('${_authRepository.baseUrl}/billing/$id/pdf'),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final disposition = response.headers['content-disposition'] ?? '';
      final match = RegExp('filename="(.+)"').firstMatch(disposition);
      return (bytes: response.bodyBytes, filename: match?.group(1) ?? 'enercore-bill.pdf');
    }

    String message = 'Failed to download bill: ${response.statusCode}';
    try {
      final err = jsonDecode(response.body);
      if (err['message'] != null) message = err['message'].toString();
    } catch (_) {}
    throw Exception(message);
  }

  Future<InvoiceModel> payInvoice(String id) async {
    final token = _authRepository.token;
    final response = await httpPost(
      Uri.parse('${_authRepository.baseUrl}/billing/$id/pay'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return InvoiceModel.fromJson(data);
    } else {
      throw Exception('Payment failed: ${response.statusCode}');
    }
  }
}
