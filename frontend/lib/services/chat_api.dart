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
    String? sessionId,
  }) async {
    final body = jsonEncode({
      'problem': problem,
      'history': [for (final turn in history) turn.toJson()],
      'student_id': ?studentId,
      'session_id': ?sessionId,
    });

    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$_baseUrl/chat'),
            headers: {'Content-Type': 'application/json'},
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

    if (response.statusCode == 503 && code == 'tutor_unavailable') {
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

  static Map<String, dynamic>? _decode(String body) {
    try {
      final value = jsonDecode(body);
      return value is Map<String, dynamic> ? value : null;
    } on FormatException {
      return null;
    }
  }
}
