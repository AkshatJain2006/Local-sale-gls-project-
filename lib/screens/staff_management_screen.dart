import 'package:flutter/material.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final List<Map<String, String>> _staff = [
    {'name': 'Ravi Kumar', 'email': 'ravi@smartsales.com', 'role': 'Staff', 'status': 'Active'},
    {'name': 'Sneha Joshi', 'email': 'sneha@smartsales.com', 'role': 'Staff', 'status': 'Active'},
    {'name': 'Mohan Das', 'email': 'mohan@smartsales.com', 'role': 'Staff', 'status': 'Inactive'},
  ];

  void _showAddStaffDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Staff Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(nameCtrl, 'Full Name'),
            const SizedBox(height: 10),
            _field(emailCtrl, 'Email'),
            const SizedBox(height: 10),
            _field(passCtrl, 'Password'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && emailCtrl.text.isNotEmpty) {
                setState(() => _staff.add({
                      'name': nameCtrl.text,
                      'email': emailCtrl.text,
                      'role': 'Staff',
                      'status': 'Active',
                    }));
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _staff.length,
        itemBuilder: (_, i) {
          final s = _staff[i];
          final isActive = s['status'] == 'Active';
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.indigo.shade100,
                child: Text(s['name']![0],
                    style: const TextStyle(
                        color: Colors.indigo, fontWeight: FontWeight.bold)),
              ),
              title: Text(s['name']!,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(s['email']!),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green.shade100 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      s['status']!,
                      style: TextStyle(
                          fontSize: 11,
                          color: isActive ? Colors.green.shade800 : Colors.grey),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => setState(() => _staff.removeAt(i)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStaffDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Staff'),
      ),
    );
  }
}
