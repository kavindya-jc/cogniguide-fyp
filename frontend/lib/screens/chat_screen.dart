import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text.dart';
import '../widgets/pip.dart';
import '../widgets/round_icon_button.dart';

/// Screen 4: the chat with the coach.
///
/// TEMPORARY for Step 3b: it only shows the chosen problem. Step 4 connects
/// it to `POST /chat` with bubbles, typing dots and maths keys.
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key, required this.eyebrow, required this.problem});

  /// For example "Problem 1 · Algebra · Grade 9".
  final String eyebrow;

  /// The problem text sent to the coach.
  final String problem;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: c.teal,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(32),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: RoundIconButton(
                        icon: Icons.arrow_back_rounded,
                        semanticLabel: l10n.settingsBack,
                        tone: RoundIconTone.light,
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                    const SizedBox(height: AppSpace.s3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: c.surfaceRaised,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            eyebrow.toUpperCase(),
                            style: AppText.eyebrow.copyWith(color: c.tealInk),
                          ),
                          const SizedBox(height: 2),
                          Text(problem, style: AppText.title),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.screen),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Pip(size: 110),
                  const SizedBox(height: AppSpace.s3),
                  Text(
                    l10n.comingChat,
                    textAlign: TextAlign.center,
                    style: AppText.title.copyWith(color: c.ink),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
