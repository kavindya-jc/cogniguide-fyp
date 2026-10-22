import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/app_services.dart';
import '../services/progress_api.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text.dart';
import '../widgets/dashed_box.dart';
import '../widgets/entrance.dart';
import '../widgets/help_chart.dart';
import '../widgets/notice_card.dart';
import '../widgets/pill_button.dart';
import '../widgets/pip.dart';
import '../widgets/stat_tile.dart';
import 'progress_list_screen.dart';

/// Tab 2: My progress, from `GET /progress`.
///
/// How the student's own thinking is growing. Not a grade: only counts,
/// the server's growth sentence, and how much help each session needed.
class ProgressTab extends StatefulWidget {
  const ProgressTab({
    super.key,
    required this.code,
    required this.active,
    required this.onStartProblem,
  });

  /// The student's anonymous code.
  final String code;

  /// True while this tab is on screen. It reloads each time it opens,
  /// so a chat that just finished is counted.
  final bool active;

  /// Goes to the Practice tab.
  final VoidCallback onStartProblem;

  @override
  State<ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<ProgressTab> {
  Future<ProgressResult>? _result;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_result == null && widget.active) _load();
  }

  @override
  void didUpdateWidget(ProgressTab old) {
    super.didUpdateWidget(old);
    final opened = widget.active && !old.active;
    final gotCode = widget.code != old.code && widget.active;
    if (opened || gotCode) _load();
  }

  void _load() {
    if (widget.code.isEmpty) return;
    setState(() {
      _result = AppServices.of(context).progress.load(widget.code);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);

    // Not opened yet (the tab is built in the background): draw nothing,
    // so no loading pulse runs where nobody can see it.
    if (_result == null) return const SizedBox.shrink();

    return SafeArea(
      bottom: false,
      child: FutureBuilder<ProgressResult>(
        future: _result,
        builder: (context, snap) {
          final result = snap.connectionState == ConnectionState.done
              ? snap.data
              : null;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.s5,
              AppSpace.s6,
              AppSpace.s5,
              104,
            ),
            children: [
              Semantics(
                header: true,
                child: Text(l10n.navProgress, style: AppText.h1),
              ),
              const SizedBox(height: AppSpace.s1),
              Text(
                l10n.progressSubtitle,
                style: AppText.body.copyWith(color: c.inkMuted),
              ),
              const SizedBox(height: AppSpace.s4),
              ...switch (result) {
                null => [const _Loading()],
                ProgressFailure(:final problem) => [
                  _Problem(problem: problem, onRetry: _load),
                ],
                ProgressLoaded(:final progress) when progress.isNewStudent => [
                  _NewStudent(
                    progress: progress,
                    onStartProblem: widget.onStartProblem,
                  ),
                ],
                ProgressLoaded(:final progress) => [
                  _WithData(progress: progress),
                ],
              },
            ],
          );
        },
      ),
    );
  }
}

/// The 4 number tiles in a 2 × 2 grid.
class _Tiles extends StatelessWidget {
  const _Tiles({required this.progress, this.dashed = false});

  final Progress progress;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tiles = [
      StatTile(
        value: dashed ? 0 : progress.sessionCount,
        label: l10n.tileSessions,
        icon: Icons.menu_book_rounded,
        dashed: dashed,
      ),
      StatTile(
        value: dashed ? 0 : progress.selfCorrections,
        label: l10n.tileSelfCorrections,
        icon: Icons.check_rounded,
        tone: StatTone.butter,
        dashed: dashed,
      ),
      StatTile(
        value: dashed ? 0 : progress.stuck,
        label: l10n.tileStuck,
        icon: Icons.notifications_none_rounded,
        tone: StatTone.peach,
        dashed: dashed,
      ),
      StatTile(
        value: dashed ? 0 : progress.reflections,
        label: l10n.tileReflections,
        icon: Icons.star_outline_rounded,
        tone: StatTone.lilac,
        dashed: dashed,
      ),
    ];

    // Two rows of two. IntrinsicHeight keeps tiles in a row the same height.
    Widget row(Widget a, Widget b) => IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: a),
          const SizedBox(width: 10),
          Expanded(child: b),
        ],
      ),
    );

    return Semantics(
      label: l10n.progressNumbers,
      container: true,
      child: Column(
        children: [
          row(tiles[0], tiles[1]),
          const SizedBox(height: 10),
          row(tiles[2], tiles[3]),
        ],
      ),
    );
  }
}

/// Two or more sessions: growth card, tiles, chart.
class _WithData extends StatelessWidget {
  const _WithData({required this.progress});

