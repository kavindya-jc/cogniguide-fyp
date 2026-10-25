import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text.dart';
import '../l10n/app_localizations.dart';
import 'duo_icon.dart';

/// A text field with a visible label above it.
///
/// - Selected: 2px ink border and a soft violet ring.
/// - Needs a fix ([fixMessage] is set): butter border and fill, plus a
///   message with an icon that says how to fix it. Never red.
class LabelledField extends StatefulWidget {
  const LabelledField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.fixMessage,
    this.markForFix = false,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;

  /// Grey helper text under the field.
  final String? helper;

  /// When set, the field shows the "needs a fix" look with this message.
  final String? fixMessage;

  /// Shows the "needs a fix" look without a message under the field
  /// (the message is in a notice above, as on Log in).
  final bool markForFix;

  final bool obscureText;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<LabelledField> createState() => _LabelledFieldState();
}

class _LabelledFieldState extends State<LabelledField> {
  final _focus = FocusNode();

  /// Password boxes start hidden (dots); the eye button shows the letters.
  late bool _hidden = widget.obscureText;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final needsFix = widget.fixMessage != null || widget.markForFix;
    final focused = _focus.hasFocus;

    final border = needsFix
        ? Border.all(color: c.butterInk, width: 2)
        : focused
        ? Border.all(color: c.ink, width: 2)
        : Border.all(color: c.fieldLine, width: 1.5);

    return Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // The screen reader hears the label with the field (below),
          // so the visible label is not read twice.
          ExcludeSemantics(
            child: Text(
              widget.label,
              style: AppText.fieldLabel.copyWith(color: c.ink),
            ),
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 150),
            constraints: const BoxConstraints(minHeight: AppSizes.button),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: needsFix ? c.butterSoft : c.surfaceRaised,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: border,
              boxShadow: focused && !needsFix
                  ? [BoxShadow(color: c.primarySoft, spreadRadius: 4)]
                  : null,
            ),
            child: Semantics(
              label: widget.label,
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                enabled: widget.enabled,
                obscureText: _hidden,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction,
                autofillHints: widget.autofillHints,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                style: AppText.input.copyWith(color: c.ink),
                cursorColor: c.ink,
                decoration: InputDecoration(
                  // The box above draws the border, so the field has none.
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  hintText: widget.hint,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.s4,
                    vertical: 14,
                  ),
                  // Password boxes: an eye button to show or hide the letters.
                  suffixIcon: widget.obscureText
                      ? _ShowPasswordButton(
                          hidden: _hidden,
                          onTap: () => setState(() => _hidden = !_hidden),
                        )
                      : null,
                ),
              ),
            ),
          ),
          if (widget.fixMessage != null) ...[
            const SizedBox(height: 6),
            Semantics(
              liveRegion: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: DuoIcon(AppIcon.alert, size: 18, color: c.butterInk),
                  ),
                  const SizedBox(width: AppSpace.s2),
                  Expanded(
                    child: Text(
                      widget.fixMessage!,
                      style: AppText.help.copyWith(
                        color: c.butterInk,
                        fontWeight: FontWeight.w500,
                        fontVariations: const [FontVariation.weight(500)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (widget.helper != null) ...[
            const SizedBox(height: 6),
            Text(
              widget.helper!,
              style: AppText.help.copyWith(color: c.inkMuted),
            ),
          ],
        ],
      ),
    );
  }
}

/// The eye button inside a password box. 48 × 48 to tap easily; a screen
/// reader hears "Show password" or "Hide password".
class _ShowPasswordButton extends StatelessWidget {
  const _ShowPasswordButton({required this.hidden, required this.onTap});

  final bool hidden;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: hidden ? l10n.passwordShow : l10n.passwordHide,
      excludeSemantics: true,
      child: IconButton(
        onPressed: onTap,
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        icon: DuoIcon(
          hidden ? AppIcon.eye : AppIcon.eyeOff,
          size: 22,
          color: c.inkMuted,
        ),
      ),
    );
  }
}
