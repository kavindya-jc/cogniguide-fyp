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

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Screen reader name for the language button on Welcome.
  ///
  /// In en, this message translates to:
  /// **'Language: {language}. Change language'**
  String welcomeLanguageButton(String language);

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Think it through, your way.'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A coach that asks good questions, so you find the answers yourself.'**
  String get welcomeSubtitle;

  /// No description provided for @welcomeStep1.
  ///
  /// In en, this message translates to:
  /// **'Pick a problem'**
  String get welcomeStep1;

  /// No description provided for @welcomeStep2.
  ///
  /// In en, this message translates to:
  /// **'Chat with your coach'**
  String get welcomeStep2;

  /// No description provided for @welcomeStep3.
  ///
  /// In en, this message translates to:
  /// **'Watch your own thinking grow'**
  String get welcomeStep3;

  /// No description provided for @welcomeCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get welcomeCreateAccount;

  /// No description provided for @welcomeLogIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get welcomeLogIn;

  /// No description provided for @pipWaving.
  ///
  /// In en, this message translates to:
  /// **'Your thinking coach, waving hello'**
  String get pipWaving;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a language'**
  String get languageTitle;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can change this any time in Settings.'**
  String get languageSubtitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSinhala.
  ///
  /// In en, this message translates to:
  /// **'Sinhala'**
  String get languageSinhala;

  /// No description provided for @languageTamil.
  ///
  /// In en, this message translates to:
  /// **'Tamil'**
  String get languageTamil;

  /// No description provided for @languageNote.
  ///
  /// In en, this message translates to:
  /// **'Your coach may answer in English first while we test Sinhala and Tamil.'**
  String get languageNote;

  /// No description provided for @fieldCode.
  ///
  /// In en, this message translates to:
  /// **'Anonymous code'**
  String get fieldCode;

  /// No description provided for @fieldCodeHint.
  ///
  /// In en, this message translates to:
  /// **'For example P001'**
  String get fieldCodeHint;

  /// No description provided for @fieldPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get fieldPassword;

  /// No description provided for @fieldPasswordAgain.
  ///
  /// In en, this message translates to:
  /// **'Type the password again'**
  String get fieldPasswordAgain;

  /// No description provided for @createTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createTitle;

  /// No description provided for @createSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No name or email needed. Just a code and a password.'**
  String get createSubtitle;

  /// No description provided for @createSubtitleFix.
  ///
  /// In en, this message translates to:
  /// **'Almost there. A few small things to fix.'**
  String get createSubtitleFix;

  /// No description provided for @createCodeHelp.
  ///
  /// In en, this message translates to:
  /// **'Letters and numbers only. Please don\'t use your real name.'**
  String get createCodeHelp;

  /// No description provided for @createPasswordHelp.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters.'**
  String get createPasswordHelp;

  /// No description provided for @createWriteItDown.
  ///
  /// In en, this message translates to:
  /// **'Write your code and password down. Because we don\'t know who you are, we can\'t recover them.'**
  String get createWriteItDown;

  /// No description provided for @createButton.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createButton;

  /// No description provided for @createHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'I already have an account'**
  String get createHaveAccount;

  /// No description provided for @creatingAccount.
  ///
  /// In en, this message translates to:
  /// **'Creating your account'**
  String get creatingAccount;

  /// No description provided for @fixCodeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Type a code first, for example P001.'**
  String get fixCodeEmpty;

  /// Shown when the code has spaces, @, or other characters (so names and emails are not used).
  ///
  /// In en, this message translates to:
  /// **'Use only letters, numbers, _ or -, with no spaces.'**
  String get fixCodeFormat;

  /// No description provided for @fixCodeTaken.
  ///
  /// In en, this message translates to:
  /// **'That code is taken. Try a different one, for example add a few more numbers.'**
  String get fixCodeTaken;

  /// No description provided for @fixPasswordShort.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Your password needs at least 8 characters. Add 1 more.} other{Your password needs at least 8 characters. Add {count} more.}}'**
  String fixPasswordShort(int count);

  /// No description provided for @fixPasswordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'The two passwords don\'t match yet. Type it again slowly.'**
  String get fixPasswordsDontMatch;

  /// No description provided for @fixPasswordEmpty.
  ///
  /// In en, this message translates to:
  /// **'Type your password.'**
  String get fixPasswordEmpty;

  /// No description provided for @fixDetailsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'That code and password don\'t match. Check them and try again.'**
  String get fixDetailsDontMatch;

  /// No description provided for @fixSomethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get fixSomethingWrong;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log in with your code and password.'**
  String get loginSubtitle;

  /// No description provided for @loginPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Your code keeps your progress private. This is not a test and nobody grades you.'**
  String get loginPrivacy;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get loginButton;

  /// No description provided for @loginNewHere.
  ///
  /// In en, this message translates to:
  /// **'New here? Create an account'**
  String get loginNewHere;

  /// No description provided for @loggingIn.
  ///
  /// In en, this message translates to:
  /// **'Logging you in'**
  String get loggingIn;

  /// Greeting with the anonymous code (never a name).
  ///
  /// In en, this message translates to:
  /// **'Hi, {code}'**
  String homeGreeting(String code);

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'What would you like to work on?'**
  String get homeTitle;

  /// No description provided for @homeSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get homeSettings;

  /// No description provided for @homeLoading.
  ///
  /// In en, this message translates to:
  /// **'Getting your problems ready'**
  String get homeLoading;

  /// No description provided for @homeEmpty.
  ///
  /// In en, this message translates to:
  /// **'No problems here yet. Try another area or type your own.'**
  String get homeEmpty;

  /// No description provided for @homeLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The problems could not be loaded. Please try again.'**
  String get homeLoadFailed;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @homeOwnLabel.
  ///
  /// In en, this message translates to:
  /// **'Or type your own problem'**
  String get homeOwnLabel;

  /// No description provided for @homeOwnHint.
  ///
  /// In en, this message translates to:
  /// **'Type the whole question. Has a figure? Describe it in words, for example: triangle ABC, AB = 5 cm, angle B = 90°.'**
  String get homeOwnHint;

  /// No description provided for @homeOwnStart.
  ///
  /// In en, this message translates to:
  /// **'Start with this problem'**
  String get homeOwnStart;

  /// No description provided for @homeOwnEmpty.
  ///
  /// In en, this message translates to:
  /// **'Type your problem first.'**
  String get homeOwnEmpty;

  /// No description provided for @homeOwnTooLong.
  ///
  /// In en, this message translates to:
  /// **'That is too long. Keep it under 2000 characters.'**
  String get homeOwnTooLong;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsBack.
  ///
  /// In en, this message translates to:
  /// **'Back to problems'**
  String get settingsBack;

  /// No description provided for @settingsYourCode.
  ///
  /// In en, this message translates to:
  /// **'Your code: {code}'**
  String settingsYourCode(String code);

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsGlass.
  ///
  /// In en, this message translates to:
  /// **'Glass effects'**
  String get settingsGlass;

  /// No description provided for @settingsGlassHelp.
  ///
  /// In en, this message translates to:
  /// **'Turn off on a slow phone to keep the app smooth and save battery.'**
  String get settingsGlassHelp;

  /// No description provided for @settingsGlassAutoOff.
  ///
  /// In en, this message translates to:
  /// **'Turned off by itself because it was slowing this phone down. You can turn it back on.'**
  String get settingsGlassAutoOff;

  /// No description provided for @logoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logoutTitle;

  /// No description provided for @logoutText.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need your code and password to log back in. Your progress stays saved.'**
  String get logoutText;

  /// No description provided for @logoutStay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get logoutStay;

  /// No description provided for @chatCoachTitle.
  ///
  /// In en, this message translates to:
  /// **'Your thinking coach'**
  String get chatCoachTitle;

  /// No description provided for @chatCoachSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Here to ask, not to tell'**
  String get chatCoachSubtitle;

  /// No description provided for @chatBack.
  ///
  /// In en, this message translates to:
  /// **'Back to problems'**
  String get chatBack;

  /// No description provided for @chatToggleProblem.
  ///
  /// In en, this message translates to:
  /// **'Show or hide the whole problem'**
  String get chatToggleProblem;

  /// No description provided for @chatConversation.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get chatConversation;

  /// No description provided for @chatMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Message your coach'**
  String get chatMessageLabel;

  /// No description provided for @chatMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Type your thinking…'**
  String get chatMessageHint;

  /// No description provided for @chatSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatSend;

  /// No description provided for @chatBusyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your coach is busy right now'**
  String get chatBusyTitle;

  /// No description provided for @chatBusyText.
  ///
  /// In en, this message translates to:
  /// **'Lots of people are asking at once. Nothing is lost. Wait a moment, then try again.'**
  String get chatBusyText;

  /// No description provided for @chatErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get chatErrorTitle;

  /// No description provided for @chatErrorText.
  ///
  /// In en, this message translates to:
  /// **'Please try again. Nothing is lost.'**
  String get chatErrorText;

  /// No description provided for @chatOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'No internet'**
  String get chatOfflineTitle;

  /// No description provided for @chatOfflineText.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again. Your message is kept here.'**
  String get chatOfflineText;

  /// No description provided for @chatMessageTooLong.
  ///
  /// In en, this message translates to:
  /// **'That message is too long. Keep it under 2000 characters.'**
  String get chatMessageTooLong;

  /// Shown when the chat reaches the server's 50-message history limit.
  ///
  /// In en, this message translates to:
  /// **'This chat is very long now. Go back and start the problem again to keep going.'**
  String get chatLimitReached;

  /// No description provided for @progressSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only you can see this. It is not a grade.'**
  String get progressSubtitle;

  /// No description provided for @progressLoading.
  ///
  /// In en, this message translates to:
  /// **'Adding up your sessions…'**
  String get progressLoading;

  /// No description provided for @progressBasedOnRecent.
  ///
  /// In en, this message translates to:
  /// **'Based on your most recent sessions'**
  String get progressBasedOnRecent;

  /// No description provided for @progressNumbers.
  ///
  /// In en, this message translates to:
  /// **'Your numbers'**
  String get progressNumbers;

  /// No description provided for @tileSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get tileSessions;

  /// No description provided for @tileSelfCorrections.
  ///
  /// In en, this message translates to:
  /// **'Times you fixed your own mistake'**
  String get tileSelfCorrections;

  /// No description provided for @tileStuck.
  ///
  /// In en, this message translates to:
  /// **'Times you felt stuck'**
  String get tileStuck;

  /// No description provided for @tileReflections.
  ///
  /// In en, this message translates to:
  /// **'Reflection questions'**
  String get tileReflections;

  /// No description provided for @chartTitle.
  ///
  /// In en, this message translates to:
  /// **'How much help you needed in each session'**
  String get chartTitle;

  /// No description provided for @chartALot.
  ///
  /// In en, this message translates to:
  /// **'A lot'**
  String get chartALot;

  /// No description provided for @chartSome.
  ///
  /// In en, this message translates to:
  /// **'Some'**
  String get chartSome;

  /// No description provided for @chartALittle.
  ///
  /// In en, this message translates to:
  /// **'A little'**
  String get chartALittle;

  /// No description provided for @chartSessionAxis.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get chartSessionAxis;

  /// No description provided for @chartLowerIsGood.
  ///
  /// In en, this message translates to:
  /// **'Lower on the chart is good. It means you needed less help to work things out.'**
  String get chartLowerIsGood;

  /// No description provided for @chartSemantics.
  ///
  /// In en, this message translates to:
  /// **'Line chart of help needed in sessions 1 to {count}: {levels}. The same numbers are in the list view.'**
  String chartSemantics(int count, String levels);

  /// No description provided for @chartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your chart will appear here after two sessions.'**
  String get chartEmpty;

  /// No description provided for @chartShowList.
  ///
  /// In en, this message translates to:
  /// **'Show the same numbers as a list'**
  String get chartShowList;

  /// No description provided for @progressRoughGuide.
  ///
  /// In en, this message translates to:
  /// **'These numbers come from simple word rules, so they are a rough guide and not proof.'**
  String get progressRoughGuide;

  /// No description provided for @progressStartProblem.
  ///
  /// In en, this message translates to:
  /// **'Start a problem'**
  String get progressStartProblem;

  /// No description provided for @progressUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Progress is not available right now. Please try again later.'**
  String get progressUnavailable;

  /// No description provided for @listTitle.
  ///
  /// In en, this message translates to:
  /// **'Help in each session'**
  String get listTitle;

  /// No description provided for @listSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The same numbers as the chart, written out.'**
  String get listSubtitle;

  /// No description provided for @listBack.
  ///
  /// In en, this message translates to:
  /// **'Back to my progress'**
  String get listBack;

  /// No description provided for @listSession.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get listSession;

  /// No description provided for @listDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get listDate;

  /// No description provided for @listHelpNeeded.
  ///
  /// In en, this message translates to:
  /// **'Help needed'**
  String get listHelpNeeded;

  /// No description provided for @ownProblemEyebrow.
  ///
  /// In en, this message translates to:
  /// **'Your own problem'**
  String get ownProblemEyebrow;

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

  /// No description provided for @pipCheering.
  ///
  /// In en, this message translates to:
  /// **'Your coach, cheering you on'**
  String get pipCheering;

  /// No description provided for @pipSurprised.
  ///
  /// In en, this message translates to:
  /// **'Your coach, surprised'**
  String get pipSurprised;

  /// No description provided for @pipDetermined.
  ///
  /// In en, this message translates to:
  /// **'Your coach, ready to think'**
  String get pipDetermined;

  /// No description provided for @pipWink.
  ///
  /// In en, this message translates to:
  /// **'Your coach, winking'**
  String get pipWink;

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

  /// Screen reader name for the bottom tab bar.
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get navMain;

  /// No description provided for @navPractice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get navPractice;

  /// No description provided for @navProgress.
  ///
  /// In en, this message translates to:
  /// **'My progress'**
  String get navProgress;

  /// Label on a student message that could not be sent.
  ///
  /// In en, this message translates to:
  /// **'Not sent'**
  String get chatNotSent;

  /// Screen reader text for the typing dots.
  ///
  /// In en, this message translates to:
  /// **'Your coach is thinking'**
  String get chatCoachThinking;

  /// Screen reader prefix before a coach message.
  ///
  /// In en, this message translates to:
  /// **'Coach'**
  String get chatFromCoach;

  /// Screen reader prefix before the student's own message.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get chatFromYou;

  /// No description provided for @mathsKeys.
  ///
  /// In en, this message translates to:
  /// **'Maths keys'**
  String get mathsKeys;

  /// No description provided for @keyPlus.
  ///
  /// In en, this message translates to:
  /// **'plus'**
  String get keyPlus;

  /// No description provided for @keyMinus.
  ///
  /// In en, this message translates to:
  /// **'minus'**
  String get keyMinus;

  /// No description provided for @keyTimes.
  ///
  /// In en, this message translates to:
  /// **'times'**
  String get keyTimes;

  /// No description provided for @keyDivide.
  ///
  /// In en, this message translates to:
  /// **'divided by'**
  String get keyDivide;

  /// No description provided for @keyEquals.
  ///
  /// In en, this message translates to:
  /// **'equals'**
  String get keyEquals;

  /// No description provided for @keyOpenBracket.
  ///
  /// In en, this message translates to:
  /// **'open bracket'**
  String get keyOpenBracket;

  /// No description provided for @keyCloseBracket.
  ///
  /// In en, this message translates to:
  /// **'close bracket'**
  String get keyCloseBracket;

  /// No description provided for @keySquared.
  ///
  /// In en, this message translates to:
  /// **'squared'**
  String get keySquared;

  /// No description provided for @keyCubed.
  ///
  /// In en, this message translates to:
  /// **'cubed'**
  String get keyCubed;

  /// No description provided for @keySquareRoot.
  ///
  /// In en, this message translates to:
  /// **'square root'**
  String get keySquareRoot;

  /// No description provided for @keyPi.
  ///
  /// In en, this message translates to:
  /// **'pi'**
  String get keyPi;

  /// No description provided for @keyTheta.
  ///
  /// In en, this message translates to:
  /// **'theta'**
  String get keyTheta;

  /// No description provided for @keyDegrees.
  ///
  /// In en, this message translates to:
  /// **'degrees'**
  String get keyDegrees;

  /// No description provided for @keySin.
  ///
  /// In en, this message translates to:
  /// **'sine'**
  String get keySin;

  /// No description provided for @keyCos.
  ///
  /// In en, this message translates to:
  /// **'cosine'**
  String get keyCos;

  /// No description provided for @keyTan.
  ///
  /// In en, this message translates to:
  /// **'tangent'**
  String get keyTan;

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
