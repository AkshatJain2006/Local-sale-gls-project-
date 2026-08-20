class Customer {
  final String id;
  final String name;
  final String phone;
  double totalPurchase;
  double totalPaid;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.totalPurchase,
    required this.totalPaid,
  });

  double get outstanding => totalPurchase - totalPaid;
}
