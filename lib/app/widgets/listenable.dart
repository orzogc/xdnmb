import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

mixin _NotifierMixin on ChangeNotifier {
  void notify() => notifyListeners();
}

class Notifier extends ChangeNotifier with _NotifierMixin {
  Notifier();
}

class ListenableNotifier extends ChangeNotifier
    with _NotifierMixin
    implements ValueListenable<bool> {
  bool _value;

  @override
  bool get value => _value;

  ListenableNotifier([bool value = false]) : _value = value;

  void trigger() {
    _value = !_value;
    notify();
  }
}

typedef ListenableWidgetBuilder = Widget Function(
    BuildContext context, Widget? child);

class ListenableBuilder extends StatefulWidget {
  final Listenable listenable;

  final ListenableWidgetBuilder builder;

  final Widget? child;

  const ListenableBuilder(
      {super.key, required this.listenable, required this.builder, this.child});

  @override
  State<ListenableBuilder> createState() => _ListenableBuilderState();
}

class _ListenableBuilderState extends State<ListenableBuilder> {
  void _notify() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();

    widget.listenable.addListener(_notify);
  }

  @override
  void didUpdateWidget(covariant ListenableBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.listenable != oldWidget.listenable) {
      oldWidget.listenable.removeListener(_notify);
      widget.listenable.addListener(_notify);
    }
  }

  @override
  void dispose() {
    widget.listenable.removeListener(_notify);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, widget.child);
}
