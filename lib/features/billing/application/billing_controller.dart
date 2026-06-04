import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/invoice_model.dart';
import '../data/billing_repository.dart';

final billingControllerProvider = AsyncNotifierProvider<BillingController, List<InvoiceModel>>(() {
  return BillingController();
});

class BillingController extends AsyncNotifier<List<InvoiceModel>> {
  @override
  Future<List<InvoiceModel>> build() async {
    return ref.read(billingRepositoryProvider).getInvoices();
  }

  Future<void> fetchInvoices() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return ref.read(billingRepositoryProvider).getInvoices();
    });
  }

  Future<void> payInvoice(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(billingRepositoryProvider).payInvoice(id);
      return ref.read(billingRepositoryProvider).getInvoices();
    });
  }
}
