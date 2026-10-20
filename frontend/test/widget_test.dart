import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cogniguide/main.dart';
import 'package:cogniguide/theme/app_colors.dart';

void main() {
  testWidgets('The app starts with the CogniGuide theme', (tester) async {
    await tester.pumpWidget(const CogniGuideApp());
    // One more frame so the language files load. (Not pumpAndSettle:
    // the gallery's loading spinner never stops moving.)
    await tester.pump();

    expect(find.text('Widget gallery'), findsOneWidget);

    final context = tester.element(find.byType(Scaffold));
    expect(Theme.of(context).scaffoldBackgroundColor, AppColors.light.surface);
    expect(AppColors.of(context).teal, const Color(0xFF2F7D6D));
  });
}
