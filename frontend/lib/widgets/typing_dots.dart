import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';

/// Three violet dots in a coach bubble while the coach is writing.
///
/// Each dot rises 4px and brightens, one after another (1.2s loop).
/// With "reduce motion" on, the dots stand still.
class TypingDots extends StatefulWidget {
  const TypingDots({super.key});

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// How far up a dot is (0 to 1) at loop time [t]:
  /// up by 40% of the loop, back down by 80%, then rest.
  static double _lift(double t) {
    if (t < 0.4) return Curves.easeInOut.transform(t / 0.4);
    if (t < 0.8) return Curves.easeInOut.transform((0.8 - t) / 0.4);
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final still = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      liveRegion: true,
      label: AppLocalizations.of(context).chatCoachThinking,
      excludeSemantics: true,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: c.surfaceRaised,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppRadius.bubble),
              topRight: Radius.circular(AppRadius.bubble),
              bottomRight: Radius.circular(AppRadius.bubble),
              bottomLeft: Radius.circular(AppRadius.bubbleTail),
            ),
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  _dot(
                    c,
                    still ? 0.5 : _lift((_controller.value - i * 0.125) % 1),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dot(AppColors c, double lift) {
    return Transform.translate(
      offset: Offset(0, -4 * lift),
      child: Opacity(
        opacity: 0.3 + 0.7 * lift,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: c.primary, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
