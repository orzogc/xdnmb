import 'dart:async';

import 'package:anchor_scroll_controller/anchor_scroll_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/state_manager.dart';

import '../data/services/settings.dart';
import '../modules/post_list.dart';
import '../utils/extensions.dart';
import '../utils/notify.dart';

class _PostListScrollPosition extends ScrollPositionWithSingleContext {
  final PostListController controller;

  bool _isShowing = false;

  bool _isHiding = false;

  _PostListScrollPosition(
      {required this.controller,
      required super.physics,
      required super.context,
      super.initialPixels = 0.0,
      super.keepScrollOffset = true,
      super.oldPosition,
      super.debugLabel});

  @override
  void updateUserScrollDirection(ScrollDirection value) {
    super.updateUserScrollDirection(value);

    PostListController.scrollDirection = value;
  }

  @override
  void applyUserOffset(double delta) {
    if (SettingsService.isAutoHideAppBar) {
      updateUserScrollDirection(
          delta > 0.0 ? ScrollDirection.forward : ScrollDirection.reverse);
      final offset = physics.applyPhysicsToUserOffset(this, delta);

      switch (controller.scrollState) {
        case PostListScrollState.outOfMinScrollExtent:
          final topPostition = pixels - minScrollExtent - offset;
          if (controller.headerHeight > 0.0 &&
              topPostition >= 0.0 &&
              topPostition <= controller.headerHeight) {
            controller.scrollState = PostListScrollState.inAppBarRange;
            controller.setAppBarHeight(controller.headerHeight - topPostition);
            setPixels(minScrollExtent);
          } else if (topPostition > controller.headerHeight) {
            controller.scrollState = PostListScrollState.outOfAppBarRange;
            controller.setAppBarHeight(0);
            setPixels(pixels - offset - controller.headerHeight);
          } else {
            final overscroll = setPixels(pixels - offset);
            // 为了能够切换`ScrollPhysics`
            if (overscroll < 0.0) {
              notifyListeners();
            }
          }

          break;
        case PostListScrollState.inAppBarRange:
          final height = controller.headerHeight + offset;

          if (height >= 0.0 && height <= PostListAppBar.height) {
            controller.setAppBarHeight(height);
            //setPixels(minScrollExtent + PostListAppBar.height - height);
          } else if (height < 0.0) {
            controller.scrollState = PostListScrollState.outOfAppBarRange;
            controller.setAppBarHeight(0.0);
            setPixels(pixels - offset);
          } else {
            controller.scrollState = PostListScrollState.outOfMinScrollExtent;
            controller.setAppBarHeight(PostListAppBar.height);
            // 这里可能不准确
            setPixels(pixels + PostListAppBar.height - height);
          }

          break;
        case PostListScrollState.outOfAppBarRange:
          if (offset < 0.0) {
            final topPostition = pixels - minScrollExtent - offset;

            if (controller.headerHeight > 0.0 &&
                topPostition >= 0.0 &&
                topPostition <= controller.headerHeight) {
              controller.scrollState = PostListScrollState.inAppBarRange;
              controller
                  .setAppBarHeight(controller.headerHeight - topPostition);
              setPixels(minScrollExtent);
            } else if (topPostition < 0.0) {
              // 一般不会有这种情况
              controller.scrollState = PostListScrollState.outOfAppBarRange;
              setPixels(pixels - offset);
            } else {
              if (controller.headerHeight > 0.0 && !_isHiding) {
                _isHiding = true;
                PostListController.hideAppBar(() => _isHiding = false);
              }

              setPixels(pixels - offset);
            }
          } else if (offset > 0.0) {
            final topPostition = pixels - minScrollExtent - offset;
            if (topPostition >= 0.0 && topPostition <= PostListAppBar.height) {
              setPixels(pixels - offset);
            } else if (topPostition < 0.0) {
              if (PostListAppBar.height - controller.headerHeight >=
                  -topPostition) {
                controller.scrollState = PostListScrollState.inAppBarRange;
                controller
                    .setAppBarHeight(controller.headerHeight - topPostition);
                setPixels(minScrollExtent);
              } else {
                controller.scrollState =
                    PostListScrollState.outOfMinScrollExtent;
                controller.setAppBarHeight(PostListAppBar.height);
                setPixels(minScrollExtent +
                    topPostition +
                    PostListAppBar.height -
                    controller.headerHeight);
              }
            } else {
              if (controller.headerHeight < PostListAppBar.height &&
                  !_isShowing) {
                _isShowing = true;
                PostListController.showAppBar(() => _isShowing = false);
              }

              setPixels(pixels - offset);
            }
          }

          break;
      }
    } else {
      super.applyUserOffset(delta);
    }
  }
}

