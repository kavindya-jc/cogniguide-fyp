import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/buddy.dart';
import '../theme/app_colors.dart';

/// The student's buddy picture in a circle.
///
/// [selected] adds a violet ring (the Pick your buddy grid also adds a
/// tick, so the choice is never shown by colour alone).
/// Decorative by default: the words beside it say who it is. Give
/// [semanticLabel] when it stands alone.
///
/// PERFORMANCE: a tiny vector picture, read once and kept by flutter_svg.
class BuddyAvatar extends StatelessWidget {
  const BuddyAvatar({
    super.key,
    required this.buddy,
    this.size = 36,
    this.selected = false,
    this.semanticLabel,
  });

  final Buddy buddy;
  final double size;
  final bool selected;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ring = size >= 64 ? 4.0 : 2.0;

    final picture = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // A thin white gap, then the violet ring when chosen.
        border: Border.all(color: c.surfaceRaised, width: ring),
        boxShadow: selected
            ? [BoxShadow(color: c.primary, spreadRadius: ring)]
            : null,
      ),
      child: ClipOval(
        child: SvgPicture.asset(
          buddy.asset,
          fit: BoxFit.cover,
          excludeFromSemantics: true,
        ),
      ),
    );

    if (semanticLabel == null) return ExcludeSemantics(child: picture);
    return Semantics(label: semanticLabel, image: true, child: picture);
  }
}
