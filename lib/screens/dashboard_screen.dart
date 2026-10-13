import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../services/settings_service.dart';
import '../widgets/barcode_scanner_modal.dart';
import 'inventory_screen.dart';
import 'sales_screen.dart';
import 'customers_screen.dart';
import 'settings_screen.dart';
import 'reports_screen.dart';
import 'staff_management_screen.dart';
import 'billing_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String role;
  final String userName;
  final String userId;

  const DashboardScreen({
    super.key,
    this.role = 'admin',
    this.userName = 'Admin User',
    this.userId = '',
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _idx = 0;
  final DataService _dataService = DataService();

  bool get _isAdmin => widget.role.toLowerCase() == 'admin';

  @override
  void initState() {
    super.initState();
    _dataService.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _dataService.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _HomeView(
        role: widget.role,
        userName: widget.userName,
        userId: widget.userId,
        onNavigateToTab: (tabIndex) => setState(() => _idx = tabIndex),
      ),
      InventoryScreen(role: widget.role),
      SalesScreen(cashierName: widget.userName, cashierId: widget.userId),
      CustomersScreen(role: widget.role),
      if (_isAdmin) const ReportsScreen(),
      SettingsScreen(role: widget.role),
    ];

    final destinations = [
      const NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      const NavigationDestination(
        icon: Icon(Icons.inventory_2_outlined),
        selectedIcon: Icon(Icons.inventory_2),
        label: 'Inventory',
      ),
      const NavigationDestination(
        icon: Icon(Icons.point_of_sale_outlined),
        selectedIcon: Icon(Icons.point_of_sale),
        label: 'POS Sale',
      ),
      const NavigationDestination(
        icon: Icon(Icons.people_alt_outlined),
        selectedIcon: Icon(Icons.people_alt),
        label: 'Customers',
      ),
      if (_isAdmin)
        const NavigationDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics),
          label: 'Reports',
        ),
      const NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: 'Settings',
      ),
    ];

    final safeIdx = _idx.clamp(0, screens.length - 1);
    final isTablet = MediaQuery.of(context).size.width >= 600;

    if (isTablet) {
      return Scaffold(
        body: Builder(builder: (scaffoldCtx) => Row(
          children: [
            NavigationRail(
              selectedIndex: safeIdx,
              onDestinationSelected: (i) => setState(() => _idx = i),
              labelType: NavigationRailLabelType.all,
              backgroundColor: Colors.white,
              elevation: 4,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                const Image(image: AssetImage('assets/logo.png'), width: 36, height: 36),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _isAdmin
                            ? Colors.amber.shade100
                            : Colors.teal.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _isAdmin ? 'ADMIN' : 'STAFF',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              destinations: destinations
                  .map((d) => NavigationRailDestination(
                        icon: d.icon,
                        selectedIcon: d.selectedIcon,
                        label: Text(d.label),
                      ))
                  .toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: screens[safeIdx]),
          ],
        )),
        floatingActionButton: safeIdx == 0
            ? Builder(builder: (fabCtx) => FloatingActionButton.extended(
                onPressed: () => BarcodeScannerModal.showStockInScanner(fabCtx),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan & Stock In'),
                backgroundColor: const Color(0xFF0D47A1),
                foregroundColor: Colors.white,
              ))
            : null,
      );
    }

    return Scaffold(
      body: screens[safeIdx],
      bottomNavigationBar: NavigationBar(
        elevation: 3,
        selectedIndex: safeIdx,
        onDestinationSelected: (i) => setState(() => _idx = i),
        destinations: destinations,
      ),
      floatingActionButton: safeIdx == 0
          ? Builder(builder: (fabCtx) => FloatingActionButton.extended(
              onPressed: () => BarcodeScannerModal.showStockInScanner(fabCtx),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan & Stock In'),
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
            ))
          : null,
    );
  }
}

class _HomeView extends StatelessWidget {
  final String role;
  final String userName;
  final String userId;
  final Function(int tabIndex) onNavigateToTab;

  const _HomeView({
    required this.role,
    required this.userName,
    required this.userId,
    required this.onNavigateToTab,
  });

  bool get _isAdmin => role.toLowerCase() == 'admin';