class PostListScrollController extends AnchorScrollController {
  final PostListController controller;

  PostListScrollController(
      {required this.controller,
      super.initialScrollOffset = 0.0,
      super.keepScrollOffset = true,
      super.debugLabel,
      super.onIndexChanged,
      super.fixedItemSize,
      super.anchorOffset});

  @override
  ScrollPosition createScrollPosition(ScrollPhysics physics,
          ScrollContext context, ScrollPosition? oldPosition) =>
      _PostListScrollPosition(
        controller: controller,
        physics: physics,
        context: context,
        initialPixels: initialScrollOffset,
        keepScrollOffset: keepScrollOffset,
        oldPosition: oldPosition,
        debugLabel: debugLabel,
      );
}

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

  late double _headerHeight;

  late StreamSubscription<double> _headerHeightSubscription;

  void _addRefresh() => _refresh++;

  void _correctScrollOffset(double offset) {
    if (_scrollController.hasClients) {
      _scrollController.position
          .correctPixels(_scrollController.offset + offset);
    }
  }

  void _setScrollOffset(double height) {
    if (height != _headerHeight) {
      if (widget.controller.scrollState.isOutOfAppBarRange) {
        _correctScrollOffset(height - _headerHeight);
      }

      _headerHeight = height;
    }
  }

  void _setScrollController() {
    _scrollController = widget.scrollController ??
        PostListScrollController(
          controller: widget.controller,
          onIndexChanged: (index, userScroll) =>
              widget.controller.page = index.getPageFromPostIndex(),
        );
  }

  void _updateScrollState() {
    if (_scrollController.hasClients) {
      final position = _scrollController.position;
      final topPostition = position.pixels - position.minScrollExtent;
      if (topPostition >= 0.0 && topPostition <= PostListAppBar.height) {
        widget.controller.scrollState = PostListScrollState.inAppBarRange;
      } else if (topPostition < 0.0) {
        widget.controller.scrollState =
            PostListScrollState.outOfMinScrollExtent;
      } else {
        widget.controller.scrollState = PostListScrollState.outOfAppBarRange;
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _setScrollController();
    _headerHeight = widget.controller.headerHeight;

    widget.controller.addListener(_addRefresh);
    _headerHeightSubscription =
        widget.controller.listenHeaderHeight(_setScrollOffset);
    widget.controller.correctScrollOffset = _correctScrollOffset;
    widget.controller.updateScrollState = _updateScrollState;
  }

  @override
  void didUpdateWidget(covariant PostListRefresher oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_addRefresh);
      _headerHeightSubscription.cancel();
      oldWidget.controller.correctScrollOffset = null;
      oldWidget.controller.updateScrollState = null;

      _headerHeight = widget.controller.headerHeight;
      widget.controller.addListener(_addRefresh);
      _headerHeightSubscription =
          widget.controller.listenHeaderHeight(_setScrollOffset);
      widget.controller.correctScrollOffset = _correctScrollOffset;
      widget.controller.updateScrollState = _updateScrollState;
    }

    if (widget.scrollController != oldWidget.scrollController) {
      if (oldWidget.scrollController == null) {
        _scrollController.dispose();
      }

      _setScrollController();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_addRefresh);
    _headerHeightSubscription.cancel();
    widget.controller.correctScrollOffset = null;
    widget.controller.updateScrollState = null;

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

class PostListHeader extends StatelessWidget {
  final PostListController controller;

  const PostListHeader({super.key, required this.controller});

  @override
  Widget build(BuildContext context) =>
      Obx(() => (SettingsService.isAutoHideAppBar &&
              controller.scrollState.isInAppBarRange)
          ? SizedBox(height: PostListAppBar.height - controller.headerHeight)
          : const SizedBox.shrink());
}
