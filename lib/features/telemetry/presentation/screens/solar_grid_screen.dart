import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/panel_model.dart';
import 'package:enercore_app/core/utils/responsive.dart';

class SolarGridScreen extends StatefulWidget {
  const SolarGridScreen({super.key});

  @override
  State<SolarGridScreen> createState() => _SolarGridScreenState();
}

class _SolarGridScreenState extends State<SolarGridScreen> {
  late List<PanelModel> panels;
  final int gridSize = 16;

  @override
  void initState() {
    super.initState();
    _generateDummyPanels();
  }

  void _generateDummyPanels() {
    panels = [];
    final random = Random();
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        // Mostly healthy, some offline, some fault, some warning
        int statusRand = random.nextInt(100);
        PanelStatus status = PanelStatus.healthy;
        if (statusRand > 95) {
          status = PanelStatus.fault;
        } else if (statusRand > 90) {
          status = PanelStatus.offline;
        } else if (statusRand > 80) {
          status = PanelStatus.warning;
        }

        panels.add(
          PanelModel(
            id: 'PNL-$r-$c',
            row: r,
            column: c,
            status: status,
            voltage: 30.0 + random.nextDouble() * 5.0,
            current: 8.0 + random.nextDouble() * 2.0,
            temperature: 35.0 + random.nextDouble() * 15.0,
            generation: 250.0 + random.nextDouble() * 50.0,
            lastSync: DateTime.now().subtract(Duration(seconds: random.nextInt(60))),
          ),
        );
      }
    }
  }

  Color _getStatusColor(PanelStatus status) {
    switch (status) {
      case PanelStatus.healthy:
        return Colors.green;
      case PanelStatus.warning:
        return Colors.yellow.shade700;
      case PanelStatus.fault:
        return Colors.red;
      case PanelStatus.offline:
        return Colors.grey.shade600;
    }
  }

  void _showPanelDetails(PanelModel panel) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Panel ${panel.id}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  Chip(
                    backgroundColor: _getStatusColor(panel.status).withValues(alpha: 0.2),
                    label: Text(
                      panel.status.name.toUpperCase(),
                      style: TextStyle(color: _getStatusColor(panel.status), fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
              const Divider(height: 32),
              _buildDetailRow('Voltage', '${panel.voltage.toStringAsFixed(1)} V'),
              _buildDetailRow('Current', '${panel.current.toStringAsFixed(1)} A'),
              _buildDetailRow('Temperature', '${panel.temperature.toStringAsFixed(1)} °C'),
              _buildDetailRow('Generation', '${panel.generation.toStringAsFixed(1)} W'),
              _buildDetailRow('Last Sync', '${panel.lastSync.hour}:${panel.lastSync.minute.toString().padLeft(2, '0')}'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solar Array Monitor'),
      ),
      body: SafeArea(
        child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegend(Colors.green, 'Healthy'),
                _buildLegend(Colors.yellow.shade700, 'Warning'),
                _buildLegend(Colors.red, 'Fault'),
                _buildLegend(Colors.grey.shade600, 'Offline'),
              ],
            ),
          ),
          Expanded(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              constrained: false,
              boundaryMargin: const EdgeInsets.all(100),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: SizedBox(
                   // Ensure the grid maintains proportional spacing
                  width: gridSize * 50.0,
                  height: gridSize * 50.0,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: gridSize,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: panels.length,
                    itemBuilder: (context, index) {
                      final panel = panels[index];
                      return InkWell(
                        onTap: () => _showPanelDetails(panel),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _getStatusColor(panel.status),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 2,
                                offset: const Offset(1, 1),
                              )
                            ],
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Responsive.isDesktop(context) 
                            ? Center(child: Text('${panel.row},${panel.column}', style: const TextStyle(color: Colors.white, fontSize: 10)))
                            : null,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
