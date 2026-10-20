import 'package:flutter/foundation.dart';

/// Where the app finds the CogniGuide server. Change it here, in one place.
///
/// - Chrome and Windows: http://127.0.0.1:5000
/// - Android emulator:   http://10.0.2.2:5000 (it cannot reach 127.0.0.1)
/// - Real phone (later): the computer's address on the same Wi-Fi, port 5000
///
/// Or set it when running, without editing code:
///   flutter run -d chrome --dart-define=API_BASE_URL=http://192.168.1.20:5000
///
/// Never put API keys or any other secret in the app.
abstract final class AppConfig {
  static const String _fromCommandLine = String.fromEnvironment('API_BASE_URL');

  static String get apiBaseUrl {
    if (_fromCommandLine.isNotEmpty) return _fromCommandLine;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000';
    }
    return 'http://127.0.0.1:5000';
  }

  /// How long to wait for the coach. The server may retry the AI a few
  /// times before answering, so this is generous.
  static const Duration chatTimeout = Duration(seconds: 120);
}
