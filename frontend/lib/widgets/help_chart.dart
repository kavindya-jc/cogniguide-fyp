import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/progress_api.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_text.dart';

/// The line chart on My progress: how much help each session needed.
///
/// One point per session, oldest on the left. "A lot" is at the top and
/// "A little" at the bottom, so lower is better. The newest point is
/// mustard. Screen readers hear the same numbers as one sentence.
///
/// When it first appears, the line draws itself from left to right
/// (1.4 s), then the points pop in one by one, the newest last.
/// PERFORMANCE: only the chart repaints while it plays (its own layer, and
/// the painter listens to the animation instead of rebuilding widgets).
/// With "reduce motion" on, the finished chart is shown at once.
class HelpChart extends StatefulWidget {
  const HelpChart({super.key, required this.sessions});

  /// Oldest first.
  final List<ProgressSession> sessions;

  static String helpWord(AppLocalizations l10n, HelpNeeded help) =>
      switch (help) {
        HelpNeeded.aLot => l10n.chartALot,
        HelpNeeded.some => l10n.chartSome,
        HelpNeeded.aLittle => l10n.chartALittle,
      };

  @override
  State<HelpChart> createState() => _HelpChartState();
}

class _HelpChartState extends State<HelpChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _draw;

  /// The line takes 1.4 s, then each point pops 0.2 s after the last.
  static const _lineMs = 1400;
  static const _pointGapMs = 200;
  static const _popMs = 300;

  @override
  void initState() {
    super.initState();
    final n = math.max(widget.sessions.length, 1);
    _draw = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: _lineMs + _pointGapMs * (n - 1) + _popMs,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _draw.value = 1;
    } else if (_draw.value == 0 && !_draw.isAnimating) {
      _draw.forward();
    }
  }

  @override
  void dispose() {
    _draw.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final sessions = widget.sessions;
    final levels = [
      for (final s in sessions) HelpChart.helpWord(l10n, s.help).toLowerCase(),
    ].join(', ');

    return Semantics(
      image: true,
      label: l10n.chartSemantics(sessions.length, levels),
      excludeSemantics: true,
      child: SizedBox(
        height: 196,
        width: double.infinity,
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _ChartPainter(
              progress: _draw,
              totalMs: _draw.duration!.inMilliseconds,
              levels: [for (final s in sessions) s.neededLevel],
              colors: c,
              labelStyle: AppText.caption.copyWith(
                color: c.inkMuted,
                fontSize: 14,
              ),
              yLabels: [l10n.chartALot, l10n.chartSome, l10n.chartALittle],
              xTitle: l10n.chartSessionAxis,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.progress,
    required this.totalMs,
    required this.levels,
    required this.colors,
    required this.labelStyle,
    required this.yLabels,
    required this.xTitle,
  }) : super(repaint: progress);

  /// 0 to 1 over the whole drawing (line, then points).
  final Animation<double> progress;
  final int totalMs;

  final List<double> levels;
  final AppColors colors;
  final TextStyle labelStyle;

  /// "A lot", "Some", "A little" (top to bottom).
  final List<String> yLabels;
  final String xTitle;

  static const _top = 24.0;
  static const _rowGap = 54.0;
  static const _left = 66.0;

  /// y for a level: 3 (a lot) at the top, 1 (a little) at the bottom.
  double _y(double level) => _top + (3 - level.clamp(1, 3)) * _rowGap;

  TextPainter _text(String s, TextStyle style) => TextPainter(
    text: TextSpan(text: s, style: style),
    textDirection: TextDirection.ltr,
  )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final right = size.width - 4;

    // Grid lines and the left labels.
    final grid = Paint()
      ..color = colors.line
      ..strokeWidth = 1.5;
    for (var i = 0; i < 3; i++) {
      final y = _top + i * _rowGap;
      var x = _left;
      while (x < right) {
        canvas.drawLine(Offset(x, y), Offset((x + 4).clamp(0, right), y), grid);
        x += 10;
      }
      final label = _text(yLabels[i], labelStyle);
      label.paint(canvas, Offset(0, y - label.height / 2));
    }

    if (levels.isEmpty) return;

    // Where each session goes across.
    final n = levels.length;
    final step = n == 1 ? 0.0 : (right - _left - 36) / (n - 1);
    final points = [
      for (var i = 0; i < n; i++) Offset(_left + 18 + i * step, _y(levels[i])),
    ];

    // How far the drawing has got, in milliseconds.
    final ms = progress.value * totalMs;
    final lineShown = Curves.easeOut.transform(
      (ms / _HelpChartState._lineMs).clamp(0.0, 1.0),
    );

    // The line, drawn from the left up to [lineShown] of its length.
    final line = Paint()
      ..color = colors.teal
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final path = Path()..addPolygon(points, false);
    if (lineShown >= 1) {
      canvas.drawPath(path, line);
    } else if (lineShown > 0) {
      for (final metric in path.computeMetrics()) {
        canvas.drawPath(metric.extractPath(0, metric.length * lineShown), line);
      }
    }

    // The points: white with a teal ring; the newest is mustard.
    for (var i = 0; i < n; i++) {
      final p = points[i];

      // Session number under each point (always shown).
      final number = _text('${i + 1}', labelStyle);
      number.paint(canvas, Offset(p.dx - number.width / 2, 154));

      // Each point pops in after the line, one after another.
      final start = _HelpChartState._lineMs + _HelpChartState._pointGapMs * i;
      final pop = ((ms - start) / _HelpChartState._popMs).clamp(0.0, 1.0);
      if (pop <= 0) continue;
      final grow = Curves.easeOutBack.transform(pop);

      if (i == n - 1) {
        canvas.drawCircle(p, 9 * grow, Paint()..color = colors.mustard);
        canvas.drawCircle(
          p,
          9 * grow,
          Paint()
            ..color = colors.ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
      } else {
        canvas.drawCircle(p, 6 * grow, Paint()..color = colors.surfaceRaised);
        canvas.drawCircle(
          p,
          6 * grow,
          Paint()
            ..color = colors.teal
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.5,
        );
      }
    }

    // "Session" under the numbers.
    final title = _text(
      xTitle,
      labelStyle.copyWith(fontWeight: FontWeight.w600),
    );
    title.paint(canvas, Offset(_left + (right - _left - title.width) / 2, 176));
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.levels != levels || old.colors != colors || old.progress != progress;
}
