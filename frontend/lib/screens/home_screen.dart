import 'package:flutter/material.dart';

import '../services/app_services.dart';
import '../theme/app_sizes.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/soft_blobs.dart';
import 'pick_problem_tab.dart';
import 'progress_tab.dart';

/// The inside of the app after logging in: the two tabs
/// (Practice and My progress) with the floating bottom nav.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AppTab _tab = AppTab.practice;
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
          // Keeps each tab's state (chosen area, scroll) when switching.
          IndexedStack(
            index: _tab.index,
            children: [
              PickProblemTab(code: _code),
              ProgressTab(
                code: _code,
                active: _tab == AppTab.progress,
                onStartProblem: () => _go(AppTab.practice),
              ),
            ],
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

  void _go(AppTab tab) => setState(() => _tab = tab);
}
