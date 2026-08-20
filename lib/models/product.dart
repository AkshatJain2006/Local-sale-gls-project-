class Product {
  final String id;
  final String name;
  final String category;
  final double purchasePrice;
  final double sellingPrice;
  int quantity;
  final int minStock;
  final String supplier;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.quantity,
    required this.minStock,
    required this.supplier,
  });

  bool get isLowStock => quantity <= minStock;
  double get profit => sellingPrice - purchasePrice;
}
