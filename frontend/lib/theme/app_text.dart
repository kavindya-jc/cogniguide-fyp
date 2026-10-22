import 'package:flutter/material.dart';

/// Text styles from the design spec.
///
/// Two fonts: Bricolage Grotesque for big headings and numbers ([h1], [h2],
/// [stat]), and Plus Jakarta Sans for everything else.
///
/// Styles carry no colour: the theme gives text the `ink` colour, and a
/// widget picks another theme colour with `.copyWith(color: ...)` if needed.
///
/// Reading text is at least 16px. Only [caption] and [eyebrow] are smaller,
/// as the spec allows, for dates, chart labels and small kicker lines.
abstract final class AppText {
  static const String fontFamily = 'PlusJakartaSans';

  /// The heading font. Only [h1], [h2] and [stat] use it.
  static const String displayFamily = 'BricolageGrotesque';

  /// Screen titles. 32 / 36, extra bold.
  static final TextStyle h1 = _display(32, 36, 800, letterSpacing: -0.64);

  /// Card titles, sheet title. 22 / 28, bold.
  static final TextStyle h2 = _display(22, 28, 700, letterSpacing: -0.22);

  /// Numbers in stat tiles. 36 / 40, extra bold.
  static final TextStyle stat = _display(36, 40, 800, letterSpacing: -0.72);

  /// Greetings, problem text, list rows. 17 / 22, semibold.
  static final TextStyle title = _style(17, 22, 600);

  /// Reading text. 16 / 24.
  static final TextStyle body = _style(16, 24, 400);

  /// Chat bubbles. 17 / 25.
  static final TextStyle chat = _style(17, 25, 400);

  /// Buttons and chips. 16 / 20, semibold.
  static final TextStyle label = _style(16, 20, 600);

  /// Field labels above inputs. 16 / 20, semibold.
  static final TextStyle fieldLabel = _style(16, 20, 600);

  /// Text typed into inputs. 17.
  static final TextStyle input = _style(17, 24, 400);

  /// Helper and fix messages under fields. 15 / 20.
  static final TextStyle help = _style(15, 20, 400);

  /// Bottom nav tab labels. 15, semibold.
  static final TextStyle tab = _style(15, 20, 600);

  /// Dates, chart axis. 13 / 16, medium.
  static final TextStyle caption = _style(13, 16, 500);

  /// "PROBLEM 1 · ALGEBRA · GRADE 9". 12 / 14, semibold.
  /// Write the words in capitals with `.toUpperCase()`.
  static final TextStyle eyebrow = _style(12, 14, 600, letterSpacing: 0.72);

  /// Plus Jakarta Sans is one variable font file, so the weight is set in two ways:
  /// [FontWeight] for Flutter, and the `wght` axis so the font draws it.
  static TextStyle _style(
    double size,
    double lineHeight,
    int weight, {
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      height: lineHeight / size,
      fontWeight: FontWeight.values[(weight ~/ 100) - 1],
      fontVariations: [FontVariation.weight(weight.toDouble())],
      // Plus Jakarta Sans would turn "3x" into "3×" (its "calt" feature).
      // In maths 3x means 3 times the unknown x, so keep letters as typed.
      fontFeatures: const [FontFeature.disable('calt')],
      letterSpacing: letterSpacing,
    );
  }

  /// A heading in Bricolage Grotesque. Its `opsz` (optical size) axis is set
  /// to the font size, so the letters are drawn for that size.
  static TextStyle _display(
    double size,
    double lineHeight,
    int weight, {
    double letterSpacing = 0,
  }) {
    return _style(
      size,
      lineHeight,
      weight,
      letterSpacing: letterSpacing,
    ).copyWith(
      fontFamily: displayFamily,
      fontVariations: [
        FontVariation.weight(weight.toDouble()),
        FontVariation('opsz', size),
      ],
    );
  }
}
