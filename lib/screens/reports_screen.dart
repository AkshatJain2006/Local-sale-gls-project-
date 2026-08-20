import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reports'),
          backgroundColor: const Color(0xFF1565C0),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Daily'),
              Tab(text: 'Weekly'),
              Tab(text: 'Monthly'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ReportView(sales: '₹12,450', profit: '₹3,250', products: '24', topProduct: 'Titan Watch'),
            _ReportView(sales: '₹68,200', profit: '₹18,400', products: '112', topProduct: 'Titan Watch'),
            _ReportView(sales: '₹1,24,500', profit: '₹32,400', products: '245', topProduct: 'Titan Watch'),
          ],
        ),
      ),
    );
  }
}

class _ReportView extends StatelessWidget {
  final String sales;
  final String profit;
  final String products;
  final String topProduct;

  const _ReportView({
    required this.sales,
    required this.profit,
    required this.products,
    required this.topProduct,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              _StatCard('Sales', sales, Icons.trending_up, Colors.blue),
              const SizedBox(width: 12),
              _StatCard('Profit', profit, Icons.account_balance_wallet, Colors.green),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatCard('Products Sold', products, Icons.inventory_2, Colors.orange),
              const SizedBox(width: 12),
              _StatCard('Top Product', topProduct, Icons.star, Colors.purple),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Sales Chart',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _Bar(height: 80, label: 'Mon', color: Colors.blue),
                      _Bar(height: 120, label: 'Tue', color: Colors.blue),
                      _Bar(height: 60, label: 'Wed', color: Colors.blue),
                      _Bar(height: 140, label: 'Thu', color: Colors.blue),
                      _Bar(height: 100, label: 'Fri', color: Colors.blue),
                      _Bar(height: 90, label: 'Sat', color: Colors.blue),
                      _Bar(height: 50, label: 'Sun', color: Colors.blue),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 6),
              Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: color)),
              Text(label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double height;
  final String label;
  final Color color;

  const _Bar({required this.height, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 28,
          height: height,
          decoration: BoxDecoration(
              color: color.withOpacity(0.7),
              borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
