import 'package:cogniguide/l10n/app_localizations.dart';
import 'package:cogniguide/theme/app_theme.dart';
import 'package:cogniguide/widgets/bottom_nav.dart';
import 'package:cogniguide/widgets/chat_bubble.dart';
import 'package:cogniguide/widgets/maths_keys.dart';
import 'package:cogniguide/widgets/stat_tile.dart';
import 'package:cogniguide/widgets/typing_dots.dart';
import 'package:cogniguide/widgets/duo_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Puts a widget inside the app's theme and language files.
Widget wrap(Widget child, {bool reduceMotion = false}) => MaterialApp(
  theme: AppTheme.light,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Scaffold(
      body: Center(child: SizedBox(width: 360, child: child)),
    ),
  ),
);

void main() {
  testWidgets('StatTile is read as one item: number and label', (tester) async {
    await tester.pumpWidget(
      wrap(const StatTile(value: 6, label: 'Sessions', icon: AppIcon.book)),
    );

    expect(find.text('6'), findsOneWidget);
    expect(find.bySemanticsLabel('6, Sessions'), findsOneWidget);
  });

  testWidgets('A dashed StatTile shows no icon', (tester) async {
    await tester.pumpWidget(
      wrap(
        const StatTile(
          value: 0,
          label: 'Sessions',
          icon: AppIcon.book,
          dashed: true,
        ),
      ),
    );

    expect(findIcon(AppIcon.book), findsNothing);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('Bottom nav marks the active tab as selected', (tester) async {
    final handle = tester.ensureSemantics();
    AppTab? picked;
    await tester.pumpWidget(
      wrap(
        AppBottomNav(current: AppTab.practice, onChanged: (t) => picked = t),
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('Practice')),
      isSemantics(isSelected: true, isButton: true, label: 'Practice'),
    );
    expect(
      tester.getSize(find.bySemanticsLabel('My progress')).height,
      greaterThanOrEqualTo(52),
    );

    await tester.tap(find.text('My progress'));
    expect(picked, AppTab.progress);
    handle.dispose();
  });

  testWidgets('Chat bubbles show only their text', (tester) async {
    await tester.pumpWidget(
      wrap(const ChatBubble(kind: BubbleKind.coach, text: 'What do you see?')),
    );

    expect(find.text('What do you see?'), findsOneWidget);
    expect(find.byType(Text), findsOneWidget);
    expect(find.bySemanticsLabel('Coach: What do you see?'), findsOneWidget);
  });

  testWidgets('An unsent bubble says "Not sent" with an icon', (tester) async {
    await tester.pumpWidget(
      wrap(const ChatBubble(kind: BubbleKind.unsent, text: 'Is it 24?')),
    );

    expect(find.text('Not sent'), findsOneWidget);
    expect(findIcon(AppIcon.cloudOff), findsOneWidget);
  });

  testWidgets('Typing dots move, and stand still with reduce motion', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const TypingDots()));
    expect(find.bySemanticsLabel('Your coach is thinking'), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isTrue);

    await tester.pumpWidget(wrap(const TypingDots(), reduceMotion: true));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('Every maths key is at least 44 × 44 and has a spoken name', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final typed = <String>[];
    await tester.pumpWidget(wrap(MathsKeyRow(onKey: typed.add)));

    // Every key has its own spoken name (not just the symbol) and a big
    // enough tap area.
    final l10n = lookupAppLocalizations(const Locale('en'));
    for (final key in mathsKeys) {
      final name = key.spokenName(l10n);
      final node = find.bySemanticsLabel(name);
      expect(node, findsOneWidget, reason: name);
      final size = tester.getSize(node);
      expect(size.width, greaterThanOrEqualTo(44), reason: name);
      expect(size.height, greaterThanOrEqualTo(44), reason: name);
    }

    // The first keys are on screen without scrolling.
    await tester.tap(find.text('+'));
    await tester.tap(find.text('×'));
    expect(typed, ['+', '×']);
    handle.dispose();
  });
}

/// Finds one of the app's own icons.
Finder findIcon(AppIcon icon) =>
    find.byWidgetPredicate((w) => w is DuoIcon && w.icon == icon);
