import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'progress_test.dart' show fourSessions, serverSays;
import 'widget_test.dart' show startApp, tapVisible;

/// Checks that nothing is cut off ("overflowed") with the app's REAL fonts,
/// on a phone 360 wide (a common small Android size), at normal text size
/// and at large text (1.3x), in light and dark. Normal tests use a stand-in font, so they
/// cannot catch this.
void main() {
  setUpAll(() async {
    final font = FontLoader('PlusJakartaSans')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-Variable.ttf'));
    await font.load();
    final headings = FontLoader(
      'BricolageGrotesque',
    )..addFont(rootBundle.load('assets/fonts/BricolageGrotesque-Variable.ttf'));
    await headings.load();
  });

  for (final (scale, brightness) in [
    (1.0, Brightness.light),
    (1.3, Brightness.light),
    (1.3, Brightness.dark),
  ]) {
    testWidgets('no text is cut off at text size $scale, ${brightness.name}', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

      // Welcome, Create account, Log in.
      await startApp(tester);
      tester.view.physicalSize = const Size(360 * 3, 780 * 3);
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Create an account'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('I already have an account'));
      await tester.pumpAndSettle();

      // Start a fresh app (clear the first one away).
      await tester.pumpWidget(const SizedBox());

      // Pick a problem, My progress (with a chart), the list, Settings.
      await startApp(
        tester,
        saved: {'student_code': 'P001'},
        progress: serverSays(fourSessions),
      );
      tester.view.physicalSize = const Size(360 * 3, 780 * 3);
      await tester.pumpAndSettle();
      await tester.tap(find.text('My progress'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Show the same numbers as a list'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Back to my progress'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Practice'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Settings'));
      await tester.pumpAndSettle();
      // Pick your buddy (from Settings), then back.
      await tester.tap(find.bySemanticsLabel('Change your buddy'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Back to problems'));
      await tester.pumpAndSettle();

      // Chat.
      await tester.tap(find.text('Solve: 3x − 5 = 2x + 7'));
      await tester.pumpAndSettle();

      // Any "overflowed" error would have failed the test above.
      expect(tester.takeException(), isNull);
    });
  }
}
