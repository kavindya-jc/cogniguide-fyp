import 'chat_api.dart';
import 'progress_api.dart';

/// Demo mode, ONLY for the online preview the team looks at:
///   flutter build web --dart-define=DEMO_MODE=true
///
/// The preview runs on the internet and cannot reach the real server on a
/// laptop, so the coach gives a few example replies and My progress shows
/// example numbers. The real app (phones) never switches this on.
abstract final class DemoMode {
  static const bool on = bool.fromEnvironment('DEMO_MODE');
}

/// A pretend coach for the preview. Like the real one it only asks
/// questions and never gives the answer.
class DemoChatApi extends ChatApi {
  DemoChatApi();

  static const _replies = [
    "Hi! Let's work on this together. What is the question asking you to find?",
    'Good start. What do you already know that could help you here?',
    'Nice thinking. What could you try as a first step?',
    'You are getting closer. Can you check that step? Does it still balance?',
    'Great, you kept going! How could you check your answer is right?',
  ];

  @override
  Future<ChatResult> send({
    required String problem,
    required List<ChatTurn> history,
    String? studentId,
    String? problemId,
    String? sessionId,
    String? token,
  }) async {
    // A short wait, so the "coach is thinking" dots show.
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    final studentTurns = history.where((t) => t.role == ChatRole.student);
    final i = studentTurns.length.clamp(0, _replies.length - 1);
    return ChatReply(reply: _replies[i], sessionId: sessionId ?? 'demo');
  }
}

/// Example numbers for My progress in the preview.
class DemoProgressApi extends ProgressApi {
  DemoProgressApi();

  @override
  Future<ProgressResult> load(String studentId, {String? token}) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return ProgressLoaded(
      Progress.fromJson({
        'student_id': studentId,
        'sessions': [
          {'started_at': '2026-10-02T10:00:00+00:00', 'needed_level': 3.0},
          {'started_at': '2026-10-05T10:00:00+00:00', 'needed_level': 3.0},
          {'started_at': '2026-10-08T10:00:00+00:00', 'needed_level': 2.0},
          {'started_at': '2026-10-12T10:00:00+00:00', 'needed_level': 2.67},
          {'started_at': '2026-10-16T10:00:00+00:00', 'needed_level': 2.0},
          {'started_at': '2026-10-20T10:00:00+00:00', 'needed_level': 1.0},
        ],
        'totals': {
          'sessions': 6,
          'stuck': 7,
          'asked_for_answer': 2,
          'self_corrections': 4,
          'reflections': 5,
        },
        'growth': {
          'trend': 'less_help',
          'message': "You're needing a little less help than before.",
        },
      }),
    );
  }
}
