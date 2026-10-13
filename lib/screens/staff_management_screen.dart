import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/data_service.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});
  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen>
    with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  final _data = DataService();
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _auth.addListener(_refresh);
    _data.addListener(_refresh);
  }

  @override
  void dispose() {
    _tab.dispose();
    _auth.removeListener(_refresh);
    _data.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  // ── Add staff dialog ────────────────────────────────────────────────────

  void _showAddStaffDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String role = 'Staff';
    bool obscure = true;
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Staff Account',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (error != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(error!,
                        style: TextStyle(
                            color: Colors.red.shade800, fontSize: 12)),
                  ),
                _dlgField(nameCtrl, 'Full Name', Icons.person_outline),
                const SizedBox(height: 10),
                _dlgField(emailCtrl, 'Login Email', Icons.email_outlined,
                    type: TextInputType.emailAddress),
                const SizedBox(height: 10),
                TextField(
                  controller: passCtrl,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    labelText: 'Password (min 4 chars)',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                          obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setDlg(() => obscure = !obscure),
                    ),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    prefixIcon: Icon(Icons.security),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: ['Staff', 'Cashier', 'Manager']
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDlg(() => role = v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white),
              onPressed: () async {
                final err = await _auth.createStaff(
                  name: nameCtrl.text,
                  email: emailCtrl.text,
                  password: passCtrl.text,
                  role: role,
                );
                if (err != null) {
                  setDlg(() => error = err);
                  return;
                }
                if (ctx.mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      'Staff account for "${nameCtrl.text.trim()}" created.'),
                  backgroundColor: Colors.green.shade800,
                ));
              },
              child: const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Reset password dialog ───────────────────────────────────────────────

  void _showResetPasswordDialog(AppUser user) {
    final passCtrl = TextEditingController();
    bool obscure = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Reset Password — ${user.name}'),
          content: TextField(
            controller: passCtrl,
            obscureText: obscure,
            decoration: InputDecoration(
              labelText: 'New Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon:
                    Icon(obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setDlg(() => obscure = !obscure),
              ),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (passCtrl.text.length < 4) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Password must be at least 4 characters.'),
                    backgroundColor: Colors.red,
                  ));
                  return;
                }
                await _auth.updateUser(
                    user.copyWith(passwordHash: passCtrl.text));
                if (ctx.mounted) Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Password updated for ${user.name}.'),
                  backgroundColor: Colors.green.shade800,
                ));
              },
              child: const Text('Update Password'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Delete confirm ──────────────────────────────────────────────────────

  void _confirmDelete(AppUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Staff Account'),
        content: Text(
            'Remove "${user.name}"? They will no longer be able to log in.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await _auth.deleteUser(user.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final staffList = _auth.staffOnly;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management'),
        bottom: TabBar(
          controller: _tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amberAccent,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Accounts'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Performance'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStaffDialog,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Staff'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          // ── Tab 1: Accounts ──────────────────────────────────────
          staffList.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline, size: 56, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No staff accounts yet.',
                          style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 4),
                      Text('Tap + Add Staff to create one.',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                  itemCount: staffList.length,
                  itemBuilder: (_, i) {
                    final u = staffList[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: u.isActive
                                  ? Colors.blue.shade50
                                  : Colors.grey.shade200,
                              child: Text(u.name[0].toUpperCase(),
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: u.isActive
                                          ? const Color(0xFF1565C0)
                                          : Colors.grey)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Text(u.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15)),
                                    const SizedBox(width: 8),
                                    _roleBadge(u.role),
                                  ]),
                                  Text(u.email,
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey)),
                                  if (!u.isActive)
                                    const Text('INACTIVE',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            // Active toggle
                            Switch(
                              value: u.isActive,
                              activeColor: Colors.green,
                              onChanged: (_) => _auth.updateUser(
                                  u.copyWith(isActive: !u.isActive)),
                            ),
                            // Reset password
                            IconButton(
                              icon: const Icon(Icons.key, color: Colors.orange),
                              tooltip: 'Reset Password',
                              onPressed: () => _showResetPasswordDialog(u),
                            ),
                            // Delete
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              tooltip: 'Remove',
                              onPressed: () => _confirmDelete(u),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

          // ── Tab 2: Performance ───────────────────────────────────
          staffList.isEmpty
              ? const Center(
                  child: Text('No staff accounts yet.',
                      style: TextStyle(color: Colors.grey)))
              : _buildPerformanceTab(staffList),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab(List<AppUser> staffList) {
    // Build stats for each staff member
    final stats = staffList.map((u) {
      final s = _data.staffStats(u.name);
      return {
        'user': u,
        'salesCount': s['salesCount'] as int,
        'revenue': s['revenue'] as double,
        'profit': s['profit'] as double,
      };
    }).toList();

    // Sort by revenue descending
    stats.sort((a, b) =>
        (b['revenue'] as double).compareTo(a['revenue'] as double));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
      itemCount: stats.length,
      itemBuilder: (_, i) {
        final s = stats[i];
        final u = s['user'] as AppUser;
        final rank = i + 1;
        final rankColor = rank == 1
            ? Colors.amber
            : rank == 2
                ? Colors.grey.shade400
                : rank == 3
                    ? Colors.brown.shade300
                    : Colors.blue.shade100;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                        color: rankColor,
                        shape: BoxShape.circle),
                    child: Center(
                      child: Text('#$rank',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(u.role,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  if (rank == 1)
                    const Text('🏆',
                        style: TextStyle(fontSize: 22)),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  _statChip(Icons.receipt_long, '${s['salesCount']} Sales',
                      Colors.blue),
                  const SizedBox(width: 8),
                  _statChip(Icons.currency_rupee,
                      'Rev: ₹${(s['revenue'] as double).toStringAsFixed(0)}',
                      Colors.teal),
                  const SizedBox(width: 8),
                  _statChip(Icons.trending_up,
                      'Profit: ₹${(s['profit'] as double).toStringAsFixed(0)}',
                      Colors.green),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statChip(IconData icon, String label, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color.shade700),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color.shade700)),
      ]),
    );
  }

  Widget _roleBadge(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(role,
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1565C0))),
    );
  }

  Widget _dlgField(
      TextEditingController ctrl, String label, IconData icon,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }
}
