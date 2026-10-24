import 'package:cogniguide/models/buddy.dart';
import 'package:cogniguide/widgets/buddy_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test.dart' show startApp, tapVisible;

/// The buddies on screen right now.
Iterable<Buddy> shownBuddies(WidgetTester tester) => tester
    .widgetList<BuddyAvatar>(find.byType(BuddyAvatar))
    .map((a) => a.buddy);

void main() {
  testWidgets('the buddy shows beside "Hi" on Pick a problem', (tester) async {
    await startApp(tester, saved: {'student_code': 'P001', 'buddy': 'dino'});
    expect(shownBuddies(tester), contains(Buddy.dino));
  });

  testWidgets('no buddy picked yet: Mochi stands in', (tester) async {
    await startApp(tester, saved: {'student_code': 'P001'});
    expect(shownBuddies(tester), contains(Buddy.mochi));
  });

  testWidgets('Settings: Change opens the picker and Save keeps the choice', (
    tester,
  ) async {
    final prefs = await startApp(
      tester,
      saved: {'student_code': 'P001', 'buddy': 'dino'},
    );
    await tester.tap(find.bySemanticsLabel('Settings'));
    await tester.pumpAndSettle();
    expect(shownBuddies(tester), contains(Buddy.dino));

    await tester.tap(find.bySemanticsLabel('Change your buddy'));
    await tester.pumpAndSettle();
    expect(find.text('Pick your buddy'), findsOneWidget);
    // The saved buddy starts chosen.
    expect(find.bySemanticsLabel('Your buddy: Dino'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Kitty'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Your buddy: Kitty'), findsOneWidget);

    await tapVisible(tester, find.text('Save'));
    await tester.pumpAndSettle();
    expect(prefs.getString('buddy'), 'kitty');
    // Back on Settings, showing the new buddy.
    expect(find.text('Settings'), findsWidgets);
    expect(shownBuddies(tester), contains(Buddy.kitty));
  });

  testWidgets('from Settings, the picker starts on the buddy you see', (
    tester,
  ) async {
    await startApp(tester, saved: {'student_code': 'P001'});
    await tester.tap(find.bySemanticsLabel('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Change your buddy'));
    await tester.pumpAndSettle();
    // No buddy picked yet: Settings showed Mochi, so the picker starts there.
    expect(find.bySemanticsLabel('Your buddy: Mochi'), findsOneWidget);
  });

  testWidgets('the student sees their buddy beside their own chat messages', (
    tester,
  ) async {
    await startApp(tester, saved: {'student_code': 'P001', 'buddy': 'rocket'});
    await tester.tap(find.text('Solve: 3x − 5 = 2x + 7'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'take away 2x');
    await tester.tap(find.bySemanticsLabel('Send'));
    await tester.pumpAndSettle();
    expect(shownBuddies(tester), contains(Buddy.rocket));
  });

  test('every buddy has its picture file', () {
    for (final b in Buddy.values) {
      expect(b.asset, 'assets/avatars/avatar-${b.name}.svg');
    }
  });
}