  @override
  Widget build(BuildContext context) {
    final data = DataService();
    final lowStock = data.lowStockProducts;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, data),
            const SizedBox(height: 18),
            _buildStatsGrid(context, data),
            const SizedBox(height: 20),
            _buildQuickActionsHeader(context),
            const SizedBox(height: 12),
            _buildQuickActionsGrid(context),
            const SizedBox(height: 22),
            if (lowStock.isNotEmpty) ...[
              _buildLowStockSection(context, data, lowStock),
              const SizedBox(height: 22),
            ],
            _buildRecentActivitySection(context, data),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DataService data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LOCAL SALE POS',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Welcome back, $userName',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _isAdmin
                          ? Colors.amber.shade400
                          : Colors.tealAccent.shade400,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _isAdmin ? '👑 ADMIN' : '👤 STAFF',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    tooltip: 'Sign Out',
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (_) => false,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 20),
          Row(
            children: [
              Icon(
                data.isBackendConnected
                    ? Icons.cloud_done
                    : Icons.cloud_off_outlined,
                size: 16,
                color: data.isBackendConnected
                    ? Colors.greenAccent
                    : Colors.white70,
              ),
              const SizedBox(width: 6),
              Text(
                data.isBackendConnected
                    ? 'Backend Server: Connected (Live Sync)'
                    : 'Offline Mode: Local Storage Active',
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
              const Spacer(),
              Text(
                '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, DataService data) {
    final items = [
      _StatCard(
        title: "Today's Sales",
        value: '₹${data.todaySalesTotal.toStringAsFixed(0)}',
        icon: Icons.trending_up,
        color: const Color(0xFF1565C0),
        subtitle: '${data.sales.length} transactions',
      ),
      _StatCard(
        title: 'Inventory Items',
        value: '${data.products.length}',
        icon: Icons.inventory_2,
        color: const Color(0xFFE65100),
        subtitle: '${data.products.fold<int>(0, (s, p) => s + p.quantity)} in stock',
      ),
      if (_isAdmin) ...[
        _StatCard(
          title: 'Gross Profit',
          value: '₹${data.totalProfit.toStringAsFixed(0)}',
          icon: Icons.account_balance_wallet,
          color: const Color(0xFF2E7D32),
          subtitle: 'Calculated margin',
        ),
        _StatCard(
          title: 'Pending Dues',
          value: '₹${data.totalPendingDues.toStringAsFixed(0)}',
          icon: Icons.warning_amber_rounded,
          color: const Color(0xFFC62828),
          subtitle: 'Unpaid accounts',
        ),
      ],
    ];

    final isTablet = MediaQuery.of(context).size.width >= 600;
    final cols = isTablet ? (items.length >= 4 ? 4 : items.length) : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: isTablet ? 1.55 : 1.6,
      ),
      itemBuilder: (_, i) => items[i],
    );
  }

  Widget _buildQuickActionsHeader(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.flash_on, color: Color(0xFF1565C0), size: 20),
        SizedBox(width: 6),
        Text(
          'Quick Operations',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    final actions = [
      _ActionTile(
        title: 'Scan & Stock In',
        icon: Icons.qr_code_scanner,
        color: const Color(0xFF0D47A1),
        onTap: () => BarcodeScannerModal.showStockInScanner(
          context,
          onCreateProduct: (_) {},
        ),
      ),
      _ActionTile(
        title: 'New POS Sale',
        icon: Icons.add_shopping_cart,
        color: const Color(0xFF00897B),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SalesScreen()),
        ),
      ),
      _ActionTile(
        title: 'Invoice History',
        icon: Icons.receipt_long,
        color: const Color(0xFF6A1B9A),
        onTap: () => onNavigateToTab(2),
      ),
      if (_isAdmin) ...[
        _ActionTile(
          title: 'Analytics Reports',
          icon: Icons.bar_chart,
          color: const Color(0xFFE65100),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReportsScreen()),
          ),
        ),
        _ActionTile(
          title: 'Staff Management',
          icon: Icons.manage_accounts,
          color: const Color(0xFF37474F),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StaffManagementScreen()),
          ),
        ),
      ],
    ];

    final isTablet = MediaQuery.of(context).size.width >= 600;
    final cols = isTablet ? (actions.length >= 5 ? 5 : actions.length) : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: isTablet ? 2.5 : 2.6,
      ),
      itemBuilder: (_, i) => actions[i],
    );
  }

  Widget _buildLowStockSection(
      BuildContext context, DataService data, List<dynamic> lowStock) {
    return Card(
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.red.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Low Stock Alerts (${lowStock.length})',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () =>
                      BarcodeScannerModal.showStockInScanner(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Restock'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red.shade800),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...lowStock.take(3).map((p) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(p.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        'Only ${p.quantity} left (Min: ${p.minStock})',
                        style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(BuildContext context, DataService data) {
    final recentSales = data.sales.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Completed Sales',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        if (recentSales.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('No transactions yet.')),
            ),
          )
        else
          ...recentSales.map((s) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    child: const Icon(Icons.receipt, color: Color(0xFF1565C0)),
                  ),
                  title: Text(s.customerName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      '${s.invoiceNo} • ${s.paymentMethod} • ${s.items.length} items'),
                  trailing: Text(
                    '₹${s.total.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1565C0)),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => BillingScreen(sale: s)),
                  ),
                ),
              )),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Flexible(
                  child: Text(
                    subtitle,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
