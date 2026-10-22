import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text.dart';
import 'dashed_box.dart';
import 'duo_icon.dart';

/// The pastel colour of a [StatTile].
enum StatTone { sky, mint, peach, lilac }

/// One of the 4 numbers on My progress, for example "6 · Sessions":
/// a soft pastel tile with an icon, a big number and a label.
///
/// [dashed] is the empty look for a new student (no icon, dashed border).
/// It shows a count, never a score or a grade.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.tone = StatTone.sky,
    this.dashed = false,
  });

  final int value;
  final String label;
  final AppIcon? icon;
  final StatTone tone;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final (Color bg, Color ink) = switch (tone) {
      StatTone.sky => (c.skySoft, c.skyInk),
      StatTone.mint => (c.mintSoft, c.mintInk),
      StatTone.peach => (c.peachSoft, c.peachInk),
      StatTone.lilac => (c.lilacSoft, c.lilacInk),
    };

    final content = Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!dashed && icon != null) ...[
            DuoIcon(icon!, size: 26, color: ink),
            const SizedBox(height: AppSpace.s1),
          ],
          Text('$value', style: AppText.stat.copyWith(color: c.ink)),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppText.label.copyWith(
              color: dashed ? c.inkMuted : ink,
              height: 20 / 16,
            ),
          ),
        ],
      ),
    );

    final tile = dashed
        ? DashedBox(
            color: c.inkMuted,
            radius: AppRadius.md,
            child: Align(alignment: Alignment.topLeft, child: content),
          )
        : Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Align(alignment: Alignment.topLeft, child: content),
          );

    // Read as one item: "6, Sessions".
    return Semantics(
      label: '$value, $label',
      excludeSemantics: true,
      child: tile,
    );
  }
}
