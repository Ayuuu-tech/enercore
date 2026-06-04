import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/ticket_model.dart';
import '../data/ticketing_repository.dart';

final ticketingControllerProvider = AsyncNotifierProvider.autoDispose<TicketingController, List<TicketModel>>(() {
  return TicketingController();
});

class TicketingController extends AsyncNotifier<List<TicketModel>> {
  Timer? _timer;

  @override
  Future<List<TicketModel>> build() async {
    ref.onDispose(() {
      _timer?.cancel();
    });

    // Start background polling every 8 seconds to auto-update ticket list
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      pollTickets();
    });

    return ref.read(ticketingRepositoryProvider).getTickets();
  }

  Future<void> pollTickets() async {
    try {
      final tickets = await ref.read(ticketingRepositoryProvider).getTickets();
      state = AsyncValue.data(tickets);
    } catch (_) {
      // Fail silently during background polling to avoid disturbing active UI
    }
  }

  Future<void> fetchTickets() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return ref.read(ticketingRepositoryProvider).getTickets();
    });
  }

  Future<TicketModel> createTicket({
    required String title,
    required String description,
    required String plantId,
    required String priority,
  }) async {
    final ticket = await ref.read(ticketingRepositoryProvider).createTicket(
      title: title,
      description: description,
      plantId: plantId,
      priority: priority,
    );
    await fetchTickets();
    return ticket;
  }
}
