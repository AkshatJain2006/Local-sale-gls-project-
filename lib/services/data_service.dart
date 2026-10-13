import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/customer.dart';
import 'api_service.dart';

Sale _s(String inv, String cust, String phone, DateTime date, List<SaleItem> items,
    double discount, String method, double paid, String cashier) {
  final s = Sale(
    invoiceNo: inv, customerName: cust, customerPhone: phone,
    date: date, items: items, discount: discount, tax: 0,
    paymentMethod: method, paid: paid, cashier: cashier,
  );
  if (paid > 0) s.paymentHistory.add(SalePayment(amount: paid, date: date, method: method));
  return s;
}

class DataService extends ChangeNotifier {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  bool _initialized = false;

  DataService._internal() {
    if (!_initialized) {
      _initialized = true;
      _initializeDefaultData();
      Future.microtask(() => checkBackendConnection());
    }
  }

  final ApiService _api = ApiService();
  bool _isBackendConnected = false;
  bool get isBackendConnected => _isBackendConnected;

  // Products
  final List<Product> _products = [];
  List<Product> get products => List.unmodifiable(_products);

  // Sales
  final List<Sale> _sales = [];
  List<Sale> get sales => List.unmodifiable(_sales);

  // Customers
  final List<Customer> _customers = [];
  List<Customer> get customers => List.unmodifiable(_customers);

  // Stock In History Log
  final List<Map<String, dynamic>> _stockLogs = [];
  List<Map<String, dynamic>> get stockLogs => List.unmodifiable(_stockLogs);

