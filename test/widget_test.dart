import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_sale/main.dart';

void main() {
  testWidgets('Login screen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const LocalSaleApp());

    expect(find.text('SMART SALES'), findsOneWidget);
    expect(find.text('LOGIN'), findsOneWidget);
  });
}
