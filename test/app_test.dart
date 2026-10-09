import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_sale/main.dart';
import 'package:local_sale/models/product.dart';
import 'package:local_sale/models/sale.dart';
import 'package:local_sale/models/customer.dart';
import 'package:local_sale/services/data_service.dart';
import 'package:local_sale/screens/dashboard_screen.dart';
import 'package:local_sale/screens/inventory_screen.dart';
import 'package:local_sale/screens/sales_screen.dart';
import 'package:local_sale/screens/billing_screen.dart';
import 'package:local_sale/screens/customers_screen.dart';
import 'package:local_sale/screens/reports_screen.dart';
import 'package:local_sale/screens/staff_management_screen.dart';
import 'package:local_sale/screens/settings_screen.dart';

void main() {
  group('1. Data Models & Business Calculation Tests', () {
    test('Product model calculations', () {
      final p = Product(
        id: 'p100',
        name: 'Test Product',
        category: 'Electronics',
        purchasePrice: 100,
        sellingPrice: 150,
        quantity: 3,
        minStock: 5,
        supplier: 'Test Supplier',
        barcode: '1234567890',
      );

      expect(p.profit, 50.0);
      expect(p.isLowStock, true);
      expect(p.profitMargin, closeTo(33.33, 0.1));

      final json = p.toJson();
      final fromJson = Product.fromJson(json);
      expect(fromJson.name, 'Test Product');
      expect(fromJson.barcode, '1234567890');
    });

    test('Sale and SaleItem calculations', () {
      final item1 = SaleItem(productName: 'Watch', qty: 2, price: 500);
      final item2 = SaleItem(productName: 'Belt', qty: 1, price: 300);

      final sale = Sale(
        invoiceNo: 'INV-TEST',
        customerName: 'Test Customer',
        date: DateTime.now(),
        items: [item1, item2],
        discount: 100,
        tax: 216,
        paymentMethod: 'Cash',
        paid: 1000,
      );

      expect(sale.subtotal, 1300.0);
      expect(sale.total, 1200.0);
      expect(sale.due, 200.0);
    });

    test('Customer model and ledger calculation', () {
      final cust = Customer(
        id: 'c1',
        name: 'John Doe',
        phone: '9999999999',
        totalPurchase: 10000,
        totalPaid: 6000,
      );

      expect(cust.outstanding, 4000.0);
    });
  });

  group('2. Central DataService State & Barcode Operations Tests', () {
    late DataService data;

    setUp(() {
      // Use a fresh product for each test group
      data = DataService();
    });

    test('Stock In by product ID increments inventory', () {
      // Add a test product first (production mode has no mock data)
      final testProduct = Product(
        id: 'test_prod_001',
        name: 'Test Watch',
        category: 'Electronics',
        purchasePrice: 1000,
        sellingPrice: 1500,
        quantity: 10,
        minStock: 5,
        supplier: 'Test Supplier',
        barcode: 'TEST_BARCODE_001',
      );
      data.addProduct(testProduct);

      final initialQty = testProduct.quantity;
      final success = data.stockInProduct('TEST_BARCODE_001', 5);
      expect(success, true);

      final updated = data.findProductByBarcode('TEST_BARCODE_001')!;
      expect(updated.quantity, initialQty + 5);
    });

    test('findProductByBarcode returns null for unknown barcode', () {
      final found = data.findProductByBarcode('NONEXISTENT_BARCODE_XYZ');
      expect(found, isNull);
    });

    test('Sale completion properly records and updates financials', () {
      final initialSaleCount = data.sales.length;
      final sale = Sale(
        invoiceNo: 'INV_AUTO_TEST_${DateTime.now().millisecondsSinceEpoch}',
        customerName: 'Test Customer',
        date: DateTime.now(),
        items: [
          SaleItem(productId: 'test_prod_001', productName: 'Test Watch', qty: 1, price: 1500)
        ],
        discount: 0,
        tax: 0,
        paymentMethod: 'Cash',
        paid: 1500,
      );

      data.addSale(sale);
      expect(data.sales.length, initialSaleCount + 1);
      expect(data.todaySalesTotal, greaterThan(0));
    });
  });

  group('3. UI Widget & Screen Rendering Tests', () {
    testWidgets('LocalSaleApp starts and renders LoginScreen', (tester) async {
      await tester.pumpWidget(const LocalSaleApp());
      await tester.pumpAndSettle();

      expect(find.text('LOCAL SALE'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Admin Demo'), findsOneWidget);
      expect(find.text('Staff Demo'), findsOneWidget);
    });

    testWidgets('DashboardScreen renders properly with Admin role', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardScreen(role: 'admin', userName: 'Admin User'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('LOCAL SALE POS'), findsOneWidget);
      expect(find.text('👑 ADMIN'), findsOneWidget);
      expect(find.text('Scan & Stock In'), findsWidgets);
    });

    testWidgets('InventoryScreen renders with search and category filters', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: InventoryScreen(role: 'admin'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Inventory & Stock'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);
    });

    testWidgets('SalesScreen renders POS Catalog and Cart', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SalesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Point of Sale (POS)'), findsOneWidget);
      expect(find.text('COMPLETE SALE'), findsOneWidget);
    });

    testWidgets('BillingScreen renders Tax Invoice', (tester) async {
      final testSale = Sale(
        invoiceNo: 'INV-TEST-001',
        customerName: 'Test Customer',
        date: DateTime.now(),
        items: [SaleItem(productName: 'Test Item', qty: 1, price: 500)],
        discount: 0,
        tax: 0,
        paymentMethod: 'Cash',
        paid: 500,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: BillingScreen(sale: testSale),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('LOCAL SALE STORE'), findsOneWidget);
      expect(find.text('Share WhatsApp'), findsOneWidget);
    });

    testWidgets('CustomersScreen renders Customer Accounts', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CustomersScreen(role: 'admin'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Customer Accounts & Dues'), findsOneWidget);
      expect(find.text('Total Receivables'), findsOneWidget);
    });

    testWidgets('ReportsScreen renders Analytics', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ReportsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Analytics & Sales Reports'), findsOneWidget);
      expect(find.text('Daily'), findsOneWidget);
    });

    testWidgets('StaffManagementScreen renders Staff Directory', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StaffManagementScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Staff & Permissions'), findsOneWidget);
      expect(find.text('Add Staff'), findsOneWidget);
    });

    testWidgets('SettingsScreen renders System Configuration', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(role: 'admin'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('System Settings'), findsOneWidget);
      expect(find.text('Backend API Integration'), findsOneWidget);
      expect(find.text('Test Connection & Sync Now'), findsOneWidget);
    });
  });
}
