import 'package:cogniguide/widgets/entrance.dart';
import 'package:cogniguide/widgets/help_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';

import 'progress_test.dart' show fourSessions, serverSays;
import 'widget_test.dart' show startApp;

void reduceMotion(WidgetTester tester) {
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
}

void main() {
  testWidgets('Welcome plays its entrance, then everything rests', (
    tester,
  ) async {
    await startApp(tester); // waits until nothing moves any more

    expect(find.byType(Entrance), findsWidgets);
    expect(find.byType(Animate), findsWidgets);
    expect(find.text('Think it through, your way.'), findsOneWidget);
    expect(find.text('Create an account'), findsOneWidget);

    // Pip's breathing stops by itself (it saves battery), so no frames
    // are waiting to be drawn.
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('reduce motion: Welcome appears at once, nothing animates', (
    tester,
  ) async {
    reduceMotion(tester);
    await startApp(tester);

    expect(find.byType(Animate), findsNothing);
    expect(find.text('Think it through, your way.'), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('the chart draws itself, then stops', (tester) async {
    await startApp(
      tester,
      saved: {'student_code': 'P001'},
      progress: serverSays(fourSessions),
    );
    await tester.tap(find.text('My progress'));
    await tester.pump(); // the tap
    await tester.pump(); // the numbers arrive
    await tester.pump(const Duration(milliseconds: 500));

    // Halfway through drawing, the chart is still moving.
    expect(find.byType(HelpChart), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isTrue);

    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('the loading pulse only runs while loading', (tester) async {
    await startApp(
      tester,
      saved: {'student_code': 'P001'},
      progress: serverSays(fourSessions),
    );
    await tester.tap(find.text('My progress'));
    await tester.pumpAndSettle();

    expect(find.byType(Pulse), findsNothing);
  });
}
