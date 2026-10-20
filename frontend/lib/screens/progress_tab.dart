import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text.dart';
import '../widgets/pip.dart';

/// Tab 2: My progress.
///
/// TEMPORARY until Step 5 connects it to `GET /progress`.
class ProgressTab extends StatelessWidget {
  const ProgressTab({super.key, required this.onStartProblem});

  /// Goes to the Practice tab (used by "Start a problem" in Step 5).
  final VoidCallback onStartProblem;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.s5,
          AppSpace.s6,
          AppSpace.s5,
          104,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(l10n.navProgress, style: AppText.h1),
            ),
            const Spacer(),
            const Center(child: Pip(mood: PipMood.thinking, size: 110)),
            const SizedBox(height: AppSpace.s3),
            Text(
              l10n.comingProgress,
              textAlign: TextAlign.center,
              style: AppText.title.copyWith(color: c.ink),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
