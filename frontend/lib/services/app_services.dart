import 'package:flutter/widgets.dart';

import 'auth_service.dart';
import 'problem_repository.dart';
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
    required super.child,
  });

  final AuthService auth;
  final SettingsStore settings;
  final ProblemRepository problems;

  static AppServices of(BuildContext context) {
    final services = context.dependOnInheritedWidgetOfExactType<AppServices>();
    assert(services != null, 'AppServices is missing above this widget.');
    return services!;
  }

  @override
  bool updateShouldNotify(AppServices old) =>
      auth != old.auth || settings != old.settings || problems != old.problems;
}
