import 'package:flutter/material.dart';

class InvoiceListScreen extends StatelessWidget {
  const InvoiceListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing & Invoices'),
        actions: [
          IconButton(icon: const Icon(Icons.credit_card), onPressed: () {}),
        ],
      ),
      body: SafeArea(
        child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: 4,
        itemBuilder: (context, index) {
          final isPending = index == 0;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                   Container(
                     padding: const EdgeInsets.all(12),
                     decoration: BoxDecoration(
                       color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                       borderRadius: BorderRadius.circular(8),
                     ),
                     child: Icon(Icons.receipt_long, color: Theme.of(context).colorScheme.primary),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text('INV-2026-${1045 + index}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                         const SizedBox(height: 4),
                         Text('Due: Nov ${10 + index}, 2026', style: const TextStyle(color: Colors.grey)),
                       ],
                     ),
                   ),
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.end,
                     children: [
                       const Text('₹45,200', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                       const SizedBox(height: 8),
                       Text(
                         isPending ? 'PENDING' : 'PAID',
                         style: TextStyle(
                           color: isPending ? Colors.red : Colors.green,
                           fontWeight: FontWeight.bold,
                           fontSize: 12,
                         ),
                       )
                     ],
                   )
                ],
              ),
            ),
          );
        }
      ),
      ),
    );
  }
}
