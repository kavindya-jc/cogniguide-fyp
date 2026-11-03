import 'package:cogniguide/widgets/glass_card.dart';
import 'package:cogniguide/widgets/round_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widget_test.dart' show startApp, tapVisible;

/// True when the glass card is drawn see-through (a soft gradient).
bool cardLooksGlass(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.byType(GlassCard).first,
          matching: find.byType(DecoratedBox),
        )
        .first,
  );
  return (box.decoration as BoxDecoration).gradient != null;
}

Future<void> openSettings(WidgetTester tester, String code) async {
  await startApp(tester, saved: {'student_code': code});
  await tester.tap(find.bySemanticsLabel('Settings'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a long username stays on one line, no overflow', (
    tester,
  ) async {
    const code = 'AVERYLONGUSERNAME_2026';
    await openSettings(tester, code);

    final text = tester.widget<Text>(find.text(code));
    expect(text.maxLines, 1);
    // Exactly one line tall (it shrinks to fit instead of wrapping).
    final height = tester.getSize(find.text(code)).height;
    expect(height, lessThan(40));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Change buddy opens the buddy picker', (tester) async {
    await openSettings(tester, 'P001');
    await tapVisible(tester, find.text('Change buddy'));
    await tester.pumpAndSettle();
    expect(find.text('Pick your buddy'), findsOneWidget);
  });

  testWidgets('glass cards and buttons turn solid with glass off', (
    tester,
  ) async {
    await openSettings(tester, 'P001');
    expect(find.byType(GlassCard), findsNWidgets(2));
    expect(cardLooksGlass(tester), isTrue);
    expect(find.byType(RoundIconButton), findsOneWidget); // Back, on glass

    await tapVisible(tester, find.byType(Switch));
    await tester.pumpAndSettle();
    expect(cardLooksGlass(tester), isFalse);
  });
}
