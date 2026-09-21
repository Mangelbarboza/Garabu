import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:garabu/main.dart';

void main() {
  testWidgets('GarabuApp inicializa correctamente', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: GarabuApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(GarabuApp), findsOneWidget);
  });
}
