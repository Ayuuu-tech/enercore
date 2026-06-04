class TicketCommentModel {
  final String id;
  final String ticketId;
  final String userId;
  final String message;
  final DateTime createdAt;

  TicketCommentModel({
    required this.id,
    required this.ticketId,
    required this.userId,
    required this.message,
    required this.createdAt,
  });

  factory TicketCommentModel.fromJson(Map<String, dynamic> json) {
    return TicketCommentModel(
      id: json['id'] as String,
      ticketId: json['ticketId'] as String,
      userId: json['userId'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
