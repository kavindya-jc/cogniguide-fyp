import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text.dart';

/// TEMPORARY test page for Step 1. It shows every theme colour and text style.
/// Only the team sees it, so its words are not in the ARB language files.
/// Delete it when the real screens exist (Step 3).
class ThemePreviewScreen extends StatelessWidget {
  const ThemePreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    final swatches = <(String, Color, Color)>[
      ('surface', c.surface, c.ink),
      ('surface-raised', c.surfaceRaised, c.ink),
      ('surface-sunken', c.surfaceSunken, c.ink),
      ('line', c.line, c.ink),
      ('field-line', c.fieldLine, c.onNight),
      ('ink', c.ink, c.onNight),
      ('ink-muted', c.inkMuted, c.onNight),
      ('night', c.night, c.onNight),
      ('teal', c.teal, c.onTeal),
      ('teal-soft', c.tealSoft, c.tealInk),
      ('teal-ink', c.tealInk, c.onTeal),
      ('lavender', c.lavender, c.onAccent),
      ('lavender-soft', c.lavenderSoft, c.lavenderInk),
      ('orange', c.orange, c.onAccent),
      ('orange-soft', c.orangeSoft, c.orangeInk),
      ('mustard', c.mustard, c.onAccent),
      ('mustard-soft', c.mustardSoft, c.mustardInk),
      ('mustard-ink', c.mustardInk, c.onNight),
    ];

    final styles = <(String, TextStyle, String)>[
      ('h1 · 32', AppText.h1, 'Pick a problem'),
      ('h2 · 22', AppText.h2, 'Log out?'),
      ('stat · 36', AppText.stat, '12'),
      ('title · 17', AppText.title, 'Hi, P001'),
      ('body · 16', AppText.body,
          'The coach never gives the answer. It asks short questions.'),
      ('chat · 17', AppText.chat, 'What does "half as many" tell you?'),
      ('label · 16', AppText.label, 'Start a problem'),
      ('caption · 13', AppText.caption, 'Mon, 19 Oct'),
      ('eyebrow · 12', AppText.eyebrow, 'PROBLEM 1 · ALGEBRA · GRADE 9'),
    ];

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSizes.designWidth),
            child: ListView(
              padding: const EdgeInsets.all(AppSpace.screen),
              children: [
                Text('Theme preview', style: AppText.h1),
                const SizedBox(height: AppSpace.s2),
                Text(
                  'Step 1 test page. Every colour and text style.',
                  style: AppText.body.copyWith(color: c.inkMuted),
                ),
                const SizedBox(height: AppSpace.s8),
                Text('Colours', style: AppText.h2),
                const SizedBox(height: AppSpace.s3),
                Wrap(
                  spacing: AppSpace.s2,
                  runSpacing: AppSpace.s2,
                  children: [
                    for (final (name, fill, text) in swatches)
                      _Swatch(name: name, fill: fill, text: text),
                  ],
                ),
                const SizedBox(height: AppSpace.s8),
                Text('Text styles', style: AppText.h2),
                const SizedBox(height: AppSpace.s3),
                for (final (name, style, sample) in styles) ...[
                  Text(name, style: AppText.caption.copyWith(color: c.inkMuted)),
                  const SizedBox(height: AppSpace.s1),
                  Text(sample, style: style),
                  const SizedBox(height: AppSpace.s4),
                ],
                const SizedBox(height: AppSpace.s4),
                Text('Theme defaults', style: AppText.h2),
                const SizedBox(height: AppSpace.s3),
                Text('Your code', style: AppText.fieldLabel),
                const SizedBox(height: 6),
                const TextField(
                  decoration: InputDecoration(hintText: 'For example P001'),
                ),
                const SizedBox(height: AppSpace.s4),
                FilledButton(onPressed: () {}, child: const Text('Main button')),
                const SizedBox(height: AppSpace.s2),
                TextButton(onPressed: () {}, child: const Text('Text link')),
                const SizedBox(height: AppSpace.s8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.name, required this.fill, required this.text});

  final String name;
  final Color fill;
  final Color text;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      width: 105,
      height: 72,
      padding: const EdgeInsets.all(AppSpace.s2),
      alignment: Alignment.bottomLeft,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: c.line),
      ),
      child: Text(name, style: AppText.caption.copyWith(color: text)),
    );
  }
}
