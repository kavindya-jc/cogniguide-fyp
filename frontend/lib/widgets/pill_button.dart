import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text.dart';
import 'press_scale.dart';

/// The look of a [PillButton].
enum PillTone {
  /// Main action: night fill.
  dark,

  /// Second action: sunken fill.
  soft,

  /// On a teal panel: white fill.
  light,

  /// Text link: no fill, teal-ink text.
  ghost,

  /// Text link on a teal panel: no fill, white text.
  ghostOnTeal,

  /// On a teal panel: white outline.
  outlineOnTeal,
}

/// The round "pill" button from the design. 52px tall.
///
/// Set [onPressed] to null to switch it off (it fades to 40%).
/// Set [loading] to show a spinner, for example "Logging you in".
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.tone = PillTone.dark,
    this.icon,
    this.loading = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final PillTone tone;
  final IconData? icon;
  final bool loading;

  /// Fill the whole width (most main buttons do).
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final (Color bg, Color fg, BorderSide side) = switch (tone) {
      PillTone.dark => (c.night, c.onNight, BorderSide.none),
      PillTone.soft => (c.surfaceSunken, c.ink, BorderSide.none),
      PillTone.light => (c.surfaceRaised, c.ink, BorderSide.none),
      PillTone.ghost => (Colors.transparent, c.tealInk, BorderSide.none),
      PillTone.ghostOnTeal => (Colors.transparent, c.onTeal, BorderSide.none),
      PillTone.outlineOnTeal => (
        Colors.transparent,
        c.onTeal,
        BorderSide(color: c.onTeal, width: 2),
      ),
    };

    final enabled = onPressed != null && !loading;

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
          horizontal: tone == PillTone.ghost || tone == PillTone.ghostOnTeal
              ? AppSpace.s3
              : AppSpace.s6,
        ),
      ),
      shape: const WidgetStatePropertyAll(StadiumBorder()),
      side: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.focused)
            ? BorderSide(
                color: c.focusRing,
                width: 3,
                strokeAlign: BorderSide.strokeAlignOutside,
              )
            : side,
      ),
      textStyle: WidgetStatePropertyAll(AppText.label),
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
          Icon(icon, size: 22, color: fg),
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

    // A loading button keeps full colour; a switched-off one fades.
    if (onPressed == null && !loading) {
      button = Opacity(opacity: 0.4, child: button);
    }

    if (expand) button = SizedBox(width: double.infinity, child: button);

    return Semantics(
      liveRegion: loading,
      child: PressScale(enabled: enabled, child: button),
    );
  }
}