  void _initializeDefaultData() {
    // ── Wholesale Electronics Catalogue ──────────────────────────────────

    // Smartphones
    _products.addAll([
      Product(id: 'p001', name: 'Samsung Galaxy A15 5G', category: 'Smartphones',
          barcode: '8901234000101', supplier: 'Samsung India Pvt Ltd',
          purchasePrice: 11500, sellingPrice: 13999, quantity: 42, minStock: 10),
      Product(id: 'p002', name: 'Redmi 13C 4G (128GB)', category: 'Smartphones',
          barcode: '8901234000102', supplier: 'Xiaomi Technology India',
          purchasePrice: 7800, sellingPrice: 9499, quantity: 60, minStock: 15),
      Product(id: 'p003', name: 'Realme C65 5G', category: 'Smartphones',
          barcode: '8901234000103', supplier: 'Realme India Distributors',
          purchasePrice: 9200, sellingPrice: 11499, quantity: 35, minStock: 10),
      Product(id: 'p004', name: 'Vivo Y28 5G', category: 'Smartphones',
          barcode: '8901234000104', supplier: 'Vivo India Pvt Ltd',
          purchasePrice: 10500, sellingPrice: 12999, quantity: 28, minStock: 8),
      Product(id: 'p005', name: 'POCO M6 Pro 5G (256GB)', category: 'Smartphones',
          barcode: '8901234000105', supplier: 'Xiaomi Technology India',
          purchasePrice: 13800, sellingPrice: 16999, quantity: 20, minStock: 5),
      Product(id: 'p006', name: 'iQOO Z9 Lite 5G', category: 'Smartphones',
          barcode: '8901234000106', supplier: 'Vivo India Pvt Ltd',
          purchasePrice: 11000, sellingPrice: 13499, quantity: 18, minStock: 5),
    ]);

    // Tablets
    _products.addAll([
      Product(id: 'p007', name: 'Samsung Galaxy Tab A9 WiFi', category: 'Tablets',
          barcode: '8901234000201', supplier: 'Samsung India Pvt Ltd',
          purchasePrice: 14500, sellingPrice: 17999, quantity: 15, minStock: 4),
      Product(id: 'p008', name: 'Redmi Pad SE 8.7 inch', category: 'Tablets',
          barcode: '8901234000202', supplier: 'Xiaomi Technology India',
          purchasePrice: 10800, sellingPrice: 13499, quantity: 12, minStock: 4),
      Product(id: 'p009', name: 'Realme Pad 2 4G', category: 'Tablets',
          barcode: '8901234000203', supplier: 'Realme India Distributors',
          purchasePrice: 16500, sellingPrice: 19999, quantity: 8, minStock: 3),
    ]);

    // Laptops
    _products.addAll([
      Product(id: 'p010', name: 'HP 15s Ryzen 5 8GB 512GB', category: 'Laptops',
          barcode: '8901234000301', supplier: 'HP India Sales Pvt Ltd',
          purchasePrice: 38500, sellingPrice: 44999, quantity: 10, minStock: 3),
      Product(id: 'p011', name: 'Lenovo IdeaPad Slim 3 i5 13th Gen', category: 'Laptops',
          barcode: '8901234000302', supplier: 'Lenovo India Pvt Ltd',
          purchasePrice: 42000, sellingPrice: 49999, quantity: 8, minStock: 2),
      Product(id: 'p012', name: 'ASUS VivoBook 15 Ryzen 7', category: 'Laptops',
          barcode: '8901234000303', supplier: 'ASUS Technology India',
          purchasePrice: 46000, sellingPrice: 54999, quantity: 6, minStock: 2),
      Product(id: 'p013', name: 'Acer Aspire Lite i3 12th Gen', category: 'Laptops',
          barcode: '8901234000304', supplier: 'Acer India Pvt Ltd',
          purchasePrice: 28500, sellingPrice: 33999, quantity: 14, minStock: 3),
    ]);

    // Audio
    _products.addAll([
      Product(id: 'p014', name: 'boAt Rockerz 450 Bluetooth Headphone', category: 'Audio',
          barcode: '8901234000401', supplier: 'Imagine Marketing Ltd',
          purchasePrice: 850, sellingPrice: 1299, quantity: 80, minStock: 20),
      Product(id: 'p015', name: 'JBL Tune 520BT Wireless Headphone', category: 'Audio',
          barcode: '8901234000402', supplier: 'Harman International India',
          purchasePrice: 2200, sellingPrice: 2999, quantity: 45, minStock: 10),
      Product(id: 'p016', name: 'Sony WH-CH520 Wireless Headphone', category: 'Audio',
          barcode: '8901234000403', supplier: 'Sony India Pvt Ltd',
          purchasePrice: 3200, sellingPrice: 3999, quantity: 30, minStock: 8),
      Product(id: 'p017', name: 'boAt Airdopes 141 TWS Earbuds', category: 'Audio',
          barcode: '8901234000404', supplier: 'Imagine Marketing Ltd',
          purchasePrice: 650, sellingPrice: 999, quantity: 120, minStock: 30),
      Product(id: 'p018', name: 'Noise Buds VS104 TWS Earbuds', category: 'Audio',
          barcode: '8901234000405', supplier: 'Nexxbase Marketing Pvt Ltd',
          purchasePrice: 580, sellingPrice: 899, quantity: 95, minStock: 25),
      Product(id: 'p019', name: 'JBL Go 4 Portable Speaker', category: 'Audio',
          barcode: '8901234000406', supplier: 'Harman International India',
          purchasePrice: 2800, sellingPrice: 3499, quantity: 25, minStock: 6),
    ]);

    // Accessories
    _products.addAll([
      Product(id: 'p020', name: 'Anker 65W GaN USB-C Charger', category: 'Accessories',
          barcode: '8901234000501', supplier: 'Anker Innovations India',
          purchasePrice: 1400, sellingPrice: 1899, quantity: 55, minStock: 15),
      Product(id: 'p021', name: 'Samsung 25W Super Fast Charger', category: 'Accessories',
          barcode: '8901234000502', supplier: 'Samsung India Pvt Ltd',
          purchasePrice: 750, sellingPrice: 1099, quantity: 90, minStock: 20),
      Product(id: 'p022', name: 'Baseus 10000mAh Power Bank 22.5W', category: 'Accessories',
          barcode: '8901234000503', supplier: 'Baseus India Distributors',
          purchasePrice: 1100, sellingPrice: 1599, quantity: 65, minStock: 15),
      Product(id: 'p023', name: 'Ambrane 20000mAh Power Bank', category: 'Accessories',
          barcode: '8901234000504', supplier: 'Ambrane India Pvt Ltd',
          purchasePrice: 1350, sellingPrice: 1999, quantity: 40, minStock: 10),
      Product(id: 'p024', name: 'USB-C to USB-C Cable 1.5m 65W', category: 'Accessories',
          barcode: '8901234000505', supplier: 'Anker Innovations India',
          purchasePrice: 280, sellingPrice: 449, quantity: 200, minStock: 50),
      Product(id: 'p025', name: 'Lightning to USB-C Cable 1m', category: 'Accessories',
          barcode: '8901234000506', supplier: 'Anker Innovations India',
          purchasePrice: 320, sellingPrice: 499, quantity: 150, minStock: 40),
      Product(id: 'p026', name: 'Tempered Glass Screen Guard 6.5 inch', category: 'Accessories',
          barcode: '8901234000507', supplier: 'Mobikin Accessories India',
          purchasePrice: 60, sellingPrice: 149, quantity: 300, minStock: 80),
      Product(id: 'p027', name: 'Silicone Back Cover Samsung A15', category: 'Accessories',
          barcode: '8901234000508', supplier: 'Mobikin Accessories India',
          purchasePrice: 55, sellingPrice: 129, quantity: 180, minStock: 50),
      Product(id: 'p028', name: 'OTG USB-C to USB-A Adapter', category: 'Accessories',
          barcode: '8901234000509', supplier: 'Baseus India Distributors',
          purchasePrice: 120, sellingPrice: 199, quantity: 160, minStock: 40),
      Product(id: 'p029', name: 'Wireless Charging Pad 15W', category: 'Accessories',
          barcode: '8901234000510', supplier: 'Anker Innovations India',
          purchasePrice: 850, sellingPrice: 1299, quantity: 35, minStock: 8),
    ]);

    // Smart Devices
    _products.addAll([
      Product(id: 'p030', name: 'Noise ColorFit Pro 5 Smartwatch', category: 'Smart Devices',
          barcode: '8901234000601', supplier: 'Nexxbase Marketing Pvt Ltd',
          purchasePrice: 2200, sellingPrice: 2999, quantity: 30, minStock: 8),
      Product(id: 'p031', name: 'boAt Wave Sigma 2 Smartwatch', category: 'Smart Devices',
          barcode: '8901234000602', supplier: 'Imagine Marketing Ltd',
          purchasePrice: 1600, sellingPrice: 2199, quantity: 40, minStock: 10),
      Product(id: 'p032', name: 'Realme Watch S2 GPS', category: 'Smart Devices',
          barcode: '8901234000603', supplier: 'Realme India Distributors',
          purchasePrice: 3500, sellingPrice: 4499, quantity: 18, minStock: 5),
      Product(id: 'p033', name: 'TP-Link Tapo C200 WiFi Camera', category: 'Smart Devices',
          barcode: '8901234000604', supplier: 'TP-Link Technologies India',
          purchasePrice: 1800, sellingPrice: 2499, quantity: 22, minStock: 5),
      Product(id: 'p034', name: 'Mi Smart Band 8 Activity Tracker', category: 'Smart Devices',
          barcode: '8901234000605', supplier: 'Xiaomi Technology India',
          purchasePrice: 2800, sellingPrice: 3499, quantity: 25, minStock: 6),
      Product(id: 'p035', name: 'Amazon Echo Dot 5th Gen', category: 'Smart Devices',
          barcode: '8901234000606', supplier: 'Amazon Seller Services India',
          purchasePrice: 3200, sellingPrice: 4499, quantity: 15, minStock: 4),
    ]);

    // Networking
    _products.addAll([
      Product(id: 'p036', name: 'TP-Link Archer C6 AC1200 Router', category: 'Networking',
          barcode: '8901234000701', supplier: 'TP-Link Technologies India',
          purchasePrice: 1600, sellingPrice: 2199, quantity: 20, minStock: 5),
      Product(id: 'p037', name: 'D-Link DIR-825 AC1200 Dual Band Router', category: 'Networking',
          barcode: '8901234000702', supplier: 'D-Link India Ltd',
          purchasePrice: 2100, sellingPrice: 2799, quantity: 14, minStock: 4),
      Product(id: 'p038', name: 'TP-Link TL-SG108 8-Port Gigabit Switch', category: 'Networking',
          barcode: '8901234000703', supplier: 'TP-Link Technologies India',
          purchasePrice: 1400, sellingPrice: 1899, quantity: 18, minStock: 4),
      Product(id: 'p039', name: 'Tenda N301 300Mbps WiFi Router', category: 'Networking',
          barcode: '8901234000704', supplier: 'Tenda Technology India',
          purchasePrice: 700, sellingPrice: 999, quantity: 35, minStock: 8),
      Product(id: 'p040', name: 'TP-Link RE330 AC1200 WiFi Extender', category: 'Networking',
          barcode: '8901234000705', supplier: 'TP-Link Technologies India',
          purchasePrice: 1500, sellingPrice: 1999, quantity: 22, minStock: 5),
    ]);

    // ── Seed Sales Data ───────────────────────────────────────────────────
    final now = DateTime.now();
    DateTime d(int daysAgo, int hour, int minute) =>
        DateTime(now.year, now.month, now.day - daysAgo, hour, minute);

    _sales.addAll([
      // ── Today ──
      _s('INV-1001', 'Arjun Electronics', '9876543201', d(0, 9, 15),
          [SaleItem(productId: 'p001', productName: 'Samsung Galaxy A15 5G', qty: 2, price: 13999, barcode: '8901234000101'),
           SaleItem(productId: 'p021', productName: 'Samsung 25W Super Fast Charger', qty: 2, price: 1099, barcode: '8901234000502')],
          500, 'UPI', 30096, 'Admin'),
      _s('INV-1002', 'Meena Digital Store', '9876543206', d(0, 10, 40),
          [SaleItem(productId: 'p017', productName: 'boAt Airdopes 141 TWS Earbuds', qty: 5, price: 999, barcode: '8901234000404'),
           SaleItem(productId: 'p026', productName: 'Tempered Glass Screen Guard 6.5 inch', qty: 10, price: 149, barcode: '8901234000507')],
          200, 'Cash', 6285, 'Admin'),
      _s('INV-1003', 'Ravi Tech Traders', '9876543203', d(0, 11, 55),
          [SaleItem(productId: 'p010', productName: 'HP 15s Ryzen 5 8GB 512GB', qty: 1, price: 44999, barcode: '8901234000301'),
           SaleItem(productId: 'p024', productName: 'USB-C to USB-C Cable 1.5m 65W', qty: 3, price: 449, barcode: '8901234000505')],
          1000, 'Card', 45344, 'Admin'),
      _s('INV-1004', 'Walk-in Customer', '', d(0, 13, 20),
          [SaleItem(productId: 'p014', productName: 'boAt Rockerz 450 Bluetooth Headphone', qty: 1, price: 1299, barcode: '8901234000401')],
          0, 'Cash', 1299, 'Admin'),
      _s('INV-1005', 'Kavita Mobile Zone', '9876543208', d(0, 14, 10),
          [SaleItem(productId: 'p002', productName: 'Redmi 13C 4G (128GB)', qty: 3, price: 9499, barcode: '8901234000102'),
           SaleItem(productId: 'p027', productName: 'Silicone Back Cover Samsung A15', qty: 3, price: 129, barcode: '8901234000508')],
          300, 'UPI', 28884, 'Admin'),
      _s('INV-1006', 'Amit Gadget Corner', '9876543216', d(0, 15, 30),
          [SaleItem(productId: 'p030', productName: 'Noise ColorFit Pro 5 Smartwatch', qty: 2, price: 2999, barcode: '8901234000601'),
           SaleItem(productId: 'p022', productName: 'Baseus 10000mAh Power Bank 22.5W', qty: 2, price: 1599, barcode: '8901234000503')],
          0, 'Credit', 0, 'Admin'),
      _s('INV-1007', 'Walk-in Customer', '', d(0, 16, 45),
          [SaleItem(productId: 'p039', productName: 'Tenda N301 300Mbps WiFi Router', qty: 1, price: 999, barcode: '8901234000704'),
           SaleItem(productId: 'p028', productName: 'OTG USB-C to USB-A Adapter', qty: 2, price: 199, barcode: '8901234000509')],
          0, 'Cash', 1397, 'Admin'),

      // ── Yesterday ──
      _s('INV-0991', 'Priya Mobile Hub', '9876543202', d(1, 10, 0),
          [SaleItem(productId: 'p003', productName: 'Realme C65 5G', qty: 4, price: 11499, barcode: '8901234000103')],
          500, 'UPI', 45496, 'Admin'),
      _s('INV-0992', 'Sunita Gadget World', '9876543204', d(1, 11, 30),
          [SaleItem(productId: 'p015', productName: 'JBL Tune 520BT Wireless Headphone', qty: 3, price: 2999, barcode: '8901234000402'),
           SaleItem(productId: 'p019', productName: 'JBL Go 4 Portable Speaker', qty: 2, price: 3499, barcode: '8901234000406')],
          500, 'Card', 15494, 'Admin'),
      _s('INV-0993', 'Nikhil Network Solutions', '9876543213', d(1, 14, 0),
          [SaleItem(productId: 'p036', productName: 'TP-Link Archer C6 AC1200 Router', qty: 5, price: 2199, barcode: '8901234000701'),
           SaleItem(productId: 'p038', productName: 'TP-Link TL-SG108 8-Port Gigabit Switch', qty: 3, price: 1899, barcode: '8901234000703')],
          1000, 'UPI', 15392, 'Admin'),
      _s('INV-0994', 'Geeta Electronics Hub', '9876543219', d(1, 16, 20),
          [SaleItem(productId: 'p031', productName: 'boAt Wave Sigma 2 Smartwatch', qty: 4, price: 2199, barcode: '8901234000602')],
          200, 'Cash', 8596, 'Admin'),

      // ── 2 days ago ──
      _s('INV-0981', 'Sanjay Laptop World', '9876543214', d(2, 9, 30),
          [SaleItem(productId: 'p011', productName: 'Lenovo IdeaPad Slim 3 i5 13th Gen', qty: 2, price: 49999, barcode: '8901234000302'),
           SaleItem(productId: 'p020', productName: 'Anker 65W GaN USB-C Charger', qty: 2, price: 1899, barcode: '8901234000501')],
          2000, 'Card', 101796, 'Admin'),
      _s('INV-0982', 'Rekha Audio & Vision', '9876543215', d(2, 13, 0),
          [SaleItem(productId: 'p016', productName: 'Sony WH-CH520 Wireless Headphone', qty: 5, price: 3999, barcode: '8901234000403'),
           SaleItem(productId: 'p018', productName: 'Noise Buds VS104 TWS Earbuds', qty: 8, price: 899, barcode: '8901234000405')],
          500, 'UPI', 26683, 'Admin'),
      _s('INV-0983', 'Walk-in Customer', '', d(2, 15, 45),
          [SaleItem(productId: 'p005', productName: 'POCO M6 Pro 5G (256GB)', qty: 1, price: 16999, barcode: '8901234000105'),
           SaleItem(productId: 'p026', productName: 'Tempered Glass Screen Guard 6.5 inch', qty: 2, price: 149, barcode: '8901234000507')],
          0, 'Cash', 17297, 'Admin'),

      // ── 3 days ago ──
      _s('INV-0971', 'Vijay Computers & Accessories', '9876543211', d(3, 10, 15),
          [SaleItem(productId: 'p012', productName: 'ASUS VivoBook 15 Ryzen 7', qty: 1, price: 54999, barcode: '8901234000303'),
           SaleItem(productId: 'p013', productName: 'Acer Aspire Lite i3 12th Gen', qty: 2, price: 33999, barcode: '8901234000304'),
           SaleItem(productId: 'p025', productName: 'Lightning to USB-C Cable 1m', qty: 3, price: 499, barcode: '8901234000506')],
          3000, 'Card', 121494, 'Admin'),
      _s('INV-0972', 'Prakash Mobile Palace', '9876543218', d(3, 14, 30),
          [SaleItem(productId: 'p004', productName: 'Vivo Y28 5G', qty: 5, price: 12999, barcode: '8901234000104'),
           SaleItem(productId: 'p027', productName: 'Silicone Back Cover Samsung A15', qty: 5, price: 129, barcode: '8901234000508')],
          1000, 'UPI', 64640, 'Admin'),

      // ── 4 days ago ──
      _s('INV-0961', 'Anita Smart Devices', '9876543210', d(4, 11, 0),
          [SaleItem(productId: 'p033', productName: 'TP-Link Tapo C200 WiFi Camera', qty: 3, price: 2499, barcode: '8901234000604'),
           SaleItem(productId: 'p035', productName: 'Amazon Echo Dot 5th Gen', qty: 2, price: 4499, barcode: '8901234000606')],
          500, 'Cash', 16994, 'Admin'),
      _s('INV-0962', 'Rohit Tech Bazaar', '9876543220', d(4, 15, 0),
          [SaleItem(productId: 'p007', productName: 'Samsung Galaxy Tab A9 WiFi', qty: 2, price: 17999, barcode: '8901234000201'),
           SaleItem(productId: 'p023', productName: 'Ambrane 20000mAh Power Bank', qty: 2, price: 1999, barcode: '8901234000504')],
          1000, 'UPI', 37996, 'Admin'),

      // ── 5 days ago ──
      _s('INV-0951', 'Ramesh Electronics Depot', '9876543209', d(5, 9, 45),
          [SaleItem(productId: 'p006', productName: 'iQOO Z9 Lite 5G', qty: 6, price: 13499, barcode: '8901234000106')],
          2000, 'Card', 78994, 'Admin'),
      _s('INV-0952', 'Pooja Telecom', '9876543212', d(5, 13, 30),
          [SaleItem(productId: 'p018', productName: 'Noise Buds VS104 TWS Earbuds', qty: 10, price: 899, barcode: '8901234000405'),
           SaleItem(productId: 'p017', productName: 'boAt Airdopes 141 TWS Earbuds', qty: 10, price: 999, barcode: '8901234000404')],
          500, 'Cash', 18880, 'Admin'),

      // ── 6 days ago ──
      _s('INV-0941', 'Deepak Wholesale Mart', '9876543205', d(6, 10, 30),
          [SaleItem(productId: 'p008', productName: 'Redmi Pad SE 8.7 inch', qty: 3, price: 13499, barcode: '8901234000202'),
           SaleItem(productId: 'p009', productName: 'Realme Pad 2 4G', qty: 2, price: 19999, barcode: '8901234000203')],
          2000, 'UPI', 78493, 'Admin'),

      // ── 10 days ago (monthly only) ──
      _s('INV-0901', 'Suresh IT Solutions', '9876543207', d(10, 11, 0),
          [SaleItem(productId: 'p034', productName: 'Mi Smart Band 8 Activity Tracker', qty: 5, price: 3499, barcode: '8901234000605'),
           SaleItem(productId: 'p032', productName: 'Realme Watch S2 GPS', qty: 3, price: 4499, barcode: '8901234000603')],
          1000, 'UPI', 29988, 'Admin'),
      _s('INV-0902', 'Arjun Electronics', '9876543201', d(10, 14, 0),
          [SaleItem(productId: 'p037', productName: 'D-Link DIR-825 AC1200 Dual Band Router', qty: 4, price: 2799, barcode: '8901234000702'),
           SaleItem(productId: 'p040', productName: 'TP-Link RE330 AC1200 WiFi Extender', qty: 4, price: 1999, barcode: '8901234000705')],
          500, 'Card', 18692, 'Admin'),

      // ── 15 days ago (monthly only) ──
      _s('INV-0851', 'Sanjay Laptop World', '9876543214', d(15, 10, 0),
          [SaleItem(productId: 'p010', productName: 'HP 15s Ryzen 5 8GB 512GB', qty: 3, price: 44999, barcode: '8901234000301')],
          3000, 'Card', 131997, 'Admin'),
      _s('INV-0852', 'Nisha Smart Hub', '9876543217', d(15, 13, 30),
          [SaleItem(productId: 'p029', productName: 'Wireless Charging Pad 15W', qty: 6, price: 1299, barcode: '8901234000510'),
           SaleItem(productId: 'p020', productName: 'Anker 65W GaN USB-C Charger', qty: 4, price: 1899, barcode: '8901234000501')],
          0, 'Cash', 15390, 'Admin'),

      // ── 20 days ago (monthly only) ──
      _s('INV-0801', 'Ravi Tech Traders', '9876543203', d(20, 9, 0),
          [SaleItem(productId: 'p001', productName: 'Samsung Galaxy A15 5G', qty: 10, price: 13999, barcode: '8901234000101'),
           SaleItem(productId: 'p002', productName: 'Redmi 13C 4G (128GB)', qty: 8, price: 9499, barcode: '8901234000102')],
          5000, 'UPI', 210982, 'Admin'),
      _s('INV-0802', 'Vijay Computers & Accessories', '9876543211', d(20, 15, 0),
          [SaleItem(productId: 'p011', productName: 'Lenovo IdeaPad Slim 3 i5 13th Gen', qty: 3, price: 49999, barcode: '8901234000302')],
          5000, 'Card', 144997, 'Admin'),
    ]);

    // ── Wholesale Customers ───────────────────────────────────────────────
    _customers.addAll([
      Customer(id: 'c001', name: 'Arjun Electronics', phone: '9876543201',
          email: 'arjun.elec@gmail.com', address: 'Shop 12, Nehru Market, Pune',
          totalPurchase: 285000, totalPaid: 250000),
      Customer(id: 'c002', name: 'Priya Mobile Hub', phone: '9876543202',
          email: 'priyamobiles@yahoo.com', address: '45 MG Road, Bengaluru',
          totalPurchase: 192000, totalPaid: 192000),
      Customer(id: 'c003', name: 'Ravi Tech Traders', phone: '9876543203',
          email: 'ravitech@gmail.com', address: 'Plot 7, MIDC, Nashik',
          totalPurchase: 430000, totalPaid: 380000),
      Customer(id: 'c004', name: 'Sunita Gadget World', phone: '9876543204',
          email: 'sunitagadgets@gmail.com', address: '22 Station Road, Nagpur',
          totalPurchase: 118000, totalPaid: 100000),
      Customer(id: 'c005', name: 'Deepak Wholesale Mart', phone: '9876543205',
          email: 'deepakwholesale@outlook.com', address: 'Sector 18, Noida',
          totalPurchase: 560000, totalPaid: 560000),
      Customer(id: 'c006', name: 'Meena Digital Store', phone: '9876543206',
          email: 'meenadigital@gmail.com', address: '8 Laxmi Nagar, Delhi',
          totalPurchase: 74000, totalPaid: 60000),
      Customer(id: 'c007', name: 'Suresh IT Solutions', phone: '9876543207',
          email: 'sureshit@gmail.com', address: 'Baner Road, Pune',
          totalPurchase: 320000, totalPaid: 320000),
      Customer(id: 'c008', name: 'Kavita Mobile Zone', phone: '9876543208',
          email: 'kavitamobiles@gmail.com', address: 'FC Road, Pune',
          totalPurchase: 95000, totalPaid: 80000),
      Customer(id: 'c009', name: 'Ramesh Electronics Depot', phone: '9876543209',
          email: 'rameshelectronics@gmail.com', address: 'Sadar Bazar, Surat',
          totalPurchase: 245000, totalPaid: 245000),
      Customer(id: 'c010', name: 'Anita Smart Devices', phone: '9876543210',
          email: 'anitasmart@gmail.com', address: 'Koregaon Park, Pune',
          totalPurchase: 88000, totalPaid: 70000),
      Customer(id: 'c011', name: 'Vijay Computers & Accessories', phone: '9876543211',
          email: 'vijaycomp@gmail.com', address: 'Tilak Road, Pune',
          totalPurchase: 410000, totalPaid: 400000),
      Customer(id: 'c012', name: 'Pooja Telecom', phone: '9876543212',
          email: 'poojatelecom@yahoo.com', address: 'Camp Area, Pune',
          totalPurchase: 62000, totalPaid: 62000),
      Customer(id: 'c013', name: 'Nikhil Network Solutions', phone: '9876543213',
          email: 'nikhilnetwork@gmail.com', address: 'Viman Nagar, Pune',
          totalPurchase: 175000, totalPaid: 150000),
      Customer(id: 'c014', name: 'Sanjay Laptop World', phone: '9876543214',
          email: 'sanjaylaptop@gmail.com', address: 'JM Road, Pune',
          totalPurchase: 520000, totalPaid: 480000),
      Customer(id: 'c015', name: 'Rekha Audio & Vision', phone: '9876543215',
          email: 'rekhaaudio@gmail.com', address: 'Deccan Gymkhana, Pune',
          totalPurchase: 48000, totalPaid: 48000),
      Customer(id: 'c016', name: 'Amit Gadget Corner', phone: '9876543216',
          email: 'amitgadget@gmail.com', address: 'Kothrud, Pune',
          totalPurchase: 135000, totalPaid: 120000),
      Customer(id: 'c017', name: 'Nisha Smart Hub', phone: '9876543217',
          email: 'nishasmart@gmail.com', address: 'Hadapsar, Pune',
          totalPurchase: 92000, totalPaid: 92000),
      Customer(id: 'c018', name: 'Prakash Mobile Palace', phone: '9876543218',
          email: 'prakashmobile@gmail.com', address: 'Chinchwad, Pune',
          totalPurchase: 310000, totalPaid: 290000),
      Customer(id: 'c019', name: 'Geeta Electronics Hub', phone: '9876543219',
          email: 'geetaelec@gmail.com', address: 'Pimpri, Pune',
          totalPurchase: 58000, totalPaid: 40000),
      Customer(id: 'c020', name: 'Rohit Tech Bazaar', phone: '9876543220',
          email: 'rohittech@gmail.com', address: 'Wakad, Pune',
          totalPurchase: 220000, totalPaid: 220000),
    ]);
  }

