import 'package:flutter/material.dart';
import '../models/customer.dart';

class CustomersScreen extends StatefulWidget {
  final String role;
  const CustomersScreen({super.key, this.role = 'staff'});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  bool get isAdmin => widget.role == 'admin';

  final List<Customer> _customers = [
    Customer(id: '1', name: 'Rahul Sharma', phone: '98765XXXXX', totalPurchase: 45000, totalPaid: 35000),
    Customer(id: '2', name: 'Amit Patel', phone: '91234XXXXX', totalPurchase: 22500, totalPaid: 22500),
    Customer(id: '3', name: 'Vijay Singh', phone: '87654XXXXX', totalPurchase: 18000, totalPaid: 10000),
    Customer(id: '4', name: 'Priya Mehta', phone: '76543XXXXX', totalPurchase: 9500, totalPaid: 9500),
  ];

  void _showAddCustomerDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Full Name', border: OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'Phone', border: OutlineInputBorder(), isDense: true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                setState(() => _customers.add(Customer(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameCtrl.text,
                      phone: phoneCtrl.text,
                      totalPurchase: 0,
                      totalPaid: 0,
                    )));
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showDetail(Customer c) {
    final transactions = [
      {'date': '20 Aug', 'amount': 5000},
      {'date': '15 Aug', 'amount': 3500},
      {'date': '10 Aug', 'amount': 2000},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        // Use SingleChildScrollView instead of DraggableScrollableSheet
        // to avoid Expanded-in-unbounded-Column crash
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Text(c.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text('📞 ${c.phone}', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              if (isAdmin) ...[
                Row(
                  children: [
                    _StatBox('Total Purchase',
                        '₹${c.totalPurchase.toStringAsFixed(0)}', Colors.blue),
                    const SizedBox(width: 8),
                    _StatBox('Paid',
                        '₹${c.totalPaid.toStringAsFixed(0)}', Colors.green),
                    const SizedBox(width: 8),
                    _StatBox(
                        'Outstanding',
                        '₹${c.outstanding.toStringAsFixed(0)}',
                        c.outstanding > 0 ? Colors.red : Colors.green),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Transactions',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Divider(),
                ...transactions.map((t) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.payment, color: Colors.green),
                      title: Text(t['date'] as String),
                      trailing: Text('₹${t['amount']}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    )),
              ] else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock, color: Colors.orange, size: 18),
                      SizedBox(width: 8),
                      Text('Financial details visible to Admin only',
                          style: TextStyle(color: Colors.orange)),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: _customers.length,
        itemBuilder: (_, i) {
          final c = _customers[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              onTap: () => _showDetail(c),
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Text(c.name[0],
                    style: const TextStyle(
                        color: Colors.blue, fontWeight: FontWeight.bold)),
              ),
              title: Text(c.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('📞 ${c.phone}'),
              trailing: isAdmin
                  ? Text(
                      c.outstanding > 0
                          ? 'Due: ₹${c.outstanding.toStringAsFixed(0)}'
                          : 'Cleared',
                      style: TextStyle(
                          color: c.outstanding > 0 ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    )
                  : const Icon(Icons.chevron_right),
            ),
          );
        },
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: _showAddCustomerDialog,
              child: const Icon(Icons.person_add),
            )
          : null,
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: color, fontSize: 13)),
            Text(label,
                style: const TextStyle(fontSize: 9, color: Colors.grey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
