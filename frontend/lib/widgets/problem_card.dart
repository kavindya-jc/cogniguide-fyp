import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text.dart';
import 'tap_surface.dart';

/// A problem in the "Pick a problem" list.
///
/// Colours take turns by [index]: night, lavender, orange, night, ...
/// [eyebrow] is the small line, for example "Problem 1 · Algebra · Grade 9";
/// it is shown in capitals.
class ProblemCard extends StatelessWidget {
  const ProblemCard({
    super.key,
    required this.index,
    required this.eyebrow,
    required this.text,
    required this.onTap,
  });

  final int index;
  final String eyebrow;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final (Color bg, Color fg, Color eyebrowColor) = switch (index % 3) {
      0 => (c.night, c.onNight, c.nightAccent),
      1 => (c.lavender, c.onAccent, c.onAccent),
      _ => (c.orange, c.onAccent, c.onAccent),
    };

    return Semantics(
      button: true,
      label: '$eyebrow. $text',
      excludeSemantics: true,
      child: TapSurface(
        onTap: onTap,
        pressScale: 0.98,
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.s5,
            AppSpace.s4,
            AppSpace.s4,
            AppSpace.s4,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow.toUpperCase(),
                      style: AppText.eyebrow.copyWith(color: eyebrowColor),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      text,
                      style: AppText.title.copyWith(
                        color: fg,
                        fontSize: 18,
                        height: 25 / 18,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.s3),
              Container(
                width: AppSizes.tap,
                height: AppSizes.tap,
                decoration: BoxDecoration(
                  color: c.surfaceRaised,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 20,
                  color: c.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
