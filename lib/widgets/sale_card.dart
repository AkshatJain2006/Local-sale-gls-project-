import 'package:flutter/material.dart';
import '../models/sale.dart';

class SaleCard extends StatelessWidget {
  final Sale sale;

  const SaleCard({super.key, required this.sale});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: const Icon(Icons.receipt, color: Colors.blue),
        ),
        title: Text(sale.invoiceNo,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(sale.customerName),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('₹${sale.total.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
              sale.due > 0 ? 'Due: ₹${sale.due.toStringAsFixed(0)}' : 'Paid',
              style: TextStyle(
                  fontSize: 12,
                  color: sale.due > 0 ? Colors.red : Colors.green),
            ),
          ],
        ),
      ),
    );
  }
}
