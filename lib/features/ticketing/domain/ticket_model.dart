class TicketModel {
  final String id;
  final String ticketNumber;
  final String title;
  final String description;
  final String status; // OPEN, IN_PROGRESS, RESOLVED
  final String priority; // LOW, MEDIUM, HIGH
  final String? lastUpdateMessage;
  final String userId;
  final String plantId;
  final DateTime createdAt;
  final DateTime updatedAt;

  TicketModel({
    required this.id,
    required this.ticketNumber,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.lastUpdateMessage,
    required this.userId,
    required this.plantId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'] as String,
      ticketNumber: json['ticketNumber'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String,
      lastUpdateMessage: json['lastUpdateMessage'] as String?,
      userId: json['userId'] as String,
      plantId: json['plantId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
