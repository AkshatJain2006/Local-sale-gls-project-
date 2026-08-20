class Payment {
  final String id;
  final String customerId;
  final double amount;
  final DateTime date;
  final String note;

  Payment({
    required this.id,
    required this.customerId,
    required this.amount,
    required this.date,
    required this.note,
  });
}
