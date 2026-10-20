import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_sizes.dart';
import '../theme/app_text.dart';
import 'tap_surface.dart';

/// One maths key: what it shows, what it types, and its spoken name.
class MathsKey {
  const MathsKey(this.label, this.insert, this.spokenName);

  final String label;
  final String insert;
  final String Function(AppLocalizations) spokenName;
}

/// The keys from the design, in order.
final List<MathsKey> mathsKeys = [
  MathsKey('+', '+', (l) => l.keyPlus),
  MathsKey('−', '−', (l) => l.keyMinus),
  MathsKey('×', '×', (l) => l.keyTimes),
  MathsKey('÷', '÷', (l) => l.keyDivide),
  MathsKey('=', '=', (l) => l.keyEquals),
  MathsKey('(', '(', (l) => l.keyOpenBracket),
  MathsKey(')', ')', (l) => l.keyCloseBracket),
  MathsKey('²', '²', (l) => l.keySquared),
  MathsKey('³', '³', (l) => l.keyCubed),
  MathsKey('√', '√', (l) => l.keySquareRoot),
  MathsKey('π', 'π', (l) => l.keyPi),
  MathsKey('θ', 'θ', (l) => l.keyTheta),
  MathsKey('°', '°', (l) => l.keyDegrees),
  MathsKey('sin', 'sin ', (l) => l.keySin),
  MathsKey('cos', 'cos ', (l) => l.keyCos),
  MathsKey('tan', 'tan ', (l) => l.keyTan),
];

/// A sideways row of maths keys above the message box.
/// [onKey] gets the text to type, for example "²" or "sin ".
class MathsKeyRow extends StatelessWidget {
  const MathsKeyRow({
    super.key,
    required this.onKey,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpace.s3),
  });

  final ValueChanged<String> onKey;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);

    return Semantics(
      container: true,
      label: l10n.mathsKeys,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        // Room for the focus ring above and below.
        padding: padding.copyWith(top: 4, bottom: 4),
        child: Row(
          children: [
            for (final key in mathsKeys) ...[
              if (key != mathsKeys.first) const SizedBox(width: 6),
              Semantics(
                button: true,
                label: key.spokenName(l10n),
                excludeSemantics: true,
                child: TapSurface(
                  onTap: () => onKey(key.insert),
                  pressScale: 0.92,
                  color: c.surfaceSunken,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: AppSizes.tap,
                      minHeight: AppSizes.tap,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.s3,
                      ),
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          key.label,
                          style: AppText.label.copyWith(
                            color: c.ink,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
