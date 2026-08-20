class SaleItem {
  final String productName;
  final int qty;
  final double price;

  SaleItem({required this.productName, required this.qty, required this.price});

  double get total => qty * price;
}

class Sale {
  final String invoiceNo;
  final String customerName;
  final DateTime date;
  final List<SaleItem> items;
  final double discount;
  final double tax;
  final String paymentMethod;
  double paid;

  Sale({
    required this.invoiceNo,
    required this.customerName,
    required this.date,
    required this.items,
    required this.discount,
    required this.tax,
    required this.paymentMethod,
    required this.paid,
  });

  double get subtotal => items.fold(0, (sum, i) => sum + i.total);
  double get total => subtotal - discount + tax;
  double get due => total - paid;
}
