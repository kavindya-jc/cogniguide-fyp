import 'package:cogniguide/widgets/bottom_nav.dart';
import 'package:cogniguide/widgets/glass_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test.dart' show startApp, tapVisible;

/// Blurs that are switched on (a switched-off blur stays in place but
/// draws nothing).
Finder blurs() =>
    find.byWidgetPredicate((w) => w is BackdropFilter && w.enabled);

/// The blur inside the bottom nav, if it is switched on.
Finder navBlur() =>
    find.descendant(of: find.byType(AppBottomNav), matching: blurs());

void main() {
  lighterGlassTests();

  testWidgets('glass is on by default: the bottom nav blurs', (tester) async {
    await startApp(tester, saved: {'student_code': 'P001'});
    // Two glass surfaces: the header and the bottom nav (never more).
    expect(find.byType(GlassSurface), findsNWidgets(2));
    expect(blurs(), findsNWidgets(2));
    expect(navBlur(), findsOneWidget);
  });

  testWidgets('"Glass effects" off: solid colour, no blur', (tester) async {
    await startApp(
      tester,
      saved: {'student_code': 'P001', 'glass_effects': false},
    );
    expect(find.byType(GlassSurface), findsNWidgets(2));
    expect(blurs(), findsNothing);
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

    // Two glass surfaces: the header and the input bar (never more).
    expect(find.byType(GlassSurface), findsNWidgets(2));
    expect(blurs(), findsNWidgets(2));
    // The coach's message is still fully readable above the bar.
    expect(find.text('Hello!'), findsOneWidget);
  });
}

void lighterGlassTests() {
  testWidgets('chat bar: glass while reading, solid while typing', (
    tester,
  ) async {
    await startApp(tester, saved: {'student_code': 'P001'});
    await tester.tap(find.text('Solve: 3x − 5 = 2x + 7'));
    await tester.pumpAndSettle();
    expect(blurs(), findsNWidgets(2));

    // The student taps into the message box: no blur while typing.
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(blurs(), findsNothing);

    // Done typing (box not active any more): the glass comes back.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(blurs(), findsNWidgets(2));
  });

  testWidgets('log-out sheet: solid while sliding, glass once stopped', (
    tester,
  ) async {
    await startApp(tester, saved: {'student_code': 'P001'});
    // The header and the bottom nav are glass: 2 blurs.
    expect(blurs(), findsNWidgets(2));

    await tester.tap(find.text('Log out'));
    await tester.pump(); // the tap
    await tester.pump(const Duration(milliseconds: 150)); // mid-slide
    // Covered by the sheet, header and nav pause their blur; the sliding
    // sheet is solid.
    expect(blurs(), findsNothing);

    await tester.pumpAndSettle(); // the sheet has stopped
    expect(blurs(), findsOneWidget); // only the sheet
  });
}
