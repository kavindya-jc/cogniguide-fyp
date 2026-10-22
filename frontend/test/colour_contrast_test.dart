import 'package:cogniguide/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// How much two colours stand apart (1 = the same, 21 = black on white).
/// Reading text needs 4.5 or more; borders and big shapes need 3.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  for (final (name, c) in [
    ('light', AppColors.light),
    ('dark', AppColors.dark),
  ]) {
    group('$name colours are easy to read', () {
      // Text colour, background, what it is used for.
      final text = <(Color, Color, String)>[
        (c.ink, c.surface, 'ink on the screen'),
        (c.ink, c.surfaceRaised, 'ink on a card'),
        (c.ink, c.surfaceSunken, 'ink on a maths key'),
        (c.inkMuted, c.surface, 'helper text on the screen'),
        (c.inkMuted, c.surfaceRaised, 'helper text on a card'),
        (c.onPrimary, c.primary, 'text on a violet button'),
        (c.primaryInk, c.surface, 'violet link on the screen'),
        (c.primaryInk, c.surfaceRaised, 'violet link on a card'),
        (c.primaryInk, c.primarySoft, 'violet text on soft violet'),
        (c.onNight, c.night, 'text on a night button'),
        (c.butterInk, c.surfaceRaised, 'fix message under a field'),
        (c.lilacInk, c.lilacSoft, 'lilac card text'),
        (c.butterInk, c.butterSoft, 'butter notice text'),
        (c.peachInk, c.peachSoft, 'peach card text'),
        (c.skyInk, c.skySoft, 'sky card text'),
        (c.mintInk, c.mintSoft, 'mint card text'),
        (c.onNavActive, c.navActive, 'chosen tab in the nav'),
        (c.onAccent, c.lilac, 'text on strong lilac'),
        (c.onAccent, c.butter, 'text on strong butter'),
        (c.onAccent, c.peach, 'text on strong peach'),
        (c.onAccent, c.sky, 'text on strong sky'),
        (c.onAccent, c.mint, 'text on strong mint'),
      ];
      for (final (fg, bg, what) in text) {
        test('$what (4.5 or more)', () {
          expect(contrast(fg, bg), greaterThanOrEqualTo(4.5));
        });
      }

      test('field borders show on a card (3 or more)', () {
        expect(contrast(c.fieldLine, c.surfaceRaised), greaterThanOrEqualTo(3));
      });
    });
  }
}
