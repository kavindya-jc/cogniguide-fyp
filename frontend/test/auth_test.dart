import 'dart:convert';

import 'package:cogniguide/main.dart';
import 'package:cogniguide/models/maths_area.dart';
import 'package:cogniguide/services/auth_service.dart';
import 'package:cogniguide/services/chat_api.dart';
import 'package:cogniguide/services/problem_repository.dart';
import 'package:cogniguide/services/progress_api.dart';
import 'package:cogniguide/services/settings_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'widget_test.dart'
    show coachSays, newStudent, pretendServer, progressSays, tapVisible;

http.Response replyWith(int status, Map<String, Object?> body) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

http.Response errorWith(int status, String code) => replyWith(status, {
  'error': {'code': code, 'message': code},
});

/// A [ServerAuthService] talking to a pretend server.
Future<
  (ServerAuthService, SharedPreferences, MemoryTokenStore, List<http.Request>)
>
makeAuth(http.Response Function(http.Request) answer) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final tokens = MemoryTokenStore();
  final asked = <http.Request>[];
  final auth = ServerAuthService(
    prefs,
    tokens,
    baseUrl: 'http://server',
    client: pretendServer((r) {
      asked.add(r);
      return answer(r);
    }),
  );
  return (auth, prefs, tokens, asked);
}

