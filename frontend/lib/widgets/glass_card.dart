import 'package:flutter/material.dart';

import '../services/app_services.dart';
import '../theme/app_colors.dart';
import 'glass_surface.dart';

/// A card that looks like glass resting on the page: its colour fades a
/// little toward the bottom so the colour glows show through, with a
/// bright edge and light catching the top.
///
/// PERFORMANCE: no blur at all (only see-through colour), so it is as
/// cheap as a normal card and does not count toward the 2-blur limit.
/// With "Glass effects" off (or reduce motion / high contrast) it is a
/// plain solid card.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    required this.color,
    this.padding = const EdgeInsets.all(12),
    this.radius = 26,
  });

  final Widget child;

  /// The card's colour (for example mintSoft or surfaceRaised).
  final Color color;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final settings = AppServices.maybeOf(context)?.settings;
    if (settings == null) return _build(context);
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final c = AppColors.of(context);
    final glass = GlassSurface.blurAllowed(context);
    final shape = BorderRadius.circular(radius);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: glass ? null : color,
        // Mostly solid, so text on it stays easy to read.
        gradient: glass
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color, color.withValues(alpha: 0.8)],
              )
            : null,
        borderRadius: shape,
        border: glass ? Border.all(color: c.glassEdge) : null,
        boxShadow: glass
            ? [
                BoxShadow(
                  color: c.shadow,
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: DecoratedBox(
        // Light catching the top edge.
        decoration: BoxDecoration(
          borderRadius: shape,
          gradient: glass
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: const Alignment(0, -0.5),
                  colors: [
                    c.glassHighlight.withValues(
                      alpha: c.glassHighlight.a * 0.4,
                    ),
                    c.glassHighlight.withValues(alpha: 0),
                  ],
                )
              : null,
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
