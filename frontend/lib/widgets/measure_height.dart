import 'package:flutter/material.dart';

/// Tells its parent how tall [child] is after each layout, so a screen can
/// leave room for something floating above or below its content (the
/// glass header, the chat input bar).
class MeasureHeight extends StatefulWidget {
  const MeasureHeight({super.key, required this.child, required this.onHeight});

  final Widget child;
  final ValueChanged<double> onHeight;

  @override
  State<MeasureHeight> createState() => _MeasureHeightState();
}

class _MeasureHeightState extends State<MeasureHeight> {
  final _key = GlobalKey();

  void _measure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = _key.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) widget.onHeight(box.size.height);
    });
  }

  @override
  Widget build(BuildContext context) {
    _measure();
    // Also measure when the child changes size by itself (a size
    // animation inside it), not only when this widget is rebuilt.
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (_) {
        _measure();
        return true;
      },
      child: SizeChangedLayoutNotifier(
        child: KeyedSubtree(key: _key, child: widget.child),
      ),
    );
  }
}
