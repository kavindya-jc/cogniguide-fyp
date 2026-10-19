import 'package:flutter/material.dart';

import 'screens/theme_preview_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const CogniGuideApp());
}

/// The root of the app. For now it opens the Step 1 theme test page.
/// The real screens come in Step 3.
class CogniGuideApp extends StatelessWidget {
  const CogniGuideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CogniGuide',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const ThemePreviewScreen(),
    );
  }
}
