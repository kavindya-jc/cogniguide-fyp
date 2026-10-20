/// Rules for the anonymous code and the password.
///
/// The code rule is the same as the server's (docs/api_contract.md):
/// 1 to 64 characters, only letters, digits, `_` or `-`.
/// So a real name with spaces, or an email address, cannot be used.
library;

/// What is wrong with a code, if anything.
enum CodeProblem { empty, format }

/// The shortest password allowed.
const int minPasswordLength = 8;

final RegExp _codePattern = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

/// Checks an anonymous code. Returns null when it is fine.
CodeProblem? checkCode(String code) {
  if (code.isEmpty) return CodeProblem.empty;
  if (!_codePattern.hasMatch(code)) return CodeProblem.format;
  return null;
}

/// How many more characters the password needs (0 when it is long enough).
int passwordShortBy(String password) => password.length >= minPasswordLength
    ? 0
    : minPasswordLength - password.length;
