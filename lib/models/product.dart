class Product {
  final String id;
  final String name;
  final String category;
  final double purchasePrice;
  final double sellingPrice;
  int quantity;
  final int minStock;
  final String supplier;
  final String barcode;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.quantity,
    required this.minStock,
    required this.supplier,
    this.barcode = '',
  });

  bool get isLowStock => quantity <= minStock;
  double get profit => sellingPrice - purchasePrice;
  double get profitMargin =>
      sellingPrice > 0 ? ((profit / sellingPrice) * 100) : 0;

  Product copyWith({
    String? id,
    String? name,
    String? category,
    double? purchasePrice,
    double? sellingPrice,
    int? quantity,
    int? minStock,
    String? supplier,
    String? barcode,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      quantity: quantity ?? this.quantity,
      minStock: minStock ?? this.minStock,
      supplier: supplier ?? this.supplier,
      barcode: barcode ?? this.barcode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'quantity': quantity,
      'minStock': minStock,
      'supplier': supplier,
      'barcode': barcode,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      purchasePrice: (json['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      minStock: (json['minStock'] as num?)?.toInt() ?? 5,
      supplier: json['supplier']?.toString() ?? '',
      barcode: json['barcode']?.toString() ?? '',
    );
  }
}
