import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import '../services/data_service.dart';
import '../services/api_service.dart';
import '../services/settings_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  final String role;
  const SettingsScreen({super.key, this.role = 'admin'});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ApiService _api = ApiService();
  final DataService _data = DataService();
  final SettingsService _settings = SettingsService();

  late TextEditingController _urlCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _gstinCtrl;
  late TextEditingController _footerCtrl;

  bool _isTestingConnection = false;
  bool _isSavingBiz = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: _api.baseUrl);
    _nameCtrl = TextEditingController(text: _settings.businessName);
    _addressCtrl = TextEditingController(text: _settings.businessAddress);
    _phoneCtrl = TextEditingController(text: _settings.businessPhone);
    _emailCtrl = TextEditingController(text: _settings.businessEmail);
    _gstinCtrl = TextEditingController(text: _settings.gstin);
    _footerCtrl = TextEditingController(text: _settings.receiptFooter);
    // Rebuild preview as user types
    _nameCtrl.addListener(() => setState(() {}));
    _gstinCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _gstinCtrl.dispose();
    _footerCtrl.dispose();
    super.dispose();
  }

  // ── Save business details ─────────────────────────────────────────────────

  Future<void> _saveBusinessDetails() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Business name cannot be empty.'),
        backgroundColor: Colors.red,
      ));
      return;
    }
    setState(() => _isSavingBiz = true);
    await _settings.save(
      name: _nameCtrl.text,
      address: _addressCtrl.text,
      phone: _phoneCtrl.text,
      email: _emailCtrl.text,
      gstin: _gstinCtrl.text,
      footer: _footerCtrl.text,
    );
    if (!mounted) return;
    setState(() => _isSavingBiz = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Business details updated. All future receipts will use the new details.'),
      backgroundColor: Colors.green,
    ));
  }

  void _resetBusinessFields() => setState(() {
        _nameCtrl.text = _settings.businessName;
        _addressCtrl.text = _settings.businessAddress;
        _phoneCtrl.text = _settings.businessPhone;
        _emailCtrl.text = _settings.businessEmail;
        _gstinCtrl.text = _settings.gstin;
        _footerCtrl.text = _settings.receiptFooter;
      });

  // ── Backend connection ────────────────────────────────────────────────────

  Future<void> _testBackendConnection() async {
    setState(() => _isTestingConnection = true);
    _api.baseUrl = _urlCtrl.text.trim();
    final ok = await _api.checkHealth();
    await _data.checkBackendConnection();
    if (!mounted) return;
    setState(() => _isTestingConnection = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: ok ? Colors.green.shade800 : Colors.red.shade800,
      content: Text(ok
          ? 'Connected to backend at ${_api.baseUrl}'
          : 'Could not connect to ${_api.baseUrl}. Running in offline mode.'),
    ));
  }

  // ── Export to Excel ───────────────────────────────────────────────────────

  Future<void> _exportToExcel() async {
    setState(() => _isExporting = true);
    try {
      final workbook = xlsio.Workbook();

      _buildSalesSheet(workbook);
      _buildInventorySheet(workbook);
      _buildCustomersSheet(workbook);

      final bytes = workbook.saveAsStream();
      workbook.dispose();

      final dir = await getTemporaryDirectory();
      final now = DateTime.now();
      final fileName =
          'LocalSale_Export_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.xlsx';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);

      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
        subject: '${_settings.businessName} — Data Export $fileName',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Export failed: $e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _buildSalesSheet(xlsio.Workbook wb) {
    final sheet = wb.worksheets[0];
    sheet.name = 'Sales';

    // Header row
    final headers = [
      'Invoice No', 'Date', 'Customer', 'Phone', 'Payment Method',
      'Subtotal', 'Discount', 'Total', 'Paid', 'Balance Due', 'Status', 'Cashier'
    ];
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.getRangeByIndex(1, i + 1);
      cell.setText(headers[i]);
      cell.cellStyle.bold = true;
      cell.cellStyle.backColor = '#1565C0';
      cell.cellStyle.fontColor = '#FFFFFF';
    }

    final sales = _data.sales;
    for (var r = 0; r < sales.length; r++) {
      final s = sales[r];
      final row = r + 2;
      sheet.getRangeByIndex(row, 1).setText(s.invoiceNo);
      sheet.getRangeByIndex(row, 2).setText(
          '${s.date.day.toString().padLeft(2, '0')}/${s.date.month.toString().padLeft(2, '0')}/${s.date.year}');
      sheet.getRangeByIndex(row, 3).setText(s.customerName);
      sheet.getRangeByIndex(row, 4).setText(s.customerPhone);
      sheet.getRangeByIndex(row, 5).setText(s.paymentMethod);
      sheet.getRangeByIndex(row, 6).setNumber(s.subtotal);
      sheet.getRangeByIndex(row, 7).setNumber(s.discount);
      sheet.getRangeByIndex(row, 8).setNumber(s.total);
      sheet.getRangeByIndex(row, 9).setNumber(s.paid);
      sheet.getRangeByIndex(row, 10).setNumber(s.due);
      sheet.getRangeByIndex(row, 11).setText(s.paymentStatus);
      sheet.getRangeByIndex(row, 12).setText(s.cashier);

      // Colour-code status
      final statusCell = sheet.getRangeByIndex(row, 11);
      if (s.paymentStatus == 'Paid') {
        statusCell.cellStyle.fontColor = '#2E7D32';
      } else if (s.paymentStatus == 'Partially Paid') {
        statusCell.cellStyle.fontColor = '#E65100';
      } else {
        statusCell.cellStyle.fontColor = '#C62828';
      }
    }

    // Auto-fit columns
    for (var i = 1; i <= headers.length; i++) {
      sheet.autoFitColumn(i);
    }
  }

  void _buildInventorySheet(xlsio.Workbook wb) {
    final sheet = wb.worksheets.addWithName('Inventory');

    final headers = [
      'ID', 'Name', 'Category', 'Barcode', 'Supplier',
      'Purchase Price', 'Selling Price', 'Quantity', 'Min Stock', 'Status'
    ];
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.getRangeByIndex(1, i + 1);
      cell.setText(headers[i]);
      cell.cellStyle.bold = true;
      cell.cellStyle.backColor = '#00897B';
      cell.cellStyle.fontColor = '#FFFFFF';
    }

    final products = _data.products;
    for (var r = 0; r < products.length; r++) {
      final p = products[r];
      final row = r + 2;
      sheet.getRangeByIndex(row, 1).setText(p.id);
      sheet.getRangeByIndex(row, 2).setText(p.name);
      sheet.getRangeByIndex(row, 3).setText(p.category);
      sheet.getRangeByIndex(row, 4).setText(p.barcode);
      sheet.getRangeByIndex(row, 5).setText(p.supplier);
      sheet.getRangeByIndex(row, 6).setNumber(p.purchasePrice);
      sheet.getRangeByIndex(row, 7).setNumber(p.sellingPrice);
      sheet.getRangeByIndex(row, 8).setNumber(p.quantity.toDouble());
      sheet.getRangeByIndex(row, 9).setNumber(p.minStock.toDouble());
      final statusCell = sheet.getRangeByIndex(row, 10);
      if (p.quantity <= 0) {
        statusCell.setText('Out of Stock');
        statusCell.cellStyle.fontColor = '#C62828';
      } else if (p.isLowStock) {
        statusCell.setText('Low Stock');
        statusCell.cellStyle.fontColor = '#E65100';
      } else {
        statusCell.setText('In Stock');
        statusCell.cellStyle.fontColor = '#2E7D32';
      }
    }

    for (var i = 1; i <= headers.length; i++) {
      sheet.autoFitColumn(i);
    }
  }

  void _buildCustomersSheet(xlsio.Workbook wb) {
    final sheet = wb.worksheets.addWithName('Customers');

    final headers = [
      'Name', 'Phone', 'Email', 'Address',
      'Total Purchase', 'Total Paid', 'Outstanding', 'Blacklisted'
    ];
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.getRangeByIndex(1, i + 1);
      cell.setText(headers[i]);
      cell.cellStyle.bold = true;
      cell.cellStyle.backColor = '#6A1B9A';
      cell.cellStyle.fontColor = '#FFFFFF';
    }

    final customers = _data.customers;
    for (var r = 0; r < customers.length; r++) {
      final c = customers[r];
      final row = r + 2;
      sheet.getRangeByIndex(row, 1).setText(c.name);
      sheet.getRangeByIndex(row, 2).setText(c.phone);
      sheet.getRangeByIndex(row, 3).setText(c.email);
      sheet.getRangeByIndex(row, 4).setText(c.address);
      sheet.getRangeByIndex(row, 5).setNumber(c.totalPurchase);
      sheet.getRangeByIndex(row, 6).setNumber(c.totalPaid);
      sheet.getRangeByIndex(row, 7).setNumber(c.outstanding);
      sheet.getRangeByIndex(row, 8).setText(c.isBlacklisted ? 'Yes' : 'No');
      if (c.outstanding > 0) {
        sheet.getRangeByIndex(row, 7).cellStyle.fontColor = '#C62828';
      }
    }

    for (var i = 1; i <= headers.length; i++) {
      sheet.autoFitColumn(i);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final previewName = _nameCtrl.text.trim().isEmpty
        ? 'LOCAL SALE STORE'
        : _nameCtrl.text.trim().toUpperCase();
    final previewGstin = _gstinCtrl.text.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('System Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Business Details ────────────────────────────────────────
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.store, color: Color(0xFF1565C0)),
                    SizedBox(width: 8),
                    Text('Business Details',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 4),
                  const Text(
                    'Appears on all receipts and bills. Changes take effect immediately after saving.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 14),

                  // Live preview strip
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D47A1).withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(previewName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF0D47A1))),
                        if (previewGstin.isNotEmpty)
                          Text('GSTIN: $previewGstin',
                              style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        const Text('Receipt Preview',
                            style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  _field(_nameCtrl, 'Business Name *', Icons.storefront),
                  const SizedBox(height: 10),
                  _field(_gstinCtrl, 'GSTIN (optional)', Icons.receipt_long),
                  const SizedBox(height: 10),
                  _field(_addressCtrl, 'Address (optional)', Icons.location_on),
                  const SizedBox(height: 10),
                  _field(_phoneCtrl, 'Phone Number (optional)', Icons.phone,
                      type: TextInputType.phone),
                  const SizedBox(height: 10),
                  _field(_emailCtrl, 'Email (optional)', Icons.email,
                      type: TextInputType.emailAddress),
                  const SizedBox(height: 10),
                  _field(_footerCtrl, 'Receipt Footer Message', Icons.message),
                  const SizedBox(height: 16),

                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _resetBusinessFields,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _isSavingBiz ? null : _saveBusinessDetails,
                        icon: _isSavingBiz
                            ? const SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check_circle, size: 18),
                        label: const Text('Update & Save'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Export Data ─────────────────────────────────────────────
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.table_chart, color: Color(0xFF2E7D32)),
                    SizedBox(width: 8),
                    Text('Export Data to Excel',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 6),
                  const Text(
                    'Exports all Sales, Inventory, and Customer data into a single .xlsx file with colour-coded sheets. Share via WhatsApp, email, or save to device.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  // Summary chips
                  Wrap(
                    spacing: 8,
                    children: [
                      _chip('${_data.sales.length} Sales', Icons.receipt_long, Colors.blue),
                      _chip('${_data.products.length} Products', Icons.inventory_2, Colors.teal),
                      _chip('${_data.customers.length} Customers', Icons.people, Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isExporting ? null : _exportToExcel,
                      icon: _isExporting
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.download),
                      label: Text(_isExporting ? 'Generating Excel...' : 'Export & Share Excel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Backend API ─────────────────────────────────────────────
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.cloud_sync, color: Color(0xFF1565C0)),
                    SizedBox(width: 8),
                    Text('Backend API Integration',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 8),
                  const Text(
                    'Configure the Node.js Express REST API server endpoint for cloud syncing.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _urlCtrl,
                    decoration: InputDecoration(
                      labelText: 'Backend Base URL',
                      prefixIcon: const Icon(Icons.link),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isTestingConnection ? null : _testBackendConnection,
                      icon: _isTestingConnection
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.cable),
                      label: const Text('Test Connection & Sync Now'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Barcode Scanner ─────────────────────────────────────────
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.qr_code_scanner, color: Color(0xFF00897B)),
                    SizedBox(width: 8),
                    Text('Barcode Scanner Hardware',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ]),
                  SizedBox(height: 8),
                  Text(
                    '• Supported: EAN-13, EAN-8, UPC-A, Code-128, QR Code\n'
                    '• Laser line guidance & optical autofocus active\n'
                    '• Continuous mobile stock-in mode enabled',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── System Info & Sign Out ──────────────────────────────────
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('App Version'),
                  trailing: Text('v2.0.0 (Pro POS Edition)',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Sign Out',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  onTap: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        isDense: true,
      ),
    );
  }

  Widget _chip(String label, IconData icon, MaterialColor color) {
    return Chip(
      avatar: Icon(icon, size: 14, color: color.shade700),
      label: Text(label, style: TextStyle(fontSize: 11, color: color.shade700)),
      backgroundColor: color.shade50,
      side: BorderSide(color: color.shade200),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
