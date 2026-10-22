import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_motion.dart';

/// Pip's moods. No sad, "wrong" or reward faces: Pip only encourages.
enum PipMood {
  /// Welcome, Pick a problem, chat.
  idle,

  /// Coach writing, loading screens, empty area, error.
  thinking,

  /// Growth sentence on My progress, Log in.
  happy,

  /// "You worked it out yourself!"
  cheering,

  /// When the student taps Pip.
  surprised,

  /// Starting a problem, Create account.
  determined,

  /// Coach busy, Log out sheet.
  sleepy,

  /// A friendly note (Language, Settings).
  wink,
}

/// Pip, the coach. One Pip per screen, always with words beside it.
///
/// Pip is drawn in code (not a picture file), so parts can move:
/// - With [breathe], Pip bobs up and down, blinks and sways its sprout for
///   about 12 seconds, then rests to save battery.
/// - When the mood changes, Pip cross-fades softly to the new face.
///
/// PERFORMANCE: one animation timer, and Pip repaints only itself (its own
/// layer), never the screen. With "reduce motion" on, Pip stays still.
class Pip extends StatelessWidget {
  const Pip({
    super.key,
    this.mood = PipMood.idle,
    this.size = 88,
    this.breathe = false,
  });

  final PipMood mood;
  final double size;
  final bool breathe;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = switch (mood) {
      PipMood.idle => l10n.pipIdle,
      PipMood.thinking => l10n.pipThinking,
      PipMood.happy => l10n.pipHappy,
      PipMood.cheering => l10n.pipCheering,
      PipMood.surprised => l10n.pipSurprised,
      PipMood.determined => l10n.pipDetermined,
      PipMood.sleepy => l10n.pipSleepy,
      PipMood.wink => l10n.pipWink,
    };

    return Semantics(
      label: label,
      image: true,
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: SizedBox.square(
            dimension: size,
            child: AnimatedSwitcher(
              duration: AppMotion.of(
                context,
                const Duration(milliseconds: 250),
              ),
              child: _PipMotion(
                key: ValueKey(mood),
                mood: mood,
                breathe: breathe,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Runs Pip's one animation timer: 12 seconds of movement, then rest.
class _PipMotion extends StatefulWidget {
  const _PipMotion({super.key, required this.mood, required this.breathe});

  final PipMood mood;
  final bool breathe;

  @override
  State<_PipMotion> createState() => _PipMotionState();
}

class _PipMotionState extends State<_PipMotion>
    with SingleTickerProviderStateMixin {
  /// How long Pip moves before resting. Every movement below repeats a
  /// whole number of times in 12 s, so Pip ends exactly in its rest pose.
  static const _activeFor = Duration(seconds: 12);

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: _activeFor,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.breathe || AppMotion.reduced(context)) {
      _c.stop();
      _c.value = 0;
    } else if (!_c.isAnimating && _c.value == 0) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PipPainter(
        mood: widget.mood,
        clock: _c,
        textStyle: DefaultTextStyle.of(context).style,
      ),
      size: Size.infinite,
    );
  }
}

/// Pip's colours for each mood. These are illustration colours (like the
/// old pip-*.svg pictures), the same in light and dark mode.
class _PipLook {
  const _PipLook(this.base, this.deep, this.light, {this.look = Offset.zero});

  final Color base;
  final Color deep;
  final Color light;

  /// Where the pupils look, in Pip's 200 x 200 drawing units.
  final Offset look;
}

const _violet = _PipLook(
  Color(0xFFA99BFF),
  Color(0xFF7C6AF0),
  Color(0xFFD9D2FF),
  look: Offset(0, 4),
);

_PipLook _lookFor(PipMood mood) => switch (mood) {
  PipMood.idle => _violet,
  PipMood.thinking => const _PipLook(
    Color(0xFF8EC7FF),
    Color(0xFF5A9BE8),
    Color(0xFFCFE6FF),
    look: Offset(8, -6),
  ),
  PipMood.happy => const _PipLook(
    Color(0xFFFFD36B),
    Color(0xFFF0A93A),
    Color(0xFFFFEDB8),
  ),
  PipMood.cheering => const _PipLook(
    Color(0xFFFFC56B),
    Color(0xFFF09A3A),
    Color(0xFFFFE6BD),
  ),
  PipMood.surprised => const _PipLook(
    Color(0xFFA99BFF),
    Color(0xFF7C6AF0),
    Color(0xFFD9D2FF),
  ),
  PipMood.determined => const _PipLook(
    Color(0xFF8FE0B8),
    Color(0xFF4CB888),
    Color(0xFFCDF3E0),
    look: Offset(0, 6),
  ),
  PipMood.sleepy => const _PipLook(
    Color(0xFFB5E6CF),
    Color(0xFF7CC6A4),
    Color(0xFFDDF4E9),
  ),
  PipMood.wink => _violet,
};

const _line = Color(0xFF2A2140);
const _cheek = Color(0xFFFF8FB4);
const _feet = Color(0xFFFF9E4A);
const _stem = Color(0xFF2E8A62);
const _leafA = Color(0xFF4CC38A);
const _leafB = Color(0xFF6ED9A3);
const _sparkle = Color(0xFFFFD25A);

/// Draws Pip in a 200 x 200 box, scaled to the widget size.
class _PipPainter extends CustomPainter {
  _PipPainter({
    required this.mood,
    required this.clock,
    required this.textStyle,
  }) : super(repaint: clock);

  final PipMood mood;
  final Animation<double> clock;
  final TextStyle textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 200;
    canvas.scale(s);

    // Seconds since Pip started moving (0 = rest pose).
    final t = clock.value * 12;
    double wave(double period) => (1 - math.cos(2 * math.pi * t / period)) / 2;

    final look = _lookFor(mood);
    final fill = Paint()..isAntiAlias = true;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = _line;

    // Shadow on the ground: smaller while Pip is up.
    final bob = wave(2.4);
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(100, 188),
        width: 2 * (48 - 6 * bob),
        height: 14,
      ),
      fill..color = const Color(0x24000000),
    );

