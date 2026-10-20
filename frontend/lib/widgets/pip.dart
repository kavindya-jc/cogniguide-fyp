import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../l10n/app_localizations.dart';

/// Pip's moods. The design uses only these four
/// (no celebrate, oops or sad: no rewards and no "wrong" feeling).
enum PipMood {
  /// Welcome, Pick a problem greeting, new-student progress, chat.
  idle,

  /// Coach typing, loading screens, empty area, error.
  thinking,

  /// Growth sentence on My progress.
  happy,

  /// Coach busy, Log out sheet.
  sleepy,
}

/// Pip, the coach. One Pip per screen, always with words beside it.
///
/// Still pictures for now. Gentle movement comes in Step 7.
class Pip extends StatelessWidget {
  const Pip({super.key, this.mood = PipMood.idle, this.size = 88});

  final PipMood mood;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = switch (mood) {
      PipMood.idle => l10n.pipIdle,
      PipMood.thinking => l10n.pipThinking,
      PipMood.happy => l10n.pipHappy,
      PipMood.sleepy => l10n.pipSleepy,
    };

    return SvgPicture.asset(
      'assets/pip/pip-${mood.name}.svg',
      width: size,
      height: size,
      semanticsLabel: label,
    );
  }
}
