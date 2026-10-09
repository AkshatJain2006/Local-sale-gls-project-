import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/product.dart';
import '../services/data_service.dart';

enum ScannerMode { stockIn, selectForCart, scanForBarcode }

class BarcodeScannerModal extends StatefulWidget {
  final ScannerMode mode;
  final Function(Product product)? onProductScanned;
  final Function(String barcode)? onBarcodeScanned;
  // Called when "not found → create product" is chosen; passes barcode string
  final Function(String barcode)? onCreateProduct;

  const BarcodeScannerModal({
    super.key,
    this.mode = ScannerMode.stockIn,
    this.onProductScanned,
    this.onBarcodeScanned,
    this.onCreateProduct,
  });

  /// Stock-in mode: scan → show stock-in dialog
  static Future<void> showStockInScanner(BuildContext context,
      {Function(String barcode)? onCreateProduct}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BarcodeScannerModal(
        mode: ScannerMode.stockIn,
        onCreateProduct: onCreateProduct,
      ),
    );
  }

  /// POS cart mode: scan → return Product
  static Future<Product?> showCartScanner(BuildContext context) async {
    Product? selected;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BarcodeScannerModal(
        mode: ScannerMode.selectForCart,
        onProductScanned: (p) => selected = p,
      ),
    );
    return selected;
  }

  /// Raw barcode mode: scan → return barcode string (for form prefill)
  static Future<String?> scanRawBarcode(BuildContext context) async {
    String? result;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BarcodeScannerModal(
        mode: ScannerMode.scanForBarcode,
        onBarcodeScanned: (b) => result = b,
      ),
    );
    return result;
  }

  @override
  State<BarcodeScannerModal> createState() => _BarcodeScannerModalState();
}

class _BarcodeScannerModalState extends State<BarcodeScannerModal> {
  final MobileScannerController _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  final TextEditingController _manualCodeCtrl = TextEditingController();
  final DataService _dataService = DataService();

  bool _isManualInput = false;
  bool _torchOn = false;
  bool _detected = false;

  @override
  void dispose() {
    _cameraController.dispose();
    _manualCodeCtrl.dispose();
    super.dispose();
  }

  void _handleBarcodeDetected(String barcode) {
    if (_detected) return;
    final code = barcode.trim();
    if (code.isEmpty) return;
    _detected = true;

    // Raw barcode mode — just return the string
    if (widget.mode == ScannerMode.scanForBarcode) {
      widget.onBarcodeScanned?.call(code);
      Navigator.pop(context, code);
      return;
    }

    final product = _dataService.findProductByBarcode(code);

    if (widget.mode == ScannerMode.selectForCart) {
      if (product != null) {
        widget.onProductScanned?.call(product);
        Navigator.pop(context, product);
      } else {
        _showProductNotFoundDialog(code);
      }
      return;
    }

    // stockIn mode
    if (product != null) {
      _showStockInDialog(product);
    } else {
      _showProductNotFoundDialog(code);
    }
  }

  void _resetDetection() => setState(() => _detected = false);

