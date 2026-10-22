import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../l10n/app_localizations.dart';
import '../services/app_services.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text.dart';
import '../widgets/entrance.dart';
import '../widgets/pill_button.dart';
import '../widgets/pip.dart';
import 'create_account_screen.dart';
import 'language_screen.dart';
import 'login_screen.dart';
import '../widgets/duo_icon.dart';

/// Screen 0: the first screen. Pip, what the app does, and the way in.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final settings = AppServices.of(context).settings;

    void open(Widget screen) => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo, name and language button.
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.screen,
                        AppSpace.s5,
                        AppSpace.screen,
                        0,
                      ),
                      child: Row(
                        children: [
                          ExcludeSemantics(
                            child: SvgPicture.asset(
                              'assets/pip/logo.svg',
                              width: AppSizes.tap,
                              height: AppSizes.tap,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(l10n.appTitle, style: AppText.h2),
                          ),
                          ListenableBuilder(
                            listenable: settings,
                            builder: (context, _) => Semantics(
                              label: l10n.welcomeLanguageButton(
                                settings.language.nativeName,
                              ),
                              excludeSemantics: true,
                              button: true,
                              child: PillButton(
                                label: settings.language.nativeName,
                                icon: AppIcon.globe,
                                tone: PillTone.light,
                                onPressed: () => open(const LanguageScreen()),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Pip and the promise.
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.screen,
                        AppSpace.s4,
                        AppSpace.screen,
                        AppSpace.screen,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // The welcome moment: Pip drops in first, then
                          // the words rise, then the violet panel slides up.
                          Entrance(
                            style: EntranceStyle.drop,
                            child: Semantics(
                              label: l10n.pipWaving,
                              excludeSemantics: true,
                              child: const Pip(size: 170, breathe: true),
                            ),
                          ),
                          const SizedBox(height: AppSpace.s2),
                          Entrance(
                            delay: const Duration(milliseconds: 150),
                            child: Semantics(
                              header: true,
                              child: Text(
                                l10n.welcomeTitle,
                                textAlign: TextAlign.center,
                                style: AppText.h1,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpace.s2),
                          Entrance(
                            delay: const Duration(milliseconds: 200),
                            child: Text(
                              l10n.welcomeSubtitle,
                              textAlign: TextAlign.center,
                              style: AppText.body.copyWith(color: c.inkMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Teal panel: the 3 steps and the buttons.
                  Entrance(
                    style: EntranceStyle.slideUp,
                    delay: const Duration(milliseconds: 250),
                    child: Container(
                      decoration: BoxDecoration(
                        color: c.primary,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppRadius.xl),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpace.screen,
                            28,
                            AppSpace.screen,
                            AppSpace.s8,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final (i, step) in [
                                l10n.welcomeStep1,
                                l10n.welcomeStep2,
                                l10n.welcomeStep3,
                              ].indexed) ...[
                                if (i > 0) const SizedBox(height: 14),
                                Entrance(
                                  // One after another, 50 ms apart.
                                  delay: Duration(milliseconds: 400 + 50 * i),
                                  child: _Step(number: i + 1, text: step),
                                ),
                              ],
                              const SizedBox(height: AppSpace.s5),
                              Entrance(
                                delay: const Duration(milliseconds: 550),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    PillButton(
                                      label: l10n.welcomeCreateAccount,
                                      tone: PillTone.light,
                                      expand: true,
                                      onPressed: () =>
                                          open(const CreateAccountScreen()),
                                    ),
                                    const SizedBox(height: 10),
                                    PillButton(
                                      label: l10n.welcomeLogIn,
                                      tone: PillTone.outlineOnPrimary,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One numbered step on the violet panel.
class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final int number;
  final String text;

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
              color: c.surfaceRaised,
              shape: BoxShape.circle,
            ),
            child: Text('$number', style: AppText.title.copyWith(color: c.ink)),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(text, style: AppText.title.copyWith(color: c.onPrimary)),
        ),
      ],
    );
  }
}
