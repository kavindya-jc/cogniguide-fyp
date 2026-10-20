import 'package:cogniguide/widgets/bottom_nav.dart';
import 'package:cogniguide/widgets/glass_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test.dart' show startApp, tapVisible;

/// The blur inside the bottom nav, if there is one.
Finder navBlur() => find.descendant(
  of: find.byType(AppBottomNav),
  matching: find.byType(BackdropFilter),
);

void main() {
  testWidgets('glass is on by default: the bottom nav blurs', (tester) async {
    await startApp(tester, saved: {'student_code': 'P001'});
    expect(find.byType(GlassSurface), findsOneWidget);
    expect(navBlur(), findsOneWidget);
  });

  testWidgets('"Glass effects" off: solid colour, no blur', (tester) async {
    await startApp(
      tester,
      saved: {'student_code': 'P001', 'glass_effects': false},
    );
    expect(find.byType(GlassSurface), findsOneWidget);
    expect(navBlur(), findsNothing);
  });

  testWidgets('reduce motion turns the blur off too', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await startApp(tester, saved: {'student_code': 'P001'});
    expect(navBlur(), findsNothing);
  });

  testWidgets('high contrast turns the blur off too', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(highContrast: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await startApp(tester, saved: {'student_code': 'P001'});
    expect(navBlur(), findsNothing);
  });

  testWidgets('the Settings switch turns glass off and saves it', (
    tester,
  ) async {
    final prefs = await startApp(tester, saved: {'student_code': 'P001'});

    await tester.tap(find.bySemanticsLabel('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Glass effects'), findsOneWidget);

    await tapVisible(tester, find.byType(Switch));
    await tester.pumpAndSettle();
    expect(prefs.getBool('glass_effects'), isFalse);

    // Back on the main screen, the nav is now solid.
    await tester.tap(find.bySemanticsLabel('Back to problems'));
    await tester.pumpAndSettle();
    expect(navBlur(), findsNothing);
  });

  testWidgets('the chat input bar is glass', (tester) async {
    await startApp(tester, saved: {'student_code': 'P001'});
    await tester.tap(find.text('Solve: 3x − 5 = 2x + 7'));
    await tester.pumpAndSettle();

    expect(find.byType(GlassSurface), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
    // The coach's message is still fully readable above the bar.
    expect(find.text('Hello!'), findsOneWidget);
  });
}
