import 'package:flutter/material.dart';

import '../services/app_services.dart';
import '../theme/app_motion.dart';
import '../theme/app_sizes.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/soft_blobs.dart';
import 'pick_problem_tab.dart';
import 'progress_tab.dart';

/// The inside of the app after logging in: the two tabs
/// (Practice and My progress) with the floating bottom nav.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialTab = AppTab.practice});

  /// The tab to open on (My progress after "You worked it out!").
  final AppTab initialTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late AppTab _tab = widget.initialTab;

  /// The tab that is fading out right now (null when no switch is running).
  AppTab? _leaving;
  String _code = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppServices.of(context).auth.currentCode().then((code) {
      if (mounted && code != null) setState(() => _code = code);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // The background with soft colour glows, for the glass to show.
          const Positioned.fill(child: SoftBlobs()),
          // Both tabs stay built, so each keeps its state (chosen area,
          // scroll). Switching fades and slides a little (see _TabPage).
          _TabPage(
            active: _tab == AppTab.practice,
            leaving: _leaving == AppTab.practice,
            fromLeft: true,
            onHidden: _switchDone,
            child: PickProblemTab(code: _code),
          ),
          _TabPage(
            active: _tab == AppTab.progress,
            leaving: _leaving == AppTab.progress,
            fromLeft: false,
            onHidden: _switchDone,
            child: ProgressTab(
              code: _code,
              active: _tab == AppTab.progress,
              onStartProblem: () => _go(AppTab.practice),
            ),
          ),
          Positioned(
            left: AppSpace.s4,
            right: AppSpace.s4,
            bottom: AppSpace.s4,
            child: SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: AppBottomNav(current: _tab, onChanged: _go),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _go(AppTab tab) {
    if (tab == _tab) return;
    setState(() {
      // With "reduce motion" there is no fade: the old tab goes at once.
      _leaving = AppMotion.reduced(context) ? null : _tab;
      _tab = tab;
    });
  }

  void _switchDone() {
    if (_leaving != null && mounted) setState(() => _leaving = null);
  }
}

/// One tab. The open tab is fully shown; the one being left fades out and
/// slides a little towards its side of the bottom nav, while the new one
/// comes in. When the fade ends, the old tab is put away (Offstage: not
/// drawn, not tappable, not read by screen readers, timers paused) but its
/// state is kept.
///
/// PERFORMANCE: only opacity and a small move, for a quarter of a second.
/// With "reduce motion" the switch is instant.
class _TabPage extends StatelessWidget {
  const _TabPage({
    required this.active,
    required this.leaving,
    required this.fromLeft,
    required this.onHidden,
    required this.child,
  });

  final bool active;

  /// True while this tab fades out after the student switched away.
  final bool leaving;

  /// The Practice tab sits on the left of the nav, My progress on the right.
  final bool fromLeft;

  final VoidCallback onHidden;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.of(context, AppMotion.medium);
    final hidden = !active && !leaving;
    return Offstage(
      offstage: hidden,
      child: TickerMode(
        enabled: !hidden,
        child: IgnorePointer(
          ignoring: !active,
          child: AnimatedSlide(
            offset: active ? Offset.zero : Offset(fromLeft ? -0.04 : 0.04, 0),
            duration: duration,
            curve: AppMotion.ease,
            child: AnimatedOpacity(
              opacity: active ? 1 : 0,
              duration: duration,
              curve: AppMotion.ease,
              // After this frame: the fade can end while widgets are built.
              onEnd: active
                  ? null
                  : () => WidgetsBinding.instance.addPostFrameCallback(
                      (_) => onHidden(),
                    ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
