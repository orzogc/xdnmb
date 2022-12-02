import 'package:flutter/material.dart';

class ColoredSafeArea extends StatelessWidget {
  final Widget child;

  const ColoredSafeArea({super.key, required this.child});

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: Theme.of(context).primaryColor,
        child: SafeArea(left: false, top: false, right: false, child: child),
      );
}
