import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/sale.dart';
import '../services/data_service.dart';
import '../services/settings_service.dart';

class BillingScreen extends StatelessWidget {
  final Sale? sale;
  const BillingScreen({super.key, this.sale});

  Future<void> _shareOnWhatsApp(BuildContext context, Sale s, SettingsService settings) async {
    final lines = s.items
        .map((i) => '  • ${i.productName} x${i.qty} = ₹${i.total.toStringAsFixed(0)}')
        .join('\n');
    final statusLine = s.paymentStatus == 'Paid'
        ? '✅ PAID IN FULL'
        : s.paymentStatus == 'Partially Paid'
            ? '⚠️ Partially Paid — Balance Due: ₹${s.due.toStringAsFixed(0)}'
            : '❌ UNPAID — Balance Due: ₹${s.due.toStringAsFixed(0)}';

    final msg = '''
🧾 *${settings.businessName}*
${settings.businessAddress.isNotEmpty ? settings.businessAddress + '\n' : ''}${settings.businessPhone.isNotEmpty ? 'Ph: ${settings.businessPhone}\n' : ''}
Invoice: ${s.invoiceNo}
Date: ${s.date.day}/${s.date.month}/${s.date.year}
Customer: ${s.customerName}${s.customerPhone.isNotEmpty ? ' | ${s.customerPhone}' : ''}

$lines

Subtotal: ₹${s.subtotal.toStringAsFixed(0)}${s.discount > 0 ? '\nDiscount: -₹${s.discount.toStringAsFixed(0)}' : ''}
*TOTAL: ₹${s.total.toStringAsFixed(0)}*
Paid: ₹${s.paid.toStringAsFixed(0)}
$statusLine

${settings.receiptFooter}'''
        .trim();

    final encoded = Uri.encodeComponent(msg);
    final uri = Uri.parse('https://wa.me/?text=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp not installed on this device.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = DataService();
    final settings = SettingsService();
    final currentSale = sale ??
        (data.sales.isNotEmpty ? data.sales.first : null);

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
        '${currentSale.date.day.toString().padLeft(2, '0')}/${currentSale.date.month.toString().padLeft(2, '0')}/${currentSale.date.year} ${currentSale.date.hour.toString().padLeft(2, '0')}:${currentSale.date.minute.toString().padLeft(2, '0')}';

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
            icon: const Icon(Icons.share),
            tooltip: 'Share on WhatsApp',
            onPressed: () => _shareOnWhatsApp(context, currentSale, settings),
          ),
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Print Thermal Receipt',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Sending Invoice ${currentSale.invoiceNo} to Thermal Bluetooth Printer...'),
                  backgroundColor: const Color(0xFF1565C0),
                ),
              );
            },
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
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header — uses SettingsService
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.storefront_rounded,
                                size: 38, color: Color(0xFF1565C0)),
                          ),
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

                    // Invoice meta + payment status badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Invoice No: ${currentSale.invoiceNo}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
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
                                child: Text(
                                  currentSale.paymentStatus,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor),
                                ),
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
                              Text(
                                currentSale.customerName,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
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

                    // Items Table header
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      child: const Row(
                        children: [
                          Expanded(
                              flex: 5,
                              child: Text('Item',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12))),
                          Expanded(
                              flex: 2,
                              child: Text('Qty',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12))),
                          Expanded(
                              flex: 2,
                              child: Text('Rate',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12))),
                          Expanded(
                              flex: 3,
                              child: Text('Amount',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12))),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    ...currentSale.items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 5,
                                child: Text(item.productName,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('${item.qty}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 13)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                    '₹${item.price.toStringAsFixed(0)}',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(fontSize: 13)),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                    '₹${item.total.toStringAsFixed(2)}',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        )),

                    const Divider(thickness: 1.2, height: 24),

                    // Totals
                    _calcRow('Subtotal',
                        '₹${currentSale.subtotal.toStringAsFixed(2)}'),
                    if (currentSale.discount > 0)
                      _calcRow('Discount Applied',
                          '-₹${currentSale.discount.toStringAsFixed(2)}',
                          color: Colors.green),
                    const Divider(height: 16),
                    _calcRow('GRAND TOTAL',
                        '₹${currentSale.total.toStringAsFixed(2)}',
                        isBold: true,
                        fontSize: 18,
                        color: const Color(0xFF1565C0)),
                    const SizedBox(height: 4),
                    _calcRow(
                        'Amount Paid', '₹${currentSale.paid.toStringAsFixed(2)}',
                        color: Colors.green.shade700),
                    if (currentSale.due > 0)
                      _calcRow('Balance Due',
                          '₹${currentSale.due.toStringAsFixed(2)}',
                          isBold: true, color: Colors.red.shade700)
                    else
                      _calcRow('Balance Due', '₹0.00 (PAID IN FULL)',
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

                    // Invoice reference
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.qr_code, size: 28),
                                const SizedBox(width: 8),
                                Text(
                                  '*${currentSale.invoiceNo}*',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    letterSpacing: 2.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            settings.receiptFooter,
                            style: const TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _shareOnWhatsApp(context, currentSale, settings),
                            icon: const Icon(Icons.share),
                            label: const Text('Share WhatsApp'),
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
                                  const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
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
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  color: color ?? Colors.black87)),
          Text(val,
              style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                  color: color ?? Colors.black87)),
        ],
      ),
    );
  }
}