  Future<void> checkBackendConnection() async {
    _isBackendConnected = await _api.checkHealth();
    if (_isBackendConnected) {
      await syncWithBackend();
    }
    notifyListeners();
  }

  Future<void> syncWithBackend() async {
    try {
      final res = await _api.get('/products');
      if (res != null && res['products'] is List) {
        _products.clear();
        for (var p in res['products']) {
          _products.add(Product.fromJson(p));
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  // --- Product & Inventory Management ---

  void addProduct(Product product) {
    _products.add(product);
    notifyListeners();
    if (_isBackendConnected) {
      _api.post('/products', product.toJson());
    }
  }

  void updateProduct(Product product) {
    final idx = _products.indexWhere((p) => p.id == product.id);
    if (idx >= 0) {
      _products[idx] = product;
      notifyListeners();
      if (_isBackendConnected) {
        _api.post('/products/${product.id}', product.toJson());
      }
    }
  }

  void deleteProduct(String id) {
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  Product? findProductByBarcode(String barcode) {
    final code = barcode.trim().toLowerCase();
    if (code.isEmpty) return null;
    try {
      return _products.firstWhere(
        (p) => p.barcode.toLowerCase() == code || p.id == code,
      );
    } catch (_) {
      return null;
    }
  }

  // Stock In operation with barcode support
  bool stockInProduct(String barcodeOrId, int quantityAdded, {String reason = 'Stock In'}) {
    if (quantityAdded <= 0) return false;
    final idx = _products.indexWhere((p) =>
        p.barcode.trim().toLowerCase() == barcodeOrId.trim().toLowerCase() ||
        p.id == barcodeOrId.trim());

    if (idx >= 0) {
      final p = _products[idx];
      _products[idx] = p.copyWith(quantity: p.quantity + quantityAdded);
      _stockLogs.insert(0, {
        'timestamp': DateTime.now(),
        'productId': p.id,
        'productName': p.name,
        'barcode': p.barcode,
        'quantityAdded': quantityAdded,
        'newQuantity': _products[idx].quantity,
        'reason': reason,
      });
      notifyListeners();
      return true;
    }
    return false;
  }

  // --- Sales Management ---

  void addSale(Sale sale) {
    // Record initial payment in history if amount > 0
    if (sale.paid > 0 && sale.paymentHistory.isEmpty) {
      sale.paymentHistory.add(SalePayment(
        amount: sale.paid,
        date: sale.date,
        method: sale.paymentMethod,
      ));
    }
    _sales.insert(0, sale);

    // Deduct stock for items sold
    for (var item in sale.items) {
      final idx = _products.indexWhere((p) =>
          (item.productId.isNotEmpty && p.id == item.productId) ||
          p.name.toLowerCase() == item.productName.toLowerCase());
      if (idx >= 0) {
        final current = _products[idx];
        final newQty = (current.quantity - item.qty).clamp(0, 99999);
        _products[idx] = current.copyWith(quantity: newQty);
      }
    }

    // Update customer stats
    final cIdx = _customers.indexWhere(
        (c) => c.name.toLowerCase() == sale.customerName.toLowerCase());
    if (cIdx >= 0) {
      final c = _customers[cIdx];
      c.totalPurchase += sale.total;
      c.totalPaid += sale.paid;
      c.transactions.insert(
        0,
        CustomerTransaction(
          id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
          date: 'Just now',
          amount: sale.total,
          description: 'Invoice #${sale.invoiceNo}',
          type: 'sale',
        ),
      );
    }

    notifyListeners();
    if (_isBackendConnected) {
      _api.post('/sales', sale.toJson());
    }
  }

  // Collect an additional payment against an existing sale.
  // Returns false if amount is invalid or sale not found.
  bool collectPayment(String invoiceNo, double amount, String method) {
    if (amount <= 0) return false;
    final idx = _sales.indexWhere((s) => s.invoiceNo == invoiceNo);
    if (idx < 0) return false;
    final sale = _sales[idx];
    final maxCollectable = sale.due;
    if (amount > maxCollectable + 0.001) return false; // prevent overpayment

    sale.paid += amount;
    sale.paymentHistory.add(SalePayment(
      amount: amount,
      date: DateTime.now(),
      method: method,
    ));

    // Update customer ledger
    final cIdx = _customers.indexWhere(
        (c) => c.name.toLowerCase() == sale.customerName.toLowerCase());
    if (cIdx >= 0) {
      _customers[cIdx].totalPaid += amount;
      _customers[cIdx].transactions.insert(
        0,
        CustomerTransaction(
          id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
          date: 'Just now',
          amount: amount,
          description: 'Payment for #${sale.invoiceNo} ($method)',
          type: 'payment',
        ),
      );
    }

    notifyListeners();
    return true;
  }

  // --- Customer Management ---

  void addCustomer(Customer customer) {
    _customers.add(customer);
    notifyListeners();
    if (_isBackendConnected) {
      _api.post('/customers', customer.toJson());
    }
  }

  void blacklistCustomer(String customerId) {
    final idx = _customers.indexWhere((c) => c.id == customerId);
    if (idx >= 0) {
      _customers[idx].isBlacklisted = true;
      notifyListeners();
    }
  }

  void unblacklistCustomer(String customerId) {
    final idx = _customers.indexWhere((c) => c.id == customerId);
    if (idx >= 0) {
      _customers[idx].isBlacklisted = false;
      notifyListeners();
    }
  }

  void recordCustomerPayment(String customerId, double amount) {
    final idx = _customers.indexWhere((c) => c.id == customerId);
    if (idx >= 0 && amount > 0) {
      final c = _customers[idx];
      c.totalPaid += amount;
      c.transactions.insert(
        0,
        CustomerTransaction(
          id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
          date: 'Today',
          amount: amount,
          description: 'Payment Received',
          type: 'payment',
        ),
      );
      notifyListeners();
    }
  }

  // Per-staff sales stats — computed from actual sales
  Map<String, dynamic> staffStats(String staffName) {
    final staffSales = _sales
        .where((s) => s.cashier.toLowerCase() == staffName.toLowerCase())
        .toList();
    double revenue = staffSales.fold(0.0, (s, sale) => s + sale.total);
    double profit = 0;
    for (final sale in staffSales) {
      for (final item in sale.items) {
        final p = _products.firstWhere(
          (prod) =>
              prod.name.toLowerCase() == item.productName.toLowerCase(),
          orElse: () => Product(
            id: '', name: '', category: '',
            purchasePrice: item.price * 0.7,
            sellingPrice: item.price,
            quantity: 0, minStock: 0, supplier: '',
          ),
        );
        profit += (item.price - p.purchasePrice) * item.qty;
      }
    }
    return {
      'salesCount': staffSales.length,
      'revenue': revenue,
      'profit': profit,
    };
  }

  // --- Calculated Statistics ---

  double get todaySalesTotal => _sales.fold(0.0, (sum, s) => sum + s.total);

  double get totalProfit {
    double total = 0.0;
    for (var sale in _sales) {
      for (var item in sale.items) {
        final p = _products.firstWhere(
          (prod) => prod.name.toLowerCase() == item.productName.toLowerCase(),
          orElse: () => Product(
            id: '',
            name: '',
            category: '',
            purchasePrice: item.price * 0.7,
            sellingPrice: item.price,
            quantity: 0,
            minStock: 0,
            supplier: '',
          ),
        );
        total += (item.price - p.purchasePrice) * item.qty;
      }
    }
    return total;
  }

  double get totalPendingDues =>
      _customers.fold(0.0, (sum, c) => sum + c.outstanding);

  List<Product> get lowStockProducts =>
      _products.where((p) => p.isLowStock).toList();
}
