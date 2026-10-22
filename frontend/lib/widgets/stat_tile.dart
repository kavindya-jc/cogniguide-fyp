import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text.dart';
import 'dashed_box.dart';

/// The colour of a [StatTile]'s icon circle.
enum StatTone { primary, butter, peach, lilac }

/// One of the 4 numbers on My progress, for example "6 · Sessions".
///
/// [dashed] is the empty look for a new student (no icon, dashed border).
/// It shows a count, never a score or a grade.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.tone = StatTone.primary,
    this.dashed = false,
  });

  final int value;
  final String label;
  final IconData? icon;
  final StatTone tone;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final (Color bg, Color well, Color onWell) = switch (tone) {
      StatTone.primary => (c.surfaceSunken, c.primary, c.onPrimary),
      StatTone.butter => (c.surfaceSunken, c.butter, c.onAccent),
      StatTone.peach => (c.peachSoft, c.peach, c.onAccent),
      StatTone.lilac => (c.lilacSoft, c.lilac, c.onAccent),
    };

    // Centred, so tiles of the same height line up in a grid.
    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.s3,
        vertical: AppSpace.s4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!dashed && icon != null) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: well, shape: BoxShape.circle),
              child: Icon(icon, size: 20, color: onWell),
            ),
            const SizedBox(height: AppSpace.s2),
          ],
          Text('$value', style: AppText.stat.copyWith(color: c.ink)),
          const SizedBox(height: AppSpace.s1),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppText.label.copyWith(
              color: c.inkMuted,
              fontWeight: FontWeight.w500,
              fontVariations: const [FontVariation.weight(500)],
            ),
          ),
        ],
      ),
    );

    final tile = dashed
        ? DashedBox(
            color: c.inkMuted,
            radius: AppRadius.md,
            child: Center(child: content),
          )
        : Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Center(child: content),
          );

    // Read as one item: "6, Sessions".
    return Semantics(
      label: '$value, $label',
      excludeSemantics: true,
      child: tile,
    );
  }
}
