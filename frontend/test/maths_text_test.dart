import 'dart:ui' show FontFeature;

import 'package:cogniguide/theme/app_text.dart';
import 'package:cogniguide/utils/maths_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  fontMathsTests();

  test('the real coach replies from the backend test read cleanly', () {
    expect(
      readableMaths(
        r'Welcome! To get us started on solving for $x$, what do you think '
        r'would be a good first step to begin grouping the terms with $x$ on '
        'one side of the equation?',
      ),
      'Welcome! To get us started on solving for x, what do you think '
      'would be a good first step to begin grouping the terms with x on '
      'one side of the equation?',
    );
    expect(
      readableMaths(r'If you subtract $2x$ from both sides, what is left?'),
      'If you subtract 2x from both sides, what is left?',
    );
  });

  test('common LaTeX becomes the symbols students know', () {
    expect(readableMaths(r'$3x - 5 = 2x + 7$'), '3x - 5 = 2x + 7');
    expect(readableMaths(r'$x^2 + 5x + 6$'), 'x² + 5x + 6');
    expect(readableMaths(r'$\frac{3}{4}$ of 240'), '3/4 of 240');
    expect(readableMaths(r'$\frac{x+1}{2}$'), '(x+1)/2');
    expect(readableMaths(r'$\sqrt{16}$'), '√16');
    expect(readableMaths(r'$6 \times 4$ and $8 \div 2$'), '6 × 4 and 8 ÷ 2');
    expect(readableMaths(r'$\sin \theta$'), 'sin θ');
    expect(readableMaths(r'angle $60^\circ$'), 'angle 60°');
    expect(readableMaths(r'$\pi r^2$'), 'π r²');
    expect(readableMaths(r'$x \neq 3$ and $y \leq 2$'), 'x ≠ 3 and y ≤ 2');
    expect(readableMaths(r'$$y = 2x + 1$$'), 'y = 2x + 1');
    expect(readableMaths(r'\(x = 4\)'), 'x = 4');
    expect(readableMaths(r'$5 \text{ cm}$'), '5  cm');
  });

  test('money and plain text are left alone', () {
    expect(readableMaths(r'It costs $5 and $10.'), r'It costs $5 and $10.');
    expect(readableMaths('A bag costs Rs. 2400.'), 'A bag costs Rs. 2400.');
    expect(readableMaths('What do you notice?'), 'What do you notice?');
  });
}

void fontMathsTests() {
  test('the font never turns 3x into 3× (calt is off in every style)', () {
    for (final style in [
      AppText.h1,
      AppText.title,
      AppText.body,
      AppText.chat,
      AppText.label,
      AppText.input,
      AppText.caption,
    ]) {
      expect(style.fontFeatures, contains(const FontFeature.disable('calt')));
    }
  });
}
