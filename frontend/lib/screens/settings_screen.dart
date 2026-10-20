import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/app_services.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text.dart';
import '../widgets/round_icon_button.dart';
import '../widgets/tap_surface.dart';
import 'language_screen.dart';
import 'logout_sheet.dart';

/// Screen 3d: Settings. Your code, Language and Log out.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final settings = AppServices.of(context).settings;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.s5,
                AppSpace.s4,
                AppSpace.s5,
                28,
              ),
              children: [
                Row(
                  children: [
                    RoundIconButton(
                      icon: Icons.arrow_back_rounded,
                      semanticLabel: l10n.settingsBack,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: AppSpace.s3),
                    Semantics(
                      header: true,
                      child: Text(l10n.settingsTitle, style: AppText.h1),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.s5),

                // Your code.
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.s5,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: c.tealSoft,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: AppSizes.tap,
                        height: AppSizes.tap,
                        decoration: BoxDecoration(
                          color: c.teal,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.key_rounded,
                          size: 22,
                          color: c.onTeal,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          l10n.settingsYourCode(code),
                          style: AppText.title.copyWith(fontSize: 19),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.s5),

                // Language and Log out.
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: c.surfaceRaised,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Column(
                    children: [
                      ListenableBuilder(
                        listenable: settings,
                        builder: (context, _) => _Row(
                          icon: Icons.language_rounded,
                          label: l10n.settingsLanguage,
                          value: settings.language.nativeName,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const LanguageScreen(),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Divider(height: 1, color: c.line),
                      ),
                      ListenableBuilder(
                        listenable: settings,
                        builder: (context, _) => _SwitchRow(
                          icon: Icons.blur_on_rounded,
                          label: l10n.settingsGlass,
                          help: l10n.settingsGlassHelp,
                          value: settings.glassEffects,
                          onChanged: settings.setGlassEffects,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Divider(height: 1, color: c.line),
                      ),
                      _Row(
                        icon: Icons.logout_rounded,
                        label: l10n.logOut,
                        onTap: () => showLogoutSheet(context),
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

/// One row in the Settings list: icon, label, optional value, arrow.
class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
  });

  final IconData icon;
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
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c.surfaceSunken,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: c.ink),
                ),
                const SizedBox(width: 14),
                Expanded(child: Text(label, style: AppText.title)),
                if (value != null) ...[
                  Text(
                    value!,
                    style: AppText.label.copyWith(color: c.inkMuted),
                  ),
                  const SizedBox(width: AppSpace.s2),
                ],
                Icon(Icons.arrow_forward_rounded, size: 20, color: c.ink),
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
    required this.label,
    required this.help,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String help;
  final bool value;
  final ValueChanged<bool> onChanged;

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
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c.surfaceSunken,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: c.ink),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: AppText.title),
                      const SizedBox(height: 2),
                      Text(
                        help,
                        style: AppText.help.copyWith(color: c.inkMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.s2),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeThumbColor: c.onTeal,
                  activeTrackColor: c.teal,
                  inactiveThumbColor: c.inkMuted,
                  inactiveTrackColor: c.surfaceSunken,
                  trackOutlineColor: WidgetStatePropertyAll(c.fieldLine),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
