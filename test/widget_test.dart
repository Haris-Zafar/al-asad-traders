import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:al_asad_traders/app.dart';

void main() {
  testWidgets('App renders dashboard screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AlAsadTradersApp(),
      ),
    );

    expect(find.text('Al Asad Traders ERP'), findsOneWidget);
  });
}
