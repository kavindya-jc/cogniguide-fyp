import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../models/maths_area.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
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
                // The tick slides in (the chip grows a little to fit it).
                AnimatedSize(
                  duration: AppMotion.of(context, AppMotion.quick),
                  curve: AppMotion.ease,
                  child: selected
                      ? Padding(
                          padding: const EdgeInsets.only(right: AppSpace.s1),
                          child: Icon(Icons.check_rounded, size: 18, color: fg),
                        )
                      : const SizedBox.shrink(),
                ),
                AnimatedDefaultTextStyle(
                  duration: AppMotion.of(context, AppMotion.quick),
                  style: AppText.label.copyWith(color: fg),
                  child: Text(label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A sideways-scrolling row with one [AreaChip] per maths area.
/// The row scrolls itself so the chosen chip is fully on screen.
class AreaChipRow extends StatefulWidget {
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
  State<AreaChipRow> createState() => _AreaChipRowState();
}

class _AreaChipRowState extends State<AreaChipRow> {
  final _keys = {for (final a in MathsArea.values) a: GlobalKey()};

  @override
  void didUpdateWidget(AreaChipRow old) {
    super.didUpdateWidget(old);
    if (widget.selected == old.selected) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chip = _keys[widget.selected]?.currentContext;
      if (chip == null || !chip.mounted) return;
      Scrollable.ensureVisible(
        chip,
        alignment: 0.5,
        duration: AppMotion.of(context, AppMotion.medium),
        curve: AppMotion.ease,
      );
    });
  }

  void _choose(MathsArea area) {
    if (area != widget.selected) HapticFeedback.selectionClick();
    widget.onChanged(area);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.areaGroup,
      container: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        // Room for the focus ring above and below.
        padding: widget.padding.copyWith(top: 4, bottom: 4),
        child: Row(
          children: [
            for (final area in MathsArea.values) ...[
              if (area != MathsArea.values.first)
                const SizedBox(width: AppSpace.s2),
              AreaChip(
                key: _keys[area],
                label: area.label(l10n),
                selected: area == widget.selected,
                onTap: () => _choose(area),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
