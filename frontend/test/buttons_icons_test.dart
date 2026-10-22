import 'package:cogniguide/widgets/duo_icon.dart';
import 'package:cogniguide/widgets/glass_surface.dart';
import 'package:cogniguide/widgets/pill_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widgets_test.dart' show wrap;

void main() {
  testWidgets('every duotone icon draws', (tester) async {
    await tester.pumpWidget(
      wrap(
        Wrap(
          children: [
            for (final icon in AppIcon.values)
              DuoIcon(icon, size: 24, color: Colors.black),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(DuoIcon), findsNWidgets(AppIcon.values.length));
  });

  testWidgets('a chunky button sinks while pressed and comes back up', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(PillButton(label: 'Start', onPressed: () => taps++)),
    );
    double top() => tester.getTopLeft(find.byType(TextButton)).dy;
    final up = top();

    final press = await tester.startGesture(
      tester.getCenter(find.text('Start')),
    );
    await tester.pumpAndSettle();
    expect(top(), up + 5);

    await press.up();
    await tester.pumpAndSettle();
    expect(top(), up);
    expect(taps, 1);
  });

  testWidgets('clear glass draws in light and dark', (tester) async {
    for (final brightness in Brightness.values) {
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(platformBrightness: brightness),
          child: wrap(
            const GlassSurface(
              tone: GlassTone.clear,
              borderRadius: BorderRadius.all(Radius.circular(28)),
              child: SizedBox(width: 200, height: 60),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(BackdropFilter), findsOneWidget);
    }
  });
}
