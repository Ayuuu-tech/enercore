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
