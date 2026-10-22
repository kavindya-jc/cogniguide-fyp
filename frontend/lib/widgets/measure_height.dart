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

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = _key.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) widget.onHeight(box.size.height);
    });
    return KeyedSubtree(key: _key, child: widget.child);
  }
}
