import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/account_rules.dart';
import '../services/app_services.dart';
import '../services/auth_service.dart';
import '../theme/app_sizes.dart';
import '../widgets/form_page.dart';
import '../widgets/labelled_field.dart';
import '../widgets/notice_card.dart';
import '../widgets/pill_button.dart';
import '../widgets/pip.dart';
import 'buddy_screen.dart';
import 'login_screen.dart';
import '../widgets/duo_icon.dart';

/// Screen 1: create an account with an anonymous code and a password.
/// No name, email or photo.
class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _again = TextEditingController();

  String? _codeFix;
  String? _passwordFix;
  String? _againFix;
  String? _otherFix;
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    _password.dispose();
    _again.dispose();
    super.dispose();
  }

  bool get _hasFix =>
      _codeFix != null || _passwordFix != null || _againFix != null;

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final code = _code.text.trim();
    final shortBy = passwordShortBy(_password.text);

    setState(() {
      _otherFix = null;
      _codeFix = switch (checkCode(code)) {
        CodeProblem.empty => l10n.fixCodeEmpty,
        CodeProblem.format => l10n.fixCodeFormat,
        null => null,
      };
      _passwordFix = shortBy > 0 ? l10n.fixPasswordShort(shortBy) : null;
      _againFix = _again.text != _password.text
          ? l10n.fixPasswordsDontMatch
          : null;
    });
    if (_hasFix) return;

    setState(() => _busy = true);
    final result = await AppServices.of(
      context,
    ).auth.signUp(code: code, password: _password.text);
    if (!mounted) return;
    setState(() => _busy = false);

    switch (result) {
      case AuthResult.ok:
        // Last step: pick a buddy picture, then into the app.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (_) => const BuddyScreen(afterSignUp: true),
          ),
          (_) => false,
        );
      case AuthResult.codeTaken:
        setState(() => _codeFix = l10n.fixCodeTaken);
      case AuthResult.detailsDontMatch || AuthResult.failed:
        setState(() => _otherFix = l10n.fixSomethingWrong);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return FormPage(
      title: l10n.createTitle,
      subtitle: _hasFix ? l10n.createSubtitleFix : l10n.createSubtitle,
      pip: PipMood.determined,
      content: [
        AutofillGroup(
          child: Opacity(
            opacity: _busy ? 0.6 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LabelledField(
                  label: l10n.fieldCode,
                  controller: _code,
                  hint: l10n.fieldCodeHint,
                  helper: l10n.createCodeHelp,
                  fixMessage: _codeFix,
                  enabled: !_busy,
                  autofillHints: const [AutofillHints.newUsername],
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() => _codeFix = null),
                ),
                const SizedBox(height: AppSpace.s4),
                LabelledField(
                  label: l10n.fieldPassword,
                  controller: _password,
                  obscureText: true,
                  helper: l10n.createPasswordHelp,
                  fixMessage: _passwordFix,
                  enabled: !_busy,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() => _passwordFix = null),
                ),
                const SizedBox(height: AppSpace.s4),
                LabelledField(
                  label: l10n.fieldPasswordAgain,
                  controller: _again,
                  obscureText: true,
                  fixMessage: _againFix,
                  enabled: !_busy,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() => _againFix = null),
                  onSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpace.s5),
        if (_otherFix != null) ...[
          NoticeCard(icon: AppIcon.alert, text: _otherFix!),
          const SizedBox(height: AppSpace.s3),
        ],
        NoticeCard(icon: AppIcon.pencil, text: l10n.createWriteItDown),
      ],
      buttons: [
        PillButton(
          label: _busy ? l10n.creatingAccount : l10n.createButton,
          loading: _busy,
          expand: true,
          onPressed: _submit,
        ),
        Center(
          child: PillButton(
            label: l10n.createHaveAccount,
            tone: PillTone.ghost,
            onPressed: _busy
                ? null
                : () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => const LoginScreen(),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