  final Progress progress;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Growth card: the server's sentence, never a score.
        Container(
          padding: const EdgeInsets.fromLTRB(12, 16, 20, 16),
          decoration: BoxDecoration(
            color: c.primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            children: [
              const Pip(mood: PipMood.happy, size: 96),
              const SizedBox(width: AppSpace.s2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      progress.growthMessage,
                      style: AppText.h2.copyWith(fontSize: 20, height: 26 / 20),
                    ),
                    if (progress.enoughData) ...[
                      const SizedBox(height: 6),
                      Text(
                        l10n.progressBasedOnRecent,
                        style: AppText.caption.copyWith(
                          color: c.primaryInk,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.s4),
        _Tiles(progress: progress),
        const SizedBox(height: AppSpace.s4),

        // Chart card.
        Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
          decoration: BoxDecoration(
            color: c.surfaceRaised,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.chartTitle,
                style: AppText.h2.copyWith(fontSize: 19, height: 24 / 19),
              ),
              const SizedBox(height: 10),
              HelpChart(sessions: progress.sessions),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.arrow_downward_rounded,
                      size: 18,
                      color: c.primaryInk,
                    ),
                  ),
                  const SizedBox(width: AppSpace.s2),
                  Expanded(
                    child: Text(
                      l10n.chartLowerIsGood,
                      style: AppText.body.copyWith(
                        fontSize: 15,
                        height: 22 / 15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              PillButton(
                label: l10n.chartShowList,
                icon: Icons.format_list_bulleted_rounded,
                tone: PillTone.soft,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        ProgressListScreen(sessions: progress.sessions),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.s4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s1),
          child: Text(
            l10n.progressRoughGuide,
            style: AppText.caption.copyWith(
              color: c.inkMuted,
              fontSize: 14,
              height: 20 / 14,
            ),
          ),
        ),
      ],
    );
  }
}

/// Fewer than 2 sessions: dashed zero tiles and an empty chart box.
class _NewStudent extends StatelessWidget {
  const _NewStudent({required this.progress, required this.onStartProblem});

  final Progress progress;
  final VoidCallback onStartProblem;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(10, 14, 18, 14),
          decoration: BoxDecoration(
            color: c.primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            children: [
              const Pip(size: 88, breathe: true),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  progress.growthMessage,
                  style: AppText.title.copyWith(height: 23 / 17),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Tiles(progress: progress, dashed: true),
        const SizedBox(height: 14),
        DashedBox(
          color: c.fieldLine,
          radius: AppRadius.lg,
          strokeWidth: 2,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 104),
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.s4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.show_chart_rounded, color: c.ink),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      l10n.chartEmpty,
                      textAlign: TextAlign.center,
                      style: AppText.body,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.s6),
        PillButton(
          label: l10n.progressStartProblem,
          expand: true,
          onPressed: onStartProblem,
        ),
      ],
    );
  }
}

/// While the numbers load.
class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);

    Widget block(double height) => Container(
      height: height,
      decoration: BoxDecoration(
        color: c.surfaceSunken,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    );

    return Semantics(
      liveRegion: true,
      label: l10n.progressLoading,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Pip(mood: PipMood.thinking, size: 88),
              const SizedBox(width: AppSpace.s2),
              Expanded(
                child: ExcludeSemantics(
                  child: Text(l10n.progressLoading, style: AppText.title),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s4),
          // Soft pulse only while loading.
          ExcludeSemantics(
            child: Pulse(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: block(120)),
                      const SizedBox(width: 10),
                      Expanded(child: block(120)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: block(120)),
                      const SizedBox(width: 10),
                      Expanded(child: block(120)),
                    ],
                  ),
                  const SizedBox(height: AppSpace.s4),
                  block(220),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Progress could not be loaded.
class _Problem extends StatelessWidget {
  const _Problem({required this.problem, required this.onRetry});

  final ProgressProblem problem;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (IconData icon, String? title, String text) = switch (problem) {
      ProgressProblem.unavailable => (
        Icons.schedule_rounded,
        null,
        l10n.progressUnavailable,
      ),
      ProgressProblem.offline => (
        Icons.wifi_off_rounded,
        l10n.chatOfflineTitle,
        l10n.chatOfflineText,
      ),
      ProgressProblem.failed => (
        Icons.error_outline_rounded,
        l10n.chatErrorTitle,
        l10n.chatErrorText,
      ),
    };

    return NoticeCard(
      icon: icon,
      title: title,
      text: text,
      action: PillButton(label: l10n.tryAgain, onPressed: onRetry),
    );
  }
}
