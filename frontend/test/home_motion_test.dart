import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test.dart' show startApp;

/// The top bar folds into a slim bar on scroll, and the tabs switch with a
/// short fade (team requests).
void main() {
  testWidgets('scrolling down folds the top bar; back at the top it opens', (
    tester,
  ) async {
    await startApp(tester, saved: {'student_code': 'P001'});
    const title = 'What would you like to work on?';
    expect(find.text(title), findsOneWidget);

    final list = find.byType(Scrollable).first;
    await tester.drag(list, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text(title), findsNothing); // folded
    expect(find.text('Hi, P001'), findsOneWidget); // the slim bar stays

    await tester.drag(list, const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(find.text(title), findsOneWidget); // open again
  });

  testWidgets('switching tabs fades, then the old tab is put away', (
    tester,
  ) async {
    await startApp(tester, saved: {'student_code': 'P001'});

    await tester.tap(find.text('My progress'));
    await tester.pump(const Duration(milliseconds: 100));
    // Half way: both tabs are there for the fade.
    expect(find.text('Hi, P001'), findsOneWidget);
    await tester.pumpAndSettle();
    // After the fade the Practice tab is offstage (not read or tapped)...
    expect(find.text('Hi, P001'), findsNothing);

    // ...but it kept its state: back on Practice, Algebra is still chosen.
    await tester.tap(find.text('Practice'));
    await tester.pumpAndSettle();
    expect(find.text('Solve: 3x − 5 = 2x + 7'), findsOneWidget);
  });

  testWidgets('with reduce motion the tab switch is instant', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await startApp(tester, saved: {'student_code': 'P001'});

    await tester.tap(find.text('My progress'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Hi, P001'), findsNothing);
  });
}
