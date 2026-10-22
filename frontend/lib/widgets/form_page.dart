import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text.dart';
import 'duo_icon.dart';
import 'pip.dart';
import 'round_icon_button.dart';
import 'soft_blobs.dart';

/// The layout shared by Language, Create account and Log in:
/// a Back button, a title and subtitle, the page content, and the buttons
/// at the bottom. It scrolls when the phone is small or the text is large.
///
/// Two looks:
/// - plain: Back on the left and a small Pip ([pip]) on the right, then
///   the title (Language, Create account);
/// - [hero]: a soft violet top area with a big Pip, the title and
///   subtitle in the middle, and the form below it (Log in).
class FormPage extends StatelessWidget {
  const FormPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.content,
    required this.buttons,
    this.onBack,
    this.pip,
    this.hero = false,
  });

  final String title;
  final String subtitle;
  final List<Widget> content;
  final List<Widget> buttons;

  /// Defaults to going back one screen.
  final VoidCallback? onBack;

  /// Pip's face on this page, if any.
  final PipMood? pip;

  /// The big welcoming top area (Log in).
  final bool hero;

  /// Widest the content gets on a tablet or a computer screen.
  static const double maxWidth = 480;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);

    final back = RoundIconButton(
      icon: AppIcon.back,
      semanticLabel: l10n.back,
      tone: RoundIconTone.light,
      onPressed: onBack ?? () => Navigator.of(context).maybePop(),
    );

    final titleText = Semantics(
      header: true,
      child: Text(
        title,
        textAlign: hero ? TextAlign.center : TextAlign.start,
        style: AppText.h1.copyWith(
          fontSize: hero ? 36 : 32,
          height: hero ? 40 / 36 : 36 / 32,
        ),
      ),
    );
    final subtitleText = Text(
      subtitle,
      textAlign: hero ? TextAlign.center : TextAlign.start,
      style: AppText.body.copyWith(color: c.inkMuted),
    );

    final form = Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpace.screen,
        hero ? 28 : AppSpace.s5,
        AppSpace.screen,
        28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...content,
          const Spacer(),
          const SizedBox(height: AppSpace.s5),
          for (final (i, b) in buttons.indexed) ...[
            if (i > 0) const SizedBox(height: 6),
            b,
          ],
        ],
      ),
    );

    final Widget page;
    if (hero) {
      page = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The soft violet top: Back, a big Pip, the title.
          DecoratedBox(
            decoration: BoxDecoration(color: c.primarySoft),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.screen,
                  AppSpace.s4,
                  AppSpace.screen,
                  48,
                ),
                child: Column(
                  children: [
                    Align(alignment: Alignment.centerLeft, child: back),
                    if (pip != null) Pip(mood: pip!, size: 150, breathe: true),
                    titleText,
                    const SizedBox(height: 6),
                    subtitleText,
                  ],
                ),
              ),
            ),
          ),
          // The form sits on a sheet that overlaps the top a little.
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -24),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),
                child: SafeArea(top: false, child: form),
              ),
            ),
          ),
        ],
      );
    } else {
      page = SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.screen,
                AppSpace.s4,
                AppSpace.screen,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      back,
                      const Spacer(),
                      if (pip != null) Pip(mood: pip!, size: 88),
                    ],
                  ),
                  SizedBox(height: pip == null ? AppSpace.s5 : 0),
                  titleText,
                  const SizedBox(height: 6),
                  subtitleText,
                ],
              ),
            ),
            Expanded(child: form),
          ],
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: SoftBlobs()),
          LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxWidth,
                    minHeight: box.maxHeight,
                  ),
                  child: IntrinsicHeight(child: page),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
