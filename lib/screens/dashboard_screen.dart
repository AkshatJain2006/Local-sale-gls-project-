import 'package:flutter/material.dart';
import 'inventory_screen.dart';
import 'sales_screen.dart';
import 'customers_screen.dart';
import 'settings_screen.dart';
import 'reports_screen.dart';
import 'billing_screen.dart';
import 'staff_management_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String role;
  final String userName;
  const DashboardScreen(
      {super.key, required this.role, required this.userName});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _idx = 0;

  bool get _isAdmin => widget.role == 'admin';

  @override
  Widget build(BuildContext context) {
    final screens = [
      _Home(role: widget.role, userName: widget.userName),
      InventoryScreen(role: widget.role),
      const SalesScreen(),
      CustomersScreen(role: widget.role),
      if (_isAdmin) SettingsScreen(role: widget.role),
    ];

    final destinations = [
      const NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Home'),
      const NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2),
          label: 'Inventory'),
      const NavigationDestination(
          icon: Icon(Icons.point_of_sale_outlined),
          selectedIcon: Icon(Icons.point_of_sale),
          label: 'Sales'),
      const NavigationDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: 'Customers'),
      if (_isAdmin)
        const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings'),
    ];

    // clamp index in case screens list changes
    final safeIdx = _idx.clamp(0, screens.length - 1);

    return Scaffold(
      body: screens[safeIdx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: safeIdx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: destinations,
      ),
    );
  }
}

class _Home extends StatelessWidget {
  final String role;
  final String userName;
  const _Home({required this.role, required this.userName});

  bool get _isAdmin => role == 'admin';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildStats(),
            const SizedBox(height: 20),
            const Text('Quick Actions',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildQuickActions(context),
            const SizedBox(height: 20),
            const Text('⚠️ Low Stock Alert',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildLowStock(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('LOCAL SALE',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0))),
            Text('Welcome, $userName 👋',
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _isAdmin
                    ? Colors.blue.shade100
                    : Colors.green.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _isAdmin ? '👑 Admin' : '👤 Staff',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _isAdmin
                      ? Colors.blue.shade800
                      : Colors.green.shade800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (!_isAdmin)
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.red),
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                ),
              )
            else
              const CircleAvatar(child: Icon(Icons.person)),
          ],
        ),
      ],
    );
  }

  Widget _buildStats() {
    final items = [
      _StatItem("Today's Sales", '₹12,450', Icons.trending_up, Colors.blue),
      _StatItem('Products', '128', Icons.inventory_2, Colors.orange),
      if (_isAdmin) ...[
        _StatItem('Total Profit', '₹3,250', Icons.account_balance_wallet,
            Colors.green),
        _StatItem(
            'Pending Dues', '₹8,500', Icons.warning_amber, Colors.red),
      ],
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemBuilder: (_, i) {
        final s = items[i];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(s.icon, color: s.color, size: 26),
                const SizedBox(height: 6),
                Text(s.value,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: s.color)),
                Text(s.title,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _ActionItem('New Sale', Icons.add_shopping_cart, Colors.blue,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesScreen()))),
      _ActionItem('Billing', Icons.receipt_long, Colors.purple,
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BillingScreen()))),
      if (_isAdmin) ...[
        _ActionItem('Reports', Icons.bar_chart, Colors.teal,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen()))),
        _ActionItem('Staff', Icons.manage_accounts, Colors.indigo,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffManagementScreen()))),
      ],
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
      ),
      itemBuilder: (_, i) {
        final a = actions[i];
        return InkWell(
          onTap: a.onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              color: a.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: a.color.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(a.icon, color: a.color, size: 20),
                const SizedBox(width: 8),
                Text(a.label,
                    style: TextStyle(
                        color: a.color,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLowStock() {
    final items = [
      {'name': 'Titan Watch', 'qty': 3},
      {'name': 'Leather Belt', 'qty': 2},
      {'name': 'Perfume', 'qty': 4},
    ];
    return Column(
      children: items
          .map((item) => ListTile(
                dense: true,
                leading:
                    const Icon(Icons.warning_amber, color: Colors.orange),
                title: Text(item['name'] as String),
                trailing: Text('${item['qty']} left',
                    style: const TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
              ))
          .toList(),
    );
  }
}

class _StatItem {
  final String title, value;
  final IconData icon;
  final Color color;
  const _StatItem(this.title, this.value, this.icon, this.color);
}

class _ActionItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionItem(this.label, this.icon, this.color, this.onTap);
}
