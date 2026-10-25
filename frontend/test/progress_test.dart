import 'dart:convert';

import 'package:cogniguide/services/progress_api.dart';
import 'package:cogniguide/widgets/help_chart.dart';
import 'package:cogniguide/widgets/stat_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'widget_test.dart'
    show newStudent, pretendServer, progressSays, startApp, tapVisible;

/// Like the real reply for TESTS8IMPROVING1163822, with more variety.
const Map<String, Object?> fourSessions = {
  'student_id': 'P001',
  'sessions': [
    {'started_at': '2026-10-02T10:00:00+00:00', 'needed_level': 3.0},
    {'started_at': '2026-10-05T10:00:00+00:00', 'needed_level': 2.0},
    {'started_at': '2026-10-08T10:00:00+00:00', 'needed_level': 1.67},
    {'started_at': '2026-10-11T10:00:00+00:00', 'needed_level': 1.0},
  ],
  'totals': {
    'sessions': 4,
    'stuck': 7,
    'asked_for_answer': 2,
    'self_corrections': 3,
    'reflections': 1,
  },
  'growth': {
    'trend': 'less_help',
    'message': 'You are needing a little less help than before.',
  },
};

ProgressApi serverSays(Map<String, Object?> body) =>
    ProgressApi(client: pretendServer((_) => progressSays(body)));

Future<void> openProgress(WidgetTester tester, ProgressApi progress) async {
  await startApp(tester, saved: {'student_code': 'P001'}, progress: progress);
  await tester.tap(find.text('My progress'));
  await tester.pumpAndSettle();
}

int tileValue(WidgetTester tester, String label) =>
    tester.widget<StatTile>(find.widgetWithText(StatTile, label)).value;

void main() {
  group('ProgressApi', () {
    test(
      'sends the login token (not the code) and reads the numbers',
      () async {
        late http.Request asked;
        final api = ProgressApi(
          baseUrl: 'http://server',
          client: pretendServer((r) {
            asked = r;
            return progressSays(fourSessions);
          }),
        );

        final r = await api.load('P001', token: 'tok123');

        // Stage 7c: the server takes the student from the token.
        expect(asked.url.toString(), 'http://server/progress');
        expect(asked.headers['Authorization'], 'Bearer tok123');
        final p = (r as ProgressLoaded).progress;
        expect(p.sessions.length, 4);
        expect(p.sessions.map((s) => s.help), [
          HelpNeeded.aLot,
          HelpNeeded.some,
          HelpNeeded.some,
          HelpNeeded.aLittle,
        ]);
        expect(p.selfCorrections, 3);
        expect(p.enoughData, isTrue);
        expect(p.isNewStudent, isFalse);
      },
    );

    test('503 progress_unavailable and no connection', () async {
      final busy = ProgressApi(
        client: pretendServer(
          (_) => http.Response(
            jsonEncode({
              'error': {'code': 'progress_unavailable', 'message': 'x'},
            }),
            503,
          ),
        ),
      );
      expect(
        ((await busy.load('P001')) as ProgressFailure).problem,
        ProgressProblem.unavailable,
      );

      final offline = ProgressApi(
        client: pretendServer((_) => throw http.ClientException('offline')),
      );
      expect(
        ((await offline.load('P001')) as ProgressFailure).problem,
        ProgressProblem.offline,
      );
    });
  });

  group('My progress tab', () {
    testWidgets('with data: growth, the 4 tiles and the chart', (tester) async {
      await openProgress(tester, serverSays(fourSessions));

      expect(
        find.text('You are needing a little less help than before.'),
        findsOneWidget,
      );
      expect(find.text('Based on your most recent sessions'), findsOneWidget);
      expect(tileValue(tester, 'Sessions'), 4);
      expect(tileValue(tester, 'Times you fixed your own mistake'), 3);
      expect(tileValue(tester, 'Times you felt stuck'), 7);
      expect(tileValue(tester, 'Reflection questions'), 1);

      expect(find.byType(HelpChart), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          RegExp('sessions 1 to 4: a lot, some, some, a little'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the list view shows dates and help words', (tester) async {
      await openProgress(tester, serverSays(fourSessions));

      await tapVisible(tester, find.text('Show the same numbers as a list'));
      await tester.pumpAndSettle();

      expect(find.text('Help in each session'), findsOneWidget);
      expect(find.text('2 Oct'), findsOneWidget);
      expect(find.text('A lot'), findsOneWidget);
      expect(find.text('Some'), findsNWidgets(2));
      expect(find.text('A little'), findsOneWidget);
    });

    testWidgets('new student: dashed zero tiles, no chart, Start a problem', (
      tester,
    ) async {
      await openProgress(tester, serverSays(newStudent));

      expect(find.byType(HelpChart), findsNothing);
      expect(
        find.text('Your chart will appear here after two sessions.'),
        findsOneWidget,
      );
      expect(find.text('Based on your most recent sessions'), findsNothing);
      final tiles = tester.widgetList<StatTile>(find.byType(StatTile));
      expect(tiles.length, 4);
      expect(tiles.every((t) => t.dashed && t.value == 0), isTrue);

      await tapVisible(tester, find.text('Start a problem'));
      await tester.pumpAndSettle();
      expect(find.text('What would you like to work on?'), findsOneWidget);
    });

    testWidgets('progress_unavailable shows its message and Try again', (
      tester,
    ) async {
      await openProgress(
        tester,
        ProgressApi(
          client: pretendServer(
            (_) => http.Response(
              jsonEncode({
                'error': {'code': 'progress_unavailable', 'message': 'x'},
              }),
              503,
            ),
          ),
        ),
      );

      expect(
        find.text(
          'Progress is not available right now. Please try again later.',
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextButton, 'Try again'), findsOneWidget);
    });
  });
}
