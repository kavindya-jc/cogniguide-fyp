import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// How much help a session needed, in words a student understands.
enum HelpNeeded {
  aLittle,
  some,
  aLot;

  /// The server's average hint level: 1 = a little help, 3 = a lot.
  static HelpNeeded fromLevel(double level) => level < 1.5
      ? HelpNeeded.aLittle
      : level < 2.5
      ? HelpNeeded.some
      : HelpNeeded.aLot;
}

/// One session on the chart.
class ProgressSession {
  const ProgressSession({required this.startedAt, required this.neededLevel});

  final DateTime? startedAt;

  /// 1 (a little help) to 3 (a lot). Lower is better.
  final double neededLevel;

  HelpNeeded get help => HelpNeeded.fromLevel(neededLevel);
}

/// Everything My progress shows. Numbers only: no message text, no
/// hint levels from the chat, no scores.
class Progress {
  const Progress({
    required this.sessions,
    required this.sessionCount,
    required this.selfCorrections,
    required this.stuck,
    required this.reflections,
    required this.growthMessage,
    required this.enoughData,
  });

  /// Oldest first.
  final List<ProgressSession> sessions;
  final int sessionCount;
  final int selfCorrections;
  final int stuck;
  final int reflections;

  /// The growth sentence for the student, written by the server.
  final String growthMessage;

  /// False when the trend is "not_enough_data": hide the
  /// "Based on your most recent sessions" line.
  final bool enoughData;

  /// Fewer than 2 sessions: show the new-student screen.
  bool get isNewStudent => sessions.length < 2;

  factory Progress.fromJson(Map<String, dynamic> json) {
    final totals = (json['totals'] as Map?) ?? const {};
    final growth = (json['growth'] as Map?) ?? const {};
    int count(String key) => (totals[key] as num?)?.toInt() ?? 0;

    return Progress(
      sessions: [
        for (final s in (json['sessions'] as List?) ?? const [])
          if (s is Map && s['needed_level'] is num)
            ProgressSession(
              startedAt: DateTime.tryParse('${s['started_at']}')?.toLocal(),
              neededLevel: (s['needed_level'] as num).toDouble(),
            ),
      ],
      sessionCount: count('sessions'),
      selfCorrections: count('self_corrections'),
      stuck: count('stuck'),
      reflections: count('reflections'),
      growthMessage: '${growth['message'] ?? ''}',
      enoughData: growth['trend'] != 'not_enough_data',
    );
  }
}

/// What went wrong when loading progress.
enum ProgressProblem {
  /// 503 progress_unavailable: "Progress is not available right now".
  unavailable,

  /// "Something went wrong".
  failed,

  /// "No internet".
  offline,

  /// 401: the login token is wrong or too old. Log in again.
  loginExpired,
}

sealed class ProgressResult {
  const ProgressResult();
}

class ProgressLoaded extends ProgressResult {
  const ProgressLoaded(this.progress);

  final Progress progress;
}

class ProgressFailure extends ProgressResult {
  const ProgressFailure(this.problem);

  final ProgressProblem problem;
}

/// Talks to `GET /progress` on the CogniGuide server. Since Stage 7c the
/// server takes the student from the login [token], not from the code.
class ProgressApi {
  ProgressApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  Future<ProgressResult> load(String studentId, {String? token}) async {
    final http.Response response;
    try {
      response = await _client
          .get(
            Uri.parse('$_baseUrl/progress'),
            headers: {if (token != null) 'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      return const ProgressFailure(ProgressProblem.failed);
    } on http.ClientException {
      return const ProgressFailure(ProgressProblem.offline);
    }

    if (response.statusCode == 401) {
      return const ProgressFailure(ProgressProblem.loginExpired);
    }

    try {
      final json = jsonDecode(response.body);
      if (response.statusCode == 200 && json is Map<String, dynamic>) {
        return ProgressLoaded(Progress.fromJson(json));
      }
      final error = json is Map ? json['error'] : null;
      if (response.statusCode == 503 &&
          error is Map &&
          error['code'] == 'progress_unavailable') {
        return const ProgressFailure(ProgressProblem.unavailable);
      }
    } on FormatException {
      // Not JSON: fall through to "something went wrong".
    } on TypeError {
      // Unexpected shape: fall through to "something went wrong".
    }
    return const ProgressFailure(ProgressProblem.failed);
  }
}
