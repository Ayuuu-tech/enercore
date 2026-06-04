class InvoiceModel {
  final String id;
  final String invoiceNumber;
  final double amount;
  final String period;
  final String status; // PENDING, PAID, OVERDUE
  final DateTime dueDate;
  final DateTime? paidAt;
  final String userId;
  final String? plantId;

  InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.amount,
    required this.period,
    required this.status,
    required this.dueDate,
    this.paidAt,
    required this.userId,
    this.plantId,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] as String,
      invoiceNumber: json['invoiceNumber'] as String,
      amount: (json['amount'] as num).toDouble(),
      period: json['period'] as String,
      status: json['status'] as String,
      dueDate: DateTime.parse(json['dueDate'] as String),
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt'] as String) : null,
      userId: json['userId'] as String,
      plantId: json['plantId'] as String?,
    );
  }
}
