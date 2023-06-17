import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';

import '../data/services/settings.dart';

// TODO: 修复标题栏自动隐藏时切换页面的空隙bug
class PageViewTabBar extends StatefulWidget implements PreferredSizeWidget {
  static const animationDuration = kTabScrollDuration;

  static const double height = _height + indicatorWeight;

  static const double indicatorWeight = 2.0;

  static const double _height = 46.0;

  final PageController pageController;

  final int initialIndex;

  final Color? indicatorColor;

  /// [PageViewTabBar]的index变化时调用，参数是index
  final ValueChanged<int> onIndex;

  final List<Widget> tabs;

  @override
  Size get preferredSize {
    double maxHeight = _height;
    for (final item in tabs) {
      if (item is PreferredSizeWidget) {
        maxHeight = max(item.preferredSize.height, maxHeight);
      }
    }

    return Size.fromHeight(maxHeight + indicatorWeight);
  }

  const PageViewTabBar(
      {super.key,
      required this.pageController,
      required this.initialIndex,
      this.indicatorColor,
      required this.onIndex,
      required this.tabs});

  @override
  State<PageViewTabBar> createState() => _PageViewTabBarState();
}

class _PageViewTabBarState extends State<PageViewTabBar>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;

  void _onIndex() => widget.onIndex(_controller.index);

  void _setController() {
    if (!_controller.indexIsChanging) {
      final page = widget.pageController.page;
      if (page != null) {
        final index = page.truncateToDouble();
        if (index == page) {
          _controller.index = index.toInt();
          _controller.offset = 0.0;
        } else {
          if ((page - _controller.index).abs() >= 1.0) {
            _controller.index = page.round();
          }
          _controller.offset = (page - _controller.index).clamp(-1.0, 1.0);
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _controller = TabController(
        initialIndex: widget.initialIndex,
        animationDuration: PageViewTabBar.animationDuration,
        length: widget.tabs.length,
        vsync: this);

    widget.pageController.addListener(_setController);
    _controller.addListener(_onIndex);
  }

  @override
  void didUpdateWidget(covariant PageViewTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.pageController != oldWidget.pageController) {
      oldWidget.pageController.removeListener(_setController);
      widget.pageController.addListener(_setController);
    }
  }

  @override
  void dispose() {
    widget.pageController.removeListener(_setController);
    _controller.removeListener(_onIndex);
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TabBar(
      controller: _controller,
      indicatorColor: widget.indicatorColor,
      indicatorWeight: PageViewTabBar.indicatorWeight,
      tabs: widget.tabs);
}

class SwipeablePageView extends StatelessWidget {
  final PageController? controller;

  final int? itemCount;

  final IndexedWidgetBuilder itemBuilder;

  final RxBool _isScrollable = true.obs;

  SwipeablePageView(
      {super.key, this.controller, this.itemCount, required this.itemBuilder});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;
    final width = MediaQuery.sizeOf(context).width;

    // 手机上PageView能左右滑动换页
    return Obx(() => (settings.isSwipeablePageRx && GetPlatform.isMobile)
        ? Listener(
            onPointerDown: (event) {
              final route = ModalRoute.of(context);
              if (route is SwipeablePageRoute) {
                // 左边缘向右滑动为返回手势
                if (event.position.dx <=
                    width * settings.swipeablePageDragWidthRatio) {
                  route.canSwipe = true;
                  _isScrollable.value = false;
                } else {
                  route.canSwipe = false;
                }
              }
            },
            onPointerUp: (event) => _isScrollable.value = true,
            child: PageView.builder(
              controller: controller,
              physics: !_isScrollable.value
                  ? const NeverScrollableScrollPhysics()
                  : null,
              itemCount: itemCount,
              itemBuilder: itemBuilder,
            ),
          )
        : PageView.builder(
            controller: controller,
            itemCount: itemCount,
            itemBuilder: itemBuilder,
          ));
  }
}

class InfinitePageView extends StatefulWidget {
  final PageController controller;

  final ScrollPhysics? physics;

  final List<Widget> children;

  const InfinitePageView(
      {super.key,
      required this.controller,
      this.physics,
      required this.children})
      : assert(children.length > 1);

  @override
  State<InfinitePageView> createState() => _InfinitePageViewState();
}

class _InfinitePageViewState extends State<InfinitePageView> {
  PageController get _controller => widget.controller;

  List<Widget> get _children => widget.children;

  void _onPageChanged() {
    if (_controller.page == _children.length) {
      WidgetsBinding.instance
          .addPostFrameCallback((timeStamp) => _controller.jumpToPage(0));
    }
  }

  @override
  void initState() {
    super.initState();

    _controller.addListener(_onPageChanged);
  }

  @override
  void didUpdateWidget(covariant InfinitePageView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_onPageChanged);
      widget.controller.addListener(_onPageChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onPageChanged);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageView(
        controller: _controller,
        physics: widget.physics,
        allowImplicitScrolling: true,
        children: [..._children, _children.first],
      );
}
