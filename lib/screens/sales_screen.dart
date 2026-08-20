import 'package:flutter/material.dart';
import '../models/sale.dart';
import '../widgets/sale_card.dart';
import 'billing_screen.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});
  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final List<Sale> _sales = [
    Sale(
      invoiceNo: 'INV001',
      customerName: 'Rahul Sharma',
      date: DateTime.now().subtract(const Duration(days: 1)),
      items: [
        SaleItem(productName: 'Titan Watch', qty: 1, price: 2500),
        SaleItem(productName: 'Leather Belt', qty: 2, price: 500),
      ],
      discount: 100,
      tax: 612,
      paymentMethod: 'Cash',
      paid: 3000,
    ),
    Sale(
      invoiceNo: 'INV002',
      customerName: 'Amit Patel',
      date: DateTime.now(),
      items: [SaleItem(productName: 'Sunglasses', qty: 1, price: 750)],
      discount: 0,
      tax: 135,
      paymentMethod: 'UPI',
      paid: 885,
    ),
  ];

  final List<Map<String, dynamic>> _cart = [];
  String _customer = 'Rahul Sharma';
  String _payment = 'Cash';
  final _discountCtrl = TextEditingController(text: '0');

  final _customers = ['Rahul Sharma', 'Amit Patel', 'Vijay Singh', 'Priya Mehta'];
  final _payments = ['Cash', 'UPI', 'Card', 'Credit'];
  final _products = [
    {'name': 'Titan Watch', 'price': 2500.0},
    {'name': 'Leather Belt', 'price': 500.0},
    {'name': 'Perfume', 'price': 950.0},
    {'name': 'Sunglasses', 'price': 750.0},
    {'name': 'Wallet', 'price': 450.0},
  ];

  double get _subtotal => _cart.fold(
      0.0, (s, i) => s + (i['price'] as double) * (i['qty'] as int));
  double get _discount =>
      double.tryParse(_discountCtrl.text) ?? 0;
  double get _taxable => (_subtotal - _discount).clamp(0, double.infinity);
  double get _tax => _taxable * 0.18;
  double get _total => _taxable + _tax;

  void _addToCart(Map<String, dynamic> p) {
    setState(() {
      final i = _cart.indexWhere((c) => c['name'] == p['name']);
      if (i >= 0) {
        _cart[i] = {..._cart[i], 'qty': (_cart[i]['qty'] as int) + 1};
      } else {
        _cart.add({'name': p['name'], 'price': p['price'], 'qty': 1});
      }
    });
  }

  void _removeFromCart(int index) {
    setState(() => _cart.removeAt(index));
  }

  void _completeSale() {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add at least one product')));
      return;
    }
    final sale = Sale(
      invoiceNo:
          'INV${(_sales.length + 1).toString().padLeft(3, '0')}',
      customerName: _customer,
      date: DateTime.now(),
      items: _cart
          .map((c) => SaleItem(
              productName: c['name'],
              qty: c['qty'] as int,
              price: c['price'] as double))
          .toList(),
      discount: _discount,
      tax: _tax,
      paymentMethod: _payment,
      paid: _total,
    );

    setState(() {
      _sales.insert(0, sale);
      _cart.clear();
      _discountCtrl.text = '0';
    });

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('✅ Sale Completed!'),
        content: Text(
            'Invoice ${sale.invoiceNo}\nCustomer: ${sale.customerName}\nTotal: ₹${sale.total.toStringAsFixed(2)}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => BillingScreen(sale: sale)));
            },
            child: const Text('View Bill'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _discountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sales'),
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            indicatorColor: Colors.white,
            tabs: [Tab(text: 'New Sale'), Tab(text: 'History')],
          ),
        ),
        body: TabBarView(children: [_newSaleTab(), _historyTab()]),
      ),
    );
  }

  Widget _newSaleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Customer',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _customer,
            decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                isDense: true),
            items: _customers
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _customer = v!),
          ),
          const SizedBox(height: 16),
          const Text('Products',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _products
                .map((p) => ActionChip(
                      avatar: const Icon(Icons.add, size: 16),
                      label: Text(
                          '${p['name']} ₹${(p['price'] as double).toStringAsFixed(0)}'),
                      onPressed: () => _addToCart(p),
                    ))
                .toList(),
          ),
          if (_cart.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Cart',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _cart.length,
              itemBuilder: (_, i) {
                final item = _cart[i];
                return ListTile(
                  dense: true,
                  title: Text(item['name'] as String),
                  subtitle: Text(
                      '${item['qty']} × ₹${(item['price'] as double).toStringAsFixed(0)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                          '₹${((item['qty'] as int) * (item['price'] as double)).toStringAsFixed(0)}'),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red, size: 20),
                        onPressed: () => _removeFromCart(i),
                      ),
                    ],
                  ),
                );
              },
            ),
            const Divider(),
            Row(
              children: [
                const Text('Discount (₹):',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 12),
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _discountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        isDense: true, border: OutlineInputBorder()),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _summaryRow('Subtotal', '₹${_subtotal.toStringAsFixed(2)}'),
            _summaryRow('Discount',
                '-₹${_discount.toStringAsFixed(2)}'),
            _summaryRow('Tax (18%)', '₹${_tax.toStringAsFixed(2)}'),
            const Divider(),
            _summaryRow('TOTAL', '₹${_total.toStringAsFixed(2)}',
                bold: true),
            const SizedBox(height: 16),
            const Text('Payment Method',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _payment,
              decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  isDense: true),
              items: _payments
                  .map((m) =>
                      DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) => setState(() => _payment = v!),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _completeSale,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('COMPLETE SALE',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _historyTab() {
    if (_sales.isEmpty) {
      return const Center(child: Text('No sales yet'));
    }
    return ListView.builder(
      itemCount: _sales.length,
      itemBuilder: (_, i) => GestureDetector(
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => BillingScreen(sale: _sales[i]))),
        child: SaleCard(sale: _sales[i]),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    final style = TextStyle(
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        fontSize: bold ? 16 : 14);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}
