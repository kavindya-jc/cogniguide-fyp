import 'package:shared_preferences/shared_preferences.dart';

/// What happened when the student tried to sign up or log in.
enum AuthResult {
  ok,

  /// Sign up: another student already has this code.
  codeTaken,

  /// Log in: the code and password don't match.
  detailsDontMatch,

  /// Anything else (for example no connection).
  failed,
}

/// Signing up, logging in and out with an anonymous code and a password.
///
/// The screens only talk to this interface, so the stand-in below can be
/// swapped for the real server version in Step 6 without changing them.
abstract class AuthService {
  /// The logged-in student's code, or null if nobody is logged in.
  Future<String?> currentCode();

  Future<AuthResult> signUp({required String code, required String password});

  Future<AuthResult> logIn({required String code, required String password});

  Future<void> logOut();
}

// ===========================================================================
// TEMPORARY STAND-IN. NOT REAL SECURITY. Replace in Step 6.
//
// The backend has no sign-up or log-in yet (Stage 7c). Until it does:
// - this only saves the CODE on the phone (shared_preferences);
// - it NEVER saves or sends the password;
// - it does NOT check the password: any password logs in;
// - it can never say "code taken" or "details don't match".
// ===========================================================================
class StandInAuthService implements AuthService {
  StandInAuthService(this._prefs);

  final SharedPreferences _prefs;

  static const _codeKey = 'student_code';

  @override
  Future<String?> currentCode() async => _prefs.getString(_codeKey);

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
