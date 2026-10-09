import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../models/sale.dart';
import '../models/product.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final DataService _data = DataService();

  @override
  void initState() {
    super.initState();
    _data.addListener(_refresh);
  }

  @override
  void dispose() {
    _data.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  // --- Real Data Calculations ---

  List<Sale> get _todaySales {
    final now = DateTime.now();
    return _data.sales.where((s) =>
        s.date.year == now.year &&
        s.date.month == now.month &&
        s.date.day == now.day).toList();
  }

  List<Sale> get _weeklySales {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return _data.sales.where((s) => s.date.isAfter(cutoff)).toList();
  }

  List<Sale> get _monthlySales {
    final now = DateTime.now();
    return _data.sales.where((s) =>
        s.date.year == now.year && s.date.month == now.month).toList();
  }

  double _revenue(List<Sale> sales) =>
      sales.fold(0.0, (sum, s) => sum + s.total);

  double _profit(List<Sale> sales) {
    double total = 0;
    for (final sale in sales) {
      for (final item in sale.items) {
        final product = _data.products.firstWhere(
          (p) => p.name.toLowerCase() == item.productName.toLowerCase(),
          orElse: () => Product(
            id: '', name: '', category: '',
            purchasePrice: item.price * 0.7,
            sellingPrice: item.price,
            quantity: 0, minStock: 0, supplier: '',
          ),
        );
        total += (item.price - product.purchasePrice) * item.qty;
      }
    }
    return total;
  }

  int _unitsSold(List<Sale> sales) =>
      sales.fold(0, (sum, s) => sum + s.items.fold(0, (i, it) => i + it.qty));

  String _topProduct(List<Sale> sales) {
    final Map<String, int> counts = {};
    for (final sale in sales) {
      for (final item in sale.items) {
        counts[item.productName] = (counts[item.productName] ?? 0) + item.qty;
      }
    }
    if (counts.isEmpty) return 'No sales yet';
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  // Build hourly chart bars for today (9AM-9PM)
  List<Map<String, dynamic>> _todayChartBars() {
    final hours = [9, 11, 13, 15, 17, 19];
    final labels = ['9AM', '11AM', '1PM', '3PM', '5PM', '7PM'];
    return List.generate(hours.length, (i) {
      final h = hours[i];
      final rev = _todaySales.where((s) => s.date.hour == h).fold(0.0, (sum, s) => sum + s.total);
      return {'label': labels[i], 'val': rev};
    });
  }

  // Build daily chart bars for this week
  List<Map<String, dynamic>> _weeklyChartBars() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: now.weekday - 1 - i));
      final rev = _data.sales.where((s) =>
          s.date.year == day.year &&
          s.date.month == day.month &&
          s.date.day == day.day).fold(0.0, (sum, s) => sum + s.total);
      return {'label': days[i], 'val': rev};
    });
  }

  // Build weekly chart bars for this month
  List<Map<String, dynamic>> _monthlyChartBars() {
    final now = DateTime.now();
    return List.generate(4, (i) {
      final weekStart = i * 7 + 1;
      final weekEnd = weekStart + 6;
      final rev = _monthlySales.where((s) =>
          s.date.day >= weekStart && s.date.day <= weekEnd)
          .fold(0.0, (sum, s) => sum + s.total);
      return {'label': 'W${i + 1}', 'val': rev};
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = _todaySales;
    final weekly = _weeklySales;
    final monthly = _monthlySales;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Analytics & Sales Reports'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.amberAccent,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Daily'),
              Tab(text: 'Weekly'),
              Tab(text: 'Monthly'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Export Report',
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Export feature coming in Phase 2'),
                  backgroundColor: Colors.orange,
                ),
              ),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _ReportTab(
              period: 'Today',
              revenue: _revenue(today),
              profit: _profit(today),
              units: _unitsSold(today),
              topProduct: _topProduct(today),
              transactions: today.length,
              chartBars: _todayChartBars(),
              sales: today,
            ),
            _ReportTab(
              period: 'This Week',
              revenue: _revenue(weekly),
              profit: _profit(weekly),
              units: _unitsSold(weekly),
              topProduct: _topProduct(weekly),
              transactions: weekly.length,
              chartBars: _weeklyChartBars(),
              sales: weekly,
            ),
            _ReportTab(
              period: 'This Month',
              revenue: _revenue(monthly),
              profit: _profit(monthly),
              units: _unitsSold(monthly),
              topProduct: _topProduct(monthly),
              transactions: monthly.length,
              chartBars: _monthlyChartBars(),
              sales: monthly,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportTab extends StatelessWidget {
  final String period;
  final double revenue;
  final double profit;
  final int units;
  final String topProduct;
  final int transactions;
  final List<Map<String, dynamic>> chartBars;
  final List<Sale> sales;

  const _ReportTab({
    required this.period,
    required this.revenue,
    required this.profit,
    required this.units,
    required this.topProduct,
    required this.transactions,
    required this.chartBars,
    required this.sales,
  });

  @override
  Widget build(BuildContext context) {
    final maxVal = chartBars.isEmpty
        ? 1.0
        : chartBars.map((b) => (b['val'] as double)).reduce((a, b) => a > b ? a : b);
    final chartMax = maxVal == 0 ? 1.0 : maxVal;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '📅 $period',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                  fontSize: 13),
            ),
          ),
          const SizedBox(height: 14),

          // Stat cards grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: [
              _StatCard('Gross Revenue', '₹${revenue.toStringAsFixed(0)}',
                  Icons.trending_up, const Color(0xFF1565C0)),
              _StatCard('Net Profit', '₹${profit.toStringAsFixed(0)}',
                  Icons.account_balance_wallet, const Color(0xFF2E7D32)),
              _StatCard('Units Sold', '$units',
                  Icons.inventory_2, const Color(0xFFE65100)),
              _StatCard('Transactions', '$transactions',
                  Icons.receipt_long, const Color(0xFF6A1B9A)),
            ],
          ),

          const SizedBox(height: 16),

          // Top product
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.star, color: Colors.amber),
              ),
              title: const Text('Top Selling Product',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              subtitle: Text(
                topProduct,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1E293B)),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Bar chart
          const Text('Sales Volume Chart',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          Container(
            height: 200,
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: revenue == 0
                ? const Center(
                    child: Text('No sales data for this period',
                        style: TextStyle(color: Colors.grey)),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: chartBars.map((bar) {
                      final val = (bar['val'] as double);
                      final heightRatio = val / chartMax;
                      final barHeight = (heightRatio * 140).clamp(4.0, 140.0);
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (val > 0)
                            Text(
                              '₹${val.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontSize: 8,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold),
                            ),
                          const SizedBox(height: 2),
                          Container(
                            width: 26,
                            height: barHeight,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: val > 0
                                    ? [const Color(0xFF1565C0), Colors.blue.shade300]
                                    : [Colors.grey.shade300, Colors.grey.shade200],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            bar['label'],
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
          ),

          const SizedBox(height: 20),

          // Recent transactions for this period
          if (sales.isNotEmpty) ...[
            const Text('Transactions in Period',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...sales.take(5).map((s) => Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.blue.shade50,
                      child: const Icon(Icons.receipt,
                          size: 16, color: Color(0xFF1565C0)),
                    ),
                    title: Text('${s.invoiceNo} — ${s.customerName}',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '${s.date.day}/${s.date.month} • ${s.paymentMethod} • ${s.items.length} items'),
                    trailing: Text(
                      '₹${s.total.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0)),
                    ),
                  ),
                )),
            if (sales.length > 5)
              Center(
                child: Text(
                  '+ ${sales.length - 5} more transactions',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
          ],

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: color)),
                Text(label,
                    style:
                        const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
