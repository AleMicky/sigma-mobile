import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sigma_mobile/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: SigmaApp()));
    await tester.pumpAndSettle();

    // Verify that the app loads
    expect(find.byType(SigmaApp), findsOneWidget);
  });
}
