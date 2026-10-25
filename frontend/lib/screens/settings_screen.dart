import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/app_services.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text.dart';
import '../widgets/buddy_avatar.dart';
import '../widgets/pill_button.dart';
import '../widgets/round_icon_button.dart';
import '../widgets/soft_blobs.dart';
import '../widgets/tap_surface.dart';
import 'buddy_screen.dart';
import 'language_screen.dart';
import 'logout_sheet.dart';
import '../widgets/duo_icon.dart';

/// Screen 3d: Settings. Your code, Language, Glass effects and Log out.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final settings = AppServices.of(context).settings;

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
                      AppSpace.s5,
                      AppSpace.s4,
                      AppSpace.s5,
                      28,
                    ),
                    child: ConstrainedBox(
                      // Fills the screen, so Log out sits at the bottom.
                      constraints: BoxConstraints(
                        minHeight: box.maxHeight - AppSpace.s4 - 28,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                RoundIconButton(
                                  icon: AppIcon.back,
                                  semanticLabel: l10n.settingsBack,
                                  tone: RoundIconTone.light,
                                  onPressed: () =>
                                      Navigator.of(context).maybePop(),
                                ),
                                const SizedBox(width: AppSpace.s3),
                                Semantics(
                                  header: true,
                                  child: Text(
                                    l10n.settingsTitle,
                                    style: AppText.h1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // Your code, with your buddy and a Change button.
                            Container(
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                12,
                                12,
                                12,
                              ),
                              decoration: BoxDecoration(
                                color: c.mintSoft,
                                borderRadius: BorderRadius.circular(26),
                              ),
                              child: Row(
                                children: [
                                  ListenableBuilder(
                                    listenable: settings,
                                    builder: (context, _) => BuddyAvatar(
                                      buddy: settings.buddyOrFallback,
                                      size: 64,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpace.s3),
                                  Expanded(
                                    child: Semantics(
                                      label: l10n.settingsYourCode(code),
                                      excludeSemantics: true,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              DuoIcon(
                                                AppIcon.key,
                                                size: 20,
                                                color: c.mintInk,
                                              ),
                                              const SizedBox(width: 6),
                                              Flexible(
                                                child: Text(
                                                  l10n.settingsYourCodeLabel,
                                                  style: AppText.label.copyWith(
                                                    color: c.mintInk,
                                                    fontWeight: FontWeight.w700,
                                                    fontVariations: const [
                                                      FontVariation(
                                                        'wght',
                                                        700,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            code,
                                            style: AppText.h1.copyWith(
                                              fontSize: 30,
                                              height: 34 / 30,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Semantics(
                                    label: l10n.buddyChangeLabel,
                                    button: true,
                                    excludeSemantics: true,
                                    child: TapSurface(
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) => const BuddyScreen(
                                            afterSignUp: false,
                                          ),
                                        ),
                                      ),
                                      color: c.surfaceRaised,
                                      shape: const StadiumBorder(),
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          minHeight: AppSizes.tap,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpace.s4,
                                          ),
                                          child: Center(
                                            widthFactor: 1,
                                            child: Text(
                                              l10n.buddyChange,
                                              style: AppText.label.copyWith(
                                                color: c.mintInk,
                                                fontWeight: FontWeight.w700,
                                                fontVariations: const [
                                                  FontVariation('wght', 700),
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
                            const SizedBox(height: 18),

                            // Language (hidden for now), Look and Glass effects.
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: c.surfaceRaised,
                                borderRadius: BorderRadius.circular(26),
                              ),
                              child: Column(
                                children: [
                                  if (showLanguageChoice) ...[
                                    ListenableBuilder(
                                      listenable: settings,
                                      builder: (context, _) => _Row(
                                        icon: AppIcon.globe,
                                        tint: c.skySoft,
                                        tintInk: c.skyInk,
                                        label: l10n.settingsLanguage,
                                        value: settings.language.nativeName,
                                        onTap: () => Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) =>
                                                const LanguageScreen(),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                      child: Divider(height: 1, color: c.line),
                                    ),
                                  ],
                                  ListenableBuilder(
                                    listenable: settings,
                                    builder: (context, _) => _ThemeRow(
                                      value: settings.themeMode,
                                      onChanged: settings.setThemeMode,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    child: Divider(height: 1, color: c.line),
                                  ),
                                  ListenableBuilder(
                                    listenable: settings,
                                    builder: (context, _) => _SwitchRow(
                                      icon: AppIcon.sparkle,
                                      tint: c.lilacSoft,
                                      tintInk: c.lilacInk,
                                      label: l10n.settingsGlass,
                                      help: l10n.settingsGlassHelp,
                                      value: settings.glassEffects,
                                      onChanged: settings.setGlassEffects,
                                      note: settings.glassTurnedOffForSpeed
                                          ? l10n.settingsGlassAutoOff
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            const SizedBox(height: AppSpace.s6),
                            PillButton(
                              label: l10n.logOut,
                              icon: AppIcon.logout,
                              tone: PillTone.soft,
                              expand: true,
                              onPressed: () => showLogoutSheet(context),
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

/// One row in the Settings list: icon, label, optional value, arrow.
class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.tint,
    required this.tintInk,
    required this.label,
    required this.onTap,
    this.value,
  });

  final AppIcon icon;

  /// The icon tile's soft colour and the icon's colour.
  final Color tint;
  final Color tintInk;
  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Semantics(
      button: true,
      label: value == null ? label : '$label, $value',
      excludeSemantics: true,
      child: TapSurface(
        onTap: onTap,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: DuoIcon(icon, size: 22, color: tintInk),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: AppText.title.copyWith(
                      fontWeight: FontWeight.w700,
                      fontVariations: const [FontVariation('wght', 700)],
                    ),
                  ),
                ),
                if (value != null) ...[
                  Text(
                    value!,
                    style: AppText.label.copyWith(color: c.inkMuted),
                  ),
                  const SizedBox(width: AppSpace.s2),
                ],
                DuoIcon(AppIcon.forward, size: 20, color: c.inkMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A Settings row with an on/off switch. The whole row can be tapped,
/// and a screen reader hears the label, the help line and on or off.
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.tint,
    required this.tintInk,
    required this.label,
    required this.help,
    required this.value,
    required this.onChanged,
    this.note,
  });

  final AppIcon icon;
  final Color tint;
  final Color tintInk;
  final String label;
  final String help;
  final bool value;
  final ValueChanged<bool> onChanged;

  /// An extra line, for example why the app turned this off by itself.
  final String? note;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return MergeSemantics(
      child: TapSurface(
        onTap: () => onChanged(!value),
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: DuoIcon(icon, size: 22, color: tintInk),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppText.title.copyWith(
                          fontWeight: FontWeight.w700,
                          fontVariations: const [FontVariation('wght', 700)],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        help,
                        style: AppText.help.copyWith(color: c.inkMuted),
                      ),
                      if (note != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: DuoIcon(
                                AppIcon.alert,
                                size: 18,
                                color: c.butterInk,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                note!,
                                style: AppText.help.copyWith(
                                  color: c.butterInk,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.s2),
                // Mint when on, with a tick on the knob (so not colour alone).
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeThumbColor: Colors.white,
                  activeTrackColor: c.mint,
                  inactiveThumbColor: c.inkMuted,
                  inactiveTrackColor: c.surfaceSunken,
                  trackOutlineColor: WidgetStatePropertyAll(c.fieldLine),
                  thumbIcon: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? Icon(Icons.check_rounded, size: 16, color: c.mintInk)
                        : null,
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

/// "Look": Same as phone, Light or Dark, as three pills in one row.
/// The chosen one is dark with a tick (so not colour alone).
class _ThemeRow extends StatelessWidget {
  const _ThemeRow({required this.value, required this.onChanged});

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final options = [
      (ThemeMode.system, l10n.settingsThemeSystem),
      (ThemeMode.light, l10n.settingsThemeLight),
      (ThemeMode.dark, l10n.settingsThemeDark),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.butterSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: DuoIcon(AppIcon.sun, size: 22, color: c.butterInk),
              ),
              const SizedBox(width: 14),
              Semantics(
                header: true,
                child: Text(
                  l10n.settingsTheme,
                  style: AppText.title.copyWith(
                    fontWeight: FontWeight.w700,
                    fontVariations: const [FontVariation('wght', 700)],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.s3),
          Semantics(
            container: true,
            label: l10n.settingsTheme,
            child: Wrap(
              spacing: AppSpace.s2,
              runSpacing: AppSpace.s2,
              children: [
                for (final (mode, label) in options)
                  _ThemePill(
                    label: label,
                    selected: value == mode,
                    onTap: () => onChanged(mode),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemePill extends StatelessWidget {
  const _ThemePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final fg = selected ? c.onNight : c.ink;

    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: label,
      excludeSemantics: true,
      child: TapSurface(
        onTap: onTap,
        color: selected ? c.night : c.surfaceSunken,
        shape: const StadiumBorder(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.tap),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  DuoIcon(AppIcon.check, size: 18, color: fg),
                  const SizedBox(width: AppSpace.s1),
                ],
                Text(label, style: AppText.label.copyWith(color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
