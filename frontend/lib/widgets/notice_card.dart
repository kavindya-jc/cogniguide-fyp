import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text.dart';

/// The look of a [NoticeCard].
enum NoticeTone {
  /// Busy, something went wrong, offline, write-it-down.
  butter,

  /// Privacy and language notes.
  primary,
}

/// A rounded note with an icon in a circle and words beside it.
/// Always an icon and words, so the meaning is never colour alone.
class NoticeCard extends StatelessWidget {
  const NoticeCard({
    super.key,
    required this.icon,
    required this.text,
    this.tone = NoticeTone.butter,
    this.title,
    this.action,
  });

  final IconData icon;
  final String text;
  final NoticeTone tone;

  /// Optional bold first line.
  final String? title;

  /// Optional button under the text, for example "Try again".
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final (Color bg, Color well, Color onWell) = switch (tone) {
      NoticeTone.butter => (c.butterSoft, c.butter, c.onAccent),
      NoticeTone.primary => (c.primarySoft, c.primary, c.onPrimary),
    };

    return Semantics(
      container: true,
      liveRegion: tone == NoticeTone.butter,
      child: Container(
        padding: const EdgeInsets.all(AppSpace.s4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: well, shape: BoxShape.circle),
              child: Icon(icon, size: 20, color: onWell),
            ),
            const SizedBox(width: AppSpace.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) ...[
                    Text(title!, style: AppText.title.copyWith(color: c.ink)),
                    const SizedBox(height: AppSpace.s1),
                  ],
                  Text(text, style: AppText.body.copyWith(color: c.ink)),
                  if (action != null) ...[
                    const SizedBox(height: AppSpace.s3),
                    action!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
