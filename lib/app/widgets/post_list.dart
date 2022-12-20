import 'package:anchor_scroll_controller/anchor_scroll_controller.dart';
import 'package:flutter/material.dart';

import '../data/services/settings.dart';
import '../modules/post_list.dart';
import '../utils/extensions.dart';
import '../utils/notify.dart';

typedef PostListScrollViewBuilder = Widget Function(
    BuildContext context, AnchorScrollController scrollController, int refresh);

class PostListScrollView extends StatefulWidget {
  final PostListController controller;

  final AnchorScrollController? scrollController;

  final bool useAnchorScrollController;

  final PostListScrollViewBuilder builder;

  const PostListScrollView(
      {super.key,
      required this.controller,
      this.scrollController,
      this.useAnchorScrollController = false,
      required this.builder});

  @override
  State<PostListScrollView> createState() => _PostListScrollViewState();
}

class _PostListScrollViewState extends State<PostListScrollView> {
  late AnchorScrollController _scrollController;

  int _refresh = 0;

  void _addRefresh() => _refresh++;

  void _setScrollDirection() {
    if (_scrollController.hasClients) {
      PostListController.scrollDirection =
          _scrollController.position.userScrollDirection;
    }
  }

  void _setScrollController() {
    final autoHideAppBar = SettingsService.to.autoHideAppBar;

    _scrollController = widget.scrollController ??
        AnchorScrollController(
          initialScrollOffset:
              autoHideAppBar ? -PostListController.appBarHeight : 0.0,
          getAnchorOffset:
              autoHideAppBar ? () => widget.controller.headerHeight : null,
          onIndexChanged: (index, userScroll) =>
              widget.controller.page = index.getPageFromPostIndex(),
        );
  }

  @override
  void initState() {
    super.initState();

    _setScrollController();
    _scrollController.addListener(_setScrollDirection);

    widget.controller.scrollController = _scrollController;
    widget.controller.addListener(_addRefresh);
  }

  @override
  void didUpdateWidget(covariant PostListScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.scrollController != oldWidget.scrollController) {
      _scrollController.removeListener(_setScrollDirection);
      if (oldWidget.scrollController == null) {
        _scrollController.dispose();
      }

      _setScrollController();
      _scrollController.addListener(_setScrollDirection);
    }

    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_addRefresh);
      oldWidget.controller.scrollController = null;

      widget.controller.scrollController = _scrollController;
      widget.controller.addListener(_addRefresh);
    } else if (widget.scrollController != oldWidget.scrollController) {
      widget.controller.scrollController = _scrollController;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_addRefresh);
    widget.controller.scrollController = null;

    _scrollController.removeListener(_setScrollDirection);
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => NotifyBuilder(
      animation: widget.controller,
      builder: (context, child) =>
          widget.builder(context, _scrollController, _refresh));
}
