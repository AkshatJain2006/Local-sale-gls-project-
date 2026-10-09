class SaleItem {
  final String productId;
  final String productName;
  final int qty;
  final double price;
  final String barcode;

  SaleItem({
    this.productId = '',
    required this.productName,
    required this.qty,
    required this.price,
    this.barcode = '',
  });

  double get total => qty * price;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'qty': qty,
        'price': price,
        'barcode': barcode,
      };

  factory SaleItem.fromJson(Map<String, dynamic> json) => SaleItem(
        productId: json['productId']?.toString() ?? '',
        productName: json['productName']?.toString() ?? '',
        qty: (json['qty'] as num?)?.toInt() ?? 1,
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        barcode: json['barcode']?.toString() ?? '',
      );
}

class SalePayment {
  final double amount;
  final DateTime date;
  final String method;

  SalePayment({
    required this.amount,
    required this.date,
    required this.method,
  });

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'date': date.toIso8601String(),
        'method': method,
      };

  factory SalePayment.fromJson(Map<String, dynamic> json) => SalePayment(
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        date: json['date'] != null
            ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
            : DateTime.now(),
        method: json['method']?.toString() ?? 'Cash',
      );
}

class Sale {
  final String invoiceNo;
  final String customerName;
  final String customerPhone;
  final DateTime date;
  final List<SaleItem> items;
  final double discount;
  final double tax;
  final String paymentMethod;
  double paid;
  final String cashier;
  final List<SalePayment> paymentHistory;

  Sale({
    required this.invoiceNo,
    required this.customerName,
    this.customerPhone = '',
    required this.date,
    required this.items,
    required this.discount,
    required this.tax,
    required this.paymentMethod,
    required this.paid,
    this.cashier = 'Admin',
    List<SalePayment>? paymentHistory,
  }) : paymentHistory = paymentHistory ?? [];

  double get subtotal => items.fold(0, (sum, i) => sum + i.total);
  double get total => (subtotal - discount).clamp(0, double.infinity);
  double get due => (total - paid).clamp(0, double.infinity);

  /// Derived — never stored separately to avoid contradictions.
  String get paymentStatus {
    if (due <= 0) return 'Paid';
    if (paid > 0) return 'Partially Paid';
    return 'Unpaid';
  }

  Map<String, dynamic> toJson() => {
        'invoiceNo': invoiceNo,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'date': date.toIso8601String(),
        'items': items.map((i) => i.toJson()).toList(),
        'discount': discount,
        'tax': tax,
        'paymentMethod': paymentMethod,
        'paid': paid,
        'cashier': cashier,
        'paymentHistory': paymentHistory.map((p) => p.toJson()).toList(),
      };

  factory Sale.fromJson(Map<String, dynamic> json) => Sale(
        invoiceNo: json['invoiceNo']?.toString() ?? 'INV-000',
        customerName: json['customerName']?.toString() ?? 'Walk-in Customer',
        customerPhone: json['customerPhone']?.toString() ?? '',
        date: json['date'] != null
            ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
            : DateTime.now(),
        items: (json['items'] as List<dynamic>?)
                ?.map((item) => SaleItem.fromJson(item as Map<String, dynamic>))
                .toList() ??
            [],
        discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
        tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
        paymentMethod: json['paymentMethod']?.toString() ?? 'Cash',
        paid: (json['paid'] as num?)?.toDouble() ?? 0.0,
        cashier: json['cashier']?.toString() ?? 'Admin',
        paymentHistory: (json['paymentHistory'] as List<dynamic>?)
                ?.map((p) => SalePayment.fromJson(p as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
