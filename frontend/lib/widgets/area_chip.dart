import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/maths_area.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text.dart';
import 'tap_surface.dart';

/// One maths area filter chip. 44px tall, white.
/// When chosen it turns night and shows a tick (so not colour alone).
class AreaChip extends StatelessWidget {
  const AreaChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final fg = selected ? c.onNight : c.ink;

    return Semantics(
      button: true,
      selected: selected,
      child: TapSurface(
        onTap: onTap,
        color: selected ? c.night : c.surfaceRaised,
        shape: const StadiumBorder(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.tap),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  Icon(Icons.check_rounded, size: 18, color: fg),
                  const SizedBox(width: AppSpace.s1),
                ],
                Text(label, style: AppText.label.copyWith(color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A sideways-scrolling row with one [AreaChip] per maths area.
class AreaChipRow extends StatelessWidget {
  const AreaChipRow({
    super.key,
    required this.selected,
    required this.onChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpace.s5),
  });

  final MathsArea selected;
  final ValueChanged<MathsArea> onChanged;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.areaGroup,
      container: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        // Room for the focus ring above and below.
        padding: padding.copyWith(top: 4, bottom: 4),
        child: Row(
          children: [
            for (final area in MathsArea.values) ...[
              if (area != MathsArea.values.first)
                const SizedBox(width: AppSpace.s2),
              AreaChip(
                label: area.label(l10n),
                selected: area == selected,
                onTap: () => onChanged(area),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
