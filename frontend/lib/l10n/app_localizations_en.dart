// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'CogniGuide';

  @override
  String get pipIdle => 'Your coach';

  @override
  String get pipThinking => 'Your coach, thinking';

  @override
  String get pipHappy => 'Your coach, happy';

  @override
  String get pipSleepy => 'Your coach, resting';

  @override
  String get areaGroup => 'Maths area';

  @override
  String get areaNumber => 'Number';

  @override
  String get areaAlgebra => 'Algebra';

  @override
  String get areaGeometry => 'Geometry';

  @override
  String get areaTrigonometry => 'Trigonometry';

  @override
  String get areaGraphs => 'Graphs';

  @override
  String get areaStatistics => 'Statistics';

  @override
  String get gradeLabel => 'Grade';

  @override
  String get gradeAll => 'All';

  @override
  String get gradeAllSemantics => 'All grades';

  @override
  String gradeSemantics(int grade) {
    return 'Grade $grade';
  }

  @override
  String problemEyebrow(int number, String area, int grade) {
    return 'Problem $number · $area · Grade $grade';
  }
}
