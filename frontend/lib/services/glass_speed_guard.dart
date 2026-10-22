import 'package:flutter/scheduler.dart';

import '../widgets/glass_surface.dart';
import 'settings_store.dart';

/// Decides from frame times whether the phone is too slow for glass.
///
/// Only frames drawn while glass (blur) is on screen are counted. The
/// first [skipFirst] are ignored (the app is still warming up). Then, in
/// each group of [window] frames, a group is "bad" when more than
/// [slowShare] of them took longer than [slow] to draw. The phone is too
/// slow only after [badInARow] bad groups in a row, so one busy moment
/// (opening a screen, the keyboard sliding up) never counts.
///
/// [slow] is 24 ms: about one and a half frames at 60 per second, where a
/// stutter starts to show. The emulator test (2026-10-22) showed 20 ms
/// was too strict and switched glass off on a phone that was fine.
class GlassSpeedJudge {
  GlassSpeedJudge({
    this.window = 120,
    this.slow = const Duration(milliseconds: 24),
    this.slowShare = 0.35,
    this.skipFirst = 60,
    this.badInARow = 2,
  });

  final int window;
  final Duration slow;
  final double slowShare;
  final int skipFirst;
  final int badInARow;

  int _skipped = 0;
  int _counted = 0;
  int _slowCount = 0;
  int _bad = 0;

  /// Adds one frame's drawing time. True when the phone is too slow.
  bool addFrame(Duration drawTime) {
    if (_skipped < skipFirst) {
      _skipped++;
      return false;
    }
    _counted++;
    if (drawTime > slow) _slowCount++;
    if (_counted < window) return false;

    final badGroup = _slowCount > window * slowShare;
    _bad = badGroup ? _bad + 1 : 0;
    _counted = 0;
    _slowCount = 0;
    return _bad >= badInARow;
  }
}

/// Watches the app's speed while glass is on, and turns glass off by
/// itself on a phone that is too slow for it (Settings then says so).
///
/// It stops watching once glass is off, or when the student has turned
/// glass back on after an automatic switch-off (their choice wins).
/// PERFORMANCE: it only reads timings Flutter collects anyway.
class GlassSpeedGuard {
  GlassSpeedGuard(this.settings, {GlassSpeedJudge? judge})
    : _judge = judge ?? GlassSpeedJudge();

  final SettingsStore settings;
  final GlassSpeedJudge _judge;
  bool _watching = false;

  void start() {
    if (_watching || !settings.shouldWatchGlassSpeed) return;
    _watching = true;
    _since.start();
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  void stop() {
    if (!_watching) return;
    _watching = false;
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
  }

  /// When watching started. The first seconds are ignored: the app is
  /// still loading (fonts, pictures, first screens), which is slow on
  /// every phone.
  final _since = Stopwatch();
  static const _warmUp = Duration(seconds: 5);

  void _onTimings(List<FrameTiming> timings) {
    if (_since.elapsed < _warmUp) return;
    if (!settings.shouldWatchGlassSpeed) return;
    if (GlassSurface.liveBlurs == 0) return; // no glass, nothing to judge
    for (final t in timings) {
      if (_judge.addFrame(t.rasterDuration)) {
        settings.turnGlassOffForSpeed();
        stop();
        return;
      }
    }
  }
}
