import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test.dart' show startApp;

void main() {
  testWidgets('tapping the chat box keeps the keyboard connected', (
    tester,
  ) async {
    await startApp(tester, saved: {'student_code': 'P001'});
    await tester.tap(find.text('Solve: 3x − 5 = 2x + 7'));
    await tester.pumpAndSettle();

    final field = find.byType(EditableText);
    final before = tester.state(field);

    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();

    // The bar turns solid while typing. The message box must stay the same
    // box (not be rebuilt), or the phone's keyboard loses its connection.
    expect(tester.state(field), same(before));
    expect(tester.testTextInput.hasAnyClients, isTrue);

    tester.testTextInput.enterText('take away 2x');
    await tester.pump();
    expect(find.text('take away 2x'), findsOneWidget);
  });
}
