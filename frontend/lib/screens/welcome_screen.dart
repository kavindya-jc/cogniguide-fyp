import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text.dart';
import '../widgets/entrance.dart';
import '../widgets/glass_surface.dart';
import '../widgets/pill_button.dart';
import '../widgets/pip.dart';
import '../widgets/soft_blobs.dart';
import 'create_account_screen.dart';
import 'login_screen.dart';

/// Screen 0: the first screen. Pip says hello in a glass speech bubble,
/// the promise, and a white panel with the 3 steps and the way in.
///
/// PERFORMANCE: the speech bubble is the only glass here (small). Pip
/// breathes for 12 seconds, then the screen is completely still.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);

    void open(Widget screen) => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: SoftBlobs()),
          LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // The app's name.
                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpace.screen,
                            AppSpace.s4,
                            AppSpace.screen,
                            0,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l10n.appTitle,
                                  style: AppText.h2.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontVariations: const [
                                      FontVariation('wght', 800),
                                      FontVariation('opsz', 22),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Pip's hello, Pip and the promise.
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpace.screen,
                            AppSpace.s3,
                            AppSpace.screen,
                            AppSpace.s4,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // The welcome moment: the bubble and Pip drop
                              // in, the words rise, then the panel slides up.
                              Entrance(
                                style: EntranceStyle.drop,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: _SpeechBubble(
                                    text: l10n.welcomeSubtitle,
                                  ),
                                ),
                              ),
                              Entrance(
                                style: EntranceStyle.drop,
                                delay: const Duration(milliseconds: 80),
                                child: Semantics(
                                  label: l10n.pipWaving,
                                  excludeSemantics: true,
                                  child: const Pip(size: 150, breathe: true),
                                ),
                              ),
                              Entrance(
                                delay: const Duration(milliseconds: 150),
                                child: Semantics(
                                  header: true,
                                  child: Text(
                                    l10n.welcomeTitle,
                                    textAlign: TextAlign.center,
                                    style: AppText.h1.copyWith(
                                      fontSize: 36,
                                      height: 40 / 36,
                                      fontVariations: const [
                                        FontVariation('wght', 800),
                                        FontVariation('opsz', 36),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // The white panel: the 3 steps and the buttons.
                      Entrance(
                        style: EntranceStyle.slideUp,
                        delay: const Duration(milliseconds: 250),
                        child: Container(
                          decoration: BoxDecoration(
                            color: c.surfaceRaised,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(36),
                            ),
                          ),
                          child: SafeArea(
                            top: false,
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 480,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    AppSpace.screen,
                                    AppSpace.s6,
                                    AppSpace.screen,
                                    AppSpace.s6,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      for (final (i, (step, bg, ink)) in [
                                        (
                                          l10n.welcomeStep1,
                                          c.butterSoft,
                                          c.butterInk,
                                        ),
                                        (
                                          l10n.welcomeStep2,
                                          c.peachSoft,
                                          c.peachInk,
                                        ),
                                        (
                                          l10n.welcomeStep3,
                                          c.mintSoft,
                                          c.mintInk,
                                        ),
                                      ].indexed) ...[
                                        if (i > 0) const SizedBox(height: 10),
                                        Entrance(
                                          // One after another, 50 ms apart.
                                          delay: Duration(
                                            milliseconds: 400 + 50 * i,
                                          ),
                                          child: _Step(
                                            number: i + 1,
                                            text: step,
                                            background: bg,
                                            ink: ink,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 18),
                                      Entrance(
                                        delay: const Duration(
                                          milliseconds: 550,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            PillButton(
                                              label: l10n.welcomeCreateAccount,
                                              expand: true,
                                              onPressed: () => open(
                                                const CreateAccountScreen(),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            PillButton(
                                              label: l10n.welcomeLogIn,
                                              tone: PillTone.soft,
                                              expand: true,
                                              onPressed: () =>
                                                  open(const LoginScreen()),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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

/// Pip's words in a small see-through glass bubble, its tail towards Pip.
class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    // A share of the width (not a fixed maximum), so the screen can measure
    // the bubble's height correctly before laying it out.
    return FractionallySizedBox(
      widthFactor: 0.78,
      child: Padding(
        padding: const EdgeInsets.only(right: AppSpace.s2),
        child: GlassSurface(
          tone: GlassTone.clear,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(6),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              text,
              style: AppText.body.copyWith(
                color: c.ink,
                height: 22 / 16,
                fontWeight: FontWeight.w700,
                fontVariations: const [FontVariation('wght', 700)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One numbered step: a pastel number tile and the words.
class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.text,
    required this.background,
    required this.ink,
  });

  final int number;
  final String text;
  final Color background;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      children: [
        ExcludeSemantics(
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              '$number',
              style: AppText.title.copyWith(
                color: ink,
                fontWeight: FontWeight.w800,
                fontVariations: const [FontVariation('wght', 800)],
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: AppText.title.copyWith(
              color: c.ink,
              fontWeight: FontWeight.w700,
              fontVariations: const [FontVariation('wght', 700)],
            ),
          ),
        ),
      ],
    );
  }
}
