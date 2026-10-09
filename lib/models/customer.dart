class CustomerTransaction {
  final String id;
  final String date;
  final double amount;
  final String description;
  final String type; // 'sale' or 'payment'

  CustomerTransaction({
    required this.id,
    required this.date,
    required this.amount,
    required this.description,
    this.type = 'sale',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'amount': amount,
        'description': description,
        'type': type,
      };

  factory CustomerTransaction.fromJson(Map<String, dynamic> json) =>
      CustomerTransaction(
        id: json['id']?.toString() ?? '',
        date: json['date']?.toString() ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        description: json['description']?.toString() ?? '',
        type: json['type']?.toString() ?? 'sale',
      );
}

class Customer {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  double totalPurchase;
  double totalPaid;
  final List<CustomerTransaction> transactions;
  bool isBlacklisted;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email = '',
    this.address = '',
    required this.totalPurchase,
    required this.totalPaid,
    List<CustomerTransaction>? transactions,
    this.isBlacklisted = false,
  }) : transactions = transactions ?? [];

  double get outstanding => (totalPurchase - totalPaid).clamp(0, double.infinity);

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    double? totalPurchase,
    double? totalPaid,
    List<CustomerTransaction>? transactions,
    bool? isBlacklisted,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      totalPurchase: totalPurchase ?? this.totalPurchase,
      totalPaid: totalPaid ?? this.totalPaid,
      transactions: transactions ?? this.transactions,
      isBlacklisted: isBlacklisted ?? this.isBlacklisted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'totalPurchase': totalPurchase,
        'totalPaid': totalPaid,
        'transactions': transactions.map((t) => t.toJson()).toList(),
        'isBlacklisted': isBlacklisted,
      };

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        totalPurchase: (json['totalPurchase'] as num?)?.toDouble() ?? 0.0,
        totalPaid: (json['totalPaid'] as num?)?.toDouble() ?? 0.0,
        transactions: (json['transactions'] as List<dynamic>?)
                ?.map((t) => CustomerTransaction.fromJson(t as Map<String, dynamic>))
                .toList() ??
            [],
        isBlacklisted: json['isBlacklisted'] as bool? ?? false,
      );
}
