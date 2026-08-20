import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final String role;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductCard({
    super.key,
    required this.product,
    this.role = 'staff',
    required this.onEdit,
    required this.onDelete,
  });

  bool get isAdmin => role == 'admin';

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(product.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                if (product.isLowStock)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8)),
                    child: const Text('Low Stock',
                        style: TextStyle(color: Colors.red, fontSize: 11)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(product.category,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('₹${product.sellingPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(width: 16),
                Text('Stock: ${product.quantity}',
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            if (isAdmin)
              Row(
                children: [
                  OutlinedButton(onPressed: onEdit, child: const Text('Edit')),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: onDelete,
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red)),
                    child: const Text('Delete'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
