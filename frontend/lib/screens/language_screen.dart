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
import '../widgets/tap_surface.dart';

/// Screen 0b: choose a language. Opened from Welcome or from Settings.
///
/// The choice is saved on the phone. The app text stays English until the
/// Sinhala and Tamil language files exist (Step 8).
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
        content: [
          Semantics(
            label: l10n.languageTitle,
            container: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final lang in AppLanguage.values) ...[
                  if (lang != AppLanguage.values.first)
                    const SizedBox(height: 10),
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
            icon: Icons.translate_rounded,
            tone: NoticeTone.teal,
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

/// One language row. The chosen one has a tick (so not colour alone).
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
      child: TapSurface(
        onTap: onTap,
        color: selected ? c.tealSoft : c.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(
            color: selected ? c.teal : c.line,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
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
                      Text(nativeName, style: AppText.title),
                      const SizedBox(height: 2),
                      Text(
                        englishName,
                        style: AppText.caption.copyWith(
                          color: c.inkMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: c.teal,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check_rounded, size: 18, color: c.onTeal),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
