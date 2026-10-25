import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/app_services.dart';
import '../services/settings_store.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text.dart';
import '../widgets/form_page.dart';
import '../widgets/notice_card.dart';
import '../widgets/pill_button.dart';
import '../widgets/pip.dart';
import '../widgets/tap_surface.dart';
import '../widgets/duo_icon.dart';

/// Screen 0b: choose a language. Opened from Welcome or from Settings.
///
/// The choice is saved on the phone. The app text stays English until the
/// Sinhala and Tamil language files exist (Step 8).
/// The language choice is hidden for now (English only). Sinhala and Tamil
/// come later: set this to true to show the Language buttons again.
const bool showLanguageChoice = false;

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = AppServices.of(context).settings;

    String englishName(AppLanguage l) => switch (l) {
      AppLanguage.english => l10n.languageEnglish,
      AppLanguage.sinhala => l10n.languageSinhala,
      AppLanguage.tamil => l10n.languageTamil,
    };

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => FormPage(
        title: l10n.languageTitle,
        subtitle: l10n.languageSubtitle,
        pip: PipMood.wink,
        content: [
          Semantics(
            label: l10n.languageTitle,
            container: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final lang in AppLanguage.values) ...[
                  if (lang != AppLanguage.values.first)
                    const SizedBox(height: 14),
                  _LanguageOption(
                    nativeName: lang.nativeName,
                    englishName: englishName(lang),
                    selected: settings.language == lang,
                    onTap: () => settings.setLanguage(lang),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpace.s5),
          NoticeCard(
            icon: AppIcon.alert,
            tone: NoticeTone.sky,
            text: l10n.languageNote,
          ),
        ],
        buttons: [
          PillButton(
            label: l10n.done,
            expand: true,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }
}

/// One language card, chunky like a button. The chosen one has a violet
/// ring and a tick (so not colour alone); the others an empty circle.
class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.nativeName,
    required this.englishName,
    required this.selected,
    required this.onTap,
  });

  final String nativeName;
  final String englishName;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: '$nativeName, $englishName',
      excludeSemantics: true,
      // The darker band under the card (the chunky look).
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? c.primaryEdge : c.line,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: selected ? 5 : 4),
          child: TapSurface(
            onTap: onTap,
            color: c.surfaceRaised,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(
                color: selected ? c.primary : c.line,
                width: selected ? 3 : 2,
              ),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 76),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.s5,
                  vertical: AppSpace.s3,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            englishName,
                            style: AppText.title.copyWith(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              fontVariations: const [
                                FontVariation('wght', 800),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            nativeName,
                            style: AppText.label.copyWith(color: c.inkMuted),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: selected ? c.primary : null,
                        shape: BoxShape.circle,
                        border: selected
                            ? null
                            : Border.all(color: c.fieldLine, width: 2),
                      ),
                      child: selected
                          ? DuoIcon(AppIcon.check, size: 18, color: c.onPrimary)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
