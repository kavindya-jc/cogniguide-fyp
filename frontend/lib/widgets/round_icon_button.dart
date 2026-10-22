import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import 'press_scale.dart';
import 'duo_icon.dart';

/// The look of a [RoundIconButton].
enum RoundIconTone {
  /// Violet (the send button).
  primary,
  dark,
  soft,

  /// White with a thin grey ring (Back, Settings).
  light,
}

/// A round button with only an icon (Back, Settings, Send).
///
/// [semanticLabel] is required: a screen reader says it, because there is
/// no visible text.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.tone = RoundIconTone.soft,
    this.size = AppSizes.iconButton,
  });

  final AppIcon icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final RoundIconTone tone;

  /// 48 normally, 52 for the send button ([AppSizes.send]).
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final (Color bg, Color fg) = switch (tone) {
      RoundIconTone.primary => (c.primary, c.onPrimary),
      RoundIconTone.dark => (c.night, c.onNight),
      RoundIconTone.soft => (c.surfaceSunken, c.ink),
      RoundIconTone.light => (c.surfaceRaised, c.ink),
    };

    final button = IconButton(
      onPressed: onPressed,
      // The icon's label becomes the button's name for screen readers.
      icon: DuoIcon(icon, size: 22, semanticLabel: semanticLabel),
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(bg),
        foregroundColor: WidgetStatePropertyAll(fg),
        overlayColor: WidgetStatePropertyAll(c.ink.withValues(alpha: 0.06)),
        fixedSize: WidgetStatePropertyAll(Size.square(size)),
        shape: const WidgetStatePropertyAll(CircleBorder()),
        side: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.focused)
              ? BorderSide(
                  color: c.focusRing,
                  width: 3,
                  strokeAlign: BorderSide.strokeAlignOutside,
                )
              : tone == RoundIconTone.light
              ? BorderSide(color: c.line, width: 1.5)
              : BorderSide.none,
        ),
      ),
    );

    return PressScale(
      enabled: onPressed != null,
      child: onPressed == null ? Opacity(opacity: 0.4, child: button) : button,
    );
  }
}
