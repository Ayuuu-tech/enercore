enum PanelStatus { healthy, warning, fault, offline }

class PanelModel {
  final String id;
  final int row;
  final int column;
  final PanelStatus status;
  final double voltage;
  final double current;
  final double temperature;
  final double generation;
  final DateTime lastSync;

  PanelModel({
    required this.id,
    required this.row,
    required this.column,
    required this.status,
    required this.voltage,
    required this.current,
    required this.temperature,
    required this.generation,
    required this.lastSync,
  });
}
