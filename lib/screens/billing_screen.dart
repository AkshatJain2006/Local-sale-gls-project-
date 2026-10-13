import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/sale.dart';
import '../services/data_service.dart';
import '../services/settings_service.dart';

class BillingScreen extends StatelessWidget {
  final Sale? sale;
  const BillingScreen({super.key, this.sale});

  // ── PDF generation ────────────────────────────────────────────────────────

  Future<Uint8List> _buildPdf(Sale s, SettingsService settings) async {
    final doc = pw.Document();

    // Load logo
    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/logo.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {}

    final statusColor = s.paymentStatus == 'Paid'
        ? PdfColors.green700
        : s.paymentStatus == 'Partially Paid'
            ? PdfColors.orange700
            : PdfColors.red700;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────
            pw.Center(
              child: pw.Column(
                children: [
                  if (logoImage != null) pw.Image(logoImage, width: 60, height: 60),
                  if (logoImage != null) pw.SizedBox(height: 6),
                  pw.Text(
                    settings.businessName.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  if (settings.businessAddress.isNotEmpty)
                    pw.Text(settings.businessAddress,
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey700)),
                  if (settings.businessPhone.isNotEmpty)
                    pw.Text('Ph: ${settings.businessPhone}',
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey700)),
                  if (settings.gstin.isNotEmpty)
                    pw.Text('GSTIN: ${settings.gstin}',
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey700)),
                ],
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Divider(color: PdfColors.blueGrey200),
            pw.SizedBox(height: 8),

            // ── Invoice meta + customer ──────────────────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Invoice No: ${s.invoiceNo}',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.Text(
                        'Date: ${s.date.day.toString().padLeft(2, '0')}/${s.date.month.toString().padLeft(2, '0')}/${s.date.year}  ${s.date.hour.toString().padLeft(2, '0')}:${s.date.minute.toString().padLeft(2, '0')}',
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey700)),
                    pw.Text('Payment: ${s.paymentMethod}',
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey700)),
                    pw.SizedBox(height: 4),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: pw.BoxDecoration(
                        color: statusColor,
                        borderRadius:
                            const pw.BorderRadius.all(pw.Radius.circular(4)),
                      ),
                      child: pw.Text(
                        s.paymentStatus,
                        style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white),
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Billed To:',
                        style: const pw.TextStyle(
                            fontSize: 10, color: PdfColors.grey600)),
                    pw.Text(s.customerName,
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    if (s.customerPhone.isNotEmpty)
                      pw.Text(s.customerPhone,
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // ── Items table ──────────────────────────────────────────
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.blueGrey100),
              columnWidths: {
                0: const pw.FlexColumnWidth(5),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(3),
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration:
                      const pw.BoxDecoration(color: PdfColors.blue900),
                  children: [
                    _cell('Item', bold: true, light: true),
                    _cell('Qty', bold: true, light: true, center: true),
                    _cell('Rate', bold: true, light: true, right: true),
                    _cell('Amount', bold: true, light: true, right: true),
                  ],
                ),
                // Item rows
                ...s.items.map((item) => pw.TableRow(children: [
                      _cell(item.productName),
                      _cell('${item.qty}', center: true),
                      _cell('Rs.${item.price.toStringAsFixed(0)}', right: true),
                      _cell('Rs.${item.total.toStringAsFixed(2)}', right: true),
                    ])),
              ],
            ),
            pw.SizedBox(height: 12),

            // ── Totals ───────────────────────────────────────────────
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.SizedBox(
                width: 220,
                child: pw.Column(
                  children: [
                    _totalRow('Subtotal',
                        'Rs.${s.subtotal.toStringAsFixed(2)}'),
                    if (s.discount > 0)
                      _totalRow('Discount',
                          '-Rs.${s.discount.toStringAsFixed(2)}',
                          color: PdfColors.green700),
                    pw.Divider(color: PdfColors.blueGrey200),
                    _totalRow(
                        'GRAND TOTAL', 'Rs.${s.total.toStringAsFixed(2)}',
                        bold: true,
                        fontSize: 14,
                        color: PdfColors.blue900),
                    _totalRow(
                        'Amount Paid', 'Rs.${s.paid.toStringAsFixed(2)}',
                        color: PdfColors.green700),
                    _totalRow(
                      'Balance Due',
                      s.due > 0
                          ? 'Rs.${s.due.toStringAsFixed(2)}'
                          : 'Rs.0.00 (PAID)',
                      bold: s.due > 0,
                      color: s.due > 0 ? PdfColors.red700 : PdfColors.green700,
                    ),
                  ],
                ),
              ),
            ),

            // ── Payment history ──────────────────────────────────────
            if (s.paymentHistory.isNotEmpty) ...[
              pw.SizedBox(height: 14),
              pw.Text('Payment History',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 11)),
              pw.SizedBox(height: 4),
              ...s.paymentHistory.map((p) => pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        '${p.date.day}/${p.date.month}/${p.date.year}  ${p.date.hour.toString().padLeft(2, '0')}:${p.date.minute.toString().padLeft(2, '0')}  —  ${p.method}',
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey700),
                      ),
                      pw.Text('Rs.${p.amount.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.green700)),
                    ],
                  )),
            ],

            pw.Spacer(),

            // ── Footer ───────────────────────────────────────────────
            pw.Divider(color: PdfColors.blueGrey200),
            pw.Center(
              child: pw.Text(
                settings.receiptFooter,
                style: pw.TextStyle(
                    fontSize: 10,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey600),
              ),
            ),
          ],
        ),
      ),
    );

    return doc.save();
  }

  // ── Share PDF ─────────────────────────────────────────────────────────────

  Future<void> _sharePdf(BuildContext context, Sale s,
      SettingsService settings) async {
    try {
      final bytes = await _buildPdf(s, settings);
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'Invoice_${s.invoiceNo}.pdf',
        subject:
            '${settings.businessName} — Invoice ${s.invoiceNo} | Total: Rs.${s.total.toStringAsFixed(0)} | Paid: Rs.${s.paid.toStringAsFixed(0)}${s.due > 0 ? ' | Due: Rs.${s.due.toStringAsFixed(0)}' : ''}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not generate PDF: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  // ── Print PDF ─────────────────────────────────────────────────────────────

  Future<void> _printPdf(BuildContext context, Sale s,
      SettingsService settings) async {
    try {
      final bytes = await _buildPdf(s, settings);
      await Printing.layoutPdf(onLayout: (_) => bytes);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not print PDF: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  pw.Widget _cell(String text,
      {bool bold = false,
      bool light = false,
      bool center = false,
      bool right = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        textAlign: center
            ? pw.TextAlign.center
            : right
                ? pw.TextAlign.right
                : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: light ? PdfColors.white : PdfColors.black,
        ),
      ),
    );
  }

  pw.Widget _totalRow(String label, String value,
      {bool bold = false,
      double fontSize = 10,
      PdfColor color = PdfColors.black}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: fontSize,
                  fontWeight:
                      bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: fontSize,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final data = DataService();
    final settings = SettingsService();
    final currentSale = sale ?? (data.sales.isNotEmpty ? data.sales.first : null);

    if (currentSale == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invoice')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long_outlined, size: 56, color: Colors.grey),
              SizedBox(height: 12),
              Text('No invoice selected.',
                  style: TextStyle(color: Colors.grey, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    final dateStr =
        '${currentSale.date.day.toString().padLeft(2, '0')}/${currentSale.date.month.toString().padLeft(2, '0')}/${currentSale.date.year}  ${currentSale.date.hour.toString().padLeft(2, '0')}:${currentSale.date.minute.toString().padLeft(2, '0')}';

    final statusColor = currentSale.paymentStatus == 'Paid'
        ? Colors.green
        : currentSale.paymentStatus == 'Partially Paid'
            ? Colors.orange
            : Colors.red;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text('Invoice #${currentSale.invoiceNo}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Share PDF Receipt',
            onPressed: () => _sharePdf(context, currentSale, settings),
          ),
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Print Receipt',
            onPressed: () => _printPdf(context, currentSale, settings),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Center(
                      child: Column(
                        children: [
                          Image.asset('assets/logo.png', width: 64, height: 64),
                          const SizedBox(height: 8),
                          Text(
                            settings.businessName.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: Color(0xFF0D47A1),
                            ),
                          ),
                          if (settings.businessAddress.isNotEmpty)
                            Text(settings.businessAddress,
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                          if (settings.businessPhone.isNotEmpty)
                            Text('Ph: ${settings.businessPhone}',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                          if (settings.gstin.isNotEmpty)
                            Text('GSTIN: ${settings.gstin}',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(thickness: 1.2),

                    // Invoice meta
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Invoice No: ${currentSale.invoiceNo}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              const SizedBox(height: 2),
                              Text('Date: $dateStr',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.black54)),
                              Text('Payment: ${currentSale.paymentMethod}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.black54)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: statusColor.withOpacity(0.4)),
                                ),
                                child: Text(currentSale.paymentStatus,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Billed To:',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey)),
                              Text(currentSale.customerName,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              if (currentSale.customerPhone.isNotEmpty)
                                Text(currentSale.customerPhone,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black54)),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Items table header
                    Container(
                      decoration: BoxDecoration(
                          color: Colors.blue.shade900,
                          borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 7),
                      child: const Row(children: [
                        Expanded(
                            flex: 5,
                            child: Text('Item',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.white))),
                        Expanded(
                            flex: 2,
                            child: Text('Qty',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.white))),
                        Expanded(
                            flex: 2,
                            child: Text('Rate',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.white))),
                        Expanded(
                            flex: 3,
                            child: Text('Amount',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.white))),
                      ]),
                    ),
                    const SizedBox(height: 4),

                    ...currentSale.items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          child: Row(children: [
                            Expanded(
                                flex: 5,
                                child: Text(item.productName,
                                    style: const TextStyle(fontSize: 13))),
                            Expanded(
                                flex: 2,
                                child: Text('${item.qty}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 13))),
                            Expanded(
                                flex: 2,
                                child: Text(
                                    '₹${item.price.toStringAsFixed(0)}',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(fontSize: 13))),
                            Expanded(
                                flex: 3,
                                child: Text(
                                    '₹${item.total.toStringAsFixed(2)}',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600))),
                          ]),
                        )),

                    const Divider(thickness: 1.2, height: 24),

                    _calcRow('Subtotal',
                        '₹${currentSale.subtotal.toStringAsFixed(2)}'),
                    if (currentSale.discount > 0)
                      _calcRow('Discount',
                          '-₹${currentSale.discount.toStringAsFixed(2)}',
                          color: Colors.green),
                    const Divider(height: 16),
                    _calcRow('GRAND TOTAL',
                        '₹${currentSale.total.toStringAsFixed(2)}',
                        isBold: true,
                        fontSize: 18,
                        color: const Color(0xFF1565C0)),
                    const SizedBox(height: 4),
                    _calcRow('Amount Paid',
                        '₹${currentSale.paid.toStringAsFixed(2)}',
                        color: Colors.green.shade700),
                    currentSale.due > 0
                        ? _calcRow('Balance Due',
                            '₹${currentSale.due.toStringAsFixed(2)}',
                            isBold: true, color: Colors.red.shade700)
                        : _calcRow(
                            'Balance Due', '₹0.00 (PAID IN FULL)',
                            color: Colors.green),

                    // Payment history
                    if (currentSale.paymentHistory.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('Payment History',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      ...currentSale.paymentHistory.map((p) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${p.date.day}/${p.date.month}/${p.date.year} ${p.date.hour.toString().padLeft(2, '0')}:${p.date.minute.toString().padLeft(2, '0')} — ${p.method}',
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.black54),
                                ),
                                Text('₹${p.amount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green)),
                              ],
                            ),
                          )),
                    ],

                    const SizedBox(height: 20),

                    Center(
                      child: Text(settings.receiptFooter,
                          style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey)),
                    ),

                    const SizedBox(height: 24),

                    // Action buttons
                    Row(children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _sharePdf(context, currentSale, settings),
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Share PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.check),
                          label: const Text('Done'),
                          style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12)),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _calcRow(String title, String val,
      {bool isBold = false, double fontSize = 13, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: fontSize,
                  fontWeight:
                      isBold ? FontWeight.bold : FontWeight.normal,
                  color: color ?? Colors.black87)),
          Text(val,
              style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: color ?? Colors.black87)),
        ],
      ),
    );
  }
}
