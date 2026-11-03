import 'package:flutter/material.dart';

import '../services/app_services.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import 'duo_icon.dart';
import 'glass_surface.dart';
import 'press_scale.dart';

/// The look of a [RoundIconButton].
enum RoundIconTone {
  /// Violet (the send button).
  primary,
  dark,
  soft,

  /// White with a thin grey ring (Back, Settings).
  light,

  /// See-through glass with a bright edge, for buttons on glass bars and
  /// on the colour glows. No blur of its own (cheap on any phone). With
  /// glass turned off it looks like [light].
  glass,
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
    final settings = AppServices.maybeOf(context)?.settings;
    if (tone != RoundIconTone.glass || settings == null) return _build(context);
    // Glass follows the "Glass effects" switch as soon as it changes.
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final c = AppColors.of(context);
    final (Color bg, Color fg) = switch (tone) {
      RoundIconTone.primary => (c.primary, c.onPrimary),
      RoundIconTone.dark => (c.night, c.onNight),
      RoundIconTone.soft => (c.surfaceSunken, c.ink),
      RoundIconTone.light => (c.surfaceRaised, c.ink),
      RoundIconTone.glass => (c.surfaceRaised, c.ink),
    };
    final glass =
        tone == RoundIconTone.glass && GlassSurface.blurAllowed(context);

    final button = IconButton(
      onPressed: onPressed,
      // The icon's label becomes the button's name for screen readers.
      icon: DuoIcon(icon, size: 22, semanticLabel: semanticLabel),
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(
          glass ? Colors.transparent : bg,
        ),
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
              : glass
              ? BorderSide(color: c.glassEdge)
              : tone == RoundIconTone.light || tone == RoundIconTone.glass
              ? BorderSide(color: c.line, width: 1.5)
              : BorderSide.none,
        ),
      ),
    );

    // Glass: brighter at the top, like light on a bead of glass.
    final shown = glass
        ? DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [bg.withValues(alpha: 0.9), bg.withValues(alpha: 0.55)],
              ),
              boxShadow: [
                BoxShadow(
                  color: c.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: button,
          )
        : button;

    return PressScale(
      enabled: onPressed != null,
      child: onPressed == null ? Opacity(opacity: 0.4, child: shown) : shown,
    );
  }
}
