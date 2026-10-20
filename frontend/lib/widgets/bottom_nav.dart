import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text.dart';
import 'tap_surface.dart';

/// The two main tabs.
enum AppTab { practice, progress }

/// The floating night pill at the bottom: Practice and My progress.
/// The active tab is lavender; each tab has an icon and a word.
///
/// The screen places it: left 16, right 16, bottom 16.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.current,
    required this.onChanged,
  });

  final AppTab current;
  final ValueChanged<AppTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);

    return Semantics(
      container: true,
      label: l10n.navMain,
      child: Container(
        padding: const EdgeInsets.all(AppSpace.s2),
        decoration: BoxDecoration(
          color: c.night,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          boxShadow: AppShadow.soft(c),
        ),
        child: Row(
          children: [
            Expanded(
              child: _Tab(
                icon: Icons.menu_book_rounded,
                label: l10n.navPractice,
                active: current == AppTab.practice,
                onTap: () => onChanged(AppTab.practice),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _Tab(
                icon: Icons.show_chart_rounded,
                label: l10n.navProgress,
                active: current == AppTab.progress,
                onTap: () => onChanged(AppTab.progress),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final fg = active ? c.onAccent : c.onNight;

    return Semantics(
      button: true,
      selected: active,
      label: label,
      excludeSemantics: true,
      child: TapSurface(
        onTap: onTap,
        color: active ? c.lavender : Colors.transparent,
        shape: const StadiumBorder(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.button),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: fg),
              const SizedBox(width: AppSpace.s2),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.tab.copyWith(color: fg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
