import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/customer.dart';
import 'api_service.dart';

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

  // Staff
  final List<Map<String, dynamic>> _staff = [];
  List<Map<String, dynamic>> get staff => List.unmodifiable(_staff);

  // Stock In History Log
  final List<Map<String, dynamic>> _stockLogs = [];
  List<Map<String, dynamic>> get stockLogs => List.unmodifiable(_stockLogs);

  void _initializeDefaultData() {
    // Production: no mock data. All data is entered by the user.
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

  // --- Staff Management ---

  void addStaff(String name, String role, String email) {
    _staff.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'role': role,
      'email': email,
      'active': true,
      'salesCount': 0,
    });
    notifyListeners();
  }

  void toggleStaffStatus(int index) {
    if (index >= 0 && index < _staff.length) {
      _staff[index]['active'] = !(_staff[index]['active'] as bool);
      notifyListeners();
    }
  }

  void deleteStaff(int index) {
    if (index >= 0 && index < _staff.length) {
      _staff.removeAt(index);
      notifyListeners();
    }
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
