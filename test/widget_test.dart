import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:alerta_acv/app.dart';

void main() {
  testWidgets('App loads and shows home pages', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: App(),
      ),
    );

    // Verify that the home pages is shown
    expect(find.text('Alerta ACV'), findsOneWidget);
    expect(find.text('Iniciar prueba FAST'), findsOneWidget);
  });
}
