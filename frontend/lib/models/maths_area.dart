import '../l10n/app_localizations.dart';

/// The six maths areas the app covers.
enum MathsArea {
  number,
  algebra,
  geometry,
  trigonometry,
  graphs,
  statistics;

  /// The area's name in the app's language.
  String label(AppLocalizations l10n) => switch (this) {
    MathsArea.number => l10n.areaNumber,
    MathsArea.algebra => l10n.areaAlgebra,
    MathsArea.geometry => l10n.areaGeometry,
    MathsArea.trigonometry => l10n.areaTrigonometry,
    MathsArea.graphs => l10n.areaGraphs,
    MathsArea.statistics => l10n.areaStatistics,
  };
}

/// The grades the app covers.
const List<int> appGrades = [8, 9, 10, 11];
