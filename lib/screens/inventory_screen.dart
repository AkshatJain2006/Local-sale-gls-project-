import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/data_service.dart';
import '../widgets/barcode_scanner_modal.dart';

class InventoryScreen extends StatefulWidget {
  final String role;
  const InventoryScreen({super.key, this.role = 'staff'});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final DataService _dataService = DataService();
  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';
  String _selectedCategory = 'All';

  bool get _isAdmin => widget.role.toLowerCase() == 'admin';

  @override
  void initState() {
    super.initState();
    _dataService.addListener(_refresh);
  }

  @override
  void dispose() {
    _dataService.removeListener(_refresh);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  List<Product> get _filteredProducts {
    return _dataService.products.where((p) {
      final q = _search.toLowerCase();
      final matchesSearch = p.name.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          p.barcode.toLowerCase().contains(q) ||
          p.supplier.toLowerCase().contains(q);
      if (!matchesSearch) return false;
      if (_selectedCategory == 'All') return true;
      if (_selectedCategory == 'Low Stock') return p.isLowStock;
      return p.category == _selectedCategory;
    }).toList();
  }

  List<String> get _categories {
    final cats = _dataService.products.map((p) => p.category).toSet().toList()
      ..sort();
    return ['All', 'Low Stock', ...cats];
  }

  // Check if barcode is already used by another product
  bool _barcodeExists(String barcode, {String? excludeId}) {
    if (barcode.trim().isEmpty) return false;
    return _dataService.products.any((p) =>
        p.barcode.trim().toLowerCase() == barcode.trim().toLowerCase() &&
        p.id != excludeId);
  }

  void _showProductForm({Product? product, String? prefillBarcode}) {
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final catCtrl =
        TextEditingController(text: product?.category ?? 'General');
    final ppCtrl = TextEditingController(
        text: product != null ? product.purchasePrice.toStringAsFixed(0) : '');
    final spCtrl = TextEditingController(
        text: product != null ? product.sellingPrice.toStringAsFixed(0) : '');
    // When editing, qty field shows current stock but is read-only
    // (use Stock In to change qty — prevents accidental resets)
    final qtyCtrl = TextEditingController(
        text: product != null ? '${product.quantity}' : '10');
    final minCtrl = TextEditingController(
        text: product != null ? '${product.minStock}' : '5');
    final supCtrl = TextEditingController(text: product?.supplier ?? '');
    final barcodeCtrl = TextEditingController(
        text: prefillBarcode ??
            product?.barcode ??
            '890${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}');

    String? barcodeError;
    final isEdit = product != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlg) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            isEdit ? 'Edit Product' : 'Add New Product',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _field(nameCtrl, 'Product Name *',
                      icon: Icons.shopping_bag_outlined),
                  _field(catCtrl, 'Category',
                      icon: Icons.category_outlined),

                  // Barcode row with scan button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: barcodeCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Barcode / SKU',
                                  prefixIcon:
                                      const Icon(Icons.qr_code, size: 18),
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                  errorText: barcodeError,
                                ),
                                onChanged: (_) {
                                  if (barcodeError != null) {
                                    setDlg(() => barcodeError = null);
                                  }
                                },
                              ),
                            ),
                            // Scan barcode button
                            IconButton(
                              icon: const Icon(Icons.qr_code_scanner,
                                  color: Color(0xFF1565C0)),
                              tooltip: 'Scan Barcode',
                              onPressed: () async {
                                final scanned =
                                    await BarcodeScannerModal.scanRawBarcode(
                                        context);
                                if (scanned != null && scanned.isNotEmpty) {
                                  // Check duplicate
                                  if (_barcodeExists(scanned,
                                      excludeId: product?.id)) {
                                    final existing =
                                        _dataService.findProductByBarcode(
                                            scanned);
                                    if (context.mounted) {
                                      setDlg(() {
                                        barcodeCtrl.text = scanned;
                                        barcodeError =
                                            'Already used by "${existing?.name}"';
                                      });
                                    }
                                  } else {
                                    setDlg(() {
                                      barcodeCtrl.text = scanned;
                                      barcodeError = null;
                                    });
                                  }
                                }
                              },
                            ),
                            // Generate random barcode
                            IconButton(
                              icon: const Icon(Icons.refresh,
                                  color: Colors.grey),
                              tooltip: 'Generate Barcode',
                              onPressed: () => setDlg(() {
                                barcodeCtrl.text =
                                    '890${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
                                barcodeError = null;
                              }),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Row(
                    children: [
                      Expanded(
                          child: _field(ppCtrl, 'Purchase Price (₹)',
                              num: true, icon: Icons.money_off)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _field(spCtrl, 'Selling Price (₹)',
                              num: true, icon: Icons.attach_money)),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: qtyCtrl,
                          keyboardType: TextInputType.number,
                          // Read-only when editing — stock changes via Stock In
                          readOnly: isEdit,
                          decoration: InputDecoration(
                            labelText: isEdit
                                ? 'Current Stock (use Stock In to change)'
                                : 'Initial Qty',
                            prefixIcon:
                                const Icon(Icons.storage, size: 18),
                            border: const OutlineInputBorder(),
                            isDense: true,
                            filled: isEdit,
                            fillColor: isEdit
                                ? Colors.grey.shade100
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _field(minCtrl, 'Min Alert Qty',
                              num: true, icon: Icons.warning_amber)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _field(supCtrl, 'Supplier / Vendor',
                      icon: Icons.business),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Product name is required')),
                  );
                  return;
                }
                final barcode = barcodeCtrl.text.trim();
                if (_barcodeExists(barcode, excludeId: product?.id)) {
                  final existing =
                      _dataService.findProductByBarcode(barcode);
                  setDlg(() => barcodeError =
                      'Already used by "${existing?.name}"');
                  return;
                }

                final p = Product(
                  id: product?.id ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameCtrl.text.trim(),
                  category: catCtrl.text.trim().isEmpty
                      ? 'General'
                      : catCtrl.text.trim(),
                  purchasePrice:
                      double.tryParse(ppCtrl.text) ?? 0.0,
                  sellingPrice:
                      double.tryParse(spCtrl.text) ?? 0.0,
                  // Preserve existing stock when editing
                  quantity: isEdit
                      ? product!.quantity
                      : (int.tryParse(qtyCtrl.text) ?? 0),
                  minStock: int.tryParse(minCtrl.text) ?? 5,
                  supplier: supCtrl.text.trim(),
                  barcode: barcode,
                );

                if (isEdit) {
                  _dataService.updateProduct(p);
                } else {
                  _dataService.addProduct(p);
                }

                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Product "${p.name}" saved!'),
                    backgroundColor: Colors.green.shade800,
                  ),
                );
              },
              child: const Text('Save Product'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
      {bool num = false, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        keyboardType: num ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, size: 18) : null,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  void _quickStockIn(Product p) {
    int addUnits = 5;
    final ctrl = TextEditingController(text: '$addUnits');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlg) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text('Stock In: ${p.name}',
              style: const TextStyle(fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: p.isLowStock
                      ? Colors.red.shade50
                      : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Current Stock',
                        style: TextStyle(
                            color: Colors.grey.shade700, fontSize: 13)),
                    Text('${p.quantity} units',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: p.isLowStock
                                ? Colors.red
                                : Colors.green.shade800)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [2, 5, 10, 20].map((q) {
                  return ChoiceChip(
                    label: Text('+$q'),
                    selected: addUnits == q,
                    onSelected: (selected) {
                      if (selected) {
                        setDlg(() {
                          addUnits = q;
                          ctrl.text = '$q';
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  final parsed = int.tryParse(v);
                  if (parsed != null && parsed > 0) {
                    setDlg(() => addUnits = parsed);
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Units to Add',
                  border: OutlineInputBorder(),
                  isDense: true,
                  prefixIcon: Icon(Icons.add_box, size: 18),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white),
              onPressed: () {
                final qty = int.tryParse(ctrl.text) ?? addUnits;
                if (qty > 0) {
                  final newQty = p.quantity + qty;
                  _dataService.stockInProduct(p.id, qty);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.green.shade800,
                      content: Text(
                          '✅ +$qty added to "${p.name}". New stock: $newQty'),
                    ),
                  );
                }
              },
              child: const Text('Add Stock'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Product p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Remove "${p.name}" from inventory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _dataService.deleteProduct(p.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted "${p.name}"')),
              );
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _launchStockInScanner() {
    BarcodeScannerModal.showStockInScanner(
      context,
      onCreateProduct: (barcode) {
        // Barcode not found → open Add Product form with barcode prefilled
        _showProductForm(prefillBarcode: barcode);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = _filteredProducts;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory & Stock'),
        actions: [
          // Scan to Stock In / Add Product
          TextButton.icon(
            onPressed: _launchStockInScanner,
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
            label: const Text('Scan',
                style: TextStyle(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search by name, category, barcode...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
            ),
          ),

          // Category filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(cat,
                        style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? const Color(0xFF1565C0)
                                : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal)),
                    selected: isSelected,
                    selectedColor: Colors.blue.shade100,
                    checkmarkColor: const Color(0xFF1565C0),
                    onSelected: (_) =>
                        setState(() => _selectedCategory = cat),
                  ),
                );
              }).toList(),
            ),
          ),

          // Stats row
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: Row(
              children: [
                Text(
                  '${products.length} product${products.length == 1 ? '' : 's'}',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade600),
                ),
                const Spacer(),
                if (_dataService.lowStockProducts.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      '⚠️ ${_dataService.lowStockProducts.length} low stock',
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.red,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Product list / grid
          Expanded(
            child: products.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text('No products found.',
                            style:
                                TextStyle(color: Colors.grey.shade600)),
                        if (_isAdmin) ...[
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => _showProductForm(),
                            icon: const Icon(Icons.add),
                            label: const Text('Add First Product'),
                          ),
                        ],
                      ],
                    ),
                  )
                : isTablet
                    ? GridView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: products.length,
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: screenWidth >= 900 ? 3 : 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.55,
                        ),
                        itemBuilder: (_, i) =>
                            _buildProductCard(products[i], isTablet: true),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        itemCount: products.length,
                        itemBuilder: (_, i) =>
                            _buildProductCard(products[i]),
                      ),
          ),
        ],
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showProductForm(),
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildProductCard(Product p, {bool isTablet = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: p.isLowStock ? Colors.red.shade300 : Colors.grey.shade200,
          width: p.isLowStock ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Name + LOW STOCK badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    p.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (p.isLowStock)
                  Container(
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('LOW',
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 4),

            // Category + Barcode chips
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _chip(p.category, Colors.grey.shade200, Colors.black87),
                if (p.barcode.isNotEmpty)
                  _chip('📦 ${p.barcode}', Colors.blue.shade50,
                      const Color(0xFF1565C0)),
                if (p.supplier.isNotEmpty)
                  _chip(p.supplier, Colors.purple.shade50,
                      Colors.purple.shade700),
              ],
            ),

            const Divider(height: 14),

            // Price + Stock row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹${p.sellingPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                    if (_isAdmin)
                      Text(
                        'Cost: ₹${p.purchasePrice.toStringAsFixed(0)}  •  ${p.profitMargin.toStringAsFixed(0)}% margin',
                        style: const TextStyle(
                            fontSize: 10, color: Colors.grey),
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${p.quantity} units',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: p.isLowStock
                            ? Colors.red
                            : Colors.green.shade800,
                      ),
                    ),
                    Text(
                      'Min: ${p.minStock}',
                      style: const TextStyle(
                          fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _quickStockIn(p),
                    icon: const Icon(Icons.add_box, size: 15),
                    label: const Text('Stock In',
                        style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1565C0),
                      side: const BorderSide(color: Color(0xFF1565C0)),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      minimumSize: const Size(0, 34),
                    ),
                  ),
                ),
                if (_isAdmin) ...[
                  const SizedBox(width: 6),
                  SizedBox(
                    height: 34,
                    child: OutlinedButton(
                      onPressed: () => _showProductForm(product: p),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10),
                        minimumSize: const Size(0, 34),
                      ),
                      child: const Icon(Icons.edit, size: 16),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    height: 34,
                    child: OutlinedButton(
                      onPressed: () => _confirmDelete(p),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10),
                        minimumSize: const Size(0, 34),
                      ),
                      child: const Icon(Icons.delete_outline, size: 16),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, color: fg, fontWeight: FontWeight.w500)),
    );
  }
}
