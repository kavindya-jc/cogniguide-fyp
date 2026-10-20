import 'package:cogniguide/l10n/app_localizations.dart';
import 'package:cogniguide/models/maths_area.dart';
import 'package:cogniguide/theme/app_theme.dart';
import 'package:cogniguide/widgets/area_chip.dart';
import 'package:cogniguide/widgets/grade_filter.dart';
import 'package:cogniguide/widgets/labelled_field.dart';
import 'package:cogniguide/widgets/notice_card.dart';
import 'package:cogniguide/widgets/pill_button.dart';
import 'package:cogniguide/widgets/pip.dart';
import 'package:cogniguide/widgets/problem_card.dart';
import 'package:cogniguide/widgets/round_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Puts a widget inside the app's theme and language files.
Widget wrap(Widget child) => MaterialApp(
  theme: AppTheme.light,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('PillButton is 52 tall and reacts to a tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(PillButton(label: 'Start', onPressed: () => taps++)),
    );

    expect(tester.getSize(find.byType(TextButton)).height, 52);
    await tester.tap(find.text('Start'));
    expect(taps, 1);
  });

  testWidgets('A loading PillButton cannot be tapped', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(
        PillButton(
          label: 'Logging you in',
          loading: true,
          onPressed: () => taps++,
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.text('Logging you in'));
    expect(taps, 0);
  });

  testWidgets('RoundIconButton has its screen reader label', (tester) async {
    await tester.pumpWidget(
      wrap(
        RoundIconButton(
          icon: Icons.arrow_back_rounded,
          semanticLabel: 'Back',
          onPressed: () {},
        ),
      ),
    );

    expect(find.bySemanticsLabel('Back'), findsOneWidget);
    expect(tester.getSize(find.byType(IconButton)), const Size(48, 48));
  });

  testWidgets('LabelledField shows a fix message with an icon', (tester) async {
    await tester.pumpWidget(
      wrap(
        const SizedBox(
          width: 340,
          child: LabelledField(label: 'Password', fixMessage: 'Add 2 more.'),
        ),
      ),
    );

    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Add 2 more.'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
  });

  testWidgets('AreaChipRow shows 6 areas and a tick on the chosen one', (
    tester,
  ) async {
    MathsArea? picked;
    await tester.pumpWidget(
      wrap(
        AreaChipRow(selected: MathsArea.algebra, onChanged: (a) => picked = a),
      ),
    );

    expect(find.byType(AreaChip), findsNWidgets(6));
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(
      tester.getSize(find.byType(AreaChip).first).height,
      greaterThanOrEqualTo(44),
    );

    await tester.tap(find.text('Number'));
    expect(picked, MathsArea.number);
  });

  testWidgets('GradeFilter buttons are at least 44 × 44', (tester) async {
    int? picked = -1;
    await tester.pumpWidget(
      wrap(GradeFilter(selected: null, onChanged: (g) => picked = g)),
    );

    final button = tester.getSize(find.text('10'));
    expect(button.height, lessThan(44)); // the text itself
    final tapArea = tester.getSize(
      find.ancestor(of: find.text('10'), matching: find.byType(InkWell)),
    );
    expect(tapArea.width, greaterThanOrEqualTo(44));
    expect(tapArea.height, greaterThanOrEqualTo(44));

    expect(find.bySemanticsLabel('Grade 10'), findsOneWidget);
    await tester.tap(find.text('10'));
    expect(picked, 10);
  });

  testWidgets('ProblemCard shows the eyebrow in capitals', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(
        SizedBox(
          width: 350,
          child: ProblemCard(
            index: 0,
            eyebrow: 'Problem 1 · Algebra · Grade 9',
            text: 'Solve: 3x − 5 = 2x + 7',
            onTap: () => taps++,
          ),
        ),
      ),
    );

    expect(find.text('PROBLEM 1 · ALGEBRA · GRADE 9'), findsOneWidget);
    await tester.tap(find.byType(ProblemCard));
    expect(taps, 1);
  });

  testWidgets('NoticeCard shows its icon and words', (tester) async {
    await tester.pumpWidget(
      wrap(
        const SizedBox(
          width: 340,
          child: NoticeCard(
            icon: Icons.schedule_rounded,
            text: 'Coach is busy',
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
    expect(find.text('Coach is busy'), findsOneWidget);
  });

  testWidgets('Pip has a screen reader name for each mood', (tester) async {
    await tester.pumpWidget(wrap(const Pip(mood: PipMood.sleepy)));
    expect(find.bySemanticsLabel('Your coach, resting'), findsOneWidget);
  });
}
