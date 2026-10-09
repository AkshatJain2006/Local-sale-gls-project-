import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/data_service.dart';

class CustomersScreen extends StatefulWidget {
  final String role;
  const CustomersScreen({super.key, this.role = 'staff'});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final DataService _dataService = DataService();
  String _search = '';

  bool get _isAdmin => widget.role.toLowerCase() == 'admin';

  @override
  void initState() {
    super.initState();
    _dataService.addListener(_refresh);
  }

  @override
  void dispose() {
    _dataService.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  List<Customer> get _filtered {
    return _dataService.customers.where((c) {
      return c.name.toLowerCase().contains(_search.toLowerCase()) ||
          c.phone.toLowerCase().contains(_search.toLowerCase()) ||
          c.email.toLowerCase().contains(_search.toLowerCase());
    }).toList();
  }

  void _showAddCustomerDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final addrCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Customer Account',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: addrCtrl,
                decoration: const InputDecoration(
                  labelText: 'Address / Location',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
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
              if (nameCtrl.text.trim().isEmpty) return;
              final cust = Customer(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                email: emailCtrl.text.trim(),
                address: addrCtrl.text.trim(),
                totalPurchase: 0,
                totalPaid: 0,
              );
              _dataService.addCustomer(cust);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Customer "${cust.name}" registered!'),
                  backgroundColor: Colors.green.shade800,
                ),
              );
            },
            child: const Text('Save Customer'),
          ),
        ],
      ),
    );
  }

  void _toggleBlacklist(Customer c) {
    final willBlacklist = !c.isBlacklisted;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(willBlacklist ? Icons.block : Icons.check_circle,
                color: willBlacklist ? Colors.red : Colors.green),
            const SizedBox(width: 8),
            Text(willBlacklist ? 'Blacklist Customer?' : 'Remove Blacklist?'),
          ],
        ),
        content: Text(
          willBlacklist
              ? '"${c.name}" will be blocked from new sales. Are you sure?'
              : '"${c.name}" will be allowed to make purchases again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: willBlacklist ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (willBlacklist) {
                _dataService.blacklistCustomer(c.id);
              } else {
                _dataService.unblacklistCustomer(c.id);
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: willBlacklist
                      ? Colors.red.shade800
                      : Colors.green.shade800,
                  content: Text(
                    willBlacklist
                        ? '"${c.name}" has been blacklisted.'
                        : '"${c.name}" removed from blacklist.',
                  ),
                ),
              );
            },
            child: Text(willBlacklist ? 'Blacklist' : 'Remove'),
          ),
        ],
      ),
    );
  }

  void _recordPayment(Customer c) {
    final amountCtrl = TextEditingController(
        text: c.outstanding > 0 ? c.outstanding.toStringAsFixed(0) : '0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Record Payment: ${c.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Outstanding:',
                      style: TextStyle(fontSize: 13)),
                  Text(
                    '₹${c.outstanding.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                        fontSize: 15),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Payment Received (₹)',
                prefixIcon: Icon(Icons.currency_rupee),
                border: OutlineInputBorder(),
                isDense: true,
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
              backgroundColor: const Color(0xFF00897B),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final amount = double.tryParse(amountCtrl.text) ?? 0.0;
              if (amount > 0) {
                _dataService.recordCustomerPayment(c.id, amount);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.green.shade800,
                    content: Text(
                        'Recorded ₹${amount.toStringAsFixed(0)} from ${c.name}!'),
                  ),
                );
              }
            },
            child: const Text('Confirm Payment'),
          ),
        ],
      ),
    );
  }

  void _showCustomerDetailSheet(Customer c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('📞 ${c.phone}',
                            style: const TextStyle(color: Colors.grey)),
                        if (c.email.isNotEmpty)
                          Text('✉️ ${c.email}',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12)),
                        if (c.isBlacklisted)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('BLACKLISTED',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red)),
                          ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      c.name.isNotEmpty ? c.name[0].toUpperCase() : 'C',
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0)),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              Row(
                children: [
                  _infoCard('Total Purchases',
                      '₹${c.totalPurchase.toStringAsFixed(0)}', Colors.blue),
                  const SizedBox(width: 8),
                  _infoCard('Total Paid',
                      '₹${c.totalPaid.toStringAsFixed(0)}', Colors.green),
                  const SizedBox(width: 8),
                  _infoCard(
                      'Outstanding',
                      '₹${c.outstanding.toStringAsFixed(0)}',
                      c.outstanding > 0 ? Colors.red : Colors.green),
                ],
              ),

              const SizedBox(height: 20),

              const Text('Transaction Activity Ledger',
                  style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (c.transactions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No recorded transactions yet.',
                      style: TextStyle(color: Colors.grey)),
                )
              else
                ...c.transactions.map((t) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: t.type == 'payment'
                            ? Colors.green.shade50
                            : Colors.blue.shade50,
                        child: Icon(
                          t.type == 'payment'
                              ? Icons.arrow_downward
                              : Icons.shopping_bag,
                          size: 16,
                          color: t.type == 'payment'
                              ? Colors.green
                              : const Color(0xFF1565C0),
                        ),
                      ),
                      title: Text(t.description,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: Text(t.date,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                      trailing: Text(
                        '${t.type == 'payment' ? '-' : '+'}₹${t.amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: t.type == 'payment'
                              ? Colors.green
                              : const Color(0xFF1565C0),
                        ),
                      ),
                    )),

              const SizedBox(height: 20),

              if (_isAdmin && c.outstanding > 0)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _recordPayment(c);
                    },
                    icon: const Icon(Icons.payment),
                    label: const Text('Record Payment / Settle Balance'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00897B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              if (_isAdmin) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _toggleBlacklist(c);
                    },
                    icon: Icon(
                      c.isBlacklisted
                          ? Icons.check_circle_outline
                          : Icons.block,
                      color: c.isBlacklisted ? Colors.green : Colors.red,
                    ),
                    label: Text(
                      c.isBlacklisted
                          ? 'Remove from Blacklist'
                          : 'Blacklist This Customer',
                      style: TextStyle(
                        color: c.isBlacklisted ? Colors.green : Colors.red,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: c.isBlacklisted ? Colors.green : Colors.red,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style:
                    const TextStyle(fontSize: 10, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _customerTrailing(Customer c) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '₹${c.outstanding.toStringAsFixed(0)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: c.outstanding > 0 ? Colors.red : Colors.green,
          ),
        ),
        if (c.outstanding > 0 && _isAdmin)
          GestureDetector(
            onTap: () => _recordPayment(c),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('Pay Now',
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.green,
                      fontWeight: FontWeight.bold)),
            ),
          )
        else
          Text(
            c.outstanding > 0 ? 'Due Pending' : 'Cleared',
            style: TextStyle(
              fontSize: 10,
              color: c.outstanding > 0 ? Colors.red : Colors.green,
            ),
          ),
      ],
    );
  }

  Widget _blacklistBadge() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text('BLACKLISTED',
            style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.red)),
      );

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Accounts & Dues'),
      ),
      body: Column(
        children: [
          // Summary banner
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _summaryCol(
                    'Active Customers',
                    '${_dataService.customers.where((c) => !c.isBlacklisted).length}',
                    Colors.white),
                Container(width: 1, height: 35, color: Colors.white24),
                _summaryCol(
                    'Total Receivables',
                    '₹${_dataService.totalPendingDues.toStringAsFixed(0)}',
                    Colors.amberAccent),
                Container(width: 1, height: 35, color: Colors.white24),
                _summaryCol(
                    'Blacklisted',
                    '${_dataService.customers.where((c) => c.isBlacklisted).length}',
                    Colors.redAccent),
              ],
            ),
          ),

          // Search
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search by name, phone or email...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),

          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('No customers found.'))
                : isTablet
                    ? GridView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        itemCount: list.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 3.0,
                        ),
                        itemBuilder: (_, i) {
                          final c = list[i];
                          return Card(
                            child: ListTile(
                              onTap: () => _showCustomerDetailSheet(c),
                              leading: CircleAvatar(
                                backgroundColor: c.isBlacklisted
                                    ? Colors.red.shade100
                                    : Colors.blue.shade50,
                                child: Text(
                                  c.name.isNotEmpty ? c.name[0] : 'C',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: c.isBlacklisted
                                          ? Colors.red
                                          : const Color(0xFF1565C0)),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Flexible(
                                    child: Text(c.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  if (c.isBlacklisted) ...[
                                    const SizedBox(width: 6),
                                    _blacklistBadge(),
                                  ],
                                ],
                              ),
                              subtitle: Text('📞 ${c.phone}'),
                              trailing: _customerTrailing(c),
                            ),
                          );
                        },
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        itemCount: list.length,
                        itemBuilder: (_, i) {
                          final c = list[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              onTap: () => _showCustomerDetailSheet(c),
                              leading: CircleAvatar(
                                backgroundColor: c.isBlacklisted
                                    ? Colors.red.shade100
                                    : Colors.blue.shade50,
                                child: Text(
                                  c.name.isNotEmpty ? c.name[0] : 'C',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: c.isBlacklisted
                                          ? Colors.red
                                          : const Color(0xFF1565C0)),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Flexible(
                                    child: Text(c.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  if (c.isBlacklisted) ...[
                                    const SizedBox(width: 6),
                                    _blacklistBadge(),
                                  ],
                                ],
                              ),
                              subtitle: Text('📞 ${c.phone}'),
                              trailing: _customerTrailing(c),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              onPressed: _showAddCustomerDialog,
              icon: const Icon(Icons.person_add),
              label: const Text('Add Customer'),
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _summaryCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.white70)),
      ],
    );
  }
}
