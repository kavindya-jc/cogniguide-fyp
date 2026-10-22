import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/app_services.dart';
import 'services/auth_service.dart';
import 'services/chat_api.dart';
import 'services/glass_speed_guard.dart';
import 'services/problem_repository.dart';
import 'services/progress_api.dart';
import 'services/settings_store.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final auth = StandInAuthService(prefs);
  final settings = SettingsStore(prefs);

  // Turns glass off by itself if this phone is too slow for it.
  GlassSpeedGuard(settings).start();

  runApp(
    CogniGuideApp(
      auth: auth,
      settings: settings,
      problems: LocalProblemRepository(),
      chat: ChatApi(),
      progress: ProgressApi(),
      // A student who is still logged in goes straight to Pick a problem.
      loggedIn: await auth.currentCode() != null,
    ),
  );
}

/// The root of the app.
class CogniGuideApp extends StatelessWidget {
  const CogniGuideApp({
    super.key,
    required this.auth,
    required this.settings,
    required this.problems,
    required this.chat,
    required this.progress,
    required this.loggedIn,
  });

  final AuthService auth;
  final SettingsStore settings;
  final ProblemRepository problems;
  final ChatApi chat;
  final ProgressApi progress;
  final bool loggedIn;

  @override
  Widget build(BuildContext context) {
    return AppServices(
      auth: auth,
      settings: settings,
      problems: problems,
      chat: chat,
      progress: progress,
      child: MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        // Follows the phone: dark when the phone is in dark mode.
        darkTheme: AppTheme.dark,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // Lets all glass on a screen share one backdrop (faster blur).
        builder: (context, child) => BackdropGroup(child: child!),
        home: loggedIn ? const HomeScreen() : const WelcomeScreen(),
      ),
    );
  }
}
