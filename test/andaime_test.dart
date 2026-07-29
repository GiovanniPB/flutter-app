import 'package:despensa/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('o app sobe dentro do ProviderScope', (WidgetTester tester) async {
    await tester.pumpWidget(const DespensaApp());
    expect(find.text('Despensa'), findsOneWidget);
  });
}
