import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_motion.dart';

/// The ways something can arrive in the Welcome entrance.
enum EntranceStyle {
  /// Fades up 14px (titles, steps, buttons). 0.55 s, as in the spec.
  rise,

  /// Grows in with a small bounce (Pip).
  drop,

  /// Slides up from the bottom edge (the violet panel).
  slideUp,
}

/// Plays one entrance animation once, after [delay].
///
/// Used for the app's ONE orchestrated moment (the Welcome screen), so
/// the rest of the app stays calm. With "reduce motion" on, the child is
/// simply shown. PERFORMANCE: fade, move and scale only.
class Entrance extends StatelessWidget {
  const Entrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.style = EntranceStyle.rise,
  });

  final Widget child;
  final Duration delay;
  final EntranceStyle style;

  static const _length = Duration(milliseconds: 550);

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) return child;

    final animated = child.animate(delay: delay);
    return switch (style) {
      EntranceStyle.rise =>
        animated
            .fadeIn(duration: _length, curve: AppMotion.ease)
            .moveY(begin: 14, end: 0, duration: _length, curve: AppMotion.ease),
      EntranceStyle.drop =>
        animated
            .fadeIn(duration: const Duration(milliseconds: 250))
            .scaleXY(
              begin: 0.6,
              end: 1,
              duration: _length,
              curve: Curves.easeOutBack,
            ),
      EntranceStyle.slideUp => animated.slideY(
        begin: 1,
        end: 0,
        duration: _length,
        curve: AppMotion.ease,
      ),
    };
  }
}

/// Soft pulse for grey "loading" placeholders. It only exists while
/// something loads, so it never runs for long. Still with reduce motion.
class Pulse extends StatefulWidget {
  const Pulse({super.key, required this.child});

  final Widget child;

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
      lowerBound: 0.5,
      value: 1,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _c.stop();
      _c.value = 1;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: FadeTransition(opacity: _c, child: widget.child),
  );
}
