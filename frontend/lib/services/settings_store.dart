import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The languages the app offers.
enum AppLanguage {
  english('en', 'English'),
  sinhala('si', 'සිංහල'),
  tamil('ta', 'தமிழ்');

  const AppLanguage(this.code, this.nativeName);

  /// Language code, for example "si".
  final String code;

  /// The language's name written in that language (not translated).
  final String nativeName;
}

/// Settings saved on the phone. Screens listen to it and rebuild on change.
///
/// For now only the language. The app text stays English until the
/// Sinhala and Tamil language files exist (Step 8).
class SettingsStore extends ChangeNotifier {
  SettingsStore(this._prefs);

  final SharedPreferences _prefs;

  static const _languageKey = 'language';

  AppLanguage get language {
    final saved = _prefs.getString(_languageKey);
    return AppLanguage.values.firstWhere(
      (l) => l.code == saved,
      orElse: () => AppLanguage.english,
    );
  }

  Future<void> setLanguage(AppLanguage language) async {
    await _prefs.setString(_languageKey, language.code);
    notifyListeners();
  }

  static const _themeKey = 'theme_mode';

  /// Light, dark, or the same as the phone (the default).
  ThemeMode get themeMode => switch (_prefs.getString(_themeKey)) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString(_themeKey, mode.name);
    notifyListeners();
  }

  static const _glassKey = 'glass_effects';
  static const _glassAutoOffKey = 'glass_auto_off';
  static const _glassKeptOnKey = 'glass_kept_on';

  /// Whether the glass look (blur) is shown. On by default. It is off when
  /// the student turned it off, or when the app turned it off by itself
  /// because the phone was too slow ([glassTurnedOffForSpeed]).
  bool get glassEffects =>
      (_prefs.getBool(_glassKey) ?? true) && !glassTurnedOffForSpeed;

  /// True when the app turned glass off by itself (see GlassSpeedGuard).
  /// Settings explains this to the student.
  bool get glassTurnedOffForSpeed => _prefs.getBool(_glassAutoOffKey) ?? false;

  /// The app watches speed only while glass is on, and never again once
  /// the student has turned glass back on after an automatic switch-off.
  bool get shouldWatchGlassSpeed =>
      glassEffects && !(_prefs.getBool(_glassKeptOnKey) ?? false);

  /// The student's choice in Settings. Turning glass back on after the app
  /// switched it off means "keep it on": the app stops checking.
  Future<void> setGlassEffects(bool on) async {
    await _prefs.setBool(_glassKey, on);
    if (on && glassTurnedOffForSpeed) {
      await _prefs.setBool(_glassAutoOffKey, false);
      await _prefs.setBool(_glassKeptOnKey, true);
    }
    notifyListeners();
  }

  /// Called by the speed guard when the phone is too slow for glass.
  Future<void> turnGlassOffForSpeed() async {
    if (!shouldWatchGlassSpeed) return;
    await _prefs.setBool(_glassAutoOffKey, true);
    notifyListeners();
  }
}
