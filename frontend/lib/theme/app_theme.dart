import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_sizes.dart';
import 'app_text.dart';

/// Puts the colours, text styles and sizes together into one Flutter theme.
///
/// Use [AppTheme.light] now. [AppTheme.dark] is ready for later.
abstract final class AppTheme {
  static ThemeData get light => _build(AppColors.light, Brightness.light);

  static ThemeData get dark => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: c.night,
      onPrimary: c.onNight,
      secondary: c.teal,
      onSecondary: c.onTeal,
      tertiary: c.lavender,
      onTertiary: c.onAccent,
      // No red anywhere: Flutter's "error" colours are mustard.
      error: c.mustardInk,
      onError: c.surfaceRaised,
      errorContainer: c.mustardSoft,
      onErrorContainer: c.ink,
      surface: c.surface,
      onSurface: c.ink,
      onSurfaceVariant: c.inkMuted,
      surfaceContainerLowest: c.surfaceRaised,
      surfaceContainerLow: c.surfaceRaised,
      surfaceContainer: c.surfaceRaised,
      surfaceContainerHigh: c.surfaceSunken,
      surfaceContainerHighest: c.surfaceSunken,
      outline: c.fieldLine,
      outlineVariant: c.line,
      shadow: c.shadow,
    );

    final textTheme = TextTheme(
      displaySmall: AppText.stat,
      headlineLarge: AppText.h1,
      headlineSmall: AppText.h2,
      titleMedium: AppText.title,
      bodyLarge: AppText.body,
      bodyMedium: AppText.body,
      labelLarge: AppText.label,
      bodySmall: AppText.caption,
      labelSmall: AppText.eyebrow,
    ).apply(bodyColor: c.ink, displayColor: c.ink);

    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: c.fieldLine, width: 1.5),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: c.surface,
      fontFamily: AppText.fontFamily,
      textTheme: textTheme,
      extensions: [c],
      materialTapTargetSize: MaterialTapTargetSize.padded,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceRaised,
        constraints: const BoxConstraints(minHeight: AppSizes.button),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.s4,
          vertical: 14,
        ),
        hintStyle: AppText.input.copyWith(color: c.inkMuted),
        labelStyle: AppText.fieldLabel.copyWith(color: c.ink),
        helperStyle: AppText.help.copyWith(color: c.inkMuted),
        errorStyle: AppText.help.copyWith(color: c.mustardInk),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: c.ink, width: 2),
        ),
        errorBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: c.mustardInk, width: 2),
        ),
        focusedErrorBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: c.mustardInk, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.night,
          foregroundColor: c.onNight,
          minimumSize: const Size(AppSizes.tap, AppSizes.button),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.s6),
          shape: const StadiumBorder(),
          textStyle: AppText.label,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.tealInk,
          minimumSize: const Size(AppSizes.tap, AppSizes.tap),
          shape: const StadiumBorder(),
          textStyle: AppText.label,
        ),
      ),
      iconTheme: IconThemeData(color: c.ink, size: 24),
      dividerTheme: DividerThemeData(color: c.line, thickness: 1),
    );
  }
}
