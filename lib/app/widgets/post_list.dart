import 'package:anchor_scroll_controller/anchor_scroll_controller.dart';
import 'package:flutter/material.dart';

import '../modules/post_list.dart';
import '../utils/extensions.dart';
import '../utils/notify.dart';

typedef PostListRefresherBuilder = Widget Function(
    BuildContext context, ScrollController scrollController, int refresh);

class PostListRefresher extends StatefulWidget {
  final PostListController controller;

  final bool useAnchorScrollController;

  final PostListRefresherBuilder builder;

  const PostListRefresher(
      {super.key,
      required this.controller,
      this.useAnchorScrollController = false,
      required this.builder});

  @override
  State<PostListRefresher> createState() => _PostListRefresherState();
}

class _PostListRefresherState extends State<PostListRefresher> {
  late final ScrollController _controller;

  int _refresh = 0;

  void _addRefresh() => _refresh++;

  void _setScrollDirection() => PostListController.setScrollPosition(
      _controller.position.userScrollDirection);

  @override
  void initState() {
    super.initState();

    _controller = widget.useAnchorScrollController
        ? AnchorScrollController(
            onIndexChanged: (index, userScroll) =>
                widget.controller.page = index.getPageFromPostIndex(),
          )
        : ScrollController();
    _controller.addListener(_setScrollDirection);

    widget.controller.addListener(_addRefresh);
  }

  @override
  void didUpdateWidget(covariant PostListRefresher oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_addRefresh);
      widget.controller.addListener(_addRefresh);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_setScrollDirection);
    _controller.dispose();
    widget.controller.removeListener(_addRefresh);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => NotifyBuilder(
      animation: widget.controller,
      builder: (context, child) =>
          widget.builder(context, _controller, _refresh));
}
