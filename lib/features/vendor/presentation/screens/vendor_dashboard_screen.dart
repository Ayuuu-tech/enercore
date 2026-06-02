import 'package:flutter/material.dart';
import 'package:enercore_app/features/dashboard/presentation/widgets/stats_card.dart';
import 'package:enercore_app/core/utils/responsive.dart';

class VendorDashboardScreen extends StatelessWidget {
  const VendorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vendor Portal')),
      body: SafeArea(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Operations', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: Responsive.isMobile(context) ? 2 : 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                StatsCard(title: 'Pending Orders', value: '34', icon: Icons.shopping_bag, color: Colors.orange),
                StatsCard(title: 'Out of Stock', value: '12', icon: Icons.inventory_2, color: Colors.red),
                StatsCard(title: 'Monthly Revenue', value: '₹4.2L', icon: Icons.account_balance_wallet, color: Colors.green),
                StatsCard(title: 'Avg Fulfillment', value: '2.1 Days', icon: Icons.local_shipping, color: Colors.blue),
              ],
            ),
            const SizedBox(height: 24),
            Text('Recent Orders', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.receipt, color: Colors.white)),
                    title: Text('Order #ORD-${9001 + index}'),
                    subtitle: Text('Status: ${index == 0 ? 'Pending' : 'Shipped'}'),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      ),
    );
  }
}
