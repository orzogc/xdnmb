import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';

import '../data/services/settings.dart';

typedef OnIndexCallback = void Function(int index);

class PageViewTabBar extends StatefulWidget implements PreferredSizeWidget {
  static const animationDuration = kTabScrollDuration;

  static const double _height = 46.0;

  final PageController pageController;

  final int initialIndex;

  final double indicatorWeight;

  final OnIndexCallback onIndex;

  final List<Widget> tabs;

  @override
  Size get preferredSize {
    double maxHeight = _height;
    for (final Widget item in tabs) {
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
      this.indicatorWeight = 2,
      required this.onIndex,
      required this.tabs})
      : assert(indicatorWeight > 0.0);

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
      indicatorWeight: widget.indicatorWeight,
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
    final media = MediaQuery.of(context);

    return (SettingsService.isBackdropUI && GetPlatform.isMobile)
        ? Listener(
            onPointerDown: (event) {
              final route = ModalRoute.of(context);
              if (route is SwipeablePageRoute) {
                if (controller?.page == 0.0 &&
                    event.position.dx <=
                        media.size.width *
                            SettingsService.to.swipeablePageDragWidthRatio) {
                  route.canSwipe = true;
                  _isScrollable.value = false;
                } else {
                  route.canSwipe = false;
                }
              }
            },
            onPointerUp: (event) => _isScrollable.value = true,
            child: Obx(
              () => PageView.builder(
                controller: controller,
                physics: !_isScrollable.value
                    ? const NeverScrollableScrollPhysics()
                    : null,
                itemCount: itemCount,
                itemBuilder: itemBuilder,
              ),
            ),
          )
        : PageView.builder(
            controller: controller,
            itemCount: itemCount,
            itemBuilder: itemBuilder,
          );
  }
}
