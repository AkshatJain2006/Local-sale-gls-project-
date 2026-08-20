import 'package:flutter/material.dart';
import '../models/sale.dart';

class BillingScreen extends StatelessWidget {
  final Sale? sale;
  const BillingScreen({super.key, this.sale});

  @override
  Widget build(BuildContext context) {
    final invoiceNo = sale?.invoiceNo ?? 'INV001';
    final customerName = sale?.customerName ?? 'Walk-in Customer';
    final now = DateTime.now();
    final date = sale != null
        ? '${sale!.date.day.toString().padLeft(2, '0')}/${sale!.date.month.toString().padLeft(2, '0')}/${sale!.date.year}'
        : '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    final items = sale?.items ??
        [
          SaleItem(productName: 'Titan Watch', qty: 1, price: 2500),
          SaleItem(productName: 'Leather Belt', qty: 2, price: 500),
        ];
    final subtotal = sale?.subtotal ?? 3500.0;
    final discount = sale?.discount ?? 100.0;
    final tax = sale?.tax ?? 612.0;
    final total = sale?.total ?? 4012.0;
    final paid = sale?.paid ?? 3000.0;
    final due = total - paid;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Invoice'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Column(
                    children: [
                      const Icon(Icons.storefront,
                          size: 40, color: Color(0xFF1565C0)),
                      const SizedBox(height: 6),
                      const Text('LOCAL SALE',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const Text('Sales Management System',
                          style:
                              TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 8),
                      Text('Invoice: $invoiceNo',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600)),
                      Text('Date: $date',
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                const Divider(height: 24),
                Text('Bill To: $customerName',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const Divider(height: 16),
                // Table header
                Row(
                  children: const [
                    Expanded(
                        flex: 4,
                        child: Text('Item',
                            style: TextStyle(
                                fontWeight: FontWeight.bold))),
                    Expanded(
                        child: Text('Qty',
                            style: TextStyle(
                                fontWeight: FontWeight.bold))),
                    Expanded(
                        child: Text('Rate',
                            style: TextStyle(
                                fontWeight: FontWeight.bold))),
                    Expanded(
                        child: Text('Total',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right)),
                  ],
                ),
                const Divider(),
                ...items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                              flex: 4, child: Text(item.productName)),
                          Expanded(child: Text('${item.qty}')),
                          Expanded(
                              child: Text(
                                  '₹${item.price.toStringAsFixed(0)}')),
                          Expanded(
                              child: Text(
                                  '₹${item.total.toStringAsFixed(0)}',
                                  textAlign: TextAlign.right)),
                        ],
                      ),
                    )),
                const Divider(),
                _row('Subtotal', '₹${subtotal.toStringAsFixed(2)}'),
                _row('Discount', '-₹${discount.toStringAsFixed(2)}'),
                _row('Tax (18%)', '₹${tax.toStringAsFixed(2)}'),
                const Divider(),
                _row('TOTAL', '₹${total.toStringAsFixed(2)}',
                    bold: true, color: const Color(0xFF1565C0)),
                const SizedBox(height: 4),
                _row('Paid', '₹${paid.toStringAsFixed(2)}',
                    color: Colors.green),
                _row('Balance Due', '₹${due.toStringAsFixed(2)}',
                    color: due > 0 ? Colors.red : Colors.green),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'PDF export will be available in Phase 2')),
                    ),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Export PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Share will be available in Phase 2')),
                    ),
                    icon: const Icon(Icons.share),
                    label: const Text('Share Invoice'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value,
      {bool bold = false, Color? color}) {
    final style = TextStyle(
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        fontSize: bold ? 15 : 13,
        color: color);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style)
        ],
      ),
    );
  }
}
