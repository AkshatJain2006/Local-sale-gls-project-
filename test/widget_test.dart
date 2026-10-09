import 'package:flutter_test/flutter_test.dart';
import 'package:local_sale/main.dart';

void main() {
  testWidgets('Login screen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const LocalSaleApp());
    await tester.pumpAndSettle();

    expect(find.text('LOCAL SALE'), findsOneWidget);
    expect(find.text('LOGIN TO SYSTEM'), findsOneWidget);
  });
}
