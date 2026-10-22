import 'package:cogniguide/services/glass_speed_guard.dart';
import 'package:cogniguide/services/settings_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'glass_test.dart' show navBlur;
import 'widget_test.dart' show startApp, tapVisible;

const _fast = Duration(milliseconds: 9);
const _slow = Duration(milliseconds: 30);

/// Feeds [count] frames, [slowEvery]th one slow. True if judged too slow.
bool feed(GlassSpeedJudge judge, int count, {required int slowEvery}) {
  var tooSlow = false;
  for (var i = 0; i < count; i++) {
    if (judge.addFrame(i % slowEvery == 0 ? _slow : _fast)) tooSlow = true;
  }
  return tooSlow;
}

void main() {
  group('the speed judge', () {
    test('a smooth phone keeps glass (1 slow frame in 10)', () {
      expect(feed(GlassSpeedJudge(), 600, slowEvery: 10), isFalse);
    });

    test('a slow phone loses glass (1 slow frame in 2)', () {
      expect(feed(GlassSpeedJudge(), 400, slowEvery: 2), isTrue);
    });

    test('the warm-up frames at the start are not counted', () {
      final judge = GlassSpeedJudge();
      for (var i = 0; i < 60; i++) {
        expect(judge.addFrame(_slow), isFalse);
      }
      expect(feed(judge, 240, slowEvery: 10), isFalse);
    });

    test('one busy moment is not enough (needs 2 bad groups in a row)', () {
      final judge = GlassSpeedJudge();
      feed(judge, 60, slowEvery: 10); // warm-up
      expect(feed(judge, 120, slowEvery: 1), isFalse); // 1 bad group
      expect(feed(judge, 120, slowEvery: 10), isFalse); // then smooth
      expect(feed(judge, 120, slowEvery: 1), isFalse); // bad again, alone
    });

    test('frames just over one frame time are not "slow" (20 ms)', () {
      final judge = GlassSpeedJudge();
      var tooSlow = false;
      for (var i = 0; i < 600; i++) {
        tooSlow |= judge.addFrame(const Duration(milliseconds: 20));
      }
      expect(tooSlow, isFalse);
    });
  });

  group('settings', () {
    Future<SettingsStore> store([Map<String, Object> saved = const {}]) async {
      SharedPreferences.setMockInitialValues(saved);
      return SettingsStore(await SharedPreferences.getInstance());
    }

    test('auto-off turns glass off and says why', () async {
      final s = await store();
      await s.turnGlassOffForSpeed();
      expect(s.glassEffects, isFalse);
      expect(s.glassTurnedOffForSpeed, isTrue);
      expect(s.shouldWatchGlassSpeed, isFalse);
    });

    test('turning glass back on wins: the app stops checking', () async {
      final s = await store();
      await s.turnGlassOffForSpeed();
      await s.setGlassEffects(true);
      expect(s.glassEffects, isTrue);
      expect(s.glassTurnedOffForSpeed, isFalse);
      expect(s.shouldWatchGlassSpeed, isFalse);

      // A later slow patch does not turn it off again.
      await s.turnGlassOffForSpeed();
      expect(s.glassEffects, isTrue);
    });

    test('nothing to do when the student already turned glass off', () async {
      final s = await store({'glass_effects': false});
      await s.turnGlassOffForSpeed();
      expect(s.glassTurnedOffForSpeed, isFalse);
    });
  });

  testWidgets('Settings explains the auto-off, and the switch brings it back', (
    tester,
  ) async {
    final prefs = await startApp(
      tester,
      saved: {'student_code': 'P001', 'glass_auto_off': true},
    );
    expect(navBlur(), findsNothing);

    await tester.tap(find.bySemanticsLabel('Settings'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Turned off by itself because it was slowing'),
      findsOneWidget,
    );

    await tapVisible(tester, find.byType(Switch));
    await tester.pumpAndSettle();
    expect(prefs.getBool('glass_kept_on'), isTrue);
    expect(find.textContaining('Turned off by itself'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Back to problems'));
    await tester.pumpAndSettle();
    expect(navBlur(), findsOneWidget);
  });
}
