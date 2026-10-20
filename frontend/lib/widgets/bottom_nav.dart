import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text.dart';
import 'glass_surface.dart';
import 'tap_surface.dart';

/// The two main tabs.
enum AppTab { practice, progress }

/// The floating glass pill at the bottom: Practice and My progress.
///
/// The lavender "active" blob is the app's signature motion: it glides to
/// the tapped tab and stretches like a drop of liquid on the way. The
/// student can also swipe along the nav; the blob follows the finger and
/// the tab changes on release. Each tab has an icon and a word.
///
/// PERFORMANCE: the blob only moves and stretches (no layout, no blur
/// change) and sits in its own repaint layer. With "reduce motion" on it
/// jumps straight to the tab.
class AppBottomNav extends StatefulWidget {
  const AppBottomNav({
    super.key,
    required this.current,
    required this.onChanged,
  });

  final AppTab current;
  final ValueChanged<AppTab> onChanged;

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav>
    with SingleTickerProviderStateMixin {
  /// 0 = Practice, 1 = My progress, in between while moving.
  late final AnimationController _pos = AnimationController.unbounded(
    vsync: this,
    value: widget.current.index.toDouble(),
  );

  /// Width of one tab plus the gap, measured while laying out.
  double _step = 1;

  static const double _gap = 6;

  @override
  void didUpdateWidget(AppBottomNav old) {
    super.didUpdateWidget(old);
    if (widget.current != old.current) _glideTo(widget.current.index);
  }

  @override
  void dispose() {
    _pos.dispose();
    super.dispose();
  }

  void _glideTo(int index) {
    if (AppMotion.reduced(context)) {
      _pos.value = index.toDouble();
      return;
    }
    _pos.animateWith(
      SpringSimulation(AppMotion.spring, _pos.value, index.toDouble(), 0),
    );
  }

  void _select(AppTab tab) {
    if (tab != widget.current) {
      HapticFeedback.selectionClick();
      widget.onChanged(tab);
    } else {
      _glideTo(tab.index); // settle back after a small swipe
    }
  }

  // Swiping along the nav moves the blob with the finger.
  void _dragUpdate(DragUpdateDetails d) {
    _pos.stop();
    _pos.value = (_pos.value + d.primaryDelta! / _step).clamp(-0.08, 1.08);
  }

  void _dragEnd(DragEndDetails d) {
    final velocity = d.primaryVelocity ?? 0;
    final target = velocity.abs() > 300
        ? (velocity > 0 ? 1 : 0)
        : _pos.value.round().clamp(0, 1);
    _select(AppTab.values[target]);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);

    return Semantics(
      container: true,
      label: l10n.navMain,
      child: GlassSurface(
        tone: GlassTone.dark,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: GestureDetector(
          onHorizontalDragUpdate: _dragUpdate,
          onHorizontalDragEnd: _dragEnd,
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.s2),
            child: LayoutBuilder(
              builder: (context, box) {
                final tabWidth = (box.maxWidth - _gap) / 2;
                _step = tabWidth + _gap;

                return AnimatedBuilder(
                  animation: _pos,
                  builder: (context, _) {
                    final t = _pos.value;
                    // How far between the two tabs (0 at rest, 1 halfway).
                    final between = math.sin(t.clamp(0.0, 1.0) * math.pi);
                    // Liquid: wider and a little flatter while moving.
                    final width = tabWidth * (1 + 0.28 * between);
                    final squash = 1 - 0.1 * between;
                    final left = t * _step - (width - tabWidth) / 2;

                    return Stack(
                      children: [
                        Positioned(
                          left: left,
                          top: 0,
                          bottom: 0,
                          width: width,
                          child: RepaintBoundary(
                            child: Transform.scale(
                              scaleY: squash,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: c.lavender,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _Tab(
                                icon: Icons.menu_book_rounded,
                                label: l10n.navPractice,
                                active: widget.current == AppTab.practice,
                                // 1 when the blob is fully under this tab.
                                cover: (1 - t).clamp(0.0, 1.0),
                                onTap: () => _select(AppTab.practice),
                              ),
                            ),
                            const SizedBox(width: _gap),
                            Expanded(
                              child: _Tab(
                                icon: Icons.show_chart_rounded,
                                label: l10n.navProgress,
                                active: widget.current == AppTab.progress,
                                cover: t.clamp(0.0, 1.0),
                                onTap: () => _select(AppTab.progress),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.icon,
    required this.label,
    required this.active,
    required this.cover,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;

  /// How much the lavender blob is under this tab (0 to 1). The text
  /// colour follows it, so it always reads well on what is behind it.
  final double cover;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final fg = Color.lerp(c.onNight, c.onAccent, cover)!;

    return Semantics(
      button: true,
      selected: active,
      label: label,
      excludeSemantics: true,
      child: TapSurface(
        onTap: onTap,
        color: Colors.transparent,
        shape: const StadiumBorder(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.button),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: fg),
              const SizedBox(width: AppSpace.s2),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.tab.copyWith(color: fg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
