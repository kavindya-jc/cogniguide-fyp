// Makes the app icon from the real Pip widget, so the icon always matches the app.
//
// Run it again only when Pip or the icon colours change (it is in tool/, not test/,
// so the normal `flutter test` does not run it):
//
//     flutter test tool/make_app_icon_test.dart
//
// It writes:
//   android/app/src/main/res/mipmap-*/ic_launcher.png             (old Android: Pip on a lilac tile)
//   android/app/src/main/res/mipmap-*/ic_launcher_foreground.png  (Android 8+: Pip alone; the phone adds the shape)
//   web/icons/Icon-*.png, web/favicon.png                         (the web preview)
//   build/app_icon_preview.png                                    (a big picture to look at)

import 'dart:io';
import 'dart:ui' as ui;

import 'package:cogniguide/l10n/app_localizations.dart';
import 'package:cogniguide/theme/app_theme.dart';
import 'package:cogniguide/widgets/pip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// The tile colour behind Pip (the light theme's soft lilac). Also in
/// android/app/src/main/res/values/ic_launcher_background.xml.
const tile = Color(0xFFE7E3FF);
const canvas = 1024.0;

Future<void> main() async {
  final key = GlobalKey();

  Future<void> draw(WidgetTester tester, {required bool withTile, required double pipShare}) async {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: key,
            child: SizedBox.square(
              dimension: canvas,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: withTile ? tile : Colors.transparent,
                  borderRadius: withTile ? BorderRadius.circular(canvas * 0.22) : null,
                ),
                child: Center(child: Pip(mood: PipMood.happy, size: canvas * pipShare)),
              ),
            ),
          ),
        ),
      ),
    );
    // Pip's pictures load in the background: give them real time.
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
    }
  }

  Future<void> save(WidgetTester tester, String path, int pixels) async {
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final bytes = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: pixels / canvas);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    });
    final file = File(path)..createSync(recursive: true);
    file.writeAsBytesSync(bytes!);
  }

  testWidgets('make the app icon', (tester) async {
    tester.view.physicalSize = const Size(canvas, canvas);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    const res = 'android/app/src/main/res';
    const legacy = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192};
    const adaptive = {'mdpi': 108, 'hdpi': 162, 'xhdpi': 216, 'xxhdpi': 324, 'xxxhdpi': 432};

    // Pip on the lilac tile: old Android phones and the web.
    await draw(tester, withTile: true, pipShare: 0.72);
    for (final MapEntry(key: dpi, value: px) in legacy.entries) {
      await save(tester, '$res/mipmap-$dpi/ic_launcher.png', px);
    }
    for (final px in [192, 512]) {
      await save(tester, 'web/icons/Icon-$px.png', px);
      await save(tester, 'web/icons/Icon-maskable-$px.png', px);
    }
    await save(tester, 'web/favicon.png', 32);
    await save(tester, 'build/app_icon_preview.png', 512);

    // Pip alone for Android 8+: the phone cuts its own shape and draws the lilac
    // behind, and only the middle 66 of 108 parts is always visible.
    await draw(tester, withTile: false, pipShare: 0.56);
    for (final MapEntry(key: dpi, value: px) in adaptive.entries) {
      await save(tester, '$res/mipmap-$dpi/ic_launcher_foreground.png', px);
    }
  });
}
