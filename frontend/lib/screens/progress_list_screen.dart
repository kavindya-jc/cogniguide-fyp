import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../services/progress_api.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text.dart';
import '../widgets/duo_icon.dart';
import '../widgets/help_chart.dart';
import '../widgets/notice_card.dart';
import '../widgets/round_icon_button.dart';
import '../widgets/soft_blobs.dart';

/// Screen 6b: the chart's numbers written out, one row per session, for
/// students (and screen readers) who prefer words to a picture.
class ProgressListScreen extends StatelessWidget {
  const ProgressListScreen({super.key, required this.sessions});

  /// Oldest first.
  final List<ProgressSession> sessions;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dateFormat = DateFormat('d MMM', locale);
    final headStyle = AppText.caption.copyWith(
      color: c.inkMuted,
      fontSize: 14,
      fontWeight: FontWeight.w700,
      fontVariations: const [FontVariation('wght', 700)],
    );

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: SoftBlobs()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.s5,
                    AppSpace.s4,
                    AppSpace.s5,
                    28,
                  ),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: RoundIconButton(
                        icon: AppIcon.back,
                        semanticLabel: l10n.listBack,
                        tone: RoundIconTone.light,
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                    const SizedBox(height: AppSpace.s4),
                    Semantics(
                      header: true,
                      child: Text(l10n.listTitle, style: AppText.h1),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.listSubtitle,
                      style: AppText.body.copyWith(color: c.inkMuted),
                    ),
                    const SizedBox(height: AppSpace.s5),
                    // Column names (the rows say them again to screen
                    // readers, so these are only for the eyes).
                    ExcludeSemantics(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${l10n.listSession} · ${l10n.listDate}',
                                style: headStyle,
                              ),
                            ),
                            Text(l10n.listHelpNeeded, style: headStyle),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpace.s2),
                    for (final (i, s) in sessions.indexed) ...[
                      if (i > 0) const SizedBox(height: AppSpace.s2),
                      _SessionRow(
                        number: i + 1,
                        date: s.startedAt == null
                            ? '–'
                            : dateFormat.format(s.startedAt!),
                        help: s.help,
                      ),
                    ],
                    const SizedBox(height: AppSpace.s5),
                    NoticeCard(
                      icon: AppIcon.alert,
                      tone: NoticeTone.sky,
                      text: l10n.progressRoughGuide,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One session: its number in a tile, the date, and how much help it
/// needed.
class _SessionRow extends StatelessWidget {
  const _SessionRow({
    required this.number,
    required this.date,
    required this.help,
  });

  final int number;
  final String date;
  final HelpNeeded help;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final word = HelpChart.helpWord(l10n, help);

    return Semantics(
      label:
          '${l10n.listSession} $number, $date, ${l10n.listHelpNeeded}: $word',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: c.surfaceRaised,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.surfaceSunken,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                '$number',
                style: AppText.h2.copyWith(fontSize: 18, height: 1),
              ),
            ),
            const SizedBox(width: AppSpace.s3),
            Expanded(
              child: Text(
                date,
                style: AppText.label.copyWith(color: c.inkMuted),
              ),
            ),
            _HelpChip(help: help, word: word),
          ],
        ),
      ),
    );
  }
}

/// "A lot" / "Some" / "A little": a pastel chip with small bars and the
/// word (never colour alone).
class _HelpChip extends StatelessWidget {
  const _HelpChip({required this.help, required this.word});

  final HelpNeeded help;
  final String word;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final (Color bg, Color fg, int bars) = switch (help) {
      HelpNeeded.aLot => (c.peachSoft, c.peachInk, 3),
      HelpNeeded.some => (c.butterSoft, c.butterInk, 2),
      HelpNeeded.aLittle => (c.mintSoft, c.mintInk, 1),
    };

    return Container(
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Bars(filled: bars, color: fg),
          const SizedBox(width: 6),
          Text(
            word,
            style: AppText.label.copyWith(
              color: fg,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              fontVariations: const [FontVariation('wght', 800)],
            ),
          ),
        ],
      ),
    );
  }
}

/// Three little bars, [filled] of them strong (more bars, more help).
class _Bars extends StatelessWidget {
  const _Bars({required this.filled, required this.color});

  final int filled;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            Container(
              width: 4,
              height: 6.0 + 5 * i,
              decoration: BoxDecoration(
                color: i < filled ? color : color.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
