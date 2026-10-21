import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_motion.dart';

/// Pip's moods. The design uses only these four
/// (no celebrate, oops or sad: no rewards and no "wrong" feeling).
enum PipMood {
  /// Welcome, Pick a problem greeting, new-student progress, chat.
  idle,

  /// Coach typing, loading screens, empty area, error.
  thinking,

  /// Growth sentence on My progress.
  happy,

  /// Coach busy, Log out sheet.
  sleepy,
}

/// Pip, the coach. One Pip per screen, always with words beside it.
///
/// - When the mood changes (for example the coach starts writing), Pip
///   cross-fades softly to the new picture.
/// - With [breathe], Pip floats gently up and down, then rests after about
///   12 seconds to save battery.
///
/// Pip is one picture, so the eyes cannot blink on their own (that needs
/// the eyes as a separate layer in the design file).
/// PERFORMANCE: a small fade and a 3px move, in their own repaint layer.
/// With "reduce motion" on, Pip stays still and swaps moods at once.
class Pip extends StatelessWidget {
  const Pip({
    super.key,
    this.mood = PipMood.idle,
    this.size = 88,
    this.breathe = false,
  });

  final PipMood mood;
  final double size;
  final bool breathe;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = switch (mood) {
      PipMood.idle => l10n.pipIdle,
      PipMood.thinking => l10n.pipThinking,
      PipMood.happy => l10n.pipHappy,
      PipMood.sleepy => l10n.pipSleepy,
    };

    Widget pip = AnimatedSwitcher(
      duration: AppMotion.of(context, const Duration(milliseconds: 250)),
      child: SvgPicture.asset(
        'assets/pip/pip-${mood.name}.svg',
        key: ValueKey(mood),
        width: size,
        height: size,
        semanticsLabel: label,
      ),
    );

    if (breathe) pip = _Breathe(child: pip);
    return RepaintBoundary(child: pip);
  }
}

/// Floats its child up and down by a few pixels, then stops.
class _Breathe extends StatefulWidget {
  const _Breathe({required this.child});

  final Widget child;

  @override
  State<_Breathe> createState() => _BreatheState();
}

class _BreatheState extends State<_Breathe>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  Timer? _rest;

  /// How long Pip breathes before resting (saves battery).
  static const _activeFor = Duration(seconds: 12);

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduced(context)) {
      _rest?.cancel();
      _c.stop();
      _c.value = 0;
    } else if (!_c.isAnimating && _rest == null) {
      _c.repeat(reverse: true);
      _rest = Timer(_activeFor, () {
        if (mounted) _c.animateTo(0, curve: Curves.easeOut);
      });
    }
  }

  @override
  void dispose() {
    _rest?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        // A smooth up-and-down: 0 at rest, 3px up at the top.
        final lift = -3 * math.sin(_c.value * math.pi / 2);
        return Transform.translate(offset: Offset(0, lift), child: child);
      },
    );
  }
}
