import 'package:flutter/material.dart';

/// Every colour in the app, from docs/design/tokens/.
///
/// Widgets read colours with `AppColors.of(context).teal` (never a raw hex),
/// so dark mode only needs [AppColors.dark] to be switched on later.
///
/// Coral and sky are left out on purpose: the design uses them only inside
/// Pip's SVG pictures, never for anything the student does.
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
    required this.teal,
    required this.onTeal,
    required this.tealSoft,
    required this.tealInk,
    required this.lavender,
    required this.lavenderSoft,
    required this.lavenderInk,
    required this.orange,
    required this.orangeSoft,
    required this.orangeInk,
    required this.mustard,
    required this.mustardSoft,
    required this.mustardInk,
    required this.focusRing,
    required this.shadow,
    required this.glassLight,
    required this.glassDark,
    required this.glassEdge,
  });

  /// Every screen background (cream).
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

  /// Main buttons, chosen chip, bottom nav.
  final Color night;
  final Color onNight;

  /// Eyebrow text on night.
  final Color nightAccent;

  /// Text on lavender, orange and mustard.
  final Color onAccent;

  /// Top panels, student bubble, chart line.
  final Color teal;
  final Color onTeal;

  /// Growth card, privacy note, chosen grade.
  final Color tealSoft;

  /// Teal as text and links.
  final Color tealInk;

  /// Active tab, problem cards.
  final Color lavender;
  final Color lavenderSoft;
  final Color lavenderInk;

  /// Problem cards, "A lot" chip.
  final Color orange;
  final Color orangeSoft;
  final Color orangeInk;

  /// All notices and errors (never red).
  final Color mustard;
  final Color mustardSoft;
  final Color mustardInk;

  /// Focus outline.
  final Color focusRing;

  /// Colour of the soft shadow under floating things.
  final Color shadow;

  /// Frosted glass for floating light things (chat bar, sheets).
  /// About 76% solid, so ink text on it stays easy to read.
  final Color glassLight;

  /// Frosted glass for the floating night pill (bottom nav).
  final Color glassDark;

  /// The thin bright edge along the top of a glass surface.
  final Color glassEdge;

  static const light = AppColors(
    surface: Color(0xFFFBF8E6),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFF2EED8),
    line: Color(0xFFE6E0C8),
    fieldLine: Color(0xFF8F887A),
    ink: Color(0xFF1F1D1B),
    inkMuted: Color(0xFF5F5A51),
    night: Color(0xFF23211F),
    onNight: Color(0xFFFFFFFF),
    nightAccent: Color(0xFFF4B23A),
    onAccent: Color(0xFF1F1D1B),
    teal: Color(0xFF2F7D6D),
    onTeal: Color(0xFFFFFFFF),
    tealSoft: Color(0xFFD7EBE4),
    tealInk: Color(0xFF25685A),
    lavender: Color(0xFF8B89E8),
    lavenderSoft: Color(0xFFE3E2FB),
    lavenderInk: Color(0xFF524FC0),
    orange: Color(0xFFF4874B),
    orangeSoft: Color(0xFFFDE3D2),
    orangeInk: Color(0xFFA84A14),
    mustard: Color(0xFFF4B23A),
    mustardSoft: Color(0xFFFCEBC4),
    mustardInk: Color(0xFF8A5A00),
    focusRing: Color(0xFF1F1D1B),
    shadow: Color(0x141F1D1B), // rgba(31, 29, 27, 0.08)
    glassLight: Color(0xC2FFFFFF), // surface-raised at 76%
    glassDark: Color(0xD123211F), // night at 82%
    glassEdge: Color(0x99FFFFFF),
  );

  /// Ready for later. Not switched on yet.
  static const dark = AppColors(
    surface: Color(0xFF181715),
    surfaceRaised: Color(0xFF24221F),
    surfaceSunken: Color(0xFF2E2B27),
    line: Color(0xFF433F38),
    fieldLine: Color(0xFF8A8478),
    ink: Color(0xFFF6F2E4),
    inkMuted: Color(0xFFB8B2A3),
    night: Color(0xFFF6F2E4),
    onNight: Color(0xFF1F1D1B),
    nightAccent: Color(0xFF8A5A00),
    onAccent: Color(0xFF1F1D1B),
    teal: Color(0xFF4FAE99),
    onTeal: Color(0xFF10201C),
    tealSoft: Color(0xFF1F3A34),
    tealInk: Color(0xFF82D4C0),
    lavender: Color(0xFF9D9BF2),
    lavenderSoft: Color(0xFF2C2B52),
    lavenderInk: Color(0xFFBDBBFF),
    orange: Color(0xFFF6955D),
    orangeSoft: Color(0xFF45291B),
    orangeInk: Color(0xFFFFAE82),
    mustard: Color(0xFFF6BD52),
    mustardSoft: Color(0xFF3F3218),
    mustardInk: Color(0xFFF6C968),
    focusRing: Color(0xFFF6F2E4),
    shadow: Color(0x73000000), // rgba(0, 0, 0, 0.45)
    glassLight: Color(0xC224221F), // surface-raised at 76%
    glassDark: Color(0xD1F6F2E4), // night (cream in dark mode) at 82%
    glassEdge: Color(0x1FFFFFFF),
  );

  /// The colours of the current theme.
  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>()!;

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) => t < 0.5 ? this : other ?? this;
}
