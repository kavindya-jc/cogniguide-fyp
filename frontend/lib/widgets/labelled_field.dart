import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text.dart';

/// A text field with a visible label above it.
///
/// - Selected: 2px ink border and a soft teal ring.
/// - Needs a fix ([fixMessage] is set): mustard border and fill, plus a
///   message with an icon that says how to fix it. Never red.
class LabelledField extends StatefulWidget {
  const LabelledField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.fixMessage,
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
    final needsFix = widget.fixMessage != null;
    final focused = _focus.hasFocus;

    final border = needsFix
        ? Border.all(color: c.mustardInk, width: 2)
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
              color: needsFix ? c.mustardSoft : c.surfaceRaised,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: border,
              boxShadow: focused && !needsFix
                  ? [BoxShadow(color: c.tealSoft, spreadRadius: 4)]
                  : null,
            ),
            child: Semantics(
              label: widget.label,
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                enabled: widget.enabled,
                obscureText: widget.obscureText,
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
                ),
              ),
            ),
          ),
          if (needsFix) ...[
            const SizedBox(height: 6),
            Semantics(
              liveRegion: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 18,
                      color: c.mustardInk,
                    ),
                  ),
                  const SizedBox(width: AppSpace.s2),
                  Expanded(
                    child: Text(
                      widget.fixMessage!,
                      style: AppText.help.copyWith(
                        color: c.mustardInk,
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
