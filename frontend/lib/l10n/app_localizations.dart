import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'CogniGuide'**
  String get appTitle;

  /// Screen reader name for Pip, the coach mascot (idle mood).
  ///
  /// In en, this message translates to:
  /// **'Your coach'**
  String get pipIdle;

  /// No description provided for @pipThinking.
  ///
  /// In en, this message translates to:
  /// **'Your coach, thinking'**
  String get pipThinking;

  /// No description provided for @pipHappy.
  ///
  /// In en, this message translates to:
  /// **'Your coach, happy'**
  String get pipHappy;

  /// No description provided for @pipSleepy.
  ///
  /// In en, this message translates to:
  /// **'Your coach, resting'**
  String get pipSleepy;

  /// Screen reader name for the row of area chips.
  ///
  /// In en, this message translates to:
  /// **'Maths area'**
  String get areaGroup;

  /// No description provided for @areaNumber.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get areaNumber;

  /// No description provided for @areaAlgebra.
  ///
  /// In en, this message translates to:
  /// **'Algebra'**
  String get areaAlgebra;

  /// No description provided for @areaGeometry.
  ///
  /// In en, this message translates to:
  /// **'Geometry'**
  String get areaGeometry;

  /// No description provided for @areaTrigonometry.
  ///
  /// In en, this message translates to:
  /// **'Trigonometry'**
  String get areaTrigonometry;

  /// No description provided for @areaGraphs.
  ///
  /// In en, this message translates to:
  /// **'Graphs'**
  String get areaGraphs;

  /// No description provided for @areaStatistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get areaStatistics;

  /// Small label before the grade filter buttons.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get gradeLabel;

  /// No description provided for @gradeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get gradeAll;

  /// No description provided for @gradeAllSemantics.
  ///
  /// In en, this message translates to:
  /// **'All grades'**
  String get gradeAllSemantics;

  /// Screen reader name for one grade filter button.
  ///
  /// In en, this message translates to:
  /// **'Grade {grade}'**
  String gradeSemantics(int grade);

  /// Small line above a problem. Shown in capitals.
  ///
  /// In en, this message translates to:
  /// **'Problem {number} · {area} · Grade {grade}'**
  String problemEyebrow(int number, String area, int grade);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
