import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text.dart';
import 'tap_surface.dart';
import 'duo_icon.dart';

/// A problem in the "Pick a problem" list.
///
/// Soft pastel colours take turns by [index]: lilac, butter, peach, sky,
/// mint, then again. [eyebrow] is the small line above the problem, for
/// example "Problem 1 · Algebra · Grade 9".
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
    final (Color bg, Color eyebrowColor) = switch (index % 5) {
      0 => (c.lilacSoft, c.lilacInk),
      1 => (c.butterSoft, c.butterInk),
      2 => (c.peachSoft, c.peachInk),
      3 => (c.skySoft, c.skyInk),
      _ => (c.mintSoft, c.mintInk),
    };
    final fg = c.ink;

    return Semantics(
      button: true,
      label: '$eyebrow. $text',
      excludeSemantics: true,
      child: TapSurface(
        onTap: onTap,
        pressScale: 0.98,
        color: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
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
                      eyebrow,
                      style: AppText.caption.copyWith(
                        color: eyebrowColor,
                        fontSize: 14,
                        height: 18 / 14,
                        fontWeight: FontWeight.w700,
                        fontVariations: const [FontVariation('wght', 700)],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      text,
                      style: AppText.title.copyWith(
                        color: fg,
                        fontSize: 19,
                        height: 25 / 19,
                        fontWeight: FontWeight.w700,
                        fontVariations: const [FontVariation('wght', 700)],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.s3),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: c.surfaceRaised,
                  shape: BoxShape.circle,
                ),
                child: DuoIcon(AppIcon.forward, size: 20, color: c.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