  void _showStockInDialog(Product product) {
    int addQty = 5;
    final qtyCtrl = TextEditingController(text: '$addQty');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.inventory_2, color: Color(0xFF1565C0)),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Stock In Product',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Barcode: ${product.barcode.isNotEmpty ? product.barcode : product.id}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue.shade900,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Stock: ${product.quantity}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: product.isLowStock
                                    ? Colors.red
                                    : Colors.green.shade700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Quick Select Units:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [1, 5, 10, 25].map((q) {
                    final isSelected = addQty == q;
                    return InkWell(
                      onTap: () => setDlg(() {
                        addQty = q;
                        qtyCtrl.text = '$q';
                      }),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1565C0)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '+$q',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final parsed = int.tryParse(v);
                    if (parsed != null && parsed > 0) {
                      setDlg(() => addQty = parsed);
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Quantity to Add',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.add_box),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _resetDetection();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Confirm Stock In'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final qty = int.tryParse(qtyCtrl.text) ?? addQty;
                if (qty > 0) {
                  final newQty = product.quantity + qty;
                  _dataService.stockInProduct(
                    product.barcode.isNotEmpty ? product.barcode : product.id,
                    qty,
                    reason: 'Barcode Scan Stock-In',
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.green.shade800,
                      content: Text(
                          '✅ Added +$qty to "${product.name}". New Stock: $newQty'),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  _resetDetection();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showProductNotFoundDialog(String barcode) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Barcode Not Found'),
          ],
        ),
        content: Text(
          'No product matches barcode:\n"$barcode"\n\nWould you like to create a new product with this barcode?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resetDetection();
            },
            child: const Text('Dismiss'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_box),
            label: const Text('Create Product'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // close scanner
              widget.onCreateProduct?.call(barcode);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.mode == ScannerMode.stockIn
        ? 'Scan to Stock In'
        : widget.mode == ScannerMode.selectForCart
            ? 'Scan Item for Cart'
            : 'Scan Barcode';

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Container(
                  width: 44, height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.qr_code_scanner, color: Colors.cyanAccent),
                        const SizedBox(width: 8),
                        Text(title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _torchOn ? Icons.flash_on : Icons.flash_off,
                            color: _torchOn ? Colors.amber : Colors.white70,
                          ),
                          onPressed: () {
                            _cameraController.toggleTorch();
                            setState(() => _torchOn = !_torchOn);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.flip_camera_android,
                              color: Colors.white70),
                          onPressed: () => _cameraController.switchCamera(),
                        ),
                        IconButton(
                          icon: Icon(
                            _isManualInput ? Icons.camera_alt : Icons.keyboard,
                            color: Colors.cyanAccent,
                          ),
                          onPressed: () =>
                              setState(() => _isManualInput = !_isManualInput),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: _isManualInput ? _buildManualInput() : _buildCameraView(),
          ),

          // Quick-tap chips for any existing products
          if (_dataService.products.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Tap a product to stock in:',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _dataService.products.map((p) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          avatar: const Icon(Icons.qr_code,
                              size: 16, color: Colors.white),
                          label: Text(
                            p.name.split(' ').first,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.white),
                          ),
                          backgroundColor: const Color(0xFF334155),
                          side: BorderSide.none,
                          onPressed: () => _handleBarcodeDetected(
                              p.barcode.isNotEmpty ? p.barcode : p.id),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    return ClipRRect(
      child: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: _cameraController,
            onDetect: (capture) {
              final barcode = capture.barcodes.firstOrNull;
              if (barcode?.rawValue != null) {
                _handleBarcodeDetected(barcode!.rawValue!);
              }
            },
          ),
          Container(
            width: 260, height: 260,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.cyanAccent, width: 2.5),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          ..._buildCornerMarkers(),
          Positioned(
            bottom: 30,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Point camera at barcode to scan',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCornerMarkers() {
    const size = 20.0;
    const thickness = 3.0;
    const color = Colors.cyanAccent;
    const offset = 115.0;
    return [
      Positioned(top: offset, left: offset,
          child: Container(width: size, height: size,
              decoration: const BoxDecoration(border: Border(
                  top: BorderSide(color: color, width: thickness),
                  left: BorderSide(color: color, width: thickness))))),
      Positioned(top: offset, right: offset,
          child: Container(width: size, height: size,
              decoration: const BoxDecoration(border: Border(
                  top: BorderSide(color: color, width: thickness),
                  right: BorderSide(color: color, width: thickness))))),
      Positioned(bottom: offset, left: offset,
          child: Container(width: size, height: size,
              decoration: const BoxDecoration(border: Border(
                  bottom: BorderSide(color: color, width: thickness),
                  left: BorderSide(color: color, width: thickness))))),
      Positioned(bottom: offset, right: offset,
          child: Container(width: size, height: size,
              decoration: const BoxDecoration(border: Border(
                  bottom: BorderSide(color: color, width: thickness),
                  right: BorderSide(color: color, width: thickness))))),
    ];
  }

  Widget _buildManualInput() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.keyboard, color: Colors.cyanAccent, size: 48),
          const SizedBox(height: 16),
          const Text('Enter barcode manually',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(
            controller: _manualCodeCtrl,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Type barcode or SKU...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(Icons.qr_code, color: Colors.cyanAccent),
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.cyanAccent),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.white24),
              ),
            ),
            onSubmitted: _handleBarcodeDetected,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('Search Product'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _handleBarcodeDetected(_manualCodeCtrl.text),
            ),
          ),
        ],
      ),
    );
  }
}
