import 'package:flutter/widgets.dart';

import 'auth_service.dart';
import 'chat_api.dart';
import 'problem_repository.dart';
import 'progress_api.dart';
import 'settings_store.dart';

/// Gives every screen the app's services.
///
/// Screens call `AppServices.of(context).auth`. Tests can put fake
/// services here instead of the real ones.
class AppServices extends InheritedWidget {
  const AppServices({
    super.key,
    required this.auth,
    required this.settings,
    required this.problems,
    required this.chat,
    required this.progress,
    required super.child,
  });

  final AuthService auth;
  final SettingsStore settings;
  final ProblemRepository problems;
  final ChatApi chat;
  final ProgressApi progress;

  /// The services, or null when there are none above (some tests).
  static AppServices? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppServices>();

  static AppServices of(BuildContext context) {
    final services = context.dependOnInheritedWidgetOfExactType<AppServices>();
    assert(services != null, 'AppServices is missing above this widget.');
    return services!;
  }

  @override
  bool updateShouldNotify(AppServices old) =>
      auth != old.auth ||
      settings != old.settings ||
      problems != old.problems ||
      chat != old.chat ||
      progress != old.progress;
}