    canvas.save();
    canvas.translate(0, -6 * bob);

    // Sprout, swaying gently from its base.
    canvas.save();
    canvas.translate(100, 46);
    canvas.rotate(6 * math.pi / 180 * math.sin(2 * math.pi * t / 3));
    canvas.drawPath(
      Path()
        ..moveTo(0, 4)
        ..cubicTo(-2, -6, 0, -14, 4, -20),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = _stem,
    );
    canvas.drawPath(
      Path()
        ..moveTo(2, -14)
        ..cubicTo(-10, -28, -28, -24, -30, -16)
        ..cubicTo(-20, -6, -6, -6, 2, -14)
        ..close(),
      fill..color = _leafA,
    );
    canvas.drawPath(
      Path()
        ..moveTo(4, -18)
        ..cubicTo(12, -34, 30, -34, 34, -26)
        ..cubicTo(26, -14, 12, -12, 4, -18)
        ..close(),
      fill..color = _leafB,
    );
    canvas.restore();

    // Arms: up when cheering, down otherwise.
    fill.color = look.deep;
    if (mood == PipMood.cheering) {
      canvas.drawPath(
        Path()
          ..moveTo(40, 112)
          ..cubicTo(24, 96, 18, 74, 26, 66)
          ..cubicTo(36, 62, 46, 86, 54, 102)
          ..close(),
        fill,
      );
      canvas.drawPath(
        Path()
          ..moveTo(160, 112)
          ..cubicTo(176, 96, 182, 74, 174, 66)
          ..cubicTo(164, 62, 154, 86, 146, 102)
          ..close(),
        fill,
      );
    } else {
      _tiltedOval(canvas, const Offset(34, 126), 13, 20, 18, fill);
      _tiltedOval(canvas, const Offset(166, 126), 13, 20, -18, fill);
    }

    // Feet.
    fill.color = _feet;
    _oval(canvas, const Offset(78, 180), 17, 9, fill);
    _oval(canvas, const Offset(122, 180), 17, 9, fill);

    // Body, a darker band at the bottom, the belly and a shine.
    canvas.drawPath(
      Path()
        ..moveTo(100, 44)
        ..cubicTo(150, 44, 174, 80, 172, 120)
        ..cubicTo(170, 160, 142, 182, 100, 182)
        ..cubicTo(58, 182, 30, 160, 28, 120)
        ..cubicTo(26, 80, 50, 44, 100, 44)
        ..close(),
      fill..color = look.base,
    );
    canvas.drawPath(
      Path()
        ..moveTo(40, 140)
        ..cubicTo(52, 168, 76, 180, 100, 180)
        ..cubicTo(124, 180, 148, 168, 160, 140)
        ..cubicTo(150, 160, 128, 172, 100, 172)
        ..cubicTo(72, 172, 50, 160, 40, 140)
        ..close(),
      fill..color = look.deep.withValues(alpha: 0.55),
    );
    _oval(canvas, const Offset(100, 148), 42, 26, fill..color = look.light);
    _tiltedOval(
      canvas,
      const Offset(66, 70),
      14,
      8,
      -30,
      fill..color = const Color(0x59FFFFFF),
    );