void main() {
  webAuthTests();
  group('ServerAuthService', () {
    test(
      'sign up: sends code + password, keeps only the token and code',
      () async {
        final (auth, prefs, tokens, asked) = await makeAuth(
          (_) => replyWith(201, {'token': 'tok-1', 'student_id': 'P001'}),
        );
        final r = await auth.signUp(code: 'P001', password: 'password1');

        expect(r, AuthResult.ok);
        expect(asked.single.url.toString(), 'http://server/auth/signup');
        expect(jsonDecode(asked.single.body), {
          'student_id': 'P001',
          'password': 'password1',
        });
        expect(await tokens.read(), 'tok-1');
        expect(await auth.currentCode(), 'P001');
        expect(await auth.token(), 'tok-1');
        // The password is never saved on the phone.
        for (final key in prefs.getKeys()) {
          expect(prefs.get(key).toString(), isNot(contains('password1')));
        }
      },
    );

    test('server answers map to the right result', () async {
      for (final (status, code, want) in [
        (409, 'code_taken', AuthResult.codeTaken),
        (401, 'details_dont_match', AuthResult.detailsDontMatch),
        (429, 'too_many_attempts', AuthResult.tooManyTries),
        (503, 'auth_unavailable', AuthResult.failed),
        (400, 'invalid_request', AuthResult.failed),
      ]) {
        final (auth, _, tokens, _) = await makeAuth(
          (_) => errorWith(status, code),
        );
        expect(
          await auth.logIn(code: 'P001', password: 'password1'),
          want,
          reason: '$status',
        );
        expect(await tokens.read(), isNull, reason: 'no token after $status');
        expect(await auth.currentCode(), isNull);
      }
    });

    test('no connection -> failed, nothing saved', () async {
      final (auth, _, tokens, _) = await makeAuth(
        (_) => throw http.ClientException('offline'),
      );
      expect(
        await auth.logIn(code: 'P001', password: 'password1'),
        AuthResult.failed,
      );
      expect(await tokens.read(), isNull);
    });

    test('log out forgets the token and the code', () async {
      final (auth, _, tokens, _) = await makeAuth(
        (_) => replyWith(200, {'token': 'tok-2', 'student_id': 'P001'}),
      );
      await auth.logIn(code: 'P001', password: 'password1');
      await auth.logOut();
      expect(await tokens.read(), isNull);
      expect(await auth.currentCode(), isNull);
    });

    test('a saved code without a token is not logged in', () async {
      SharedPreferences.setMockInitialValues({'student_code': 'P001'});
      final prefs = await SharedPreferences.getInstance();
      final auth = ServerAuthService(prefs, MemoryTokenStore());
      expect(await auth.currentCode(), isNull);
    });
  });

  group('ChatApi with a token', () {
    test('sends the token and reads 401 as "log in again"', () async {
      late http.Request asked;
      final api = ChatApi(
        baseUrl: 'http://server',
        client: pretendServer((r) {
          asked = r;
          return errorWith(401, 'login_required');
        }),
      );
      final r = await api.send(
        problem: 'Solve 3x = 6',
        history: const [],
        studentId: 'P001',
        token: 'tok-9',
      );
      expect(asked.headers['Authorization'], 'Bearer tok-9');
      expect((r as ChatFailure).problem, ChatProblem.loginExpired);
    });
  });

  testWidgets('an expired login sends the student to Log in with a note', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({
      'student_code': 'P001',
      'buddy': 'dino',
    });
    final prefs = await SharedPreferences.getInstance();
    final auth = ServerAuthService(prefs, MemoryTokenStore('old-token'));
    final problems = LocalProblemRepository();
    await tester.runAsync(() => problems.problems(area: MathsArea.number));

    await tester.pumpWidget(
      CogniGuideApp(
        auth: auth,
        settings: SettingsStore(prefs),
        problems: problems,
        chat: ChatApi(
          client: pretendServer((_) => errorWith(401, 'login_required')),
        ),
        progress: ProgressApi(
          client: pretendServer((_) => progressSays(newStudent)),
        ),
        loggedIn: await auth.currentCode() != null,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hi, P001'), findsOneWidget);

    await tester.tap(find.text('Solve: 3x − 5 = 2x + 7'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(
      find.text('Please log in again. Your progress is saved.'),
      findsOneWidget,
    );
    expect(await auth.token(), isNull);
    expect(prefs.getString('buddy'), isNull);
  });

  testWidgets('Log in: "too many tries" shows a calm note', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final auth = ServerAuthService(
      prefs,
      MemoryTokenStore(),
      client: pretendServer((_) => errorWith(429, 'too_many_attempts')),
    );
    await tester.pumpWidget(
      CogniGuideApp(
        auth: auth,
        settings: SettingsStore(prefs),
        problems: LocalProblemRepository(),
        chat: ChatApi(client: pretendServer((_) => coachSays('Hi'))),
        progress: ProgressApi(
          client: pretendServer((_) => progressSays(newStudent)),
        ),
        loggedIn: false,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'P001');
    await tester.enterText(fields.at(1), 'password1');
    await tapVisible(tester, find.widgetWithText(TextButton, 'Log in'));
    await tester.pumpAndSettle();
    expect(
      find.text('Too many tries. Please wait 15 minutes and try again.'),
      findsOneWidget,
    );
  });
}

// ---- The web version (a browser has no Keystore) ----

class _BrokenTokenStore implements TokenStore {
  @override
  Future<String?> read() async => null;
  @override
  Future<void> write(String token) async => throw StateError('storage broken');
  @override
  Future<void> delete() async {}
}

void webAuthTests() {
  group('web token storage', () {
    test('PrefsTokenStore keeps, reads and deletes the token', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = PrefsTokenStore(prefs);
      expect(await store.read(), isNull);
      await store.write('tok-web');
      expect(await store.read(), 'tok-web');
      await store.delete();
      expect(await store.read(), isNull);
    });

    test('a token that cannot be saved gives "failed", not a hang', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final auth = ServerAuthService(
        prefs,
        _BrokenTokenStore(),
        baseUrl: 'http://server',
        client: pretendServer(
          (_) => replyWith(201, {'token': 'tok-1', 'student_id': 'P001'}),
        ),
      );
      expect(
        await auth.signUp(code: 'P001', password: 'password1'),
        AuthResult.failed,
      );
      expect(await auth.currentCode(), isNull); // not half logged in
    });
  });
}
