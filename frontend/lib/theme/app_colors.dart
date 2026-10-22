import 'package:flutter/material.dart';

/// Every colour in the app: the soft violet + pastel palette from the
/// playful concept mockup (2026-10-22), in light and dark.
///
/// Widgets read colours with `AppColors.of(context).primary` (never a raw
/// hex), so light and dark mode switch by themselves.
///
/// Each pastel comes in three shades:
/// * the plain name (`lilac`) is the strong colour, for shapes and edges;
/// * `...Soft` is the gentle background for cards and chips;
/// * `...Ink` is text and icons on the soft background (4.5:1 or more).
///
/// There is no red anywhere: notices and errors use butter.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSunken,
    required this.line,
    required this.fieldLine,
    required this.ink,
    required this.inkMuted,
    required this.night,
    required this.onNight,
    required this.nightAccent,
    required this.onAccent,
    required this.primary,
    required this.onPrimary,
    required this.primaryEdge,
    required this.primarySoft,
    required this.primaryInk,
    required this.lilac,
    required this.lilacSoft,
    required this.lilacInk,
    required this.butter,
    required this.butterSoft,
    required this.butterInk,
    required this.peach,
    required this.peachSoft,
    required this.peachInk,
    required this.sky,
    required this.skySoft,
    required this.skyInk,
    required this.mint,
    required this.mintSoft,
    required this.mintInk,
    required this.focusRing,
    required this.shadow,
    required this.glassLight,
    required this.glassDark,
    required this.glassEdge,
    required this.glassClearTop,
    required this.glassClearMid,
    required this.glassClearBottom,
    required this.glassHighlight,
  });

  /// Every screen background.
  final Color surface;

  /// Cards, coach bubble, inputs, sheets, chat bar.
  final Color surfaceRaised;

  /// Maths keys, soft buttons, loading placeholders.
  final Color surfaceSunken;

  /// Dividers and chart grid (decoration only).
  final Color line;

  /// Input and empty-box borders (3:1 contrast).
  final Color fieldLine;

  /// Main text and icons.
  final Color ink;

  /// Helper text, dates, chart labels.
  final Color inkMuted;

  /// Dark pill buttons, chosen chip, bottom nav.
  final Color night;
  final Color onNight;

  /// Small kicker text on night.
  final Color nightAccent;

  /// Text on the strong pastel colours (lilac, butter, peach, sky, mint).
  final Color onAccent;

  /// The main violet: main buttons, top panels, student bubble, chart line.
  final Color primary;
  final Color onPrimary;

  /// The darker band under a chunky 3D button.
  final Color primaryEdge;

  /// Growth card, privacy note, chosen grade.
  final Color primarySoft;

  /// Violet as text and links.
  final Color primaryInk;

  /// Active tab, problem cards.
  final Color lilac;
  final Color lilacSoft;
  final Color lilacInk;

  /// All notices and errors (never red), growth card.
  final Color butter;
  final Color butterSoft;
  final Color butterInk;

  /// Problem cards, "A lot" chip.
  final Color peach;
  final Color peachSoft;
  final Color peachInk;

  /// Problem cards, stat tiles.
  final Color sky;
  final Color skySoft;
  final Color skyInk;

  /// Problem cards, "fixed your own mistake" tile.
  final Color mint;
  final Color mintSoft;
  final Color mintInk;

  /// Focus outline.
  final Color focusRing;

  /// Colour of the soft shadow under floating things.
  final Color shadow;

  /// Frosted glass for floating light things (chat bar, sheets).
  /// About 76% solid, so ink text on it stays easy to read.
  final Color glassLight;

  /// Frosted glass for the floating night pill (bottom nav).
  final Color glassDark;

  /// The thin bright edge around a glass surface.
  final Color glassEdge;

  /// See-through "liquid" glass (header, nav, chat bar): a soft gradient
  /// from the top, through the middle, to the bottom.
  final Color glassClearTop;
  final Color glassClearMid;
  final Color glassClearBottom;

  /// The light catching the top of the glass.
  final Color glassHighlight;

  static const light = AppColors(
    surface: Color(0xFFF5F4F8),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFECEAF2),
    line: Color(0xFFE3E0EC),
    fieldLine: Color(0xFF8A859C),
    ink: Color(0xFF26233A),
    inkMuted: Color(0xFF5F5A74),
    night: Color(0xFF26233A),
    onNight: Color(0xFFFFFFFF),
    nightAccent: Color(0xFFFFD36B),
    onAccent: Color(0xFF1B1830),
    primary: Color(0xFF6656DD),
    onPrimary: Color(0xFFFFFFFF),
    primaryEdge: Color(0xFF4636B8),
    primarySoft: Color(0xFFECE8FF),
    primaryInk: Color(0xFF4B3FC0),
    lilac: Color(0xFFA99BFF),
    lilacSoft: Color(0xFFE7E3FF),
    lilacInk: Color(0xFF3E3399),
    butter: Color(0xFFFFC94D),
    butterSoft: Color(0xFFFFF1C2),
    butterInk: Color(0xFF6E5400),
    peach: Color(0xFFFF9E6B),
    peachSoft: Color(0xFFFFE0D2),
    peachInk: Color(0xFF8A3B16),
    sky: Color(0xFF7DB8F2),
    skySoft: Color(0xFFDCEBFF),
    skyInk: Color(0xFF1F4C85),
    mint: Color(0xFF6FD3A4),
    mintSoft: Color(0xFFD8F2E6),
    mintInk: Color(0xFF1D6447),
    focusRing: Color(0xFF26233A),
    shadow: Color(0x1A26233A), // ink at 10%
    glassLight: Color(0xB8FFFFFF), // surface-raised at 72%
    glassDark: Color(0xD126233A), // night at 82%
    glassEdge: Color(0x80FFFFFF),
    glassClearTop: Color(0x75FFFFFF), // white at 46%
    glassClearMid: Color(0x24FFFFFF), // white at 14%
    glassClearBottom: Color(0x42FFFFFF), // white at 26%
    glassHighlight: Color(0xFFFFFFFF),
  );

  /// Deep violet-black (not pure black) so it is gentle on the eyes at night.
  static const dark = AppColors(
    surface: Color(0xFF12111C),
    surfaceRaised: Color(0xFF1E1C2A),
    surfaceSunken: Color(0xFF2A2738),
    line: Color(0xFF3A3547),
    fieldLine: Color(0xFF8A8499),
    ink: Color(0xFFECE9F5),
    inkMuted: Color(0xFFB3AEC6),
    night: Color(0xFFECE9F5),
    onNight: Color(0xFF16141F),
    nightAccent: Color(0xFF4B3FC0),
    onAccent: Color(0xFF14121D),
    primary: Color(0xFFA99EFF),
    onPrimary: Color(0xFF16141F),
    primaryEdge: Color(0xFF6F5FE0),
    primarySoft: Color(0xFF2C2750),
    primaryInk: Color(0xFFC9C1FF),
    lilac: Color(0xFFA99BFF),
    lilacSoft: Color(0xFF2C2750),
    lilacInk: Color(0xFFD2CBFF),
    butter: Color(0xFFFFD36B),
    butterSoft: Color(0xFF3A3322),
    butterInk: Color(0xFFFFE29A),
    peach: Color(0xFFFF9E6B),
    peachSoft: Color(0xFF3E2B25),
    peachInk: Color(0xFFFFC6AE),
    sky: Color(0xFF7DB8F2),
    skySoft: Color(0xFF1F2C40),
    skyInk: Color(0xFFBBD8FF),
    mint: Color(0xFF6FD3A4),
    mintSoft: Color(0xFF1E3329),
    mintInk: Color(0xFFA9E6C9),
    focusRing: Color(0xFFECE9F5),
    shadow: Color(0x73000000), // rgba(0, 0, 0, 0.45)
    glassLight: Color(0xB81E1C2A), // surface-raised at 72%
    glassDark: Color(0xD1ECE9F5), // night (light in dark mode) at 82%
    glassEdge: Color(0x1FFFFFFF),
    glassClearTop: Color(0x24FFFFFF), // white at 14%
    glassClearMid: Color(0x08FFFFFF), // white at 3%
    glassClearBottom: Color(0x14FFFFFF), // white at 8%
    glassHighlight: Color(0x4DFFFFFF),
  );

  /// The colours of the current theme.
  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>()!;

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) => t < 0.5 ? this : other ?? this;
}
