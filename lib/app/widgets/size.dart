import 'package:flutter/material.dart';

typedef ChildSizeBuilder = Widget Function(
    BuildContext context, Size size, Widget? child);

class ChildSizeNotifier extends StatefulWidget {
  final ChildSizeBuilder builder;

  final Widget? child;

  const ChildSizeNotifier({super.key, required this.builder, this.child});

  @override
  State<ChildSizeNotifier> createState() => _ChildSizeNotifierState();
}

class _ChildSizeNotifierState extends State<ChildSizeNotifier> {
  final ValueNotifier<Size> _notifier = ValueNotifier(Size.zero);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _notifier.value = (context.findRenderObject() as RenderBox).size,
    );
  }

  @override
  void dispose() {
    _notifier.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Size>(
        valueListenable: _notifier,
        builder: widget.builder,
        child: widget.child,
      );
}
