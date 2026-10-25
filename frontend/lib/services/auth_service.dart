import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

/// What happened when the student tried to sign up or log in.
enum AuthResult {
  ok,

  /// Sign up: another student already has this code.
  codeTaken,

  /// Log in: the code and password don't match.
  detailsDontMatch,

  /// Log in: 5 wrong passwords in 15 minutes; wait and try again.
  tooManyTries,

  /// Anything else (for example no connection).
  failed,
}

/// Signing up, logging in and out with an anonymous code and a password.
///
/// The screens only talk to this interface: [ServerAuthService] for the
/// real app, [StandInAuthService] for the online demo preview.
abstract class AuthService {
  /// The logged-in student's code, or null if nobody is logged in.
  Future<String?> currentCode();

  /// The login token to send to the server, or null (not logged in, or
  /// the demo, which has no server).
  Future<String?> token();

  Future<AuthResult> signUp({required String code, required String password});

  Future<AuthResult> logIn({required String code, required String password});

  Future<void> logOut();
}

/// Where the login token is kept. The real app uses the phone's secure
/// storage; tests use [MemoryTokenStore].
abstract class TokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> delete();
}

/// The phone's locked storage (Android Keystore, iOS Keychain).
class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _key = 'auth_token';

  @override
  Future<String?> read() async {
    try {
      return await _storage.read(key: _key);
    } catch (_) {
      return null; // a broken keystore = logged out, never a crash
    }
  }

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> delete() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {}
  }
}

/// For tests: keeps the token in memory.
class MemoryTokenStore implements TokenStore {
  MemoryTokenStore([this._token]);

  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<void> delete() async => _token = null;
}

/// Real sign up and log in, through the CogniGuide server (Stage 7c,
/// docs/api_contract.md section 0).
///
/// - The password is sent once over the connection and NEVER saved.
/// - The token goes in [TokenStore] (secure storage on the phone).
/// - The code goes in shared_preferences, to show "Hi, P001".
class ServerAuthService implements AuthService {
  ServerAuthService(
    this._prefs,
    this._tokens, {
    http.Client? client,
    String? baseUrl,
  }) : _client = client ?? http.Client(),
       _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final SharedPreferences _prefs;
  final TokenStore _tokens;
  final http.Client _client;
  final String _baseUrl;

  static const _codeKey = 'student_code';

  @override
  Future<String?> currentCode() async {
    // Logged in only with both: a code to show and a token to send.
    final code = _prefs.getString(_codeKey);
    if (code == null) return null;
    return await _tokens.read() == null ? null : code;
  }

  @override
  Future<String?> token() => _tokens.read();

  @override
  Future<AuthResult> signUp({required String code, required String password}) =>
      _send('signup', code, password);

  @override
  Future<AuthResult> logIn({required String code, required String password}) =>
      _send('login', code, password);

  Future<AuthResult> _send(String path, String code, String password) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$_baseUrl/auth/$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'student_id': code, 'password': password}),
          )
          .timeout(AppConfig.serverTimeout);
    } on TimeoutException {
      return AuthResult.failed;
    } on http.ClientException {
      return AuthResult.failed;
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      final token = _field(response.body, 'token');
      if (token == null) return AuthResult.failed;
      await _tokens.write(token);
      await _prefs.setString(_codeKey, code);
      return AuthResult.ok;
    }
    return switch (response.statusCode) {
      409 => AuthResult.codeTaken,
      401 => AuthResult.detailsDontMatch,
      429 => AuthResult.tooManyTries,
      _ => AuthResult.failed,
    };
  }

  static String? _field(String body, String name) {
    try {
      final json = jsonDecode(body);
      final value = json is Map ? json[name] : null;
      return value is String && value.isNotEmpty ? value : null;
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> logOut() async {
    // The server keeps nothing: forgetting the token logs out.
    await _tokens.delete();
    await _prefs.remove(_codeKey);
  }
}

// ===========================================================================
// DEMO ONLY (the online preview, which cannot reach a server).
// NOT REAL SECURITY: any password logs in, and only the code is saved.
// Never used in the phone app (see main.dart).
// ===========================================================================
class StandInAuthService implements AuthService {
  StandInAuthService(this._prefs);

  final SharedPreferences _prefs;

  static const _codeKey = 'student_code';

  @override
  Future<String?> currentCode() async => _prefs.getString(_codeKey);

  @override
  Future<String?> token() async => null;

  @override
  Future<AuthResult> signUp({
    required String code,
    required String password,
  }) async {
    // The password is ignored on purpose (see the note above).
    await _prefs.setString(_codeKey, code);
    return AuthResult.ok;
  }

  @override
  Future<AuthResult> logIn({
    required String code,
    required String password,
  }) async {
    // The password is NOT checked (see the note above).
    await _prefs.setString(_codeKey, code);
    return AuthResult.ok;
  }

  @override
  Future<void> logOut() async {
    await _prefs.remove(_codeKey);
  }
}
