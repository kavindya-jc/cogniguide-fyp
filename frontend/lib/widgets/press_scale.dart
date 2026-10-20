import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../theme/app_motion.dart';

/// Shrinks its child a little while a finger or mouse presses it
/// (buttons and chips 0.97, maths keys 0.92), then springs back with a
/// tiny bounce when let go.
///
/// Does nothing when the phone's "reduce motion" setting is on.
/// PERFORMANCE: only a scale (cheap), inside its own repaint layer.
class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    this.scale = 0.97,
    this.enabled = true,
  });

  final Widget child;
  final double scale;
  final bool enabled;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale>
    with SingleTickerProviderStateMixin {
  // 1 = normal size. Unbounded so the spring may overshoot a little.
  // Made in initState (not lazily), so dispose never has to create it.
  late final AnimationController _size;

  @override
  void initState() {
    super.initState();
    _size = AnimationController.unbounded(vsync: this, value: 1);
  }

  @override
  void dispose() {
    _size.dispose();
    super.dispose();
  }

  void _down() => _size.animateTo(
    widget.scale,
    duration: const Duration(milliseconds: 90),
    curve: Curves.easeOut,
  );

  void _up() =>
      _size.animateWith(SpringSimulation(AppMotion.spring, _size.value, 1, 0));

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context) || !widget.enabled) return widget.child;

    return Listener(
      onPointerDown: (_) => _down(),
      onPointerUp: (_) => _up(),
      onPointerCancel: (_) => _up(),
      child: ScaleTransition(scale: _size, child: widget.child),
    );
  }
}
