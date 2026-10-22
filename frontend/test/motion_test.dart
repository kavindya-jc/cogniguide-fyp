import 'package:cogniguide/widgets/appear.dart';
import 'package:cogniguide/widgets/bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test.dart' show startApp;

/// Turns the phone's "reduce motion" setting on for one test.
void reduceMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

/// The lilac blob's left edge inside the bottom nav.
double blobLeft(WidgetTester tester) {
  final blob = find.descendant(
    of: find.byType(AppBottomNav),
    matching: find.byType(Positioned),
  );
  return tester.widget<Positioned>(blob.first).left!;
}

void main() {
  testWidgets('swiping along the nav switches tab', (tester) async {
    await startApp(tester, saved: {'student_code': 'P001'});

    // A finger sliding right along the nav, like a real swipe.
    final nav = find.byType(AppBottomNav);
    final finger = await tester.startGesture(
      tester.getCenter(nav) - const Offset(80, 0),
    );
    for (var i = 0; i < 10; i++) {
      await finger.moveBy(const Offset(20, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await finger.up();
    await tester.pumpAndSettle();

    expect(
      find.text('Only you can see this. It is not a grade.'),
      findsOneWidget,
    );
  });

  testWidgets('the liquid blob glides, then rests under the new tab', (
    tester,
  ) async {
    await startApp(tester, saved: {'student_code': 'P001'});
    final start = blobLeft(tester);

    await tester.tap(find.text('My progress'));
    await tester.pump(); // the tap
    await tester.pump(const Duration(milliseconds: 60));
    final moving = blobLeft(tester);
    await tester.pumpAndSettle();
    final end = blobLeft(tester);

    expect(moving, greaterThan(start)); // on its way
    expect(end, greaterThan(moving)); // arrived further right
  });

  testWidgets('reduce motion: the blob jumps straight to the tab', (
    tester,
  ) async {
    reduceMotion(tester);
    await startApp(tester, saved: {'student_code': 'P001'});

    await tester.tap(find.text('My progress'));
    await tester.pump(); // the tap
    await tester.pump(); // one frame later it is already there
    final jumped = blobLeft(tester);
    await tester.pumpAndSettle();
    expect(blobLeft(tester), jumped);
    expect(
      find.text('Only you can see this. It is not a grade.'),
      findsOneWidget,
    );
  });

  testWidgets('the grade pill moves to the chosen grade', (tester) async {
    await startApp(tester, saved: {'student_code': 'P001'});

    Rect pill() => tester.getRect(
      find
          .descendant(
            of: find.byType(Stack),
            matching: find.byType(AnimatedPositioned),
          )
          .first,
    );

    final allButton = tester.getRect(find.bySemanticsLabel('All grades'));
    expect(pill().center.dx, closeTo(allButton.center.dx, 1));

    await tester.tap(find.bySemanticsLabel('Grade 10'));
    await tester.pumpAndSettle();
    final ten = tester.getRect(find.bySemanticsLabel('Grade 10'));
    expect(pill().center.dx, closeTo(ten.center.dx, 1));
  });

  testWidgets('chat bubbles pop in, and appear at once with reduce motion', (
    tester,
  ) async {
    reduceMotion(tester);
    await startApp(tester, saved: {'student_code': 'P001'});
    await tester.tap(find.text('Solve: 3x − 5 = 2x + 7'));
    await tester.pumpAndSettle();

    expect(find.byType(Appear), findsWidgets);
    // Fully shown: no half-faded bubble left behind.
    final faded = tester
        .widgetList<Opacity>(
          find.descendant(
            of: find.byType(Appear),
            matching: find.byType(Opacity),
          ),
        )
        .where((o) => o.opacity < 1);
    expect(faded, isEmpty);
  });

  testWidgets('the pinned problem opens to show the whole text', (
    tester,
  ) async {
    await startApp(tester, saved: {'student_code': 'P001'});
    await tester.tap(find.text('Solve: 3x − 5 = 2x + 7'));
    await tester.pumpAndSettle();

    Text problemText() =>
        tester.widget<Text>(find.text('Solve: 3x − 5 = 2x + 7'));
    expect(problemText().maxLines, 1);

    await tester.tap(find.text('Solve: 3x − 5 = 2x + 7'));
    await tester.pumpAndSettle();
    expect(problemText().maxLines, isNull);
  });
}
