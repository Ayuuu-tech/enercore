import 'package:flutter/material.dart';

class CreateTicketScreen extends StatelessWidget {
  const CreateTicketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Open Support Ticket')),
      body: SafeArea(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Issue Subject', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Severity', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'Low', child: Text('Low - General Inquiry')),
                DropdownMenuItem(value: 'Medium', child: Text('Medium - Degraded Performance')),
                DropdownMenuItem(value: 'High', child: Text('High - Plant Offline')),
              ],
              onChanged: (v) {},
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Associated Plant', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'Plant_A', child: Text('Alpha Solar Plant - Gurgaon')),
              ],
              onChanged: (v) {},
            ),
            const SizedBox(height: 16),
            TextFormField(
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Detailed Description',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {}, // Logic to upload image
              icon: const Icon(Icons.camera_alt),
              label: const Text('Attach Image/Document'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('SUBMIT TICKET'),
            )
          ],
        ),
      ),
      ),
    );
  }
}
