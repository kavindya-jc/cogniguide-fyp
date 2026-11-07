import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_motion.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text.dart';
import '../widgets/pip.dart';

/// The brand colours of the opening screen. They stay the same in light and
/// dark mode, like the app icon, and [_purple] matches the Android start-up
/// colour (`launch_purple` in `android/.../values/launch_colors.xml`), so
/// the phone's first screen and this one join without a flash.
const _purple = Color(0xFF6656DD);
const _purpleDeep = Color(0xFF4636B8);
const _lilac = Color(0xFFA99BFF);

/// Pip, the app's name and the promise, shown for about a second when the
/// app opens. Then it fades to [next].
///
/// PERFORMANCE: the background is painted once and never repaints. Only Pip
/// moves (one small bounce, in its own layer), with no glass and no blur.
/// With "reduce motion" on, nothing moves.
class OpeningScreen extends StatefulWidget {
  const OpeningScreen({super.key, required this.next});

  /// The screen to open afterwards.
  final Widget next;

  @override
  State<OpeningScreen> createState() => _OpeningScreenState();
}

class _OpeningScreenState extends State<OpeningScreen>
    with SingleTickerProviderStateMixin {
  static const _shownFor = Duration(milliseconds: 1150);
  static const _fadeFor = Duration(milliseconds: 250);

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: _shownFor,
  )..addStatusListener(_onStatus);

  late final Animation<double> _bounce = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.8,
        end: 1.06,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 30,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.06,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 15,
    ),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 55),
  ]).animate(_c);

  late final Animation<double> _wordsIn = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.1, 0.4, curve: AppMotion.ease),
  );

  @override
  void initState() {
    super.initState();
    _c.forward();
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: AppMotion.of(context, _fadeFor),
        pageBuilder: (_, _, _) => widget.next,
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final still = AppMotion.reduced(context);
    final pipSize = (MediaQuery.sizeOf(context).shortestSide * 0.62).clamp(
      150.0,
      260.0,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _purple,
        body: Stack(
          children: [
            const Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(painter: _BackdropPainter()),
              ),
            ),
            SafeArea(
              child: Center(
                // Very large phone text can make this taller than the screen.
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpace.screen),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScaleTransition(
                        scale: still ? kAlwaysCompleteAnimation : _bounce,
                        child: Pip(mood: PipMood.happy, size: pipSize),
                      ),
                      const SizedBox(height: AppSpace.s4),
                      FadeTransition(
                        opacity: still ? kAlwaysCompleteAnimation : _wordsIn,
                        child: Column(
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                l10n.appTitle,
                                textAlign: TextAlign.center,
                                style: AppText.h1.copyWith(
                                  color: Colors.white,
                                  fontSize: 40,
                                  height: 44 / 40,
                                  fontVariations: const [
                                    FontVariation('wght', 800),
                                    FontVariation('opsz', 40),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpace.s2),
                            Text(
                              l10n.welcomeTitle,
                              textAlign: TextAlign.center,
                              style: AppText.title.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Soft bubbles, a glow behind Pip and faint maths symbols. The symbols stay
/// near the edges, so they never sit behind the words.
class _BackdropPainter extends CustomPainter {
  const _BackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final unit = size.shortestSide.clamp(0.0, 600.0) / 252;

    void bubble(double x, double y, double radius, Color color) =>
        canvas.drawCircle(
          Offset(w * x, h * y),
          radius * unit,
          Paint()..color = color,
        );

    bubble(0.9, 0.08, 96, _lilac.withValues(alpha: 0.45));
    bubble(0.06, 0.93, 108, _purpleDeep.withValues(alpha: 0.6));
    bubble(0.5, 0.42, 104, Colors.white.withValues(alpha: 0.1));

    final stroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    /// Draws one symbol from its own small drawing units, centred on a point.
    void symbol(double x, double y, void Function(Path path) draw) {
      final path = Path();
      draw(path);
      canvas.save();
      canvas.translate(w * x, h * y);
      canvas.scale(unit);
      canvas.drawPath(path, stroke);
      canvas.restore();
    }

    void line(Path p, double x1, double y1, double x2, double y2) => p
      ..moveTo(x1, y1)
      ..lineTo(x2, y2);

    // Plus.
    symbol(0.15, 0.1, (p) {
      line(p, -11, 0, 11, 0);
      line(p, 0, -11, 0, 11);
    });
    // Times.
    symbol(0.86, 0.13, (p) {
      line(p, -9, -9, 9, 9);
      line(p, 9, -9, -9, 9);
    });
    // Minus.
    symbol(0.5, 0.09, (p) => line(p, -12, 0, 12, 0));
    // Equals.
    symbol(0.09, 0.3, (p) {
      line(p, -11, -5, 11, -5);
      line(p, -11, 5, 11, 5);
    });
    // Triangle.
    symbol(0.91, 0.32, (p) {
      p
        ..moveTo(0, -15)
        ..lineTo(15, 13)
        ..lineTo(-15, 13)
        ..close();
    });
    // Square root.
    symbol(0.09, 0.63, (p) {
      p
        ..moveTo(-15, 2)
        ..lineTo(-8, 16)
        ..lineTo(2, -16)
        ..lineTo(17, -16);
    });
    // Circle with its diameter.
    symbol(0.9, 0.61, (p) {
      p.addOval(Rect.fromCircle(center: Offset.zero, radius: 14));
      line(p, -14, 0, 14, 0);
    });
    // Wave.
    symbol(0.5, 0.92, (p) {
      p
        ..moveTo(-28, 0)
        ..quadraticBezierTo(-14, -20, 0, 0)
        ..quadraticBezierTo(14, 20, 28, 0);
    });
    // Divide.
    symbol(0.86, 0.87, (p) {
      line(p, -13, 0, 13, 0);
      line(p, 0, -10, 0, -9);
      line(p, 0, 9, 0, 10);
    });
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) => false;
}
