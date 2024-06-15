import 'package:anchor_scroll_controller/anchor_scroll_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/services/settings.dart';
import '../modules/post_list.dart';
import '../utils/extensions.dart';
import 'listenable.dart';
import 'size.dart';

class PostHeader extends StatelessWidget {
  final List<Widget> children;

  const PostHeader({super.key, required this.children});

  @override
  Widget build(BuildContext context) => Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 5.0,
        runSpacing: 5.0,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      );
}

class PostListHeader extends StatelessWidget {
  final ValueChanged<Size>? onSize;

  final Widget child;

  const PostListHeader({super.key, this.onSize, required this.child});

  @override
  Widget build(BuildContext context) => ChildSizeNotifier(
        builder: (context, size, _) {
          WidgetsBinding.instance
              .addPostFrameCallback((timeStamp) => onSize?.call(size));

          return Material(elevation: 2.0, child: child);
        },
      );
}

class PostListScrollController extends AnchorScrollController {
  final ValueGetter<double>? getInitialScrollOffset;

  @override
  double get initialScrollOffset =>
      getInitialScrollOffset?.call() ?? super.initialScrollOffset;

  PostListScrollController(
      {this.getInitialScrollOffset,
      super.initialScrollOffset,
      super.getAnchorOffset,
      super.onIndexChanged});

  PostListScrollController.fromPostListController(PostListController controller)
      : this(
          getInitialScrollOffset: () => SettingsService.to.autoHideAppBar
              ? -controller.appBarHeight
              : 0.0,
          getAnchorOffset: () =>
              SettingsService.to.autoHideAppBar ? controller.appBarHeight : 0.0,
          onIndexChanged: (index, userScroll) =>
              controller.page = index.pageFromPostIndex,
        );
}

typedef PostListScrollViewBuilder = Widget Function(BuildContext context,
    PostListScrollController scrollController, int refresh);

class PostListScrollView extends StatefulWidget {
  final PostListController controller;

  /// 不为`null`时需要自行设置 [controller] 的`scrollController`为这个 [scrollController]
  final PostListScrollController? scrollController;

  final VoidCallback? onRefresh;

  final PostListScrollViewBuilder builder;

  const PostListScrollView(
      {super.key,
      required this.controller,
      this.scrollController,
      this.onRefresh,
      required this.builder});

  @override
  State<PostListScrollView> createState() => _PostListScrollViewState();
}

class _PostListScrollViewState extends State<PostListScrollView> {
  late PostListScrollController _scrollController;

  int _refresh = 0;

  void _addRefresh() {
    widget.onRefresh?.call();

    _refresh++;
  }

  void _setScrollDirection() {
    if (_scrollController.hasClients) {
      PostListController.scrollDirection =
          _scrollController.position.userScrollDirection;
    }
  }

  void _setScrollController() => _scrollController = widget.scrollController ??
      PostListScrollController.fromPostListController(widget.controller);

  @override
  void initState() {
    super.initState();

    _setScrollController();
    _scrollController.addListener(_setScrollDirection);

    if (widget.scrollController == null) {
      widget.controller.scrollController = _scrollController;
    }
    widget.controller.addListener(_addRefresh);
  }

  @override
  void didUpdateWidget(covariant PostListScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.scrollController != oldWidget.scrollController) {
      _scrollController.removeListener(_setScrollDirection);
      if (oldWidget.scrollController == null) {
        oldWidget.controller.scrollController = null;
        _scrollController.dispose();
      }

      _setScrollController();
      _scrollController.addListener(_setScrollDirection);
      if (widget.scrollController == null) {
        widget.controller.scrollController = _scrollController;
      }
    }

    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_addRefresh);
      if (oldWidget.scrollController == null) {
        oldWidget.controller.scrollController = null;
      }

      if (widget.scrollController == null) {
        widget.controller.scrollController = _scrollController;
      }
      widget.controller.addListener(_addRefresh);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_addRefresh);
    _scrollController.removeListener(_setScrollDirection);
    if (widget.scrollController == null) {
      widget.controller.scrollController = null;
      _scrollController.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenBuilder(
      listenable: widget.controller,
      builder: (context, child) =>
          widget.builder(context, _scrollController, _refresh));
}

class PostListWithTabBarOrHeader extends StatelessWidget {
  final PostListController controller;

  final ValueGetter<double>? tabBarHeight;

  final Widget? tabBar;

  final ValueGetter<double>? headerHeight;

  final Widget? header;

  final Widget postList;

  const PostListWithTabBarOrHeader(
      {super.key,
      required this.controller,
      this.tabBarHeight,
      this.tabBar,
      this.headerHeight,
      this.header,
      required this.postList})
      : assert((tabBarHeight != null && tabBar != null) ||
            (tabBarHeight == null && tabBar == null)),
        assert((headerHeight != null && header != null) ||
            (headerHeight == null && header == null));

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;
    final theme = Theme.of(context);
    final dumb = false.obs;

    final Widget? tabBarWidget = tabBar != null
        ? Material(
            elevation:
                theme.appBarTheme.elevation ?? PostListAppBar.defaultElevation,
            color: theme.primaryColor,
            child: tabBar,
          )
        : null;

    return Stack(
      children: [
        (tabBarWidget != null || header != null)
            ? Obx(
                () {
                  // 为了 Obx 不崩溃
                  dumb.value;

                  return Padding(
                    padding: EdgeInsets.only(
                        top: (tabBarHeight?.call() ?? 0.0) +
                            (headerHeight?.call() ?? 0.0)),
                    child: postList,
                  );
                },
              )
            : postList,
        if (header != null)
          Obx(
            () => Positioned(
              left: 0.0,
              top: (settings.autoHideAppBarRx ? controller.appBarHeight : 0.0) +
                  (tabBarHeight?.call() ?? 0.0),
              right: 0.0,
              child: header!,
            ),
          ),
        if (tabBarWidget != null)
          Obx(
            () => settings.autoHideAppBarRx
                ? Positioned(
                    left: 0.0,
                    top: controller.appBarHeight,
                    right: 0.0,
                    child: tabBarWidget,
                  )
                : tabBarWidget,
          ),
      ],
    );
  }
}
