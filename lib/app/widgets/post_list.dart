import 'package:anchor_scroll_controller/anchor_scroll_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/state_manager.dart';

import '../data/services/settings.dart';
import '../modules/post_list.dart';
import '../utils/extensions.dart';
import '../utils/notify.dart';

typedef PostListRefresherBuilder = Widget Function(
    BuildContext context, ScrollController scrollController, int refresh);

class PostListRefresher extends StatefulWidget {
  final PostListController controller;

  final ScrollController? scrollController;

  final bool useAnchorScrollController;

  final PostListRefresherBuilder builder;

  const PostListRefresher(
      {super.key,
      required this.controller,
      this.scrollController,
      this.useAnchorScrollController = false,
      required this.builder});

  @override
  State<PostListRefresher> createState() => _PostListRefresherState();
}

class _PostListRefresherState extends State<PostListRefresher> {
  late ScrollController _scrollController;

  int _refresh = 0;

  void _addRefresh() => _refresh++;

  void _setScrollDirection() {
    if (_scrollController.hasClients) {
      PostListController.scrollDirection =
          _scrollController.position.userScrollDirection;
    }
  }

  void _setScrollController() {
    _scrollController = widget.scrollController ??
        (widget.useAnchorScrollController
            ? AnchorScrollController(
                initialScrollOffset:
                    PostListAppBar.height - widget.controller.headerHeight,
                onIndexChanged: (index, userScroll) =>
                    widget.controller.page = index.getPageFromPostIndex(),
              )
            : ScrollController(
                initialScrollOffset:
                    PostListAppBar.height - widget.controller.headerHeight));
    _scrollController.addListener(_setScrollDirection);
  }

  @override
  void initState() {
    super.initState();

    _setScrollController();

    widget.controller.addListener(_addRefresh);
  }

  @override
  void didUpdateWidget(covariant PostListRefresher oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.scrollController != oldWidget.scrollController) {
      _scrollController.removeListener(_setScrollDirection);
      if (oldWidget.scrollController == null) {
        _scrollController.dispose();
      }

      _setScrollController();
    }

    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_addRefresh);
      widget.controller.addListener(_addRefresh);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_setScrollDirection);
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }

    widget.controller.removeListener(_addRefresh);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => NotifyBuilder(
      animation: widget.controller,
      builder: (context, child) =>
          widget.builder(context, _scrollController, _refresh));
}

class _Anchor extends StatefulWidget {
  final PostListController controller;

  final ScrollController scrollController;

  const _Anchor(
      // ignore: unused_element
      {super.key,
      required this.controller,
      required this.scrollController});

  @override
  State<_Anchor> createState() => _AnchorState();
}

class _AnchorState extends State<_Anchor> {
  void _setAppBarHeight() {
    if (mounted &&
        widget.scrollController.hasClients &&
        widget.scrollController.position.userScrollDirection !=
            ScrollDirection.idle) {
      final renderBox = context.findRenderObject();
      final viewport = RenderAbstractViewport.of(renderBox);
      if (renderBox != null && viewport != null) {
        final offset = viewport.getOffsetToReveal(renderBox, 0);

        final height = widget.scrollController.position.pixels - offset.offset;
        if (height >= 0 && height <= PostListAppBar.height) {
          widget.controller.appBarHeight = PostListAppBar.height - height;
        } else {
          widget.controller.appBarHeight = null;
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();

    widget.scrollController.addListener(_setAppBarHeight);
  }

  @override
  void didUpdateWidget(covariant _Anchor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.scrollController != oldWidget.scrollController) {
      oldWidget.scrollController.removeListener(_setAppBarHeight);
      widget.scrollController.addListener(_setAppBarHeight);
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_setAppBarHeight);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class PostListHeader extends StatelessWidget {
  final PostListController controller;

  final ScrollController scrollController;

  const PostListHeader(
      {super.key, required this.controller, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return Obx(() {
      final height = controller.appBarHeight;

      return settings.isAutoHideAppBar
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (height != null)
                  SizedBox(
                      height: PostListAppBar.height - controller.headerHeight),
                _Anchor(
                    controller: controller, scrollController: scrollController),
              ],
            )
          : const SizedBox.shrink();
    });
  }
}
