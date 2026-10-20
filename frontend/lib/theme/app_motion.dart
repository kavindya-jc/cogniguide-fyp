import 'package:flutter/material.dart';

/// Motion timings from the design spec, in one place.
///
/// PERFORMANCE: animations only move, scale or fade things (cheap on any
/// phone). Nothing animates blur. Everything is skipped when the phone's
/// "reduce motion" setting is on: use [AppMotion.of] to get a duration
/// that becomes zero then.
abstract final class AppMotion {
  /// Small reactions: press, tick, colour change.
  static const Duration quick = Duration(milliseconds: 180);

  /// Things that move a short way: grade pill, problem card opening.
  static const Duration medium = Duration(milliseconds: 280);

  /// Chat bubbles popping in.
  static const Duration pop = Duration(milliseconds: 350);

  /// Bigger moves: the log-out sheet sliding up.
  static const Duration sheet = Duration(milliseconds: 450);

  /// The spec's main curve.
  static const Curve ease = Curves.easeOutCubic;

  /// A soft, slightly bouncy spring (the "liquid" feel).
  static const SpringDescription spring = SpringDescription(
    mass: 1,
    stiffness: 420,
    damping: 26,
  );

  /// True when the phone asks for less motion.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [duration], or zero when the phone asks for less motion.
  static Duration of(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;
}
