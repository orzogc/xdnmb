import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/services/settings.dart';
import '../data/services/xdnmb_client.dart';
import '../modules/post_list.dart';
import '../routes/routes.dart';
import '../utils/theme.dart';
import 'buttons.dart';
import 'forum_list.dart';
import 'guide.dart';
import 'page_view.dart';
import 'tab_list.dart';

const double _drawerMaxWidth = 304.0;

class _DrawerHeader extends StatelessWidget {
  final bool isCompact;

  // ignore: unused_element
  const _DrawerHeader({super.key, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onPrimary;

    return SizedBox(
      height: PostListAppBar.height + MediaQuery.paddingOf(context).top,
      child: DrawerHeader(
        decoration: BoxDecoration(
          color: theme.appBarTheme.backgroundColor ?? theme.colorScheme.primary,
        ),
        margin: null,
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            if (!isCompact)
              Text(
                '霞岛',
                style: (theme.appBarTheme.titleTextStyle ??
                        theme.textTheme.titleLarge)
                    ?.apply(
                  color: theme.appBarTheme.foregroundColor ?? color,
                ),
              ),
            if (!isCompact) const Spacer(),
            const Flexible(child: DarkModeGuide(DarkModeButton())),
            Flexible(
              child: SearchGuide(
                SearchButton(iconColor: color, afterSearch: Get.back),
              ),
            ),
            Flexible(
              child: SettingsGuide(
                SettingsButton(iconColor: color, onTapPrelude: Get.back),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerBottom extends StatelessWidget {
  // ignore: unused_element
  const _DrawerBottom({super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const Flexible(child: SponsorButton()),
            Flexible(child: HistoryGuide(HistoryButton(onTapEnd: Get.back))),
            Flexible(child: FeedGuide(FeedButton(onTapEnd: Get.back))),
          ],
        ),
      );
}

class AppDrawer extends StatelessWidget {
  final double width;

  const AppDrawer({super.key, required this.width});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Obx(
      () => Drawer(
        width: settings.endDrawerSettingRx == 2
            ? min(width * 0.5, _drawerMaxWidth)
            : null,
        child: Column(
          children: [
            _DrawerHeader(isCompact: settings.endDrawerSettingRx == 2),
            Expanded(
              child: settings.endDrawerSettingRx == 1
                  ? TabList(onTapEnd: Get.back)
                  : ForumList(onTapEnd: Get.back),
            ),
            const Divider(height: 10.0, thickness: 1.0),
            const _DrawerBottom(),
            if (bottomPadding > 0.0) SizedBox(height: bottomPadding),
          ],
        ),
      ),
    );
  }
}

class _EndDrawerHeader extends StatelessWidget {
  // ignore: unused_element
  const _EndDrawerHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;
    final client = XdnmbClientService.to;
    final theme = Theme.of(context);
    final textStyle =
        (theme.appBarTheme.titleTextStyle ?? theme.textTheme.titleLarge)?.apply(
      color: theme.appBarTheme.foregroundColor ?? theme.colorScheme.onPrimary,
    );

    return SizedBox(
      width: double.infinity,
      height: PostListAppBar.height + MediaQuery.paddingOf(context).top,
      child: DrawerHeader(
        decoration: BoxDecoration(
          color: theme.appBarTheme.backgroundColor ?? theme.colorScheme.primary,
        ),
        margin: null,
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Obx(
          () => settings.endDrawerSettingRx == 1
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('版块', style: textStyle),
                    client.isReady.value
                        ? ReorderForumsGuide(
                            IconButton(
                              onPressed: AppRoutes.toReorderForums,
                              icon: Icon(
                                Icons.swap_vert,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ],
                )
              : Align(
                  alignment: Alignment.centerLeft,
                  child: Text('标签页', style: textStyle),
                ),
        ),
      ),
    );
  }
}

class _EndDrawerBottom extends StatelessWidget {
  // ignore: unused_element
  const _EndDrawerBottom({super.key});

  @override
  Widget build(BuildContext context) {
    final Widget historyButton = HistoryButton(
      iconPadding: PostListBottomBar.iconPadding,
      onTapEnd: Get.back,
    );
    final Widget feedButton = FeedButton(
      iconPadding: PostListBottomBar.iconPadding,
      onTapEnd: Get.back,
    );
    final Widget settingsButton = SettingsButton(
      iconPadding: PostListBottomBar.iconPadding,
      onTapPrelude: Get.back,
    );
    final Widget searchButton = SearchButton(
      iconPadding: PostListBottomBar.iconPadding,
      afterSearch: Get.back,
    );

    return SizedBox(
      height: PostListBottomBar.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Flexible(child: HistoryGuide(historyButton)),
          Flexible(child: FeedGuide(feedButton)),
          Flexible(child: SettingsGuide(settingsButton)),
          Flexible(child: SearchGuide(searchButton)),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final bool isActive;

  final double width;

  final String text;

  final VoidCallback onTap;

  const _Tab(
      // ignore: unused_element
      {super.key,
      this.isActive = false,
      required this.width,
      required this.text,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: theme.primaryColor,
        width: width,
        height: PostListAppBar.height,
        child: Center(
          child: Text(
            text,
            style: isActive
                ? theme.textTheme.titleLarge
                    ?.apply(color: theme.colorScheme.onPrimary)
                : theme.textTheme.titleMedium
                    ?.apply(color: AppTheme.inactiveSettingColor),
          ),
        ),
      ),
    );
  }
}

class _InfiniteTabList extends StatefulWidget {
  final PageController pageController;

  final double width;

  const _InfiniteTabList(
      // ignore: unused_element
      {super.key,
      required this.pageController,
      required this.width});

  @override
  State<_InfiniteTabList> createState() => _InfiniteTabListState();
}

class _InfiniteTabListState extends State<_InfiniteTabList> {
  late final ScrollController _controller;

  final RxInt _activeIndex = _TabAndForumListState._initialPage.obs;

  PageController get _pageController => widget.pageController;

  double get _width => widget.width;

  void _updatePosition() {
    final page = _pageController.page;
    if (page != null) {
      if (page == 2.0) {
        _controller.jumpTo(0.0);
        _activeIndex.value = 0;
      } else {
        _controller.jumpTo(0.5 * _width * page);
        _activeIndex.value = page.round();
      }
    }
  }

  void _animateToPage(int page) {
    page = page.clamp(0, 2);
    if (_pageController.page != page) {
      _pageController.animateToPage(page,
          duration: PageViewTabBar.animationDuration, curve: Curves.easeIn);
    }
  }

  @override
  void initState() {
    super.initState();

    _controller = ScrollController(
        initialScrollOffset: 0.5 * _width * _TabAndForumListState._initialPage);
    _pageController.addListener(_updatePosition);
  }

  @override
  void didUpdateWidget(covariant _InfiniteTabList oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.pageController != oldWidget.pageController) {
      oldWidget.pageController.removeListener(_updatePosition);
      widget.pageController.addListener(_updatePosition);
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_updatePosition);
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      elevation: PostListAppBar.defaultElevation,
      color: theme.primaryColor,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        controller: _controller,
        child: Obx(
          () => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Tab(
                isActive: _activeIndex.value == 0,
                width: _width * 0.5,
                text: '标签页',
                onTap: () => _animateToPage(0),
              ),
              _Tab(
                isActive: _activeIndex.value == 1,
                width: _width * 0.5,
                text: '版块',
                onTap: () => _animateToPage(1),
              ),
              _Tab(
                isActive: _activeIndex.value == 2,
                width: _width * 0.5,
                text: '标签页',
                onTap: () => _animateToPage(2),
              ),
              _Tab(
                isActive: _activeIndex.value == 3,
                width: _width * 0.5,
                text: '版块',
                onTap: () => {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabAndForumList extends StatefulWidget {
  final double? bottomPadding;

  // ignore: unused_element
  const _TabAndForumList({super.key, this.bottomPadding})
      : assert(bottomPadding == null || bottomPadding >= 0.0);

  @override
  State<_TabAndForumList> createState() => _TabAndForumListState();
}

class _TabAndForumListState extends State<_TabAndForumList> {
  static int _initialPage = 0;

  late final PageController _controller;

  final RxBool _isGoingLeft = false.obs;

  bool _toRebuild = false;

  final List<PointerDataPacket> _pointerDataPackets = [];

  PointerDataPacketCallback? _pointerDataPacketCallback;

  void _setRebuild(bool rebuild) {
    _isGoingLeft.value = rebuild;
    _toRebuild = rebuild;
  }

  void _onPageChanged() {
    final page = _controller.page;
    if (page != null) {
      if (page <= 1.0) {
        _initialPage = page.round();
      } else {
        _initialPage = 0;
      }
    }
  }

  void _handleRemainedPointerDataPacket() {
    if (_pointerDataPackets.isNotEmpty) {
      for (final dataPacket in _pointerDataPackets) {
        _pointerDataPacketCallback?.call(dataPacket);
      }

      _pointerDataPackets.clear();
    }
  }

  void _pointerDataCallback(PointerDataPacket packet) {
    if (_toRebuild) {
      _pointerDataPackets.add(packet);
    } else {
      _handleRemainedPointerDataPacket();

      _pointerDataPacketCallback?.call(packet);
    }
  }

  @override
  void initState() {
    super.initState();

    _controller = PageController(initialPage: _initialPage);
    _controller.addListener(_onPageChanged);

    _pointerDataPacketCallback =
        WidgetsBinding.instance.platformDispatcher.onPointerDataPacket;
    WidgetsBinding.instance.platformDispatcher.onPointerDataPacket =
        _pointerDataCallback;
  }

  @override
  void dispose() {
    _controller.removeListener(_onPageChanged);
    _controller.dispose();

    _handleRemainedPointerDataPacket();

    if (_pointerDataPacketCallback != null) {
      WidgetsBinding.instance.platformDispatcher.onPointerDataPacket =
          _pointerDataPacketCallback;
      _pointerDataPacketCallback = null;
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;
    final theme = Theme.of(context);
    final paddingTop = MediaQuery.paddingOf(context).top;

    return LayoutBuilder(
      builder: (context, constraints) => Obx(
        () => Column(
          children: [
            if (paddingTop > 0.0)
              Container(color: theme.primaryColor, height: paddingTop),
            _InfiniteTabList(
                pageController: _controller, width: constraints.maxWidth),
            Expanded(
              child: Listener(
                onPointerMove: (event) {
                  final delta = event.delta;
                  final page = _controller.page;
                  if (page != null &&
                      page - page.truncate() == 0.0 &&
                      delta.dx.abs() > delta.dy.abs() &&
                      delta.dx > 0.0 &&
                      !_isGoingLeft.value) {
                    _setRebuild(true);
                  }
                },
                onPointerUp: (event) => _setRebuild(false),
                onPointerCancel: (event) => _setRebuild(false),
                child: Obx(() {
                  if (_isGoingLeft.value && _toRebuild) {
                    _toRebuild = false;
                  }

                  return InfinitePageView(
                    controller: _controller,
                    physics: _isGoingLeft.value
                        ? const NeverScrollableScrollPhysics()
                        : const ClampingScrollPhysics(),
                    children: [
                      TabList(
                        bottomPadding: settings.hasBottomBarRx
                            ? widget.bottomPadding
                            : null,
                        onTapEnd: Get.back,
                      ),
                      ForumList(
                        bottomPadding: settings.hasBottomBarRx
                            ? widget.bottomPadding
                            : null,
                        onTapEnd: Get.back,
                      ),
                    ],
                  );
                }),
              ),
            ),
            if (!settings.hasBottomBarRx)
              const Divider(height: 10.0, thickness: 1.0),
            if (!settings.hasBottomBarRx) const _EndDrawerBottom(),
            if (!settings.hasBottomBarRx &&
                widget.bottomPadding != null &&
                widget.bottomPadding! > 0.0)
              SizedBox(height: widget.bottomPadding),
          ],
        ),
      ),
    );
  }
}

class AppEndDrawer extends StatefulWidget {
  final double width;

  const AppEndDrawer({super.key, required this.width});

  @override
  State<AppEndDrawer> createState() => _AppEndDrawerState();
}

class _AppEndDrawerState extends State<AppEndDrawer> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback((timeStamp) => PostListBottomBar.toHide = true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance
        .addPostFrameCallback((timeStamp) => PostListBottomBar.toHide = false);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;
    final padding = MediaQuery.paddingOf(context);
    final bottomPadding = padding.bottom > 0.0 ? padding.bottom : null;

    return Obx(
      () => Drawer(
        width: settings.endDrawerSettingRx == 1
            ? min(widget.width * 0.5, _drawerMaxWidth)
            : null,
        child: settings.endDrawerSettingRx != 3
            ? Column(
                children: [
                  const _EndDrawerHeader(),
                  Expanded(
                    child: settings.endDrawerSettingRx == 1
                        ? ForumList(
                            bottomPadding: bottomPadding, onTapEnd: Get.back)
                        : (settings.endDrawerSettingRx == 2
                            ? TabList(
                                bottomPadding: bottomPadding,
                                onTapEnd: Get.back)
                            : const SizedBox.shrink()),
                  ),
                ],
              )
            : _TabAndForumList(bottomPadding: bottomPadding),
      ),
    );
  }
}
