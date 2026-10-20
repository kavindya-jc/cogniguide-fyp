import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';
import '../services/progress_api.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text.dart';
import '../widgets/help_chart.dart';
import '../widgets/round_icon_button.dart';

/// Screen 6b: the chart's numbers as a table, for students (and screen
/// readers) who prefer words to a picture.
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
    final headStyle = AppText.caption.copyWith(color: c.inkMuted, fontSize: 14);

    return Scaffold(
      body: SafeArea(
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
                    icon: Icons.arrow_back_rounded,
                    semanticLabel: l10n.listBack,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
                const SizedBox(height: AppSpace.s5),
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
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  decoration: BoxDecoration(
                    color: c.surfaceRaised,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Table(
                    columnWidths: const {
                      0: FlexColumnWidth(0.9),
                      1: FlexColumnWidth(1.1),
                      2: FlexColumnWidth(1.4),
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      TableRow(
                        children: [
                          Text(l10n.listSession, style: headStyle),
                          Text(l10n.listDate, style: headStyle),
                          Text(l10n.listHelpNeeded, style: headStyle),
                        ],
                      ),
                      for (final (i, s) in sessions.indexed)
                        TableRow(
                          decoration: BoxDecoration(
                            border: Border(top: BorderSide(color: c.line)),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text('${i + 1}', style: AppText.title),
                            ),
                            Text(
                              s.startedAt == null
                                  ? '–'
                                  : dateFormat.format(s.startedAt!),
                              style: AppText.body,
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: _HelpChip(help: s.help),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.s4),
                Text(
                  l10n.progressRoughGuide,
                  style: AppText.caption.copyWith(
                    color: c.inkMuted,
                    fontSize: 14,
                    height: 20 / 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "A lot" / "Some" / "A little": words with a soft colour (never colour
/// alone).
class _HelpChip extends StatelessWidget {
  const _HelpChip({required this.help});

  final HelpNeeded help;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final (Color bg, Color fg) = switch (help) {
      HelpNeeded.aLot => (c.orangeSoft, c.orangeInk),
      HelpNeeded.some => (c.mustardSoft, c.mustardInk),
      HelpNeeded.aLittle => (c.tealSoft, c.tealInk),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        HelpChart.helpWord(l10n, help),
        style: AppText.label.copyWith(color: fg, fontSize: 15),
      ),
    );
  }
}
