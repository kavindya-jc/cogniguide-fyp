import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'progress_test.dart' show fourSessions, serverSays;
import 'widget_test.dart' show startApp, tapVisible;

/// Opens problem 1 and sends one message.
Future<void> chatAndReply(WidgetTester tester) async {
  await tester.tap(find.text('Solve: 3x − 5 = 2x + 7'));
  await tester.pumpAndSettle();
  // No message from the student yet: no button.
  expect(find.text('I worked it out!'), findsNothing);

  await tester.enterText(find.byType(TextField), 'take away 2x');
  await tester.tap(find.bySemanticsLabel('Send'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('"I worked it out!" appears after a message and celebrates', (
    tester,
  ) async {
    await startApp(tester, saved: {'student_code': 'P001'});
    await chatAndReply(tester);

    await tapVisible(tester, find.text('I worked it out!'));
    await tester.pumpAndSettle();

    expect(find.text('You worked it out yourself!'), findsOneWidget);
    // Only numbers the app knows, never a score.
    expect(find.bySemanticsLabel('1, Messages you sent'), findsOneWidget);
    expect(find.bySemanticsLabel('1, Minutes thinking'), findsOneWidget);
    expect(find.textContaining('point'), findsNothing);
    expect(find.textContaining('score'), findsNothing);
  });

  testWidgets('Try another problem goes back to Practice', (tester) async {
    await startApp(tester, saved: {'student_code': 'P001'});
    await chatAndReply(tester);
    await tapVisible(tester, find.text('I worked it out!'));
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('Try another problem'));
    await tester.pumpAndSettle();
    expect(find.text('What would you like to work on?'), findsOneWidget);
  });

  testWidgets('See my progress opens the My progress tab', (tester) async {
    await startApp(
      tester,
      saved: {'student_code': 'P001'},
      progress: serverSays(fourSessions),
    );
    await chatAndReply(tester);
    await tapVisible(tester, find.text('I worked it out!'));
    await tester.pumpAndSettle();

    await tapVisible(tester, find.text('See my progress'));
    await tester.pumpAndSettle();
    expect(
      find.text('You are needing a little less help than before.'),
      findsOneWidget,
    );
  });
}
