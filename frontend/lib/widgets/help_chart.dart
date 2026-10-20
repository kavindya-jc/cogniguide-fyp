import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/progress_api.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// The line chart on My progress: how much help each session needed.
///
/// One point per session, oldest on the left. "A lot" is at the top and
/// "A little" at the bottom, so lower is better. The newest point is
/// mustard. Screen readers hear the same numbers as one sentence.
class HelpChart extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final levels = [
      for (final s in sessions) helpWord(l10n, s.help).toLowerCase(),
    ].join(', ');

    return Semantics(
      image: true,
      label: l10n.chartSemantics(sessions.length, levels),
      excludeSemantics: true,
      child: SizedBox(
        height: 196,
        width: double.infinity,
        child: CustomPaint(
          painter: _ChartPainter(
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
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.levels,
    required this.colors,
    required this.labelStyle,
    required this.yLabels,
    required this.xTitle,
  });

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

    // The line.
    final line = Paint()
      ..color = colors.teal
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(Path()..addPolygon(points, false), line);

    // The points: white with a teal ring; the newest is mustard.
    for (var i = 0; i < n; i++) {
      final p = points[i];
      if (i == n - 1) {
        canvas.drawCircle(p, 9, Paint()..color = colors.mustard);
        canvas.drawCircle(
          p,
          9,
          Paint()
            ..color = colors.ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
      } else {
        canvas.drawCircle(p, 6, Paint()..color = colors.surfaceRaised);
        canvas.drawCircle(
          p,
          6,
          Paint()
            ..color = colors.teal
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.5,
        );
      }

      // Session number under each point.
      final number = _text('${i + 1}', labelStyle);
      number.paint(canvas, Offset(p.dx - number.width / 2, 154));
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
      old.levels != levels || old.colors != colors;
}
