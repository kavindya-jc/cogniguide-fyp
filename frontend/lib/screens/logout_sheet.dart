import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/app_services.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text.dart';
import '../widgets/glass_surface.dart';
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
    // The sheet draws its own glass, so the default fill is see-through.
    backgroundColor: Colors.transparent,
    elevation: 0,
    // Lighter than before, so the page shows through the frosted sheet.
    barrierColor: c.night.withValues(alpha: 0.3),
    constraints: const BoxConstraints(maxWidth: 480),
    // Slides up softly (0.45 s, as in the design spec); no movement with
    // reduce motion.
    sheetAnimationStyle: AppMotion.reduced(context)
        ? AnimationStyle.noAnimation
        : AnimationStyle(
            duration: AppMotion.sheet,
            reverseDuration: AppMotion.medium,
            curve: AppMotion.ease,
          ),
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

    // Plain solid white while the sheet slides up or down, glass only once
    // it has stopped. Re-blurring half the screen on every frame of the
    // slide was just over the smooth limit in the emulator test.
    final slide = ModalRoute.of(context)?.animation;
    return ListenableBuilder(
      listenable: slide ?? const AlwaysStoppedAnimation(1.0),
      builder: (context, child) => GlassSurface(
        blur: slide == null || slide.status == AnimationStatus.completed,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
        child: child!,
      ),
      child: SafeArea(
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
                  color: c.fieldLine.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: AppSpace.s3),
              const Pip(mood: PipMood.sleepy, size: 120),
              const SizedBox(height: AppSpace.s2),
              Semantics(
                header: true,
                child: Text(
                  l10n.logoutTitle,
                  style: AppText.h2.copyWith(fontSize: 28, height: 32 / 28),
                ),
              ),
              const SizedBox(height: AppSpace.s2),
              Text(
                l10n.logoutText,
                textAlign: TextAlign.center,
                style: AppText.body.copyWith(color: c.inkMuted, fontSize: 17),
              ),
              const SizedBox(height: AppSpace.s5),
              // Night, not violet: a calm "are you sure" action.
              PillButton(
                label: l10n.logOut,
                tone: PillTone.night,
                expand: true,
                onPressed: logOut,
              ),
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
      ),
    );
  }
}
