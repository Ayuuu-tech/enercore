import 'package:flutter/material.dart';
import 'package:enercore_app/core/utils/responsive.dart';
import 'package:enercore_app/features/dashboard/presentation/widgets/stats_card.dart';

class TelemetryDashboardScreen extends StatelessWidget {
  const TelemetryDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Telemetry'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildControlPanel(context),
              const SizedBox(height: 24),
              Text(
                'Live Metrics',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: Responsive.isDesktop(context) ? 4 : (Responsive.isTablet(context) ? 3 : 2),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                childAspectRatio: Responsive.isDesktop(context) ? 1.5 : 1.2,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  const StatsCard(title: 'Voltage', value: '415 V', icon: Icons.electric_bolt, color: Colors.blue),
                  const StatsCard(title: 'Current', value: '45.2 A', icon: Icons.waves, color: Colors.indigo),
                  const StatsCard(title: 'Frequency', value: '50.0 Hz', icon: Icons.speed, color: Colors.purple),
                  const StatsCard(title: 'Active Power', value: '18.4 kW', icon: Icons.bolt, color: Colors.orange),
                  StatsCard(title: 'Grid Health', value: 'Excellent', icon: Icons.health_and_safety, color: Colors.green.shade600),
                  StatsCard(title: 'Inverter Status', value: 'Sync', icon: Icons.sync, color: Colors.teal.shade600),
                  const StatsCard(title: 'Battery SoC', value: '84%', icon: Icons.battery_charging_full, color: Colors.lightGreen),
                  const StatsCard(title: 'Energy', value: '1.2 MWh', icon: Icons.data_usage, color: Colors.blueGrey),
                ],
              ),
              const SizedBox(height: 24),
              Responsive(
                mobile: Column(
                  children: [
                    _buildChartCard(context, 'Voltage/Current Waveform'),
                    const SizedBox(height: 16),
                    _buildChartCard(context, 'Real-time Power Output'),
                  ],
                ),
                tablet: Row(
                  children: [
                    Expanded(child: _buildChartCard(context, 'Voltage/Current Waveform')),
                    const SizedBox(width: 16),
                    Expanded(child: _buildChartCard(context, 'Real-time Power Output')),
                  ],
                ),
                desktop: Row(
                  children: [
                    Expanded(child: _buildChartCard(context, 'Voltage/Current Waveform')),
                    const SizedBox(width: 16),
                    Expanded(child: _buildChartCard(context, 'Real-time Power Output')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlPanel(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.dvr),
                const SizedBox(width: 8),
                Text('Telemetry Controls (Admin/Sim)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Responsive(
               mobile: Column(
                 children: [
                   _buildSimulationSlider('Voltage Injection', 415),
                   _buildSimulationSlider('Current Injection', 45),
                 ]
               ),
               desktop: Row(
                  children: [
                    Expanded(child: _buildSimulationSlider('Voltage Injection', 415)),
                    const SizedBox(width: 24),
                    Expanded(child: _buildSimulationSlider('Current Injection', 45)),
                  ],
               ),
            ),
             const SizedBox(height: 16),
             Row(
               mainAxisAlignment: MainAxisAlignment.end,
               children: [
                  OutlinedButton.icon(onPressed: (){}, icon: const Icon(Icons.warning, color: Colors.orange), label: const Text('Inject Fault')),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(onPressed: (){}, icon: const Icon(Icons.send), label: const Text('Send Alert')),
               ],
             )
          ],
        ),
      ),
    );
  }

  Widget _buildSimulationSlider(String label, double val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Row(
          children: [
            Expanded(child: Slider(value: val, max: 500, min: 0, onChanged: (v){})),
            Text(val.toStringAsFixed(0)),
          ],
        ),
      ],
    );
  }

  Widget _buildChartCard(BuildContext context, String title) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              height: 250,
              width: double.infinity,
              color: Colors.black.withValues(alpha: 0.02),
              alignment: Alignment.center,
              child: const Text('Live Chart Canvas Component', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}
