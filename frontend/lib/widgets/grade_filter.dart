import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../models/maths_area.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text.dart';
import 'tap_surface.dart';

/// "Grade  All 8 9 10 11". Each button is at least 44 × 44.
///
/// The chosen one has a violet-soft pill with a violet ring. When another
/// grade is chosen, the pill slides over to it (the same liquid feel as
/// the bottom nav). [selected] is null for "All".
///
/// PERFORMANCE: only the pill moves; the buttons stay still. With
/// "reduce motion" on, the pill jumps.
class GradeFilter extends StatefulWidget {
  const GradeFilter({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final int? selected;
  final ValueChanged<int?> onChanged;

  @override
  State<GradeFilter> createState() => _GradeFilterState();
}

class _GradeFilterState extends State<GradeFilter> {
  /// All, then each grade.
  static final List<int?> _options = [null, ...appGrades];

  final _stackKey = GlobalKey();
  final _keys = {for (final g in _options) g: GlobalKey()};

  /// Where the pill is, measured from the chosen button after layout.
  Rect? _pill;

  /// False until the pill has its first place (so it does not slide in
  /// from nowhere when the screen opens).
  bool _placed = false;

  void _measure() {
    final stack = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final button =
        _keys[widget.selected]?.currentContext?.findRenderObject()
            as RenderBox?;
    if (stack == null || button == null || !button.hasSize) return;
    final topLeft = button.localToGlobal(Offset.zero, ancestor: stack);
    final rect = topLeft & button.size;
    if (rect != _pill) {
      setState(() {
        _placed = _pill != null;
        _pill = rect;
      });
    }
  }

  void _choose(int? grade) {
    if (grade != widget.selected) HapticFeedback.selectionClick();
    widget.onChanged(grade);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _measure();
    });

    return Semantics(
      label: l10n.gradeLabel,
      container: true,
      child: Stack(
        key: _stackKey,
        children: [
          if (_pill != null)
            AnimatedPositioned(
              duration: _placed
                  ? AppMotion.of(context, AppMotion.medium)
                  : Duration.zero,
              curve: Curves.easeOutBack,
              left: _pill!.left,
              top: _pill!.top,
              width: _pill!.width,
              height: _pill!.height,
              child: RepaintBoundary(
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: c.primarySoft,
                    shape: StadiumBorder(
                      side: BorderSide(color: c.primary, width: 2),
                    ),
                  ),
                ),
              ),
            ),
          // Wrap, not Row: with large system text the buttons move onto a
          // second line instead of running off the screen.
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 2,
            runSpacing: AppSpace.s1,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ExcludeSemantics(
                  child: Text(
                    l10n.gradeLabel,
                    style: AppText.label.copyWith(color: c.inkMuted),
                  ),
                ),
              ),
              for (final g in _options)
                _GradeButton(
                  key: _keys[g],
                  text: g == null ? l10n.gradeAll : '$g',
                  semanticLabel: g == null
                      ? l10n.gradeAllSemantics
                      : l10n.gradeSemantics(g),
                  selected: widget.selected == g,
                  onTap: () => _choose(g),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GradeButton extends StatelessWidget {
  const _GradeButton({
    super.key,
    required this.text,
    required this.semanticLabel,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final String semanticLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      excludeSemantics: true,
      child: TapSurface(
        onTap: onTap,
        pressScale: 0.95,
        // The sliding pill behind shows which one is chosen.
        color: Colors.transparent,
        shape: const StadiumBorder(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppSizes.tap,
            minHeight: AppSizes.tap,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Center(
              widthFactor: 1,
              child: AnimatedDefaultTextStyle(
                duration: AppMotion.of(context, AppMotion.quick),
                style: AppText.label.copyWith(
                  color: selected ? c.primaryInk : c.inkMuted,
                ),
                child: Text(text),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
