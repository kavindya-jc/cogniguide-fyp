import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/app_services.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text.dart';
import '../widgets/pill_button.dart';
import '../widgets/pip.dart';
import 'welcome_screen.dart';

/// Screen 3f: the "Log out?" sheet that slides up from the bottom.
/// Log out goes back to Welcome; Stay closes the sheet.
Future<void> showLogoutSheet(BuildContext context) {
  final c = AppColors.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: c.surfaceRaised,
    barrierColor: c.night.withValues(alpha: 0.5),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    constraints: const BoxConstraints(maxWidth: 480),
    builder: (_) => const _LogoutSheet(),
  );
}

class _LogoutSheet extends StatelessWidget {
  const _LogoutSheet();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);

    Future<void> logOut() async {
      await AppServices.of(context).auth.logOut();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
        (_) => false,
      );
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.screen,
          AppSpace.s3,
          AppSpace.screen,
          AppSpace.s6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: c.line,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: AppSpace.s3),
            const Pip(mood: PipMood.sleepy, size: 110),
            const SizedBox(height: AppSpace.s2),
            Semantics(
              header: true,
              child: Text(
                l10n.logoutTitle,
                style: AppText.h2.copyWith(fontSize: 26, height: 30 / 26),
              ),
            ),
            const SizedBox(height: AppSpace.s2),
            Text(
              l10n.logoutText,
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(color: c.inkMuted, fontSize: 17),
            ),
            const SizedBox(height: AppSpace.s5),
            PillButton(label: l10n.logOut, expand: true, onPressed: logOut),
            const SizedBox(height: 10),
            PillButton(
              label: l10n.logoutStay,
              tone: PillTone.soft,
              expand: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
