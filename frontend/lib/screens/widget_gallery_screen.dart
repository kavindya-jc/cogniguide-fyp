import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/maths_area.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text.dart';
import '../widgets/area_chip.dart';
import '../widgets/grade_filter.dart';
import '../widgets/labelled_field.dart';
import '../widgets/notice_card.dart';
import '../widgets/pill_button.dart';
import '../widgets/pip.dart';
import '../widgets/problem_card.dart';
import '../widgets/round_icon_button.dart';
import 'theme_preview_screen.dart';

/// TEMPORARY test page for Step 2. It shows every shared widget and its states.
/// Only the team sees it, so its words are not in the ARB language files
/// (the widgets' own words are). Delete it when the real screens exist.
class WidgetGalleryScreen extends StatefulWidget {
  const WidgetGalleryScreen({super.key});

  @override
  State<WidgetGalleryScreen> createState() => _WidgetGalleryScreenState();
}

class _WidgetGalleryScreenState extends State<WidgetGalleryScreen> {
  MathsArea _area = MathsArea.algebra;
  int? _grade;
  String _lastTap = 'Nothing yet';

  void _tapped(String what) => setState(() => _lastTap = what);

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSizes.designWidth),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.screen),
              children: [
                _pad(Text('Widget gallery', style: AppText.h1)),
                const SizedBox(height: AppSpace.s2),
                _pad(
                  Text(
                    'Step 2a test page. Last tap: $_lastTap',
                    style: AppText.body.copyWith(color: c.inkMuted),
                  ),
                ),
                const SizedBox(height: AppSpace.s3),
                _pad(
                  PillButton(
                    label: 'Open theme preview',
                    tone: PillTone.soft,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ThemePreviewScreen(),
                      ),
                    ),
                  ),
                ),

                _heading('Pill buttons'),
                _pad(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PillButton(
                        label: 'Main action (dark)',
                        expand: true,
                        onPressed: () => _tapped('dark button'),
                      ),
                      const SizedBox(height: AppSpace.s3),
                      PillButton(
                        label: 'Second action (soft)',
                        tone: PillTone.soft,
                        expand: true,
                        onPressed: () => _tapped('soft button'),
                      ),
                      const SizedBox(height: AppSpace.s3),
                      const PillButton(
                        label: 'Logging you in',
                        loading: true,
                        expand: true,
                        onPressed: null,
                      ),
                      const SizedBox(height: AppSpace.s3),
                      const PillButton(
                        label: 'Switched off',
                        expand: true,
                        onPressed: null,
                      ),
                      const SizedBox(height: AppSpace.s3),
                      Container(
                        padding: const EdgeInsets.all(AppSpace.s3),
                        decoration: BoxDecoration(
                          color: c.teal,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: PillButton(
                                label: 'On teal',
                                tone: PillTone.light,
                                expand: true,
                                onPressed: () => _tapped('light button'),
                              ),
                            ),
                            const SizedBox(width: AppSpace.s2),
                            Expanded(
                              child: PillButton(
                                label: 'Outline',
                                tone: PillTone.outlineOnTeal,
                                expand: true,
                                onPressed: () => _tapped('outline button'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpace.s3),
                      Row(
                        children: [
                          RoundIconButton(
                            icon: Icons.arrow_back_rounded,
                            semanticLabel: 'Back',
                            onPressed: () => _tapped('back'),
                          ),
                          const SizedBox(width: AppSpace.s3),
                          RoundIconButton(
                            icon: Icons.settings_outlined,
                            semanticLabel: 'Settings',
                            tone: RoundIconTone.light,
                            onPressed: () => _tapped('settings'),
                          ),
                          const SizedBox(width: AppSpace.s3),
                          RoundIconButton(
                            icon: Icons.arrow_forward_rounded,
                            semanticLabel: 'Send',
                            tone: RoundIconTone.dark,
                            size: AppSizes.send,
                            onPressed: () => _tapped('send'),
                          ),
                          const SizedBox(width: AppSpace.s2),
                          PillButton(
                            label: 'Text link',
                            tone: PillTone.ghost,
                            onPressed: () => _tapped('text link'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                _heading('Text fields'),
                _pad(
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LabelledField(
                        label: 'Anonymous code',
                        hint: 'For example P001',
                        helper: 'Letters and numbers only.',
                      ),
                      SizedBox(height: AppSpace.s4),
                      LabelledField(
                        label: 'Password',
                        obscureText: true,
                        fixMessage:
                            'Your password needs at least 8 characters. Add 2 more.',
                      ),
                    ],
                  ),
                ),

                _heading('Area chips and grade filter'),
                AreaChipRow(
                  selected: _area,
                  onChanged: (a) => setState(() => _area = a),
                ),
                const SizedBox(height: AppSpace.s2),
                _pad(
                  GradeFilter(
                    selected: _grade,
                    onChanged: (g) => setState(() => _grade = g),
                  ),
                ),

                _heading('Problem cards'),
                _pad(
                  Column(
                    children: [
                      for (final (i, text) in const [
                        'Solve: 3x − 5 = 2x + 7',
                        'Factorise: x² + 5x + 6',
                        'Solve together: 2x + y = 11 and x − y = 1',
                      ].indexed) ...[
                        ProblemCard(
                          index: i,
                          eyebrow: l10n.problemEyebrow(
                            i + 1,
                            _area.label(l10n),
                            9 + i,
                          ),
                          text: text,
                          onTap: () => _tapped('problem ${i + 1}'),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),

                _heading('Notices'),
                _pad(
                  Column(
                    children: [
                      NoticeCard(
                        icon: Icons.schedule_rounded,
                        title: 'Coach is busy',
                        text: 'Wait a moment, then send your message again.',
                        action: PillButton(
                          label: 'Try again',
                          onPressed: () => _tapped('try again'),
                        ),
                      ),
                      const SizedBox(height: AppSpace.s3),
                      const NoticeCard(
                        icon: Icons.lock_outline_rounded,
                        tone: NoticeTone.teal,
                        text:
                            'Your code keeps your progress private. '
                            'This is not a test and nobody grades you.',
                      ),
                    ],
                  ),
                ),

                _heading('Pip'),
                _pad(
                  Wrap(
                    spacing: AppSpace.s3,
                    runSpacing: AppSpace.s3,
                    children: [
                      for (final mood in PipMood.values)
                        Column(
                          children: [
                            Pip(mood: mood),
                            Text(mood.name, style: AppText.caption),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.s8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pad(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpace.s5),
    child: child,
  );

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpace.s5,
      AppSpace.s8,
      AppSpace.s5,
      AppSpace.s3,
    ),
    child: Text(text, style: AppText.h2),
  );
}
