import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../models/buddy.dart';
import '../services/app_services.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text.dart';
import '../widgets/buddy_avatar.dart';
import '../widgets/duo_icon.dart';
import '../widgets/pill_button.dart';
import '../widgets/round_icon_button.dart';
import '../widgets/soft_blobs.dart';
import '../widgets/tap_surface.dart';
import 'home_screen.dart';

/// "Pick your buddy": the student chooses a cartoon profile picture.
///
/// Shown right after Create account ([afterSignUp], button "Let's go!",
/// then Pick a problem), and from Settings (button "Save", then back).
class BuddyScreen extends StatefulWidget {
  const BuddyScreen({super.key, required this.afterSignUp});

  final bool afterSignUp;

  @override
  State<BuddyScreen> createState() => _BuddyScreenState();
}

class _BuddyScreenState extends State<BuddyScreen> {
  Buddy? _chosen;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A new student starts on a random buddy (one is always chosen).
    // From Settings it starts on the buddy they already see.
    final settings = AppServices.of(context).settings;
    _chosen ??= widget.afterSignUp
        ? (settings.buddy ??
              Buddy.values[math.Random().nextInt(Buddy.values.length)])
        : settings.buddyOrFallback;
  }

  void _pick(Buddy buddy) {
    if (buddy != _chosen) HapticFeedback.selectionClick();
    setState(() => _chosen = buddy);
  }

  Future<void> _done() async {
    await AppServices.of(context).settings.setBuddy(_chosen!);
    if (!mounted) return;
    if (widget.afterSignUp) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final chosen = _chosen!;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: SoftBlobs()),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: LayoutBuilder(
                  builder: (context, box) => SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.screen,
                      AppSpace.s4,
                      AppSpace.screen,
                      28,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: box.maxHeight - AppSpace.s4 - 28,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                if (!widget.afterSignUp)
                                  RoundIconButton(
                                    icon: AppIcon.back,
                                    semanticLabel: l10n.back,
                                    tone: RoundIconTone.light,
                                    onPressed: () =>
                                        Navigator.of(context).maybePop(),
                                  )
                                else
                                  Text(
                                    l10n.buddyLastStep,
                                    style: AppText.label.copyWith(
                                      color: c.inkMuted,
                                      fontWeight: FontWeight.w700,
                                      fontVariations: const [
                                        FontVariation('wght', 700),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpace.s3),
                            Semantics(
                              header: true,
                              child: Text(l10n.buddyTitle, style: AppText.h1),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              l10n.buddySubtitle,
                              style: AppText.body.copyWith(color: c.inkMuted),
                            ),
                            const SizedBox(height: AppSpace.s5),

                            // The big preview of the chosen buddy.
                            Center(
                              child: Semantics(
                                liveRegion: true,
                                label: l10n.buddyYours(chosen.label),
                                excludeSemantics: true,
                                child: Column(
                                  children: [
                                    AnimatedSwitcher(
                                      duration: AppMotion.of(
                                        context,
                                        AppMotion.medium,
                                      ),
                                      switchInCurve: Curves.easeOutBack,
                                      transitionBuilder: (child, anim) =>
                                          ScaleTransition(
                                            scale: Tween(
                                              begin: 0.8,
                                              end: 1.0,
                                            ).animate(anim),
                                            child: FadeTransition(
                                              opacity: anim,
                                              child: child,
                                            ),
                                          ),
                                      child: BuddyAvatar(
                                        key: ValueKey(chosen),
                                        buddy: chosen,
                                        size: 128,
                                        selected: true,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpace.s3),
                                    Text(
                                      chosen.label,
                                      style: AppText.h2.copyWith(
                                        fontWeight: FontWeight.w800,
                                        fontVariations: const [
                                          FontVariation('wght', 800),
                                          FontVariation('opsz', 22),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpace.s4),

                            // All 12, in a white card.
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: AppSpace.s4,
                              ),
                              decoration: BoxDecoration(
                                color: c.surfaceRaised,
                                borderRadius: BorderRadius.circular(26),
                              ),
                              child: Semantics(
                                container: true,
                                label: l10n.buddyGroup,
                                child: Wrap(
                                  alignment: WrapAlignment.spaceEvenly,
                                  spacing: AppSpace.s2,
                                  runSpacing: 14,
                                  children: [
                                    for (final b in Buddy.values)
                                      _BuddyTile(
                                        buddy: b,
                                        selected: b == chosen,
                                        onTap: () => _pick(b),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const Spacer(),
                            const SizedBox(height: AppSpace.s5),
                            PillButton(
                              label: widget.afterSignUp
                                  ? l10n.buddyGo
                                  : l10n.buddySave,
                              expand: true,
                              onPressed: _done,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One buddy in the grid: 72 px (4 fit in a row on a phone), with a ring
/// and a tick when chosen.
class _BuddyTile extends StatelessWidget {
  const _BuddyTile({
    required this.buddy,
    required this.selected,
    required this.onTap,
  });

  final Buddy buddy;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: buddy.label,
      excludeSemantics: true,
      child: TapSurface(
        onTap: onTap,
        pressScale: 0.92,
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: SizedBox.square(
          dimension: 72,
          child: Stack(
            alignment: Alignment.center,
            children: [
              BuddyAvatar(buddy: buddy, size: 64, selected: selected),
              if (selected)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: c.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.surfaceRaised, width: 3),
                    ),
                    child: DuoIcon(AppIcon.check, size: 14, color: c.onPrimary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
