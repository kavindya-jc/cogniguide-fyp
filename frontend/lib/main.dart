import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'screens/widget_gallery_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const CogniGuideApp());
}

/// The root of the app. For now it opens the Step 2 widget gallery.
/// The real screens come in Step 3.
class CogniGuideApp extends StatelessWidget {
  const CogniGuideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const WidgetGalleryScreen(),
    );
  }
}
