import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test.dart' show startApp, tapVisible;

/// The brightness the app is drawn with right now.
Brightness shown(WidgetTester tester) =>
    Theme.of(tester.element(find.text('Settings').first)).brightness;

void main() {
  testWidgets('Settings: Light, Dark or Same as phone, and it is saved', (
    tester,
  ) async {
    final prefs = await startApp(tester, saved: {'student_code': 'P001'});
    await tester.tap(find.bySemanticsLabel('Settings'));
    await tester.pumpAndSettle();

    // The test phone is in light mode, and "Same as phone" is the default.
    expect(shown(tester), Brightness.light);

    await tapVisible(tester, find.text('Dark'));
    await tester.pumpAndSettle();
    expect(shown(tester), Brightness.dark);
    expect(prefs.getString('theme_mode'), 'dark');

    await tapVisible(tester, find.text('Light'));
    await tester.pumpAndSettle();
    expect(shown(tester), Brightness.light);

    await tapVisible(tester, find.text('Same as phone'));
    await tester.pumpAndSettle();
    expect(prefs.getString('theme_mode'), 'system');
  });

  testWidgets('a saved Dark choice is used when the app opens', (tester) async {
    await startApp(
      tester,
      saved: {'student_code': 'P001', 'theme_mode': 'dark'},
    );
    final context = tester.element(find.text('Practice'));
    expect(Theme.of(context).brightness, Brightness.dark);
  });
}
