import 'package:cogniguide/widgets/bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test.dart' show startApp, tapVisible;

/// True when some text box has the keyboard.
bool aBoxHasFocus(WidgetTester tester) => tester
    .widgetList<EditableText>(find.byType(EditableText))
    .any((e) => e.focusNode.hasFocus);

void main() {
  testWidgets('the bottom nav hides while the keyboard is up', (
    tester,
  ) async {
    await startApp(tester, saved: {'student_code': 'P001'});
    expect(find.byType(AppBottomNav), findsOneWidget);

    // The keyboard takes the bottom 300 points of the screen.
    tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(find.byType(AppBottomNav), findsNothing);

    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(find.byType(AppBottomNav), findsOneWidget);
  });

  testWidgets('coming back from Settings does not reopen the keyboard', (
    tester,
  ) async {
    await startApp(tester, saved: {'student_code': 'P001'});
    await tapVisible(tester, find.text('Type your own problem'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(aBoxHasFocus(tester), isTrue);

    await tester.tap(find.bySemanticsLabel('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Back to problems'));
    await tester.pumpAndSettle();
    expect(aBoxHasFocus(tester), isFalse);
  });
}
