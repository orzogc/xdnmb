import 'package:flutter/material.dart';

class ColoredSafeArea extends StatelessWidget {
  final Color? color;

  final Widget child;

  const ColoredSafeArea({super.key, this.color, required this.child});

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: color ?? Theme.of(context).primaryColor,
        child: SafeArea(left: false, top: false, right: false, child: child),
      );
}
