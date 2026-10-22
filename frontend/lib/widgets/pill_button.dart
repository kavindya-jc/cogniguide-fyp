import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text.dart';
import 'duo_icon.dart';
import 'press_scale.dart';

/// The look of a [PillButton].
enum PillTone {
  /// Main action: chunky violet button.
  primary,

  /// Serious action (Log out): chunky night button.
  night,

  /// Second action: chunky white button with a grey edge.
  soft,

  /// On a violet panel: chunky white button.
  light,

  /// Text link: no fill, violet-ink text.
  ghost,

  /// Text link on a violet panel: no fill, white text.
  ghostOnPrimary,

  /// On a violet panel: white outline.
  outlineOnPrimary,
}

/// The app's button. 52px tall.
///
/// The filled tones are "chunky": they sit on a darker band
/// ([AppSizes.buttonEdge]) and sink into it while pressed, like a real key.
///
/// Set [onPressed] to null to switch it off (it fades to 40%).
/// Set [loading] to show a spinner, for example "Logging you in".
///
/// PERFORMANCE: the sink is a 5px move of the top part (cheap), in its own
/// repaint layer.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.tone = PillTone.primary,
    this.icon,
    this.loading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final PillTone tone;
  final AppIcon? icon;
  final bool loading;

  /// Fill the whole width (most main buttons do).
  final bool expand;

  bool get _chunky =>
      tone == PillTone.primary ||
      tone == PillTone.night ||
      tone == PillTone.soft ||
      tone == PillTone.light;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final (Color bg, Color fg, Color edge, BorderSide side) = switch (tone) {
      PillTone.primary => (
        c.primary,
        c.onPrimary,
        c.primaryEdge,
        BorderSide.none,
      ),
      PillTone.night => (c.night, c.onNight, c.primaryEdge, BorderSide.none),
      PillTone.soft => (
        c.surfaceRaised,
        c.ink,
        c.line,
        BorderSide(color: c.line, width: 2),
      ),
      PillTone.light => (
        c.surfaceRaised,
        c.ink,
        c.primaryEdge,
        BorderSide.none,
      ),
      PillTone.ghost => (
        Colors.transparent,
        c.primaryInk,
        Colors.transparent,
        BorderSide.none,
      ),
      PillTone.ghostOnPrimary => (
        Colors.transparent,
        c.onPrimary,
        Colors.transparent,
        BorderSide.none,
      ),
      PillTone.outlineOnPrimary => (
        Colors.transparent,
        c.onPrimary,
        Colors.transparent,
        BorderSide(color: c.onPrimary, width: 2),
      ),
    };

    final enabled = onPressed != null && !loading;
    final shape = _chunky
        ? RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          )
        : const StadiumBorder();

    final style = ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(bg),
      foregroundColor: WidgetStatePropertyAll(fg),
      overlayColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.pressed)
            ? c.ink.withValues(alpha: 0.06)
            : null,
      ),
      minimumSize: const WidgetStatePropertyAll(
        Size(AppSizes.tap, AppSizes.button),
      ),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(
          horizontal: tone == PillTone.ghost || tone == PillTone.ghostOnPrimary
              ? AppSpace.s3
              : AppSpace.s6,
        ),
      ),
      shape: WidgetStatePropertyAll(shape),
      side: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.focused)
            ? BorderSide(
                color: c.focusRing,
                width: 3,
                strokeAlign: BorderSide.strokeAlignOutside,
              )
            : side,
      ),
      textStyle: WidgetStatePropertyAll(
        AppText.label.copyWith(
          fontWeight: FontWeight.w800,
          fontVariations: const [FontVariation('wght', 800)],
        ),
      ),
      elevation: const WidgetStatePropertyAll(0),
    );

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading) ...[
          SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 3, color: fg),
          ),
          const SizedBox(width: 10),
        ] else if (icon != null) ...[
          DuoIcon(icon!, size: 22, color: fg),
          const SizedBox(width: AppSpace.s2),
        ],
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    );

    Widget button = TextButton(
      onPressed: enabled ? onPressed : null,
      style: style,
      child: content,
    );

    if (expand) button = SizedBox(width: double.infinity, child: button);

    button = _chunky
        ? _ChunkyPress(enabled: enabled, edge: edge, child: button)
        : PressScale(enabled: enabled, child: button);

    // A loading button keeps full colour; a switched-off one fades.
    if (onPressed == null && !loading) {
      button = Opacity(opacity: 0.4, child: button);
    }

    return Semantics(liveRegion: loading, child: button);
  }
}

/// Puts a button on a darker band and sinks it into the band while pressed.
class _ChunkyPress extends StatefulWidget {
  const _ChunkyPress({
    required this.enabled,
    required this.edge,
    required this.child,
  });

  final bool enabled;
  final Color edge;
  final Widget child;

  @override
  State<_ChunkyPress> createState() => _ChunkyPressState();
}

class _ChunkyPressState extends State<_ChunkyPress> {
  bool _down = false;

  void _set(bool down) {
    if (widget.enabled && down != _down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    const e = AppSizes.buttonEdge;
    // The sink answers the finger, so it stays on with reduce motion,
    // just without the slide.
    final duration = AppMotion.of(context, const Duration(milliseconds: 70));

    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: RepaintBoundary(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: widget.edge,
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          child: AnimatedPadding(
            duration: duration,
            curve: Curves.easeOut,
            padding: EdgeInsets.only(top: _down ? e : 0, bottom: _down ? 0 : e),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
