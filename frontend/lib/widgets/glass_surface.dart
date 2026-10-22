import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../services/app_services.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';

/// The kinds of glass.
enum GlassTone {
  /// Frosted and mostly solid, so text right on it is easy to read
  /// (sheets).
  light,

  /// Frosted night (the bottom nav, for now).
  dark,

  /// See-through "liquid" glass, for bars whose words and fields sit on
  /// their own backgrounds (header, nav, chat bar).
  clear,
}

/// Frosted "liquid glass" for things that float above the page.
///
/// PERFORMANCE (blur is the costly part on cheap phones):
/// - Use it only on small floating things, never on a whole screen, and
///   keep at most 2 on screen at once.
/// - The blur amount never animates.
/// - RepaintBoundary keeps the blur from redrawing the rest of the page.
/// - It becomes plain solid colour (no blur) when the student turns
///   "Glass effects" off in Settings, or when the phone's reduce-motion
///   or high-contrast setting is on.
/// - A screen can also turn the blur off for a moment with [blur], at the
///   times it would cost the most (while typing, while sliding).
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    required this.borderRadius,
    this.tone = GlassTone.light,
    this.shadow = true,
    this.blur = true,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final GlassTone tone;

  /// The soft shadow under floating things.
  final bool shadow;

  /// False shows plain solid colour for now (no blur), even when glass is
  /// on. Used while typing in the chat and while the sheet slides.
  final bool blur;

  /// How soft the blur is. Fixed on purpose (animating it is expensive).
  static const double blurSigma = 14;

  /// True when the app may draw the blur.
  static bool blurAllowed(BuildContext context) {
    final settings = AppServices.maybeOf(context)?.settings;
    final media = MediaQuery.of(context);
    return (settings?.glassEffects ?? true) &&
        !media.disableAnimations &&
        !media.highContrast;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final settings = AppServices.maybeOf(context)?.settings;

    return ListenableBuilder(
      listenable: settings ?? const _NeverChanges(),
      builder: (context, _) {
        final glass = blur && blurAllowed(context);
        final solid = tone == GlassTone.dark ? c.night : c.surfaceRaised;

        final surface = DecoratedBox(
          decoration: BoxDecoration(
            color: !glass
                ? solid
                : switch (tone) {
                    GlassTone.light => c.glassLight,
                    GlassTone.dark => c.glassDark,
                    GlassTone.clear => null,
                  },
            // Liquid glass: brighter at the top, clearest in the middle.
            gradient: glass && tone == GlassTone.clear
                ? LinearGradient(
                    begin: const Alignment(-0.3, -1),
                    end: const Alignment(0.3, 1),
                    colors: [
                      c.glassClearTop,
                      c.glassClearMid,
                      c.glassClearBottom,
                    ],
                    stops: const [0, 0.55, 1],
                  )
                : null,
            borderRadius: borderRadius,
            // The thin bright edge that makes glass read as glass.
            border: glass ? Border.all(color: c.glassEdge) : null,
          ),
          // Light catching the top edge.
          position: DecorationPosition.background,
          child: glass
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: const Alignment(0, -0.6),
                      colors: [
                        c.glassHighlight.withValues(
                          alpha: c.glassHighlight.a * 0.35,
                        ),
                        c.glassHighlight.withValues(alpha: 0),
                      ],
                    ),
                  ),
                  child: child,
                )
              : child,
        );

        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            boxShadow: shadow ? AppShadow.soft(c) : null,
          ),
          child: RepaintBoundary(
            child: ClipRRect(
              borderRadius: borderRadius,
              child: glass
                  ? BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: blurSigma,
                        sigmaY: blurSigma,
                      ),
                      child: surface,
                    )
                  : surface,
            ),
          ),
        );
      },
    );
  }
}

/// Stands in for the settings when there are none (it never changes).
class _NeverChanges implements Listenable {
  const _NeverChanges();

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}
