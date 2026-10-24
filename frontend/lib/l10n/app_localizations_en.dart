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
  String get back => 'Back';

  @override
  String get done => 'Done';

  @override
  String welcomeLanguageButton(String language) {
    return 'Language: $language. Change language';
  }

  @override
  String get welcomeTitle => 'Think it through, your way.';

  @override
  String get welcomeSubtitle =>
      'A coach that asks good questions, so you find the answers yourself.';

  @override
  String get welcomeStep1 => 'Pick a problem';

  @override
  String get welcomeStep2 => 'Chat with your coach';

  @override
  String get welcomeStep3 => 'Watch your own thinking grow';

  @override
  String get welcomeCreateAccount => 'Create an account';

  @override
  String get welcomeLogIn => 'Log in';

  @override
  String get pipWaving => 'Your thinking coach, waving hello';

  @override
  String get languageTitle => 'Choose a language';

  @override
  String get languageSubtitle => 'You can change this any time in Settings.';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSinhala => 'Sinhala';

  @override
  String get languageTamil => 'Tamil';

  @override
  String get languageNote =>
      'Your coach may answer in English first while we test Sinhala and Tamil.';

  @override
  String get fieldCode => 'Anonymous code';

  @override
  String get fieldCodeHint => 'For example P001';

  @override
  String get fieldPassword => 'Password';

  @override
  String get fieldPasswordAgain => 'Type the password again';

  @override
  String get createTitle => 'Create your account';

  @override
  String get createSubtitle =>
      'No name or email needed. Just a code and a password.';

  @override
  String get createSubtitleFix => 'Almost there. A few small things to fix.';

  @override
  String get createCodeHelp =>
      'Letters and numbers only. Please don\'t use your real name.';

  @override
  String get createPasswordHelp => 'At least 8 characters.';

  @override
  String get createWriteItDown =>
      'Write your code and password down. Because we don\'t know who you are, we can\'t recover them.';

  @override
  String get createButton => 'Create account';

  @override
  String get createHaveAccount => 'I already have an account';

  @override
  String get creatingAccount => 'Creating your account';

  @override
  String get fixCodeEmpty => 'Type a code first, for example P001.';

  @override
  String get fixCodeFormat =>
      'Use only letters, numbers, _ or -, with no spaces.';

  @override
  String get fixCodeTaken =>
      'That code is taken. Try a different one, for example add a few more numbers.';

  @override
  String fixPasswordShort(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Your password needs at least 8 characters. Add $count more.',
      one: 'Your password needs at least 8 characters. Add 1 more.',
    );
    return '$_temp0';
  }

  @override
  String get fixPasswordsDontMatch =>
      'The two passwords don\'t match yet. Type it again slowly.';

  @override
  String get fixPasswordEmpty => 'Type your password.';

  @override
  String get fixDetailsDontMatch =>
      'That code and password don\'t match. Check them and try again.';

  @override
  String get fixSomethingWrong => 'Something went wrong. Please try again.';

  @override
  String get loginTitle => 'Welcome back';

  @override
  String get loginSubtitle => 'Log in with your code and password.';

  @override
  String get loginPrivacy =>
      'Your code keeps your progress private. This is not a test and nobody grades you.';

  @override
  String get loginButton => 'Log in';

  @override
  String get loginNewHere => 'New here? Create an account';

  @override
  String get loggingIn => 'Logging you in';

  @override
  String homeGreeting(String code) {
    return 'Hi, $code';
  }

  @override
  String get logOut => 'Log out';

  @override
  String get homeTitle => 'What would you like to work on?';

  @override
  String get homeSettings => 'Settings';

  @override
  String get homeLoading => 'Getting your problems ready';

  @override
  String get homeEmpty =>
      'No problems here yet. Try another area or type your own.';

  @override
  String get homeLoadFailed =>
      'The problems could not be loaded. Please try again.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get homeOwnLabel => 'Or type your own problem';

  @override
  String get homeOwnHint =>
      'Type the whole question. Has a figure? Describe it in words, for example: triangle ABC, AB = 5 cm, angle B = 90°.';

  @override
  String get homeOwnStart => 'Start with this problem';

  @override
  String get homeOwnEmpty => 'Type your problem first.';

  @override
  String get homeOwnTooLong =>
      'That is too long. Keep it under 2000 characters.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsBack => 'Back to problems';

  @override
  String settingsYourCode(String code) {
    return 'Your code: $code';
  }

  @override
  String get settingsYourCodeLabel => 'Your code';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsTheme => 'Look';

  @override
  String get settingsThemeSystem => 'Same as phone';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsGlass => 'Glass effects';

  @override
  String get settingsGlassHelp =>
      'Turn off on a slow phone to keep the app smooth and save battery.';

  @override
  String get settingsGlassAutoOff =>
      'Turned off by itself because it was slowing this phone down. You can turn it back on.';

  @override
  String get buddyTitle => 'Pick your buddy';

  @override
  String get buddySubtitle =>
      'Your buddy shows next to your messages. It\'s just for fun, and you can change it in Settings.';

  @override
  String get buddyLastStep => 'Last step';

  @override
  String get buddyGroup => 'Buddies';

  @override
  String get buddyGo => 'Let\'s go!';

  @override
  String get buddySave => 'Save';

  @override
  String get buddyChange => 'Change';

  @override
  String get buddyChangeLabel => 'Change your buddy';

  @override
  String buddyYours(String name) {
    return 'Your buddy: $name';
  }

  @override
  String get chatWorkedItOut => 'I worked it out!';

  @override
  String get momentTitle => 'You worked it out yourself!';

  @override
  String get momentText =>
      'You asked good questions and kept going. That\'s how real mathematicians think.';

  @override
  String get momentMessages => 'Messages you sent';

  @override
  String get momentMinutes => 'Minutes thinking';

  @override
  String get momentTryAnother => 'Try another problem';

  @override
  String get momentSeeProgress => 'See my progress';

  @override
  String get logoutTitle => 'Log out?';

  @override
  String get logoutText =>
      'You\'ll need your code and password to log back in. Your progress stays saved.';

  @override
  String get logoutStay => 'Stay';

  @override
  String get chatCoachTitle => 'Your thinking coach';

  @override
  String get chatCoachSubtitle => 'Here to ask, not to tell';

  @override
  String get chatBack => 'Back to problems';

  @override
  String get chatToggleProblem => 'Show or hide the whole problem';

  @override
  String get chatConversation => 'Conversation';

  @override
  String get chatMessageLabel => 'Message your coach';

  @override
  String get chatMessageHint => 'Type your thinking…';

  @override
  String get chatSend => 'Send';

  @override
  String get chatBusyTitle => 'Your coach is busy right now';

  @override
  String get chatBusyText =>
      'Lots of people are asking at once. Nothing is lost. Wait a moment, then try again.';

  @override
  String get chatErrorTitle => 'Something went wrong';

  @override
  String get chatErrorText => 'Please try again. Nothing is lost.';

  @override
  String get chatOfflineTitle => 'No internet';

  @override
  String get chatOfflineText =>
      'Check your connection and try again. Your message is kept here.';

  @override
  String get chatMessageTooLong =>
      'That message is too long. Keep it under 2000 characters.';

  @override
  String get chatLimitReached =>
      'This chat is very long now. Go back and start the problem again to keep going.';

  @override
  String get progressSubtitle => 'Only you can see this. It is not a grade.';

  @override
  String get progressLoading => 'Adding up your sessions…';

  @override
  String get progressBasedOnRecent => 'Based on your most recent sessions';

  @override
  String get progressNumbers => 'Your numbers';

  @override
  String get tileSessions => 'Sessions';

  @override
  String get tileSelfCorrections => 'Times you fixed your own mistake';

  @override
  String get tileStuck => 'Times you felt stuck';

  @override
  String get tileReflections => 'Reflection questions';

  @override
  String get chartTitle => 'How much help you needed in each session';

  @override
  String get chartALot => 'A lot';

  @override
  String get chartSome => 'Some';

  @override
  String get chartALittle => 'A little';

  @override
  String get chartSessionAxis => 'Session';

  @override
  String get chartLowerIsGood =>
      'Lower on the chart is good. It means you needed less help to work things out.';

  @override
  String chartSemantics(int count, String levels) {
    return 'Line chart of help needed in sessions 1 to $count: $levels. The same numbers are in the list view.';
  }

  @override
  String get chartEmpty => 'Your chart will appear here after two sessions.';

  @override
  String get chartShowList => 'Show the same numbers as a list';

  @override
  String get progressRoughGuide =>
      'These numbers come from simple word rules, so they are a rough guide and not proof.';

  @override
  String get progressStartProblem => 'Start a problem';

  @override
  String get progressUnavailable =>
      'Progress is not available right now. Please try again later.';

  @override
  String get listTitle => 'Help in each session';

  @override
  String get listSubtitle => 'The same numbers as the chart, written out.';

  @override
  String get listBack => 'Back to my progress';

  @override
  String get listSession => 'Session';

  @override
  String get listDate => 'Date';

  @override
  String get listHelpNeeded => 'Help needed';

  @override
  String get ownProblemEyebrow => 'Your own problem';

  @override
  String get pipIdle => 'Your coach';

  @override
  String get pipThinking => 'Your coach, thinking';

  @override
  String get pipHappy => 'Your coach, happy';

  @override
  String get pipSleepy => 'Your coach, resting';

  @override
  String get pipCheering => 'Your coach, cheering you on';

  @override
  String get pipSurprised => 'Your coach, surprised';

  @override
  String get pipDetermined => 'Your coach, ready to think';

  @override
  String get pipWink => 'Your coach, winking';

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
  String get navMain => 'Main';

  @override
  String get navPractice => 'Practice';

  @override
  String get navProgress => 'My progress';

  @override
  String get chatNotSent => 'Not sent';

  @override
  String get chatCoachThinking => 'Your coach is thinking';

  @override
  String get chatFromCoach => 'Coach';

  @override
  String get chatFromYou => 'You';

  @override
  String get mathsKeys => 'Maths keys';

  @override
  String get keyPlus => 'plus';

  @override
  String get keyMinus => 'minus';

  @override
  String get keyTimes => 'times';

  @override
  String get keyDivide => 'divided by';

  @override
  String get keyEquals => 'equals';

  @override
  String get keyOpenBracket => 'open bracket';

  @override
  String get keyCloseBracket => 'close bracket';

  @override
  String get keySquared => 'squared';

  @override
  String get keyCubed => 'cubed';

  @override
  String get keySquareRoot => 'square root';

  @override
  String get keyPi => 'pi';

  @override
  String get keyTheta => 'theta';

  @override
  String get keyDegrees => 'degrees';

  @override
  String get keySin => 'sine';

  @override
  String get keyCos => 'cosine';

  @override
  String get keyTan => 'tangent';

  @override
  String problemEyebrow(int number, String area, int grade) {
    return 'Problem $number · $area · Grade $grade';
  }
}
