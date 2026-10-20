import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/maths_area.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text.dart';
import 'tap_surface.dart';

/// "Grade  All 8 9 10 11". Each button is at least 44 × 44.
/// The chosen one is teal-soft with a teal ring.
///
/// [selected] is null for "All".
class GradeFilter extends StatelessWidget {
  const GradeFilter({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final int? selected;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);

    return Semantics(
      label: l10n.gradeLabel,
      container: true,
      child: Row(
        children: [
          ExcludeSemantics(
            child: Text(
              l10n.gradeLabel,
              style: AppText.label.copyWith(color: c.inkMuted),
            ),
          ),
          const SizedBox(width: AppSpace.s2),
          _GradeButton(
            text: l10n.gradeAll,
            semanticLabel: l10n.gradeAllSemantics,
            selected: selected == null,
            onTap: () => onChanged(null),
          ),
          for (final g in appGrades) ...[
            const SizedBox(width: 2),
            _GradeButton(
              text: '$g',
              semanticLabel: l10n.gradeSemantics(g),
              selected: selected == g,
              onTap: () => onChanged(g),
            ),
          ],
        ],
      ),
    );
  }
}

class _GradeButton extends StatelessWidget {
  const _GradeButton({
    required this.text,
    required this.semanticLabel,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final String semanticLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      excludeSemantics: true,
      child: TapSurface(
        onTap: onTap,
        pressScale: 0.95,
        color: selected ? c.tealSoft : Colors.transparent,
        shape: StadiumBorder(
          side: selected
              ? BorderSide(color: c.teal, width: 2)
              : BorderSide.none,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppSizes.tap,
            minHeight: AppSizes.tap,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Center(
              widthFactor: 1,
              child: Text(
                text,
                style: AppText.label.copyWith(
                  color: selected ? c.tealInk : c.inkMuted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
