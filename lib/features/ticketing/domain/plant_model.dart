class PlantModel {
  final String id;
  final String name;
  final String location;
  final double peakCapacity;
  final String status;
  final String ownerId;

  PlantModel({
    required this.id,
    required this.name,
    required this.location,
    required this.peakCapacity,
    required this.status,
    required this.ownerId,
  });

  factory PlantModel.fromJson(Map<String, dynamic> json) {
    return PlantModel(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String,
      peakCapacity: (json['peakCapacity'] as num).toDouble(),
      status: json['status'] as String,
      ownerId: json['ownerId'] as String,
    );
  }
}

class PanelModel {
  final String id;
  final int row;
  final int column;
  final String status;
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

  factory PanelModel.fromJson(Map<String, dynamic> json) {
    return PanelModel(
      id: json['id'] as String,
      row: json['row'] as int,
      column: json['column'] as int,
      status: json['status'] as String,
      voltage: (json['voltage'] as num).toDouble(),
      current: (json['current'] as num).toDouble(),
      temperature: (json['temperature'] as num).toDouble(),
      generation: (json['generation'] as num).toDouble(),
      lastSync: DateTime.parse(json['lastSync'] as String),
    );
  }
}
