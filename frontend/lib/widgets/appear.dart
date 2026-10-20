import 'package:flutter/material.dart';

import '../theme/app_motion.dart';

/// How a new thing arrives on screen.
enum AppearStyle {
  /// A coach bubble: pops up from its bottom-left corner.
  popLeft,

  /// The student's bubble: pops up from its bottom-right corner (the side
  /// of the input bar it came from).
  popRight,

  /// A notice: drops in gently from just above. No shaking.
  drop,
}

/// Plays a short arrival animation once, the first time [child] is shown.
///
/// Give it a stable key in lists, so it does not replay on rebuilds.
/// PERFORMANCE: only fades, moves a few pixels and scales (cheap).
/// With "reduce motion" on, the child simply appears.
class Appear extends StatelessWidget {
  const Appear({super.key, required this.child, required this.style});

  final Widget child;
  final AppearStyle style;

  @override
  Widget build(BuildContext context) {
    final drop = style == AppearStyle.drop;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.of(context, AppMotion.pop),
      // A small spring for bubbles; a calm ease for notices.
      curve: drop ? AppMotion.ease : Curves.easeOutBack,
      child: child,
      builder: (context, t, child) {
        if (t >= 1) return child!;
        final shown = t.clamp(0.0, 1.0);
        return Opacity(
          opacity: shown,
          child: Transform.translate(
            offset: Offset(0, drop ? -6 * (1 - t) : 8 * (1 - t)),
            child: drop
                ? child
                : Transform.scale(
                    scale: 0.94 + 0.06 * t,
                    alignment: style == AppearStyle.popLeft
                        ? Alignment.bottomLeft
                        : Alignment.bottomRight,
                    child: child,
                  ),
          ),
        );
      },
    );
  }
}
