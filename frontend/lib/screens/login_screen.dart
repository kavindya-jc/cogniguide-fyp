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
import 'create_account_screen.dart';
import 'home_screen.dart';
import '../widgets/duo_icon.dart';

/// Screen 2: log in with the anonymous code and password.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _code = TextEditingController();
  final _password = TextEditingController();

  String? _codeFix;
  String? _passwordFix;

  /// "Details don't match" (or another problem): a notice above the form,
  /// and both fields get the fix look.
  String? _formFix;
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final code = _code.text.trim();

    setState(() {
      _formFix = null;
      _codeFix = switch (checkCode(code)) {
        CodeProblem.empty => l10n.fixCodeEmpty,
        CodeProblem.format => l10n.fixCodeFormat,
        null => null,
      };
      _passwordFix = _password.text.isEmpty ? l10n.fixPasswordEmpty : null;
    });
    if (_codeFix != null || _passwordFix != null) return;

    setState(() => _busy = true);
    final result = await AppServices.of(
      context,
    ).auth.logIn(code: code, password: _password.text);
    if (!mounted) return;
    setState(() => _busy = false);

    switch (result) {
      case AuthResult.ok:
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
          (_) => false,
        );
      case AuthResult.detailsDontMatch:
        setState(() => _formFix = l10n.fixDetailsDontMatch);
      case AuthResult.codeTaken || AuthResult.failed:
        setState(() => _formFix = l10n.fixSomethingWrong);
    }
  }

  void _clearFix() => setState(() {
    _formFix = null;
    _codeFix = null;
    _passwordFix = null;
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mismatch = _formFix != null;

    return FormPage(
      title: l10n.loginTitle,
      subtitle: l10n.loginSubtitle,
      pip: PipMood.happy,
      hero: true,
      content: [
        if (mismatch) ...[
          NoticeCard(icon: AppIcon.alert, text: _formFix!),
          const SizedBox(height: AppSpace.s4),
        ],
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
                  fixMessage: _codeFix,
                  markForFix: mismatch,
                  enabled: !_busy,
                  autofillHints: const [AutofillHints.username],
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => _clearFix(),
                ),
                const SizedBox(height: AppSpace.s4),
                LabelledField(
                  label: l10n.fieldPassword,
                  controller: _password,
                  obscureText: true,
                  fixMessage: _passwordFix,
                  markForFix: mismatch,
                  enabled: !_busy,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => _clearFix(),
                  onSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpace.s5),
        NoticeCard(
          icon: AppIcon.lock,
          tone: NoticeTone.mint,
          text: l10n.loginPrivacy,
        ),
      ],
      buttons: [
        PillButton(
          label: _busy ? l10n.loggingIn : l10n.loginButton,
          loading: _busy,
          expand: true,
          onPressed: _submit,
        ),
        Center(
          child: PillButton(
            label: l10n.loginNewHere,
            tone: PillTone.ghost,
            onPressed: _busy
                ? null
                : () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (_) => const CreateAccountScreen(),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
