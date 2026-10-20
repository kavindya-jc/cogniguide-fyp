import 'dart:async';
import 'dart:convert';

import 'package:cogniguide/services/chat_api.dart';
import 'package:cogniguide/widgets/chat_bubble.dart';
import 'package:cogniguide/widgets/typing_dots.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'widget_test.dart' show coachSays, pretendServer, startApp;

/// The JSON body the app sent.
Map<String, dynamic> bodyOf(http.Request r) =>
    jsonDecode(r.body) as Map<String, dynamic>;

http.Response serverError(int status, String code) => http.Response(
  jsonEncode({
    'error': {'code': code, 'message': 'test'},
  }),
  status,
);

/// Logs in as P001 and opens the first problem.
Future<void> openFirstProblem(WidgetTester tester, ChatApi chat) async {
  await startApp(tester, saved: {'student_code': 'P001'}, chat: chat);
  await tester.tap(find.text('Solve: 3x − 5 = 2x + 7'));
  await tester.pumpAndSettle();
}

Future<void> typeAndSend(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.tap(find.bySemanticsLabel('Send'));
  await tester.pumpAndSettle();
}

void main() {
  group('ChatApi', () {
    test('first call: empty history, no session, the student code', () async {
      late Map<String, dynamic> sent;
      final api = ChatApi(
        baseUrl: 'http://server',
        client: pretendServer((r) {
          expect(r.url.toString(), 'http://server/chat');
          sent = bodyOf(r);
          return coachSays('What do you notice first?');
        }),
      );

      final result = await api.send(
        problem: 'Solve: 3x − 5 = 2x + 7',
        history: const [],
        studentId: 'P001',
      );

      expect(sent['problem'], 'Solve: 3x − 5 = 2x + 7');
      expect(sent['history'], isEmpty);
      expect(sent['student_id'], 'P001');
      expect(sent.containsKey('session_id'), isFalse);
      expect(result, isA<ChatReply>());
      expect((result as ChatReply).reply, 'What do you notice first?');
      expect(result.sessionId, 'S-1');
    });

    test('503 tutor_unavailable is "busy"', () async {
      final api = ChatApi(
        client: pretendServer((_) => serverError(503, 'tutor_unavailable')),
      );
      final r = await api.send(
        problem: 'p',
        history: const [],
        studentId: 'P001',
      );
      expect((r as ChatFailure).problem, ChatProblem.busy);
    });

    test('500 and 400 are "something went wrong"', () async {
      for (final (status, code) in [
        (500, 'server_error'),
        (400, 'invalid_request'),
      ]) {
        final api = ChatApi(
          client: pretendServer((_) => serverError(status, code)),
        );
        final r = await api.send(
          problem: 'p',
          history: const [],
          studentId: 'P001',
        );
        expect((r as ChatFailure).problem, ChatProblem.failed, reason: code);
      }
    });

    test('a slow coach (timeout) is "busy", not "no internet"', () async {
      final never = Completer<http.Response>();
      final api = ChatApi(
        client: MockClient((_) => never.future),
        timeout: const Duration(milliseconds: 50),
      );
      final r = await api.send(
        problem: 'p',
        history: const [],
        studentId: 'P001',
      );
      expect((r as ChatFailure).problem, ChatProblem.busy);
    });

    test('no connection is "no internet"', () async {
      final api = ChatApi(
        client: pretendServer((_) => throw http.ClientException('offline')),
      );
      final r = await api.send(
        problem: 'p',
        history: const [],
        studentId: 'P001',
      );
      expect((r as ChatFailure).problem, ChatProblem.offline);
    });
  });

  group('Chat screen', () {
    testWidgets('the coach opens; history and session are sent back', (
      tester,
    ) async {
      final requests = <Map<String, dynamic>>[];
      final chat = ChatApi(
        client: pretendServer((r) {
          requests.add(bodyOf(r));
          return requests.length == 1
              ? coachSays('What is the first step?')
              : coachSays('Nice. What next?');
        }),
      );

      await openFirstProblem(tester, chat);

      // The coach spoke first, and only the reply text is shown.
      expect(find.text('What is the first step?'), findsOneWidget);
      expect(find.text('2'), findsNothing); // hint_level
      expect(find.text('improving'), findsNothing); // reflection_type

      await typeAndSend(tester, 'Add 5 to both sides');

      expect(requests.length, 2);
      expect(requests[1]['session_id'], 'S-1');
      expect(requests[1]['problem'], 'Solve: 3x − 5 = 2x + 7');
      expect(requests[1]['history'], [
        {'role': 'teacher', 'content': 'What is the first step?'},
        {'role': 'student', 'content': 'Add 5 to both sides'},
      ]);
      expect(find.text('Add 5 to both sides'), findsOneWidget);
      expect(find.text('Nice. What next?'), findsOneWidget);
    });

    testWidgets('busy: "Not sent", then Try again sends the same message', (
      tester,
    ) async {
      final requests = <Map<String, dynamic>>[];
      final chat = ChatApi(
        client: pretendServer((r) {
          requests.add(bodyOf(r));
          return switch (requests.length) {
            1 => coachSays('What is the first step?'),
            2 => serverError(503, 'tutor_unavailable'),
            _ => coachSays('Good thinking.'),
          };
        }),
      );

      await openFirstProblem(tester, chat);
      await typeAndSend(tester, 'x = 12');

      expect(find.text('Your coach is busy right now'), findsOneWidget);
      expect(find.text('Not sent'), findsOneWidget);
      final unsent = tester.widget<ChatBubble>(
        find.widgetWithText(ChatBubble, 'x = 12'),
      );
      expect(unsent.kind, BubbleKind.unsent);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(requests[2]['history'], requests[1]['history']);
      expect(find.text('Not sent'), findsNothing);
      expect(find.text('Good thinking.'), findsOneWidget);
    });

    testWidgets('no internet and something went wrong show their notices', (
      tester,
    ) async {
      var calls = 0;
      final chat = ChatApi(
        client: pretendServer((_) {
          calls++;
          if (calls == 1) throw http.ClientException('offline');
          return serverError(500, 'server_error');
        }),
      );

      await openFirstProblem(tester, chat);
      expect(find.text('No internet'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets(r'coach maths like $2x$ shows as plain 2x', (tester) async {
      final chat = ChatApi(
        client: pretendServer(
          (_) => coachSays(r'If you subtract $2x$ from both sides?'),
        ),
      );
      await openFirstProblem(tester, chat);
      expect(find.text('If you subtract 2x from both sides?'), findsOneWidget);
    });

    testWidgets('typing dots show while waiting; maths keys type', (
      tester,
    ) async {
      // The pretend coach answers only when the test says so.
      final answer = Completer<http.Response>();
      final chat = ChatApi(client: MockClient((_) => answer.future));
      await startApp(tester, saved: {'student_code': 'P001'}, chat: chat);
      await tester.tap(find.text('Solve: 3x − 5 = 2x + 7'));
      await tester.pump(); // the chat opens; the coach has not answered yet
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(TypingDots), findsOneWidget);

      answer.complete(coachSays('Hello!'));
      await tester.pumpAndSettle();
      expect(find.byType(TypingDots), findsNothing);

      await tester.enterText(find.byType(TextField), 'x');
      await tester.tap(find.text('×'));
      await tester.pump();
      expect(find.text('x×'), findsOneWidget);
    });
  });
}
