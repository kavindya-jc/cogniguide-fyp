import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';

/// The page colour behind the phone's status bar (clock, battery), fading
/// out just below it, so a list scrolling up does not show through there.
/// Drawn once; nothing moves. Put it in a Stack above the list, under any
/// floating buttons.
class StatusBarFade extends StatelessWidget {
  const StatusBarFade({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final top = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: top + AppSpace.s4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [c.surface, c.surface, c.surface.withValues(alpha: 0)],
            stops: [0, top / (top + AppSpace.s4), 1],
          ),
        ),
      ),
    );
  }
}
