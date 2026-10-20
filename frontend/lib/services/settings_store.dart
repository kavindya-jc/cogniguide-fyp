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

  static const _glassKey = 'glass_effects';

  /// The frosted glass look (blur). On by default. Students with a slow
  /// phone can turn it off in Settings to keep the app smooth.
  bool get glassEffects => _prefs.getBool(_glassKey) ?? true;

  Future<void> setGlassEffects(bool on) async {
    await _prefs.setBool(_glassKey, on);
    notifyListeners();
  }
}
