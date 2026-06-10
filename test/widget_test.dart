import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:espenseai/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: ExpenseMateApp(),
      ),
    );

    // Verify that the logo name 'ExpenseMate' is visible on startup
    expect(find.text('ExpenseMate'), findsOneWidget);
  });
}
