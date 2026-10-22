import 'package:cogniguide/widgets/pip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widgets_test.dart' show wrap;

void main() {
  testWidgets('every Pip mood draws and has a screen reader name', (
    tester,
  ) async {
    for (final mood in PipMood.values) {
      await tester.pumpWidget(wrap(Pip(mood: mood, size: 120)));
      expect(tester.takeException(), isNull, reason: mood.name);
      expect(
        tester.getSemantics(find.byType(Pip)).label,
        startsWith('Your coach'),
        reason: mood.name,
      );
    }
  });

  testWidgets('a breathing Pip moves, then rests after 12 seconds', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const Pip(breathe: true)));
    await tester.pump(const Duration(seconds: 1));
    expect(SchedulerBinding.instance.transientCallbackCount, greaterThan(0));

    await tester.pump(const Duration(seconds: 12));
    await tester.pump();
    // No more frames are asked for: Pip is resting and saves battery.
    expect(SchedulerBinding.instance.transientCallbackCount, 0);
  });

  testWidgets('with reduce motion, a breathing Pip stays still', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: wrap(const Pip(breathe: true)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(SchedulerBinding.instance.transientCallbackCount, 0);
  });
}
