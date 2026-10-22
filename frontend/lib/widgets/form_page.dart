import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text.dart';
import 'round_icon_button.dart';
import 'duo_icon.dart';

/// The layout shared by Language, Create account and Log in:
/// a Back button, a title and subtitle, the page content, and the buttons
/// at the bottom. It scrolls when the phone is small or the text is large.
class FormPage extends StatelessWidget {
  const FormPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.content,
    required this.buttons,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final List<Widget> content;
  final List<Widget> buttons;

  /// Defaults to going back one screen.
  final VoidCallback? onBack;

  /// Widest the content gets on a tablet or a computer screen.
  static const double maxWidth = 480;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                  minHeight: box.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.screen,
                      AppSpace.s4,
                      AppSpace.screen,
                      28,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: RoundIconButton(
                            icon: AppIcon.back,
                            semanticLabel: l10n.back,
                            onPressed:
                                onBack ??
                                () => Navigator.of(context).maybePop(),
                          ),
                        ),
                        const SizedBox(height: AppSpace.s5),
                        Semantics(
                          header: true,
                          child: Text(title, style: AppText.h1),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: AppText.body.copyWith(color: c.inkMuted),
                        ),
                        const SizedBox(height: AppSpace.s5),
                        ...content,
                        const Spacer(),
                        const SizedBox(height: AppSpace.s5),
                        for (final (i, b) in buttons.indexed) ...[
                          if (i > 0) const SizedBox(height: 6),
                          b,
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
