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
    show coachSays, newStudent, pretendServer, progressSays, startApp;

const _old = 'aaaaaaaa-1111-4111-8111-111111111111';

http.Response json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// A pretend server with one solved old chat and one unfinished one.
http.Response oldChats(http.Request r) {
  final path = r.url.path;
  if (path.endsWith('/sessions')) {
    return json({
      'sessions': [
        {
          'session_id': _old,
          'problem': 'Solve: 3x − 5 = 2x + 7',
          'problem_id': 'alg-9-1',
          'status': 'active',
          'started_at': '2026-10-30T10:00:00+00:00',
        },
        {
          'session_id': 'bbbbbbbb-2222-4222-8222-222222222222',
          'problem': 'Find 20% of 350.',
          'problem_id': null,
          'status': 'solved',
          'started_at': '2026-10-29T10:00:00+00:00',
        },
      ],
    });
  }
  if (path.endsWith('/sessions/$_old/messages')) {
    return json({
      'session_id': _old,
      'problem': 'Solve: 3x − 5 = 2x + 7',
      'messages': [
        {'role': 'teacher', 'content': 'What do you notice first?'},
        {'role': 'student', 'content': 'There are x on both sides'},
        {'role': 'teacher', 'content': 'Good. What could you do with them?'},
      ],
    });
  }
  return coachSays('Nice, keep going.', session: _old);
}

/// The app with a real login token, so saved chats can come back.
Future<void> startLoggedIn(
  WidgetTester tester,
  http.Response Function(http.Request) server,
) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({'student_code': 'P001'});
  final prefs = await SharedPreferences.getInstance();
  final auth = ServerAuthService(prefs, MemoryTokenStore('tok'));
  final problems = LocalProblemRepository();
  await tester.runAsync(() => problems.problems(area: MathsArea.number));

  await tester.pumpWidget(
    CogniGuideApp(
      auth: auth,
      settings: SettingsStore(prefs),
      problems: problems,
      chat: ChatApi(client: pretendServer(server)),
      progress: ProgressApi(
        client: pretendServer((_) => progressSays(newStudent)),
      ),
      loggedIn: true,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ChatApi recent chats', () {
    test('reads the list with the login token', () async {
      String? auth;
      final api = ChatApi(
        baseUrl: 'http://server',
        client: pretendServer((r) {
          auth = r.headers['Authorization'];
          return oldChats(r);
        }),
      );
      final chats = await api.recentChats(token: 'tok');
      expect(auth, 'Bearer tok');
      expect(chats!.map((c) => c.problem), [
        'Solve: 3x − 5 = 2x + 7',
        'Find 20% of 350.',
      ]);
      expect(chats.first.problemId, 'alg-9-1');
      expect(chats.first.solved, isFalse);
      expect(chats.last.solved, isTrue);
    });

    test('no login, or an old server without the list: null', () async {
      final api = ChatApi(
        baseUrl: 'http://server',
        client: pretendServer((_) => json({'error': {}}, 404)),
      );
      expect(await api.recentChats(token: null), isNull);
      expect(await api.recentChats(token: 'tok'), isNull);
      expect(await api.chatMessages(sessionId: _old, token: 'tok'), isNull);
    });

    test('reads one chat\'s messages in order', () async {
      final api = ChatApi(
        baseUrl: 'http://server',
        client: pretendServer(oldChats),
      );
      final turns = await api.chatMessages(sessionId: _old, token: 'tok');
      expect(turns!.map((t) => t.role), [
        ChatRole.teacher,
        ChatRole.student,
        ChatRole.teacher,
      ]);
      expect(turns.last.content, 'Good. What could you do with them?');
    });
  });

  testWidgets('Recent chats: open an old chat and carry on', (tester) async {
    final chatCalls = <Map<String, dynamic>>[];
    await startLoggedIn(tester, (r) {
      if (r.url.path.endsWith('/chat')) {
        chatCalls.add(jsonDecode(r.body) as Map<String, dynamic>);
      }
      return oldChats(r);
    });

    await tester.tap(find.bySemanticsLabel('Recent chats'));
    await tester.pumpAndSettle();
    expect(find.text('Find 20% of 350.'), findsOneWidget);
    // Solved: an icon and the word, not colour alone.
    expect(find.text('Solved'), findsOneWidget);

    await tester.tap(find.text('Solve: 3x − 5 = 2x + 7').last);
    await tester.pumpAndSettle();

    // The old messages are back, and the coach did not start again.
    expect(find.text('There are x on both sides'), findsOneWidget);
    expect(find.text('Good. What could you do with them?'), findsOneWidget);
    expect(find.text('From your recent chats'), findsOneWidget);
    expect(chatCalls, isEmpty);

    // The next message carries on the same session, with the history.
    await tester.enterText(find.byType(TextField), 'Take x from both sides');
    await tester.tap(find.bySemanticsLabel('Send'));
    await tester.pumpAndSettle();
    expect(chatCalls, hasLength(1));
    expect(chatCalls.single['session_id'], _old);
    expect(chatCalls.single['problem_id'], 'alg-9-1');
    expect(chatCalls.single['history'], hasLength(4));
    expect(find.text('Nice, keep going.'), findsOneWidget);
  });

  testWidgets('Recent chats: a calm note when they cannot load', (
    tester,
  ) async {
    // The stand-in login has no token, like an old server: nothing loads.
    await startApp(tester, saved: {'student_code': 'P001'});

    await tester.tap(find.bySemanticsLabel('Recent chats'));
    await tester.pumpAndSettle();
    expect(
      find.text('Your chats could not be loaded. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);

    // A tap on the dimmed page beside the panel closes it.
    await tester.tapAt(const Offset(380, 420));
    await tester.pumpAndSettle();
    expect(find.text('Recent chats'), findsNothing);
  });

  testWidgets('Recent chats: a new student sees how to start', (tester) async {
    await startLoggedIn(
      tester,
      (r) => r.url.path.endsWith('/sessions')
          ? json({'sessions': []})
          : coachSays('Hello!'),
    );
    await tester.tap(find.bySemanticsLabel('Recent chats'));
    await tester.pumpAndSettle();
    expect(
      find.text('No chats yet. Pick a problem to start one.'),
      findsOneWidget,
    );
  });

  testWidgets('Chat: the floating Problem button shows the whole problem', (
    tester,
  ) async {
    await startApp(tester, saved: {'student_code': 'P001'});
    await tester.tap(find.text('Solve: 3x − 5 = 2x + 7'));
    await tester.pumpAndSettle();

    // The problem is the first card of the chat.
    expect(find.text('Your thinking coach'), findsOneWidget);
    expect(find.text('Solve: 3x − 5 = 2x + 7'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Show the problem'));
    await tester.pumpAndSettle();
    expect(find.text('The problem'), findsOneWidget);
    expect(find.text('Solve: 3x − 5 = 2x + 7'), findsNWidgets(2));

    await tester.tap(find.text('Back to the chat'));
    await tester.pumpAndSettle();
    expect(find.text('The problem'), findsNothing);
  });
}
