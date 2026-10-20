import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Spacing steps from the design: 4, 8, 12, 16, 20, 24, 32.
abstract final class AppSpace {
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;

  /// Left and right padding of a screen.
  static const double screen = 24;

  /// Inside a card.
  static const double card = 20;
}

/// Corner radius from the design.
abstract final class AppRadius {
  /// Maths key, icon well.
  static const double sm = 12;

  /// Input, stat tile, notice.
  static const double md = 20;

  /// Coach and student chat bubbles (the tail corner uses [bubbleTail]).
  static const double bubble = 22;
  static const double bubbleTail = 8;

  /// Card, problem card.
  static const double lg = 28;

  /// Top panel (bottom corners), bottom sheet (top corners).
  static const double xl = 40;

  /// Buttons, chips, bottom nav, send button.
  static const double pill = 999;
}

/// Minimum sizes from the accessibility rules.
abstract final class AppSizes {
  /// Main buttons and inputs.
  static const double button = 52;

  /// Smallest tap target (chips, grade filter, maths keys).
  static const double tap = 44;

  /// Round icon button.
  static const double iconButton = 48;

  /// Round send button in the chat.
  static const double send = 52;

  /// Phone width the design was drawn at.
  static const double designWidth = 390;
}

/// The soft shadow, only for floating things: bottom nav, sheets, chat bar.
abstract final class AppShadow {
  static List<BoxShadow> soft(AppColors colors) => [
    BoxShadow(color: colors.shadow, offset: const Offset(0, 8), blurRadius: 24),
  ];
}
