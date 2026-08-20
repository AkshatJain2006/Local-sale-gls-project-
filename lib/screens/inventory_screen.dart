import 'package:flutter/material.dart';
import '../models/product.dart';

class InventoryScreen extends StatefulWidget {
  final String role;
  const InventoryScreen({super.key, this.role = 'staff'});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  bool get _isAdmin => widget.role == 'admin';

  final List<Product> _products = [
    Product(id: '1', name: 'Titan Watch', category: 'Electronics', purchasePrice: 1800, sellingPrice: 2500, quantity: 3, minStock: 5, supplier: 'Titan Co.'),
    Product(id: '2', name: 'Leather Belt', category: 'Accessories', purchasePrice: 300, sellingPrice: 500, quantity: 2, minStock: 5, supplier: 'Fashion Hub'),
    Product(id: '3', name: 'Perfume', category: 'Cosmetics', purchasePrice: 600, sellingPrice: 950, quantity: 4, minStock: 5, supplier: 'Scent World'),
    Product(id: '4', name: 'Sunglasses', category: 'Accessories', purchasePrice: 400, sellingPrice: 750, quantity: 18, minStock: 5, supplier: 'Vision Plus'),
    Product(id: '5', name: 'Wallet', category: 'Accessories', purchasePrice: 250, sellingPrice: 450, quantity: 22, minStock: 5, supplier: 'Fashion Hub'),
  ];

  String _search = '';

  List<Product> get _filtered => _products
      .where((p) =>
          p.name.toLowerCase().contains(_search.toLowerCase()) ||
          p.category.toLowerCase().contains(_search.toLowerCase()))
      .toList();

  void _showDialog({Product? product, int? index}) {
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final catCtrl = TextEditingController(text: product?.category ?? '');
    final ppCtrl = TextEditingController(
        text: product?.purchasePrice.toStringAsFixed(0) ?? '');
    final spCtrl = TextEditingController(
        text: product?.sellingPrice.toStringAsFixed(0) ?? '');
    final qtyCtrl =
        TextEditingController(text: product?.quantity.toString() ?? '');
    final minCtrl =
        TextEditingController(text: product?.minStock.toString() ?? '5');
    final supCtrl =
        TextEditingController(text: product?.supplier ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(product == null ? 'Add Product' : 'Edit Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _f(nameCtrl, 'Product Name'),
              _f(catCtrl, 'Category'),
              _f(ppCtrl, 'Purchase Price', num: true),
              _f(spCtrl, 'Selling Price', num: true),
              _f(qtyCtrl, 'Quantity', num: true),
              _f(minCtrl, 'Min Stock', num: true),
              _f(supCtrl, 'Supplier'),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              final p = Product(
                id: product?.id ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameCtrl.text.trim(),
                category: catCtrl.text.trim(),
                purchasePrice:
                    double.tryParse(ppCtrl.text) ?? 0,
                sellingPrice:
                    double.tryParse(spCtrl.text) ?? 0,
                quantity: int.tryParse(qtyCtrl.text) ?? 0,
                minStock: int.tryParse(minCtrl.text) ?? 5,
                supplier: supCtrl.text.trim(),
              );
              setState(() {
                if (product == null) {
                  _products.add(p);
                } else if (index != null) {
                  // find in original list by id
                  final origIdx = _products
                      .indexWhere((x) => x.id == product.id);
                  if (origIdx >= 0) _products[origIdx] = p;
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _f(TextEditingController c, String label,
      {bool num = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        keyboardType:
            num ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            isDense: true),
      ),
    );
  }

  void _delete(Product p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Delete "${p.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() =>
                  _products.removeWhere((x) => x.id == p.id));
              Navigator.pop(context);
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('No products found'))
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final p = list[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(p.name,
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight:
                                                FontWeight.bold)),
                                  ),
                                  if (p.isLowStock)
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2),
                                      decoration: BoxDecoration(
                                          color: Colors.red.shade100,
                                          borderRadius:
                                              BorderRadius.circular(
                                                  8)),
                                      child: const Text('Low Stock',
                                          style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 11)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(p.category,
                                  style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12)),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                      '₹${p.sellingPrice.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15)),
                                  const SizedBox(width: 16),
                                  Text('Stock: ${p.quantity}',
                                      style: TextStyle(
                                          color: p.isLowStock
                                              ? Colors.red
                                              : Colors.grey)),
                                  if (_isAdmin) ...[
                                    const SizedBox(width: 16),
                                    Text(
                                        'Buy: ₹${p.purchasePrice.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12)),
                                  ],
                                ],
                              ),
                              if (_isAdmin) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          _showDialog(product: p),
                                      icon: const Icon(Icons.edit,
                                          size: 16),
                                      label: const Text('Edit'),
                                      style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets
                                              .symmetric(
                                              horizontal: 12,
                                              vertical: 4)),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: () => _delete(p),
                                      icon: const Icon(Icons.delete,
                                          size: 16),
                                      label: const Text('Delete'),
                                      style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: const BorderSide(
                                              color: Colors.red),
                                          padding: const EdgeInsets
                                              .symmetric(
                                              horizontal: 12,
                                              vertical: 4)),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
              backgroundColor: const Color(0xFF1565C0),
            )
          : null,
    );
  }
}
