import 'package:flutter/material.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  final String role;
  const SettingsScreen({super.key, this.role = 'admin'});

  bool get _isAdmin => role == 'admin';

  @override
  Widget build(BuildContext context) {
    final items = [
      _Item(Icons.person, 'Profile', Colors.blue),
      _Item(Icons.store, 'Business Details', Colors.orange),
      _Item(Icons.notifications, 'Notifications', Colors.purple),
      _Item(Icons.backup, 'Backup & Restore', Colors.teal),
      _Item(Icons.security, 'Security', Colors.red),
      _Item(Icons.info_outline, 'About Local Sale', Colors.grey),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: _isAdmin
                      ? Colors.blue.shade100
                      : Colors.green.shade100,
                  child: Icon(Icons.person,
                      size: 36,
                      color: _isAdmin ? Colors.blue : Colors.green),
                ),
                const SizedBox(height: 8),
                Text(_isAdmin ? 'Admin' : 'Staff',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                    _isAdmin
                        ? 'admin@localsale.com'
                        : 'staff@localsale.com',
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isAdmin
                        ? Colors.blue.shade100
                        : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _isAdmin ? '👑 Admin' : '👤 Staff',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _isAdmin
                            ? Colors.blue.shade800
                            : Colors.green.shade800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          ...items.map((item) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: item.color.withOpacity(0.15),
                  child: Icon(item.icon, color: item.color),
                ),
                title: Text(item.label),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('${item.label} — coming in Phase 2')),
                ),
              )),
          const Divider(),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFFFEBEE),
              child: Icon(Icons.logout, color: Colors.red),
            ),
            title: const Text('Logout',
                style: TextStyle(color: Colors.red)),
            onTap: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (_) => false,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _Item {
  final IconData icon;
  final String label;
  final Color color;
  const _Item(this.icon, this.label, this.color);
}
