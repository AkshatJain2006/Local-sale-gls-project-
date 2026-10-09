import 'package:flutter/material.dart';
import '../models/sale.dart';
import '../models/product.dart';
import '../models/customer.dart';
import '../services/data_service.dart';
import '../widgets/barcode_scanner_modal.dart';
import 'billing_screen.dart';

// Payment status badge helper
Widget _statusBadge(String status) {
  final color = status == 'Paid'
      ? Colors.green
      : status == 'Partially Paid'
          ? Colors.orange
          : Colors.red;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Text(status,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.bold, color: color)),
  );
}

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final DataService _dataService = DataService();
  final List<Map<String, dynamic>> _cart = [];
  String _selectedCategory = 'All';
  String? _selectedCustomer;
  String _selectedPaymentMethod = 'Cash';
  final TextEditingController _discountCtrl = TextEditingController(text: '0');
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _paidCtrl = TextEditingController();
  String _searchQuery = '';
  int? _selectedDiscountPct; // null = custom, else 5/10/15/20
  // 'full' | 'partial' | 'unpaid'
  String _paymentMode = 'full';

  @override
  void initState() {
    super.initState();
    _dataService.addListener(_refresh);
    // Don't pre-select — default is Walk-in Customer (null)
  }

  @override
  void dispose() {
    _dataService.removeListener(_refresh);
    _discountCtrl.dispose();
    _searchCtrl.dispose();
    _paidCtrl.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      // If the currently selected customer got blacklisted, reset to Walk-in
      if (_selectedCustomer != null) {
        final stillValid = _dataService.customers.any(
          (c) => c.name == _selectedCustomer && !c.isBlacklisted,
        );
        if (!stillValid) _selectedCustomer = null;
      }
      setState(() {});
    }
  }

  double get _subtotal => _cart.fold(
      0.0, (s, i) => s + (i['price'] as double) * (i['qty'] as int));
  double get _discount => double.tryParse(_discountCtrl.text) ?? 0.0;
  double get _total => (_subtotal - _discount).clamp(0, double.infinity);

  double get _amountPaid {
    if (_paymentMode == 'full') return _total;
    if (_paymentMode == 'unpaid') return 0.0;
    return (double.tryParse(_paidCtrl.text) ?? 0.0).clamp(0, _total);
  }

  void _applyDiscountPct(int? pct) {
    setState(() {
      _selectedDiscountPct = pct;
      if (pct != null) {
        final discountAmt = (_subtotal * pct / 100);
        _discountCtrl.text = discountAmt.toStringAsFixed(0);
      }
    });
  }

  void _addToCart(Product p) {
    if (p.quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ "${p.name}" is out of stock!'),
          backgroundColor: Colors.red.shade800,
        ),
      );
      return;
    }

    setState(() {
      final i = _cart.indexWhere((c) => c['productId'] == p.id);
      if (i >= 0) {
        final currentQty = _cart[i]['qty'] as int;
        if (currentQty < p.quantity) {
          _cart[i]['qty'] = currentQty + 1;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot add more than available stock (${p.quantity})'),
            ),
          );
        }
      } else {
        _cart.add({
          'productId': p.id,
          'name': p.name,
          'price': p.sellingPrice,
          'qty': 1,
          'barcode': p.barcode,
          'maxStock': p.quantity,
        });
      }
    });
  }

  void _updateQty(int index, int delta) {
    setState(() {
      final current = _cart[index]['qty'] as int;
      final max = _cart[index]['maxStock'] as int;
      final newQty = current + delta;
      if (newQty <= 0) {
        _cart.removeAt(index);
      } else if (newQty <= max) {
        _cart[index]['qty'] = newQty;
      }
    });
  }

  void _scanBarcodeForCart() async {
    final scanned = await BarcodeScannerModal.showCartScanner(context);
    if (scanned != null) {
      _addToCart(scanned);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade800,
            content: Text('Added "${scanned.name}" to cart via Barcode Scanner'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _completeSale() {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product to cart!')),
      );
      return;
    }

    final invoiceNumber =
        'INV${(_dataService.sales.length + 1).toString().padLeft(3, '0')}';

    final sale = Sale(
      invoiceNo: invoiceNumber,
      customerName: _selectedCustomer ?? 'Walk-in Customer',
      date: DateTime.now(),
      items: _cart
          .map((c) => SaleItem(
                productId: c['productId'] ?? '',
                productName: c['name'],
                qty: c['qty'] as int,
                price: c['price'] as double,
                barcode: c['barcode'] ?? '',
              ))
          .toList(),
      discount: _discount,
      tax: 0,
      paymentMethod: _selectedPaymentMethod,
      paid: _amountPaid,
    );

    _dataService.addSale(sale);

    setState(() {
      _cart.clear();
      _discountCtrl.text = '0';
      _paidCtrl.clear();
      _paymentMode = 'full';
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Sale Successful!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invoice #: ${sale.invoiceNo}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text('Customer: ${sale.customerName}'),
            Text('Payment Method: ${sale.paymentMethod}'),
            const Divider(height: 16),
            Text('Total Amount: ₹${sale.total.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.receipt_long),
            label: const Text('View Bill / Receipt'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BillingScreen(sale: sale)),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAddCustomerQuickDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Quick Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Customer Full Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'Phone Number', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                final newCust = Customer(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  totalPurchase: 0,
                  totalPaid: 0,
                );
                _dataService.addCustomer(newCust);
                setState(() => _selectedCustomer = newCust.name);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add & Select'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = _dataService.products.where((p) {
      final matchesSearch =
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.barcode.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;
      if (_selectedCategory == 'All') return true;
      return p.category == _selectedCategory;
    }).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Point of Sale (POS)'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.amberAccent,
            indicatorWeight: 3,
            tabs: [
              Tab(icon: Icon(Icons.point_of_sale), text: 'New Sale Register'),
              Tab(icon: Icon(Icons.history), text: 'Sales History'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              tooltip: 'Scan Barcode to Add Item',
              onPressed: _scanBarcodeForCart,
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Tab 1: New Sale Screen
            Row(
              children: [
                // Left Area: Product Selector Catalog
                Expanded(
                  flex: 6,
                  child: Column(
                    children: [
                      // Search & Barcode Scan Bar
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchCtrl,
                                onChanged: (v) =>
                                    setState(() => _searchQuery = v),
                                decoration: InputDecoration(
                                  hintText: 'Search product or barcode...',
                                  prefixIcon: const Icon(Icons.search),
                                  filled: true,
                                  fillColor: Colors.white,
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            IconButton.filled(
                              icon: const Icon(Icons.qr_code_scanner),
                              tooltip: 'Scan Item Barcode',
                              onPressed: _scanBarcodeForCart,
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFF1565C0),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Category Pills
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            'All',
                            ..._dataService.products
                                .map((p) => p.category)
                                .toSet()
                          ].map((cat) {
                            final isSel = _selectedCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(cat,
                                    style: const TextStyle(fontSize: 11)),
                                selected: isSel,
                                onSelected: (_) =>
                                    setState(() => _selectedCategory = cat),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Product Grid / List
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: products.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1.3,
                          ),
                          itemBuilder: (_, i) {
                            final p = products[i];
                            return InkWell(
                              onTap: () => _addToCart(p),
                              borderRadius: BorderRadius.circular(10),
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: p.quantity <= 0
                                        ? Colors.red.shade200
                                        : Colors.grey.shade200,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            p.category,
                                            style: const TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '₹${p.sellingPrice.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1565C0),
                                              fontSize: 14,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: p.quantity <= 0
                                                  ? Colors.red.shade100
                                                  : Colors.green.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${p.quantity} left',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: p.quantity <= 0
                                                    ? Colors.red
                                                    : Colors.green.shade800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Right Area: Shopping Cart & Checkout Panel
                Expanded(
                  flex: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                          left: BorderSide(color: Colors.grey.shade300)),
                    ),
                    child: Column(
                      children: [
                        // Cart Header
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          color: Colors.blue.shade50,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.shopping_cart,
                                      size: 18, color: Color(0xFF1565C0)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Cart (${_cart.length})',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1565C0),
                                    ),
                                  ),
                                ],
                              ),
                              if (_cart.isNotEmpty)
                                InkWell(
                                  onTap: () => setState(() => _cart.clear()),
                                  child: const Text('Clear',
                                      style: TextStyle(
                                          color: Colors.red, fontSize: 12)),
                                ),
                            ],
                          ),
                        ),

                        // Cart Items List
                        Expanded(
                          child: _cart.isEmpty
                              ? const Center(
                                  child: Text('Cart is empty.\nTap or scan products to add.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey)),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.all(8),
                                  itemCount: _cart.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 8),
                                  itemBuilder: (_, idx) {
                                    final item = _cart[idx];
                                    return Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(item['name'],
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 12)),
                                              Text(
                                                  '₹${(item['price'] as double).toStringAsFixed(0)} each',
                                                  style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 10)),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove_circle_outline,
                                                  size: 18),
                                              onPressed: () =>
                                                  _updateQty(idx, -1),
                                            ),
                                            Text('${item['qty']}',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            IconButton(
                                              icon: const Icon(Icons.add_circle_outline,
                                                  size: 18),
                                              onPressed: () =>
                                                  _updateQty(idx, 1),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          '₹${((item['price'] as double) * (item['qty'] as int)).toStringAsFixed(0)}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                        ),

                        // Checkout Summary & Action Controls
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            border: Border(
                                top: BorderSide(color: Colors.grey.shade200)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Customer Picker
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedCustomer,
                                      isDense: true,
                                      decoration: const InputDecoration(
                                        labelText: 'Customer',
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 8),
                                      ),
                                      items: [
                                        const DropdownMenuItem(
                                          value: null,
                                          child: Text('Walk-in Customer',
                                              style: TextStyle(fontSize: 12)),
                                        ),
                                        ..._dataService.customers
                                            .where((c) => !c.isBlacklisted)
                                            .map((c) => DropdownMenuItem(
                                                  value: c.name,
                                                  child: Text(c.name,
                                                      style: const TextStyle(
                                                          fontSize: 12)),
                                                )),
                                      ],
                                      onChanged: (v) =>
                                          setState(() => _selectedCustomer = v),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.person_add,
                                        size: 18, color: Color(0xFF1565C0)),
                                    onPressed: _showAddCustomerQuickDialog,
                                    tooltip: 'Add Customer',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),

                              // Payment Method
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 4,
                                runSpacing: 4,
                                children: [
                                  const Text('Payment: ',
                                      style: TextStyle(fontSize: 11)),
                                  ...['Cash', 'UPI', 'Card'].map((m) {
                                    final isSel = _selectedPaymentMethod == m;
                                    return ChoiceChip(
                                      label: Text(m,
                                          style:
                                              const TextStyle(fontSize: 10)),
                                      selected: isSel,
                                      onSelected: (_) => setState(
                                          () => _selectedPaymentMethod = m),
                                    );
                                  }),
                                ],
                              ),
                              // Discount % chips + custom amount
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Discount:',
                                      style: TextStyle(fontSize: 11)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      ...[5, 10, 15, 20].map((pct) {
                                        final isSel =
                                            _selectedDiscountPct == pct;
                                        final discAmt =
                                            _subtotal * pct / 100;
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                              right: 4),
                                          child: GestureDetector(
                                            onTap: () =>
                                                _applyDiscountPct(
                                                    isSel ? null : pct),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: isSel
                                                    ? const Color(
                                                        0xFF1565C0)
                                                    : Colors.grey.shade200,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        6),
                                              ),
                                              child: Column(
                                                children: [
                                                  Text('$pct%',
                                                      style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight
                                                                  .bold,
                                                          color: isSel
                                                              ? Colors
                                                                  .white
                                                              : Colors
                                                                  .black87)),
                                                  Text(
                                                      '₹${discAmt.toStringAsFixed(0)}',
                                                      style: TextStyle(
                                                          fontSize: 9,
                                                          color: isSel
                                                              ? Colors
                                                                  .white70
                                                              : Colors
                                                                  .grey)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                      Expanded(
                                        child: TextField(
                                          controller: _discountCtrl,
                                          keyboardType:
                                              TextInputType.number,
                                          onChanged: (_) => setState(() =>
                                              _selectedDiscountPct = null),
                                          decoration: const InputDecoration(
                                            hintText: '₹ Custom',
                                            isDense: true,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 6),
                                            border: OutlineInputBorder(),
                                          ),
                                          style: const TextStyle(
                                              fontSize: 11),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Subtotal:',
                                      style: TextStyle(fontSize: 11)),
                                  Text('₹${_subtotal.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11)),
                                ],
                              ),
                              const Divider(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('TOTAL:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Color(0xFF1565C0))),
                                  Text('₹${_total.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFF1565C0))),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Payment mode selector
                              const Text('Amount Received:',
                                  style: TextStyle(fontSize: 11)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  ...[
                                    ('full', 'Paid Full'),
                                    ('partial', 'Partial'),
                                    ('unpaid', 'Unpaid'),
                                  ].map((e) {
                                    final isSel = _paymentMode == e.$1;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: ChoiceChip(
                                        label: Text(e.$2,
                                            style: const TextStyle(fontSize: 10)),
                                        selected: isSel,
                                        selectedColor: e.$1 == 'unpaid'
                                            ? Colors.red.shade100
                                            : e.$1 == 'partial'
                                                ? Colors.orange.shade100
                                                : Colors.green.shade100,
                                        onSelected: (_) => setState(
                                            () => _paymentMode = e.$1),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                              if (_paymentMode == 'partial') ...[
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _paidCtrl,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    labelText: 'Amount Received (₹)',
                                    hintText: 'e.g. ${(_total * 0.5).toStringAsFixed(0)}',
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 8),
                                    border: const OutlineInputBorder(),
                                    suffixText:
                                        'Due: ₹${(_total - _amountPaid).clamp(0, double.infinity).toStringAsFixed(0)}',
                                    suffixStyle: const TextStyle(
                                        color: Colors.red,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                              const SizedBox(height: 8),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _cart.isEmpty ? null : _completeSale,
                                  icon: const Icon(Icons.check, size: 18),
                                  label: const Text('COMPLETE SALE'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00897B),
                                    foregroundColor: Colors.white,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Tab 2: Sales History List
            _buildSalesHistoryView(),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesHistoryView() {
    final sales = _dataService.sales;
    if (sales.isEmpty) {
      return const Center(child: Text('No historical sales recorded.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sales.length,
      itemBuilder: (_, i) {
        final s = sales[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade50,
              child: const Icon(Icons.receipt, color: Color(0xFF1565C0)),
            ),
            title: Text('${s.invoiceNo} — ${s.customerName}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Row(
              children: [
                Expanded(
                  child: Text(
                      '${s.date.day}/${s.date.month}/${s.date.year} • ${s.paymentMethod} • ₹${s.total.toStringAsFixed(0)}'),
                ),
                _statusBadge(s.paymentStatus),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Purchased Items:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    ...s.items.map((it) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${it.productName} × ${it.qty}'),
                              Text('₹${it.total.toStringAsFixed(2)}'),
                            ],
                          ),
                        )),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Paid: ₹${s.paid.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.green)),
                        Text('Due: ₹${s.due.toStringAsFixed(2)}',
                            style: TextStyle(
                                color: s.due > 0 ? Colors.red : Colors.green)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.receipt_long, size: 16),
                            label: const Text('View Bill'),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => BillingScreen(sale: s)),
                            ),
                          ),
                        ),
                        if (s.due > 0) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.payments, size: 16),
                              label: const Text('Collect'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00897B),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () =>
                                  _showCollectPaymentDialog(s),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCollectPaymentDialog(Sale sale) {
    final amtCtrl = TextEditingController();
    String method = sale.paymentMethod;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Collect Payment — ${sale.invoiceNo}'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customer: ${sale.customerName}'),
                Text('Total: ₹${sale.total.toStringAsFixed(2)}'),
                Text('Already Paid: ₹${sale.paid.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.green)),
                Text(
                  'Balance Due: ₹${sale.due.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: amtCtrl,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Amount Received (₹)',
                    hintText: sale.due.toStringAsFixed(0),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) {
                    final amt = double.tryParse(v ?? '');
                    if (amt == null || amt <= 0) return 'Enter a valid amount';
                    if (amt > sale.due + 0.001) {
                      return 'Cannot exceed balance due (₹${sale.due.toStringAsFixed(2)})';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  children: ['Cash', 'UPI', 'Card'].map((m) {
                    return ChoiceChip(
                      label: Text(m, style: const TextStyle(fontSize: 11)),
                      selected: method == m,
                      onSelected: (_) => setDlg(() => method = m),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final amt = double.parse(amtCtrl.text.trim());
                final ok =
                    _dataService.collectPayment(sale.invoiceNo, amt, method);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  backgroundColor:
                      ok ? Colors.green.shade800 : Colors.red.shade800,
                  content: Text(ok
                      ? '₹${amt.toStringAsFixed(0)} collected for ${sale.invoiceNo}'
                      : 'Payment failed — please try again'),
                ));
              },
              child: const Text('Confirm Payment'),
            ),
          ],
        ),
      ),
    );
  }
}

