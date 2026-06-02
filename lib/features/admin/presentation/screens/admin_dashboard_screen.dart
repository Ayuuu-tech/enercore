import 'package:flutter/material.dart';
import 'package:enercore_app/features/dashboard/presentation/widgets/stats_card.dart';
import 'package:enercore_app/core/utils/responsive.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Command Center'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Hits', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: Responsive.isMobile(context) ? 2 : 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                StatsCard(title: 'Total Plants', value: '142', icon: Icons.solar_power, color: Colors.blue),
                StatsCard(title: 'Active Faults', value: '18', icon: Icons.warning, color: Colors.red),
                StatsCard(title: 'Pending Tickets', value: '12', icon: Icons.build, color: Colors.orange),
                StatsCard(title: 'Marketplace Rev', value: '₹1.2Cr', icon: Icons.trending_up, color: Colors.green),
              ],
            ),
            const SizedBox(height: 24),
            Text('Fleet Map (Preview)', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Container(
                height: 300,
                width: double.infinity,
                color: Colors.grey.shade200,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Interactive Fleet Map Loading...', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
