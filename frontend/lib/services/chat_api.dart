import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// Who said a message, in the server's words.
enum ChatRole { teacher, student }

/// One message in the conversation history.
class ChatTurn {
  const ChatTurn(this.role, this.content);

  final ChatRole role;
  final String content;

  Map<String, String> toJson() => {'role': role.name, 'content': content};
}

/// Limits from docs/api_contract.md.
const int maxHistoryItems = 50;
const int maxMessageLength = 2000;

/// What went wrong, in the 3 ways the student sees it.
enum ChatProblem {
  /// 503 tutor_unavailable, or the server took too long (the AI was
  /// overloaded): "Your coach is busy". Safe to send again.
  busy,

  /// 500, 400 (an app bug) or anything unexpected: "Something went wrong".
  failed,

  /// The server could not be reached at all: "No internet".
  offline,

  /// 401: the login token is wrong or too old. Log in again.
  loginExpired,
}

/// The answer from [ChatApi.send]: a reply, or a problem.
sealed class ChatResult {
  const ChatResult();
}

class ChatReply extends ChatResult {
  const ChatReply({required this.reply, required this.sessionId});

  /// The coach's message. The ONLY part of the reply the app shows.
  final String reply;

  /// Send this back on every later call of the same chat (may be null).
  final String? sessionId;
}

class ChatFailure extends ChatResult {
  const ChatFailure(this.problem);

  final ChatProblem problem;
}

/// One chat in the Recent chats list.
class RecentChat {
  const RecentChat({
    required this.sessionId,
    required this.problem,
    required this.problemId,
    required this.solved,
    required this.startedAt,
  });

  final String sessionId;
  final String problem;

  /// Null for a problem the student typed in.
  final String? problemId;
  final bool solved;
  final DateTime? startedAt;

  /// Null when the row is missing its id or problem.
  static RecentChat? fromJson(Map<String, dynamic> json) {
    final id = json['session_id'];
    final problem = json['problem'];
    if (id is! String || problem is! String || problem.isEmpty) return null;
    final problemId = json['problem_id'];
    return RecentChat(
      sessionId: id,
      problem: problem,
      problemId: problemId is String ? problemId : null,
      solved: json['status'] == 'solved',
      startedAt: DateTime.tryParse('${json['started_at']}')?.toLocal(),
    );
  }
}

/// Talks to `POST /chat` on the CogniGuide server.
///
/// The server keeps no memory, so the app sends the whole [history] every
/// time. The reply also has hint_level, scaffold_level and reflection_type:
/// they are never read here, so they can never be shown to the student.
class ChatApi {
  ChatApi({http.Client? client, String? baseUrl, Duration? timeout})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
      _timeout = timeout ?? AppConfig.chatTimeout;

  final http.Client _client;
  final String _baseUrl;
  final Duration _timeout;

  Future<ChatResult> send({
    required String problem,
    required List<ChatTurn> history,
    required String? studentId,
    String? problemId,
    String? sessionId,
    String? token,
  }) async {
    final body = jsonEncode({
      'problem': problem,
      // A problem from the list: the server checks answers with its answer sheet.
      'problem_id': ?problemId,
      'history': [for (final turn in history) turn.toJson()],
      'student_id': ?studentId,
      'session_id': ?sessionId,
    });

    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$_baseUrl/chat'),
            headers: {
              'Content-Type': 'application/json',
              // Stage 7c: the server knows the student from this token.
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: body,
          )
          .timeout(_timeout);
    } on TimeoutException {
      // The internet works, but the coach is slow (the server keeps
      // retrying the AI). "Busy" is the honest message here.
      return const ChatFailure(ChatProblem.busy);
    } on http.ClientException {
      return const ChatFailure(ChatProblem.offline);
    }

    final json = _decode(response.body);

    if (response.statusCode == 200) {
      final reply = json?['reply'];
      if (reply is String && reply.isNotEmpty) {
        final session = json?['session_id'];
        return ChatReply(
          reply: reply,
          sessionId: session is String ? session : null,
        );
      }
      return const ChatFailure(ChatProblem.failed);
    }

    final error = json?['error'];
    final code = error is Map ? error['code'] : null;

    if (response.statusCode == 401) {
      return const ChatFailure(ChatProblem.loginExpired);
    }
    // 429: too many messages in a minute. "Wait a moment, then try again"
    // is the right advice, so it shows like "busy".
    if ((response.statusCode == 503 && code == 'tutor_unavailable') ||
        response.statusCode == 429) {
      return const ChatFailure(ChatProblem.busy);
    }
    if (response.statusCode == 400) {
      // A bug in the app. Log the server's reason only (never the
      // student's words), and show "Something went wrong".
      final reason = error is Map ? error['message'] : null;
      debugPrint('CogniGuide: /chat said invalid_request: $reason');
    }
    return const ChatFailure(ChatProblem.failed);
  }

  /// Tells the server the chat is over: [reason] is "worked_it_out" (the
  /// student pressed "I worked it out!") or "left". The server checks its
  /// own notes to see if the answer was really found. This is research data
  /// only: the student never waits for it or sees an error from it.
  Future<void> endSession({
    required String sessionId,
    required String reason,
    String? token,
  }) async {
    if (token == null) return; // nothing was saved for a chat without login
    try {
      await _client
          .post(
            Uri.parse('$_baseUrl/session/end'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'session_id': sessionId, 'reason': reason}),
          )
          .timeout(_timeout);
    } on Exception catch (e) {
      debugPrint('CogniGuide: could not end the session: ${e.runtimeType}');
    }
  }

  /// Recent chats (`GET /sessions`): the student's newest chats, newest
  /// first. Null when they could not be loaded (no login, offline, an old
  /// server without this endpoint).
  Future<List<RecentChat>?> recentChats({String? token}) async {
    final json = await _get('/sessions', token);
    final list = json?['sessions'];
    if (list is! List) return null;
    return [
      for (final item in list)
        if (item is Map<String, dynamic>) ?RecentChat.fromJson(item),
    ];
  }

  /// One old chat's messages, oldest first (`GET /sessions/{id}/messages`),
  /// to carry it on. Null when it could not be loaded.
  Future<List<ChatTurn>?> chatMessages({
    required String sessionId,
    String? token,
  }) async {
    final json = await _get(
      '/sessions/${Uri.encodeComponent(sessionId)}/messages',
      token,
    );
    final list = json?['messages'];
    if (list is! List) return null;
    return [
      for (final m in list)
        if (m is Map &&
            m['content'] is String &&
            ChatRole.values.any((r) => r.name == m['role']))
          ChatTurn(ChatRole.values.byName(m['role'] as String), m['content']),
    ];
  }

  /// A logged-in GET; the JSON body of a 200 reply, or null.
  Future<Map<String, dynamic>?> _get(String path, String? token) async {
    if (token == null) return null; // only saved chats can come back
    try {
      final response = await _client
          .get(
            Uri.parse('$_baseUrl$path'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(_timeout);
      return response.statusCode == 200 ? _decode(response.body) : null;
    } on Exception catch (e) {
      debugPrint('CogniGuide: could not load $path: ${e.runtimeType}');
      return null;
    }
  }

  static Map<String, dynamic>? _decode(String body) {
    try {
      final value = jsonDecode(body);
      return value is Map<String, dynamic> ? value : null;
    } on FormatException {
      return null;
    }
  }
}
