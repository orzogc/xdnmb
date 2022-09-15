import 'package:flutter/material.dart';

typedef TapToReloadBuilder = Widget Function(
    BuildContext context, Widget? child);

class TapToReload extends StatefulWidget {
  final TapToReloadBuilder builder;

  final Widget? tapped;

  const TapToReload({super.key, required this.builder, this.tapped});

  @override
  State<TapToReload> createState() => _TapToReloadState();
}

class _TapToReloadState extends State<TapToReload> {
  @override
  Widget build(BuildContext context) => widget.tapped != null
      ? widget.builder(
          context,
          GestureDetector(
            onTap: () {
              if (mounted) {
                setState(() {});
              }
            },
            child: widget.tapped,
          ),
        )
      : GestureDetector(
          onTap: () {
            if (mounted) {
              setState(() {});
            }
          },
          child: widget.builder(context, null),
        );
}
