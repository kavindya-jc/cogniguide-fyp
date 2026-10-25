import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/maths_area.dart';
import '../models/problem.dart';
import '../services/app_services.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text.dart';
import '../theme/app_motion.dart';
import '../widgets/appear.dart';
import '../widgets/buddy_avatar.dart';
import '../widgets/area_chip.dart';
import '../widgets/dashed_box.dart';
import '../widgets/duo_icon.dart';
import '../widgets/entrance.dart';
import '../widgets/glass_surface.dart';
import '../widgets/grade_filter.dart';
import '../widgets/measure_height.dart';
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

  /// The list scrolls under the floating glass header.
  final _scroll = ScrollController();

  /// How tall the glass header is, so the list starts below it.
  double _headerHeight = 220;

  /// True after scrolling down: the header folds into a slim bar.
  bool _collapsed = false;

  /// How far the list scrolls before the header folds.
  static const double _collapseAt = 96;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  /// Only rebuilds when the header should fold or unfold (twice per
  /// scroll at most), not on every scrolled pixel.
  void _onScroll() {
    final collapsed = _scroll.hasClients && _scroll.offset > _collapseAt;
    if (collapsed != _collapsed) setState(() => _collapsed = collapsed);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _problems ??= _load();
  }

  @override
  void dispose() {
    _own.dispose();
    _scroll.dispose();
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

  void _openChat({
    required String eyebrow,
    required String problem,
    String? problemId,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          eyebrow: eyebrow,
          problem: problem,
          problemId: problemId,
        ),
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

        final list = ListView(
          controller: _scroll,
          padding: EdgeInsets.only(top: _headerHeight + 14, bottom: 120),
          children: [
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
                  icon: AppIcon.alert,
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
                          // Each card rises in the first time it scrolls
                          // onto the screen.
                          return Appear(
                            key: ValueKey('${p.area}-${p.grade}-${p.text}'),
                            style: AppearStyle.rise,
                            child: ProblemCard(
                              index: i,
                              eyebrow: eyebrow,
                              text: p.text,
                              onTap: () => _openChat(
                                eyebrow: eyebrow,
                                problem: p.text,
                                problemId: p.id,
                              ),
                            ),
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

        return Stack(
          children: [
            list,
            // A soft fade behind the phone's clock and battery, so the list
            // does not show through there when it scrolls up under the
            // (slim) header. Drawn once; nothing here moves.
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(child: _StatusBarFade()),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: MeasureHeight(
                onHeight: (h) {
                  // The list keeps the FULL header height as its top space,
                  // so it does not jump when the header folds.
                  if (!_collapsed && (h - _headerHeight).abs() > 0.5) {
                    setState(() => _headerHeight = h);
                  }
                },
                child: _Header(
                  code: widget.code,
                  scroll: _scroll,
                  showPip: !loading && items.isNotEmpty,
                  collapsed: _collapsed,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The floating glass header: "Hi, P001", Log out, Settings, the title
/// and Pip. The list scrolls underneath it.
///
/// As the student scrolls down, the title shrinks a little and Pip floats
/// up and tilts, so the screen feels alive. Further down, the title and Pip
/// fold away and only the slim top row stays (buddy, greeting, Log out,
/// Settings), so more problems fit on screen. Back near the top they return.
/// PERFORMANCE: only a scale, a move and a turn (no layout, no blur
/// change). The glass is one of at most two blurred things on screen
/// (the other is the bottom nav). With "reduce motion" on, nothing moves.
class _Header extends StatelessWidget {
  const _Header({
    required this.code,
    required this.scroll,
    required this.showPip,
    required this.collapsed,
  });

  final String code;
  final ScrollController scroll;

  /// Folded into the slim bar (see [_PickProblemTabState._collapseAt]).
  final bool collapsed;

  /// One Pip per screen: hidden while the thinking Pip shows below.
  final bool showPip;

  /// How far the student scrolls before the effect is complete.
  static const double _range = 160;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final still = AppMotion.reduced(context);

    // 0 at the top of the list, 1 after scrolling [_range] pixels.
    double progress() => still || !scroll.hasClients
        ? 0
        : (scroll.offset / _range).clamp(0.0, 1.0);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, AppSpace.s2, 14, 0),
        child: GlassSurface(
          tone: GlassTone.clear,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 10, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // The student's buddy beside the greeting.
                    if (AppServices.maybeOf(context) case final services?)
                      ListenableBuilder(
                        listenable: services.settings,
                        builder: (context, _) => Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: BuddyAvatar(
                            buddy: services.settings.buddyOrFallback,
                            size: 44,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        l10n.homeGreeting(code),
                        style: AppText.title.copyWith(
                          color: c.ink,
                          fontWeight: FontWeight.w700,
                          fontVariations: const [FontVariation('wght', 700)],
                        ),
                      ),
                    ),
                    PillButton(
                      label: l10n.logOut,
                      tone: PillTone.ghost,
                      onPressed: () => showLogoutSheet(context),
                    ),
                    const SizedBox(width: AppSpace.s1),
                    RoundIconButton(
                      icon: AppIcon.settings,
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
                // The fold: one size animation, then nothing moves.
                // With "reduce motion" it folds at once (no animation).
                _Fold(
                  still: still,
                  child: collapsed
                      ? const SizedBox(width: double.infinity)
                      : Row(
                          children: [
                            Expanded(
                              child: AnimatedBuilder(
                                animation: scroll,
                                builder: (context, child) => Transform.scale(
                                  scale: 1 - 0.14 * progress(),
                                  alignment: Alignment.centerLeft,
                                  child: child,
                                ),
                                child: Semantics(
                                  header: true,
                                  child: Text(
                                    l10n.homeTitle,
                                    style: AppText.h1.copyWith(
                                      color: c.ink,
                                      fontSize: 28,
                                      height: 32 / 28,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (showPip)
                              AnimatedBuilder(
                                animation: scroll,
                                builder: (context, child) {
                                  final t = progress();
                                  return Transform.translate(
                                    offset: Offset(0, -14 * t),
                                    child: Transform.rotate(
                                      angle: -0.1 * t,
                                      child: child,
                                    ),
                                  );
                                },
                                // Pip stays still here: anything moving inside the
                                // glass makes the blur redraw every frame. The
                                // scroll gives Pip its movement instead.
                                child: const Pip(
                                  mood: PipMood.determined,
                                  size: 84,
                                ),
                              ),
                          ],
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
            color: needsFix ? c.butterSoft : c.surfaceRaised,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: needsFix ? c.butterInk : c.fieldLine,
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
                icon: AppIcon.forward,
                semanticLabel: l10n.homeOwnStart,
                tone: RoundIconTone.primary,
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
                DuoIcon(AppIcon.alert, size: 18, color: c.butterInk),
                const SizedBox(width: AppSpace.s2),
                Expanded(
                  child: Text(
                    fixMessage!,
                    style: AppText.help.copyWith(color: c.butterInk),
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

/// Folds the header's title row away (or back) with one size animation.
/// With "reduce motion" ([still]) it changes at once.
class _Fold extends StatelessWidget {
  const _Fold({required this.still, required this.child});

  final bool still;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (still) return child;
    return AnimatedSize(
      duration: AppMotion.medium,
      curve: AppMotion.ease,
      alignment: Alignment.topCenter,
      child: child,
    );
  }
}

/// The page colour behind the status bar, fading out just below it.
class _StatusBarFade extends StatelessWidget {
  const _StatusBarFade();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final top = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: top + AppSpace.s4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [c.surface, c.surface, c.surface.withValues(alpha: 0)],
            stops: [0, top / (top + AppSpace.s4), 1],
          ),
        ),
      ),
    );
  }
}