    // Cheeks.
    fill.color = _cheek.withValues(alpha: 0.75);
    _oval(canvas, const Offset(54, 124), 11, 7, fill);
    _oval(canvas, const Offset(146, 124), 11, 7, fill);

    // Open eyes, with a blink every 4.2 seconds.
    if (mood != PipMood.happy &&
        mood != PipMood.sleepy &&
        mood != PipMood.wink) {
      final phase = (t % 4.2) / 4.2;
      final blink = phase < 0.9 || phase > 0.98
          ? 1.0
          : phase < 0.94
          ? 1 - 0.92 * (phase - 0.9) / 0.04
          : 0.08 + 0.92 * (phase - 0.94) / 0.04;
      canvas.save();
      canvas.translate(0, 98);
      canvas.scale(1, blink);
      canvas.translate(0, -98);
      _eyes(canvas, fill, look.look, small: mood == PipMood.surprised);
      canvas.restore();
    }

    _face(canvas, fill, stroke, look, t);
    canvas.restore();
  }

  void _eyes(Canvas canvas, Paint fill, Offset look, {bool small = false}) {
    fill.color = Colors.white;
    _oval(canvas, const Offset(76, 98), 21, 24, fill);
    _oval(canvas, const Offset(124, 98), 21, 24, fill);
    fill.color = _line;
    final r = small ? 7.0 : 12.0;
    canvas.drawCircle(Offset(78, 102) + look, r, fill);
    canvas.drawCircle(Offset(122, 102) + look, r, fill);
    fill.color = Colors.white;
    canvas.drawCircle(Offset(83, 95) + look, 4.5, fill);
    canvas.drawCircle(Offset(127, 95) + look, 4.5, fill);
  }

  void _face(Canvas canvas, Paint fill, Paint stroke, _PipLook look, double t) {
    switch (mood) {
      case PipMood.idle:
        _curve(
          canvas,
          stroke,
          6,
          const Offset(86, 132),
          const Offset(100, 146),
          const Offset(114, 132),
        );
      case PipMood.thinking:
        _line2(canvas, stroke, 5, const Offset(62, 68), const Offset(88, 74));
        _line2(canvas, stroke, 5, const Offset(112, 72), const Offset(138, 62));
        _curve(
          canvas,
          stroke,
          5,
          const Offset(92, 136),
          const Offset(102, 130),
          const Offset(112, 136),
        );
        _oval(canvas, const Offset(128, 150), 14, 11, fill..color = look.deep);
        _text(canvas, '?', const Offset(160, 30), 30, look.deep, 1);
      case PipMood.happy:
        _curve(
          canvas,
          stroke,
          7,
          const Offset(58, 100),
          const Offset(76, 80),
          const Offset(94, 100),
        );
        _curve(
          canvas,
          stroke,
          7,
          const Offset(106, 100),
          const Offset(124, 80),
          const Offset(142, 100),
        );
        _openSmile(canvas, fill, 122, 160, 140, 150);
      case PipMood.cheering:
        _openSmile(canvas, fill, 120, 168, 142, 154);
        final glow = (1 + math.cos(2 * math.pi * t / 1.5)) / 2;
        _star(canvas, const Offset(22, 54), 14, 0.2 + 0.8 * glow);
        _star(canvas, const Offset(176, 41), 11, 1 - 0.8 * glow);
      case PipMood.surprised:
        _curve(
          canvas,
          stroke,
          5,
          const Offset(58, 66),
          const Offset(76, 56),
          const Offset(92, 66),
        );
        _curve(
          canvas,
          stroke,
          5,
          const Offset(108, 66),
          const Offset(124, 56),
          const Offset(142, 66),
        );
        _oval(canvas, const Offset(100, 138), 10, 13, fill..color = _line);
      case PipMood.determined:
        _line2(canvas, stroke, 6, const Offset(56, 70), const Offset(90, 82));
        _line2(canvas, stroke, 6, const Offset(144, 70), const Offset(110, 82));
        _curve(
          canvas,
          stroke,
          6,
          const Offset(84, 134),
          const Offset(100, 142),
          const Offset(116, 130),
        );
      case PipMood.sleepy:
        _curve(
          canvas,
          stroke,
          6,
          const Offset(58, 100),
          const Offset(76, 112),
          const Offset(94, 100),
        );
        _curve(
          canvas,
          stroke,
          6,
          const Offset(106, 100),
          const Offset(124, 112),
          const Offset(142, 100),
        );
        _oval(canvas, const Offset(100, 138), 7, 5, fill..color = _line);
        final p = (t % 2.4) / 2.4;
        final rest = t == 0 || t >= 12;
        final z1 = rest ? 1.0 : math.sin(math.pi * p);
        final z2 = rest
            ? 1.0
            : (p < 1 / 3 ? 0.0 : math.sin(1.5 * math.pi * (p - 1 / 3)));
        _text(canvas, 'z', const Offset(150, 38), 24, look.deep, z1);
        _text(canvas, 'Z', const Offset(166, 12), 30, look.deep, z2);
      case PipMood.wink:
        _eyesWink(canvas, fill);
        _curve(
          canvas,
          stroke,
          7,
          const Offset(106, 100),
          const Offset(124, 88),
          const Offset(142, 100),
        );
        _curve(
          canvas,
          stroke,
          6,
          const Offset(84, 128),
          const Offset(102, 148),
          const Offset(120, 126),
        );
    }
  }

  void _eyesWink(Canvas canvas, Paint fill) {
    fill.color = Colors.white;
    _oval(canvas, const Offset(76, 98), 21, 24, fill);
    canvas.drawCircle(const Offset(78, 102), 11, fill..color = _line);
    canvas.drawCircle(const Offset(82, 96), 4.5, fill..color = Colors.white);
  }

  /// A wide-open smile with a pink tongue.
  void _openSmile(
    Canvas canvas,
    Paint fill,
    double top,
    double bottom,
    double tongueTop,
    double tongueBottom,
  ) {
    final w = bottom - top > 40 ? 24.0 : 22.0;
    canvas.drawPath(
      Path()
        ..moveTo(100 - w, top)
        ..quadraticBezierTo(100, bottom, 100 + w, top)
        ..close(),
      fill..color = _line,
    );
    canvas.drawPath(
      Path()
        ..moveTo(88, tongueTop)
        ..quadraticBezierTo(100, tongueBottom, 112, tongueTop)
        ..quadraticBezierTo(100, tongueTop - 4, 88, tongueTop)
        ..close(),
      fill..color = _cheek,
    );
  }

  void _star(Canvas canvas, Offset c, double r, double opacity) {
    final k = r * 0.3;
    canvas.drawPath(
      Path()
        ..moveTo(c.dx, c.dy - r)
        ..lineTo(c.dx + k, c.dy - k)
        ..lineTo(c.dx + r, c.dy)
        ..lineTo(c.dx + k, c.dy + k)
        ..lineTo(c.dx, c.dy + r)
        ..lineTo(c.dx - k, c.dy + k)
        ..lineTo(c.dx - r, c.dy)
        ..lineTo(c.dx - k, c.dy - k)
        ..close(),
      Paint()..color = _sparkle.withValues(alpha: opacity),
    );
  }

  void _text(
    Canvas canvas,
    String s,
    Offset at,
    double size,
    Color c,
    double o,
  ) {
    if (o <= 0) return;
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: textStyle.copyWith(
          fontSize: size,
          height: 1,
          fontWeight: FontWeight.w800,
          fontVariations: const [FontVariation('wght', 800)],
          color: c.withValues(alpha: o.clamp(0, 1)),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at);
    tp.dispose();
  }

  static void _oval(Canvas canvas, Offset c, double rx, double ry, Paint p) {
    canvas.drawOval(
      Rect.fromCenter(center: c, width: rx * 2, height: ry * 2),
      p,
    );
  }

  static void _tiltedOval(
    Canvas canvas,
    Offset c,
    double rx,
    double ry,
    double degrees,
    Paint p,
  ) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(degrees * math.pi / 180);
    _oval(canvas, Offset.zero, rx, ry, p);
    canvas.restore();
  }

  static void _curve(
    Canvas canvas,
    Paint stroke,
    double width,
    Offset a,
    Offset control,
    Offset b,
  ) {
    canvas.drawPath(
      Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(control.dx, control.dy, b.dx, b.dy),
      stroke..strokeWidth = width,
    );
  }

  static void _line2(
    Canvas canvas,
    Paint stroke,
    double width,
    Offset a,
    Offset b,
  ) {
    canvas.drawLine(a, b, stroke..strokeWidth = width);
  }

  @override
  bool shouldRepaint(_PipPainter old) => old.mood != mood || old.clock != clock;
}
