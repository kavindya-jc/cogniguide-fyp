import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/duo_icon.dart';
import '../widgets/entrance.dart';
import '../widgets/pill_button.dart';
import '../widgets/pip.dart';
import '../widgets/soft_blobs.dart';
import '../widgets/stat_tile.dart';
import 'home_screen.dart';

/// "You worked it out yourself!": opened when the student taps
/// "I worked it out!" in the chat.
///
/// It celebrates the student's own thinking, never a score: no points,
/// stars or "correct". The two numbers are ones the app already knows
/// (messages the student sent, minutes in the chat). The app does not
/// check the answer; the coach never gives answers.
class MomentScreen extends StatelessWidget {
  const MomentScreen({
    super.key,
    required this.messages,
    required this.minutes,
  });

  /// How many messages the student sent in this chat.
  final int messages;

  /// Whole minutes spent in the chat (at least 1).
  final int minutes;

  void _goHome(BuildContext context, AppTab tab) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => HomeScreen(initialTab: tab)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);

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
                            const Spacer(),
                            // A warm glow behind cheering Pip.
                            Entrance(
                              style: EntranceStyle.drop,
                              child: Center(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        c.butter.withValues(alpha: 0.45),
                                        c.butter.withValues(alpha: 0),
                                      ],
                                      stops: const [0, 0.7],
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(28),
                                    child: Semantics(
                                      label: l10n.pipCheering,
                                      excludeSemantics: true,
                                      child: const Pip(
                                        mood: PipMood.cheering,
                                        size: 190,
                                        breathe: true,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Entrance(
                              delay: const Duration(milliseconds: 150),
                              child: Semantics(
                                header: true,
                                child: Text(
                                  l10n.momentTitle,
                                  textAlign: TextAlign.center,
                                  style: AppText.h1.copyWith(
                                    color: c.primaryInk,
                                    fontSize: 32,
                                    height: 36 / 32,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpace.s2),
                            Entrance(
                              delay: const Duration(milliseconds: 200),
                              child: Text(
                                l10n.momentText,
                                textAlign: TextAlign.center,
                                style: AppText.body.copyWith(
                                  color: c.inkMuted,
                                  fontSize: 17,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpace.s5),
                            Entrance(
                              delay: const Duration(milliseconds: 300),
                              child: IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: StatTile(
                                        value: messages,
                                        label: l10n.momentMessages,
                                        icon: AppIcon.pencil,
                                        tone: StatTone.lilac,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: StatTile(
                                        value: minutes,
                                        label: l10n.momentMinutes,
                                        icon: AppIcon.clock,
                                        tone: StatTone.sky,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Spacer(),
                            const SizedBox(height: AppSpace.s5),
                            PillButton(
                              label: l10n.momentTryAnother,
                              expand: true,
                              onPressed: () =>
                                  _goHome(context, AppTab.practice),
                            ),
                            const SizedBox(height: AppSpace.s3),
                            PillButton(
                              label: l10n.momentSeeProgress,
                              tone: PillTone.soft,
                              expand: true,
                              onPressed: () =>
                                  _goHome(context, AppTab.progress),
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
