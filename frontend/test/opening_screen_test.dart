import 'package:cogniguide/l10n/app_localizations.dart';
import 'package:cogniguide/main.dart';
import 'package:cogniguide/screens/opening_screen.dart';
import 'package:cogniguide/services/auth_service.dart';
import 'package:cogniguide/services/demo_mode.dart';
import 'package:cogniguide/services/problem_repository.dart';
import 'package:cogniguide/services/settings_store.dart';
import 'package:cogniguide/theme/app_theme.dart';
import 'package:cogniguide/widgets/pip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _next = Scaffold(body: Text('Next screen'));

Widget _app({bool reduceMotion = false, double textScale = 1}) => MaterialApp(
  theme: AppTheme.light,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(
      disableAnimations: reduceMotion,
      textScaler: TextScaler.linear(textScale),
    ),
    child: child!,
  ),
  home: const OpeningScreen(next: _next),
);

void main() {
  testWidgets(
    'Shows Pip, the name and the promise, then opens the next screen',
    (tester) async {
      await tester.pumpWidget(_app());

      expect(find.byType(Pip), findsOneWidget);
      expect(find.text('CogniGuide'), findsOneWidget);
      expect(find.text('Think it through, your way.'), findsOneWidget);
      expect(find.text('Next screen'), findsNothing);

      // Still showing just before the end.
      await tester.pump(const Duration(milliseconds: 1100));
      expect(find.text('Next screen'), findsNothing);

      await tester.pumpAndSettle();
      expect(find.text('Next screen'), findsOneWidget);
      expect(find.byType(OpeningScreen), findsNothing);
    },
  );

  testWidgets('The student cannot go back to it', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    expect(navigator.canPop(), isFalse);
  });

  testWidgets(
    'With reduce motion, Pip stays still and the app still moves on',
    (tester) async {
      await tester.pumpWidget(_app(reduceMotion: true));

      final scale = tester.widget<ScaleTransition>(
        find.ancestor(
          of: find.byType(Pip),
          matching: find.byType(ScaleTransition),
        ),
      );
      expect(scale.scale.value, 1);

      await tester.pump(const Duration(milliseconds: 1150));
      await tester.pumpAndSettle();
      expect(find.text('Next screen'), findsOneWidget);
    },
  );

  testWidgets('Fits a small phone with very large text', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(textScale: 2));
    await tester.pump(const Duration(milliseconds: 600));

    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
  });

  testWidgets('Text meets the 16px minimum', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(milliseconds: 600));

    final promise = tester.widget<Text>(
      find.text('Think it through, your way.'),
    );
    expect(promise.style!.fontSize, greaterThanOrEqualTo(16));
    await tester.pumpAndSettle();
  });

  for (final (name, saved, expected) in [
    ('A new student', <String, Object>{}, 'Create an account'),
    (
      'A logged-in student',
      <String, Object>{'student_code': 'P001'},
      'Hi, P001',
    ),
  ]) {
    testWidgets('$name reaches the right screen through it', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues(saved);
      final prefs = await SharedPreferences.getInstance();
      final auth = StandInAuthService(prefs);
      await tester.pumpWidget(
        CogniGuideApp(
          auth: auth,
          settings: SettingsStore(prefs),
          problems: LocalProblemRepository(),
          chat: DemoChatApi(),
          progress: DemoProgressApi(),
          loggedIn: await auth.currentCode() != null,
          showOpening: true,
        ),
      );

      expect(find.byType(OpeningScreen), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1150));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(seconds: 2));

      expect(find.byType(OpeningScreen), findsNothing);
      expect(find.text(expected), findsOneWidget);
    });
  }
}
