import 'package:cogniguide/main.dart';
import 'package:cogniguide/models/maths_area.dart';
import 'package:cogniguide/services/auth_service.dart';
import 'package:cogniguide/services/chat_api.dart';
import 'package:cogniguide/services/problem_repository.dart';
import 'package:cogniguide/services/progress_api.dart';
import 'package:cogniguide/services/settings_store.dart';
import 'package:cogniguide/theme/app_colors.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Starts the app with fresh phone storage.
Future<SharedPreferences> startApp(
  WidgetTester tester, {
  Map<String, Object> saved = const {},
  ChatApi? chat,
  ProgressApi? progress,
}) async {
  // A phone-sized screen (the design's 390 × 844).
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues(saved);
  final prefs = await SharedPreferences.getInstance();
  final auth = StandInAuthService(prefs);

  // Read the problems file once with a real clock. (The test clock does
  // not wait for files, so the screen would stay on "loading".)
  final problems = LocalProblemRepository();
  await tester.runAsync(() => problems.problems(area: MathsArea.number));

  await tester.pumpWidget(
    CogniGuideApp(
      auth: auth,
      settings: SettingsStore(prefs),
      problems: problems,
      // A pretend server, so tests never call the real one.
      chat: chat ?? ChatApi(client: pretendServer((_) => coachSays('Hello!'))),
      progress:
          progress ??
          ProgressApi(client: pretendServer((_) => progressSays(newStudent))),
      loggedIn: await auth.currentCode() != null,
    ),
  );
  await tester.pumpAndSettle();
  return prefs;
}

void main() {
  testWidgets('A new student sees Welcome with the CogniGuide theme', (
    tester,
  ) async {
    await startApp(tester);

    expect(find.text('Think it through, your way.'), findsOneWidget);
    final context = tester.element(find.byType(Scaffold));
    expect(Theme.of(context).scaffoldBackgroundColor, AppColors.light.surface);
  });

  testWidgets('A logged-in student goes straight to Pick a problem', (
    tester,
  ) async {
    await startApp(tester, saved: {'student_code': 'P001'});
    expect(find.text('Hi, P001'), findsOneWidget);
  });

  testWidgets('Create account: fix messages, then in, then log out', (
    tester,
  ) async {
    final prefs = await startApp(tester);

    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();
    expect(find.text('Create your account'), findsOneWidget);

    // A name with a space, a short password, and passwords that differ.
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Nimal Perera');
    await tester.enterText(fields.at(1), 'abc123');
    await tester.enterText(fields.at(2), 'abc12');
    await tapVisible(tester, find.text('Create account'));
    await tester.pumpAndSettle();

    expect(
      find.text('Use only letters, numbers, _ or -, with no spaces.'),
      findsOneWidget,
    );
    expect(
      find.text('Your password needs at least 8 characters. Add 2 more.'),
      findsOneWidget,
    );
    expect(
      find.text("The two passwords don't match yet. Type it again slowly."),
      findsOneWidget,
    );
    expect(find.text('Almost there. A few small things to fix.'), findsOne);

    // Fix them.
    await tester.enterText(fields.at(0), 'P001');
    await tester.enterText(fields.at(1), 'password1');
    await tester.enterText(fields.at(2), 'password1');
    await tapVisible(tester, find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Hi, P001'), findsOneWidget);
    // Only the code is saved on the phone, never the password.
    expect(prefs.getString('student_code'), 'P001');
    for (final key in prefs.getKeys()) {
      expect(prefs.get(key).toString(), isNot(contains('password1')));
    }

    // Log out opens the "Log out?" sheet; its dark button logs out.
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Log out').last);
    await tester.pumpAndSettle();
    expect(find.text('Think it through, your way.'), findsOneWidget);
    expect(prefs.getString('student_code'), isNull);
  });

  testWidgets('Log in: empty fields get fix messages', (tester) async {
    await startApp(tester);

    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.widgetWithText(TextButton, 'Log in'));
    await tester.pumpAndSettle();

    expect(find.text('Type a code first, for example P001.'), findsOneWidget);
    expect(find.text('Type your password.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'TEST01');
    await tester.enterText(find.byType(TextField).at(1), 'anything');
    await tapVisible(tester, find.widgetWithText(TextButton, 'Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Hi, TEST01'), findsOneWidget);
  });

  testWidgets('Language: the choice is saved and shown on Welcome', (
    tester,
  ) async {
    final prefs = await startApp(tester);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a language'), findsOneWidget);

    await tester.tap(find.text('தமிழ்'));
    await tester.pumpAndSettle();
    expect(prefs.getString('language'), 'ta');

    await tapVisible(tester, find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('தமிழ்'), findsOneWidget);
  });
}

/// Scrolls a button into view (the page may be taller than the phone),
/// then taps it.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

/// A pretend CogniGuide server for tests. [answer] gets each request.
http.Client pretendServer(http.Response Function(http.Request) answer) =>
    MockClient((request) async => answer(request));

/// A normal `/chat` reply. The extra numbers are there on purpose:
/// the app must never show them.
http.Response coachSays(String reply, {String session = 'S-1'}) =>
    http.Response(
      jsonEncode({
        'reply': reply,
        'session_id': session,
        'hint_level': 2,
        'scaffold_level': 3,
        'reflection_type': 'improving',
      }),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

/// A `/progress` reply with [body] as JSON.
http.Response progressSays(Map<String, Object?> body) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// What the server sends for a code it has never seen.
const Map<String, Object?> newStudent = {
  'student_id': 'P001',
  'sessions': <Object>[],
  'totals': {
    'sessions': 0,
    'stuck': 0,
    'asked_for_answer': 0,
    'self_corrections': 0,
    'reflections': 0,
  },
  'growth': {
    'trend': 'not_enough_data',
    'message': 'Not enough sessions yet. Come back after a couple more.',
  },
};
