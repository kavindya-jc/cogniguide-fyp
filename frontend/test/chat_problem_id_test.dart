import 'dart:convert';

import 'package:cogniguide/services/chat_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'widget_test.dart' show coachSays, pretendServer;

/// Agent plan, Phase 2: a problem from the list is sent with its id, so the
/// server can check the student's answer against its answer sheet.
void main() {
  Future<Map<String, dynamic>> sentBody({String? problemId}) async {
    late http.Request asked;
    final api = ChatApi(
      baseUrl: 'http://server',
      client: pretendServer((r) {
        asked = r;
        return coachSays('What could you do first?');
      }),
    );
    await api.send(
      problem: 'Solve: 3x − 5 = 2x + 7',
      history: const [],
      studentId: 'P001',
      problemId: problemId,
    );
    return jsonDecode(asked.body) as Map<String, dynamic>;
  }

  test('a problem from the list sends its id and its text', () async {
    final body = await sentBody(problemId: 'alg-9-1');
    expect(body['problem_id'], 'alg-9-1');
    expect(body['problem'], 'Solve: 3x − 5 = 2x + 7');
  });

  test('a typed-in problem sends no id', () async {
    final body = await sentBody();
    expect(body.containsKey('problem_id'), isFalse);
  });

  group('endSession (research data)', () {
    test('sends the session, the reason and the login', () async {
      late http.Request asked;
      final api = ChatApi(
        baseUrl: 'http://server',
        client: pretendServer((r) {
          asked = r;
          return http.Response('{"status": "solved", "verified": true}', 200);
        }),
      );
      await api.endSession(
        sessionId: 'abc',
        reason: 'worked_it_out',
        token: 'tok-1',
      );
      expect(asked.url.toString(), 'http://server/session/end');
      expect(asked.headers['Authorization'], 'Bearer tok-1');
      expect(jsonDecode(asked.body), {
        'session_id': 'abc',
        'reason': 'worked_it_out',
      });
    });

    test('without a login nothing is sent', () async {
      var calls = 0;
      final api = ChatApi(
        client: pretendServer((_) {
          calls++;
          return http.Response('{}', 200);
        }),
      );
      await api.endSession(sessionId: 'abc', reason: 'left', token: null);
      expect(calls, 0);
    });

    test('no internet never shows an error to the student', () async {
      final api = ChatApi(
        client: pretendServer((_) => throw http.ClientException('offline')),
      );
      await api.endSession(sessionId: 'abc', reason: 'left', token: 'tok');
    });
  });
}
