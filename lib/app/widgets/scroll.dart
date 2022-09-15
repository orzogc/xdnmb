import 'package:flutter/material.dart';

class SingleChildScrollViewWithScrollbar extends StatefulWidget {
  final Widget child;

  const SingleChildScrollViewWithScrollbar({super.key, required this.child});

  @override
  State<SingleChildScrollViewWithScrollbar> createState() =>
      _SingleChildScrollViewWithScrollbarState();
}

class _SingleChildScrollViewWithScrollbarState
    extends State<SingleChildScrollViewWithScrollbar> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scrollbar(
        controller: _controller,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _controller,
          child: widget.child,
        ),
      );
}
