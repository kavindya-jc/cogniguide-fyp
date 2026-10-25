import 'package:cogniguide/models/maths_area.dart';
import 'package:cogniguide/services/problem_repository.dart';
import 'package:cogniguide/widgets/problem_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test.dart' show startApp, tapVisible;

void main() {
  testWidgets('The sample problems file loads and filters', (tester) async {
    final repo = LocalProblemRepository();
    // Read the file with a real clock (the test clock does not wait).
    await tester.runAsync(() => repo.problems(area: MathsArea.number));

    final algebra = await repo.problems(area: MathsArea.algebra);
    expect(algebra.map((p) => p.text), contains('Solve: 3x − 5 = 2x + 7'));
    expect(algebra.every((p) => p.area == MathsArea.algebra), isTrue);

    final grade9 = await repo.problems(area: MathsArea.algebra, grade: 9);
    expect(grade9.length, 1);

    final none = await repo.problems(area: MathsArea.statistics, grade: 11);
    expect(none, isEmpty);
  });

  testWidgets('Pick a problem: greeting, cards, filters and empty state', (
    tester,
  ) async {
    await startApp(tester, saved: {'student_code': 'P001'});

    expect(find.text('Hi, P001'), findsOneWidget);
    expect(find.text('What would you like to work on?'), findsOneWidget);
    // Algebra is chosen first: 3 sample problems.
    expect(find.byType(ProblemCard), findsNWidgets(3));
    expect(find.text('Problem 1 · Algebra · Grade 9'), findsOneWidget);

    // Grade 10 only.
    await tester.tap(find.bySemanticsLabel('Grade 10'));
    await tester.pumpAndSettle();
    expect(find.byType(ProblemCard), findsOneWidget);
    expect(find.text('Factorise: x² + 5x + 6'), findsOneWidget);

    // Statistics, Grade 11: nothing yet.
    await tester.tap(find.bySemanticsLabel('Grade 11'));
    await tapVisible(tester, find.text('Statistics'));
    await tester.pumpAndSettle();
    expect(find.byType(ProblemCard), findsNothing);
    expect(
      find.text('No problems here yet. Try another area or type your own.'),
      findsOneWidget,
    );
  });

  testWidgets('Tapping a problem opens the chat with that problem', (
    tester,
  ) async {
    await startApp(tester, saved: {'student_code': 'P001'});

    await tester.tap(find.text('Solve: 3x − 5 = 2x + 7'));
    await tester.pumpAndSettle();
    expect(find.text('Problem 1 · Algebra · Grade 9'), findsOneWidget);
    expect(find.text('Solve: 3x − 5 = 2x + 7'), findsOneWidget);
  });

  testWidgets('Own problem: empty gets a fix message, text opens chat', (
    tester,
  ) async {
    await startApp(tester, saved: {'student_code': 'P001'});

    final start = find.bySemanticsLabel('Start with this problem');
    await tapVisible(tester, start);
    await tester.pumpAndSettle();
    expect(find.text('Type your problem first.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Find 20% of 350.');
    await tapVisible(tester, start);
    await tester.pumpAndSettle();
    expect(find.text('Your own problem'), findsOneWidget);
    expect(find.text('Find 20% of 350.'), findsOneWidget);
  });

  testWidgets('Settings shows the code; Log out sheet: Stay, then Log out', (
    tester,
  ) async {
    final prefs = await startApp(tester, saved: {'student_code': 'P001'});

    await tester.tap(find.bySemanticsLabel('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('P001'), findsOneWidget);
    expect(find.bySemanticsLabel('Your username: P001'), findsOneWidget);

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Log out?'), findsOneWidget);

    await tester.tap(find.text('Stay'));
    await tester.pumpAndSettle();
    expect(find.text('Log out?'), findsNothing);
    expect(prefs.getString('student_code'), 'P001');

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Log out').last);
    await tester.pumpAndSettle();
    expect(find.text('Think it through, your way.'), findsOneWidget);
    expect(prefs.getString('student_code'), isNull);
  });

  testWidgets('The bottom nav switches to My progress and back', (
    tester,
  ) async {
    await startApp(tester, saved: {'student_code': 'P001'});

    await tester.tap(find.text('My progress'));
    await tester.pumpAndSettle();
    expect(
      find.text('Only you can see this. It is not a grade.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Practice'));
    await tester.pumpAndSettle();
    expect(find.text('What would you like to work on?'), findsOneWidget);
  });
}
