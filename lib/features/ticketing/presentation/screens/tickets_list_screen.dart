import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TicketsListScreen extends StatelessWidget {
  const TicketsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance Tickets'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-ticket'),
        icon: const Icon(Icons.add),
        label: const Text('New Ticket'),
      ),
      body: SafeArea(
        child: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: 5,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final isResolved = index % 3 == 0;
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16.0),
              leading: CircleAvatar(
                backgroundColor: isResolved ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                child: Icon(
                  isResolved ? Icons.check_circle : Icons.build,
                  color: isResolved ? Colors.green : Colors.orange,
                ),
              ),
              title: Text('Inverter Fault at Block ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text('Reported: Oct 1$index, 2026', style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(isResolved ? 'RESOLVED' : 'IN PROGRESS'),
                    backgroundColor: isResolved ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                    labelStyle: TextStyle(color: isResolved ? Colors.green : Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                  )
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/ticket-detail'),
            ),
          );
        },
      ),
      ),
    );
  }
}
