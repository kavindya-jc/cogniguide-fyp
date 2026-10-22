import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The screen background: the ground colour plus three big soft colour
/// glows (violet, peach, sky). They give the liquid glass something to
/// show through.
///
/// PERFORMANCE: big gradients are costly to draw on every frame (the
/// emulator test showed about 5 ms a frame). So the glows are drawn ONCE
/// into a small picture (1/8 of the screen size), which is then stretched
/// to fill the screen. The glows are so soft that stretching looks the
/// same, and showing one picture costs about as much as a plain colour.
class SoftBlobs extends StatelessWidget {
  const SoftBlobs({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(painter: _BlobPainter(c), size: Size.infinite),
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  _BlobPainter(this.colors);

  final AppColors colors;

  /// How much smaller the stored picture is than the screen.
  static const double _shrink = 8;

  /// Pictures already drawn, by colours and screen size.
  static final Map<(AppColors, int, int), ui.Image> _cache = {};

  ui.Image _picture(Size size) {
    final key = (colors, size.width.round(), size.height.round());
    final cached = _cache[key];
    if (cached != null) return cached;

    final w = (size.width / _shrink).ceil().clamp(1, 4096);
    final h = (size.height / _shrink).ceil().clamp(1, 4096);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(1 / _shrink);
    canvas.drawRect(Offset.zero & size, Paint()..color = colors.surface);

    void blob(Color color, Offset centre, double diameter) {
      final rect = Rect.fromCircle(center: centre, radius: diameter / 2);
      canvas.drawOval(
        rect,
        Paint()
          ..shader = RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
            stops: const [0, 0.68],
          ).createShader(rect),
      );
    }

    // The same places as the design mockup (sizes in screen points).
    blob(colors.blobViolet, const Offset(-90 + 160, -70 + 160), 320);
    blob(colors.blobPeach, Offset(size.width + 130 - 180, 320 + 180), 360);
    blob(colors.blobSky, Offset(-70 + 150, size.height + 90 - 150), 300);

    final picture = recorder.endRecording();
    final image = picture.toImageSync(w, h);
    picture.dispose();

    // Keep only a few (light, dark, a rotated screen).
    if (_cache.length > 6) _cache.clear();
    return _cache[key] = image;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final image = _picture(size);
    canvas.drawImageRect(
      image,
      Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.low,
    );
  }

  @override
  bool shouldRepaint(_BlobPainter old) => old.colors != colors;
}
