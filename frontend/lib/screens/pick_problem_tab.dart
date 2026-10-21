import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/maths_area.dart';
import '../models/problem.dart';
import '../services/app_services.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text.dart';
import '../widgets/area_chip.dart';
import '../widgets/dashed_box.dart';
import '../widgets/entrance.dart';
import '../widgets/grade_filter.dart';
import '../widgets/notice_card.dart';
import '../widgets/pill_button.dart';
import '../widgets/pip.dart';
import '../widgets/problem_card.dart';
import '../widgets/round_icon_button.dart';
import 'chat_screen.dart';
import 'logout_sheet.dart';
import 'settings_screen.dart';

/// The longest problem the server accepts (docs/api_contract.md).
const int maxProblemLength = 2000;

/// Screen 3 (Practice tab): pick a problem, or type your own.
class PickProblemTab extends StatefulWidget {
  const PickProblemTab({super.key, required this.code});

  /// The student's anonymous code, for "Hi, P001".
  final String code;

  @override
  State<PickProblemTab> createState() => _PickProblemTabState();
}

class _PickProblemTabState extends State<PickProblemTab> {
  MathsArea _area = MathsArea.algebra;
  int? _grade;
  Future<List<Problem>>? _problems;

  final _own = TextEditingController();
  String? _ownFix;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _problems ??= _load();
  }

  @override
  void dispose() {
    _own.dispose();
    super.dispose();
  }

  Future<List<Problem>> _load() =>
      AppServices.of(context).problems.problems(area: _area, grade: _grade);

  void _filter({MathsArea? area, int? grade, bool allGrades = false}) {
    setState(() {
      if (area != null) _area = area;
      if (grade != null || allGrades) _grade = grade;
      _problems = _load();
    });
  }

  void _openChat({required String eyebrow, required String problem}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(eyebrow: eyebrow, problem: problem),
      ),
    );
  }

  void _startOwn() {
    final l10n = AppLocalizations.of(context);
    final text = _own.text.trim();
    setState(() {
      _ownFix = text.isEmpty
          ? l10n.homeOwnEmpty
          : text.length > maxProblemLength
          ? l10n.homeOwnTooLong
          : null;
    });
    if (_ownFix == null) {
      _openChat(eyebrow: l10n.ownProblemEyebrow, problem: text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return FutureBuilder<List<Problem>>(
      future: _problems,
      builder: (context, snap) {
        final loading = snap.connectionState != ConnectionState.done;
        final items = snap.data ?? const <Problem>[];

        return ListView(
          padding: const EdgeInsets.only(bottom: 104),
          children: [
            _Header(code: widget.code, showPip: !loading && items.isNotEmpty),
            const SizedBox(height: 14),
            AreaChipRow(
              selected: _area,
              onChanged: (a) => _filter(area: a),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.s5),
              child: GradeFilter(
                selected: _grade,
                onChanged: (g) => _filter(grade: g, allGrades: g == null),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.s5),
              child: switch ((loading, snap.hasError, items.isEmpty)) {
                (true, _, _) => const _Loading(),
                (_, true, _) => NoticeCard(
                  icon: Icons.error_outline_rounded,
                  text: l10n.homeLoadFailed,
                  action: PillButton(
                    label: l10n.tryAgain,
                    onPressed: () => _filter(),
                  ),
                ),
                (_, _, true) => const _Empty(),
                _ => Column(
                  children: [
                    for (final (i, p) in items.indexed) ...[
                      if (i > 0) const SizedBox(height: 10),
                      Builder(
                        builder: (context) {
                          final eyebrow = l10n.problemEyebrow(
                            i + 1,
                            p.area.label(l10n),
                            p.grade,
                          );
                          return ProblemCard(
                            index: i,
                            eyebrow: eyebrow,
                            text: p.text,
                            onTap: () =>
                                _openChat(eyebrow: eyebrow, problem: p.text),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              },
            ),
            const SizedBox(height: AppSpace.s4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.s5),
              child: _OwnProblemBox(
                controller: _own,
                fixMessage: _ownFix,
                onChanged: () => setState(() => _ownFix = null),
                onStart: _startOwn,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The teal panel: Pip, "Hi, P001", Log out, Settings and the title.
class _Header extends StatelessWidget {
  const _Header({required this.code, required this.showPip});

  final String code;

  /// One Pip per screen: hidden while the thinking Pip shows below.
  final bool showPip;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: c.teal,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xl),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.s5,
            AppSpace.s3,
            AppSpace.s5,
            AppSpace.s6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (showPip) ...[
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: c.tealSoft,
                        shape: BoxShape.circle,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: const Pip(size: 56),
                    ),
                    const SizedBox(width: AppSpace.s2),
                  ],
                  Expanded(
                    child: Text(
                      l10n.homeGreeting(code),
                      style: AppText.title.copyWith(color: c.onTeal),
                    ),
                  ),
                  PillButton(
                    label: l10n.logOut,
                    tone: PillTone.ghostOnTeal,
                    onPressed: () => showLogoutSheet(context),
                  ),
                  const SizedBox(width: AppSpace.s1),
                  RoundIconButton(
                    icon: Icons.settings_outlined,
                    semanticLabel: l10n.homeSettings,
                    tone: RoundIconTone.light,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SettingsScreen(code: code),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Semantics(
                header: true,
                child: Text(
                  l10n.homeTitle,
                  style: AppText.h1.copyWith(
                    color: c.onTeal,
                    fontSize: 30,
                    height: 34 / 30,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// While the problems load: thinking Pip and grey placeholder cards.
class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);

    Widget block() => Container(
      height: 92,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: c.surfaceSunken,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    );

    return Semantics(
      liveRegion: true,
      label: l10n.homeLoading,
      child: Column(
        children: [
          const Pip(mood: PipMood.thinking, size: 110),
          ExcludeSemantics(
            child: Text(
              l10n.homeLoading,
              style: AppText.title.copyWith(color: c.ink),
            ),
          ),
          const SizedBox(height: AppSpace.s4),
          // Soft pulse only while loading.
          ExcludeSemantics(
            child: Pulse(child: Column(children: [block(), block()])),
          ),
        ],
      ),
    );
  }
}

/// No problems for this area and grade.
class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);

    return Semantics(
      liveRegion: true,
      child: DashedBox(
        color: c.fieldLine,
        radius: AppRadius.lg,
        strokeWidth: 2,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.s5,
            AppSpace.s4,
            AppSpace.s5,
            22,
          ),
          child: Column(
            children: [
              const Pip(mood: PipMood.thinking, size: 110),
              const SizedBox(height: 6),
              Text(
                l10n.homeEmpty,
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(color: c.ink, fontSize: 17),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Or type your own problem": a big text box and a round start button.
class _OwnProblemBox extends StatelessWidget {
  const _OwnProblemBox({
    required this.controller,
    required this.fixMessage,
    required this.onChanged,
    required this.onStart,
  });

  final TextEditingController controller;
  final String? fixMessage;
  final VoidCallback onChanged;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final needsFix = fixMessage != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(child: Text(l10n.homeOwnLabel, style: AppText.title)),
        const SizedBox(height: AppSpace.s2),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 10, 10, 10),
          decoration: BoxDecoration(
            color: needsFix ? c.mustardSoft : c.surfaceRaised,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: needsFix ? c.mustardInk : c.fieldLine,
              width: needsFix ? 2 : 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Semantics(
                  label: l10n.homeOwnLabel,
                  child: TextField(
                    controller: controller,
                    minLines: 4,
                    maxLines: 6,
                    onChanged: (_) => onChanged(),
                    style: AppText.body.copyWith(color: c.ink),
                    cursorColor: c.ink,
                    decoration: InputDecoration(
                      hintText: l10n.homeOwnHint,
                      hintMaxLines: 4,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.s2),
              RoundIconButton(
                icon: Icons.arrow_forward_rounded,
                semanticLabel: l10n.homeOwnStart,
                tone: RoundIconTone.dark,
                onPressed: onStart,
              ),
            ],
          ),
        ),
        if (needsFix) ...[
          const SizedBox(height: 6),
          Semantics(
            liveRegion: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 18,
                  color: c.mustardInk,
                ),
                const SizedBox(width: AppSpace.s2),
                Expanded(
                  child: Text(
                    fixMessage!,
                    style: AppText.help.copyWith(color: c.mustardInk),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
