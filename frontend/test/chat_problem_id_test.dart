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
}
