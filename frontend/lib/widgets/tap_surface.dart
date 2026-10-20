import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'press_scale.dart';

/// A coloured, tappable shape used by chips, grade buttons and problem cards.
///
/// It gives every one of them the same behaviour:
/// - darkens a little on hover and press,
/// - shrinks a little when pressed ([PressScale]),
/// - shows a 3px ink focus ring when reached with the keyboard.
class TapSurface extends StatefulWidget {
  const TapSurface({
    super.key,
    required this.child,
    required this.onTap,
    required this.color,
    required this.shape,
    this.pressScale = 0.97,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final OutlinedBorder shape;
  final double pressScale;

  @override
  State<TapSurface> createState() => _TapSurfaceState();
}

class _TapSurfaceState extends State<TapSurface> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final keyboard =
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    final showRing = _focused && keyboard;

    return PressScale(
      scale: widget.pressScale,
      enabled: widget.onTap != null,
      child: Material(
        color: widget.color,
        shape: widget.shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onFocusChange: (f) => setState(() => _focused = f),
          overlayColor: WidgetStatePropertyAll(c.ink.withValues(alpha: 0.06)),
          focusColor: Colors.transparent,
          child: widget.child,
        ),
      ),
    ).wrapRing(
      show: showRing,
      shape: widget.shape.copyWith(
        side: BorderSide(
          color: c.focusRing,
          width: 3,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
    );
  }
}

extension on Widget {
  /// Paints [shape]'s border on top of the widget when [show] is true.
  Widget wrapRing({required bool show, required OutlinedBorder shape}) {
    if (!show) return this;
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: ShapeDecoration(shape: shape),
      child: this,
    );
  }
}
