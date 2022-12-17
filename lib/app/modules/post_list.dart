import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_swipe_detector/flutter_swipe_detector.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:showcaseview/showcaseview.dart';

import '../data/models/controller.dart';
import '../data/models/draft.dart';
import '../data/models/forum.dart';
import '../data/services/blacklist.dart';
import '../data/services/draft.dart';
import '../data/services/emoticon.dart';
import '../data/services/forum.dart';
import '../data/services/persistent.dart';
import '../data/services/history.dart';
import '../data/services/settings.dart';
import '../data/services/stack.dart';
import '../data/services/user.dart';
import '../data/services/version.dart';
import '../data/services/xdnmb_client.dart';
import '../modules/edit_post.dart';
import '../routes/routes.dart';
import '../utils/extensions.dart';
import '../utils/image.dart';
import '../utils/navigation.dart';
import '../utils/notify.dart';
import '../utils/padding.dart';
import '../utils/theme.dart';
import '../utils/toast.dart';
import '../widgets/backdrop.dart';
import '../widgets/buttons.dart';
import '../widgets/drawer.dart';
import '../widgets/edit_post.dart';
import '../widgets/end_drawer.dart';
import '../widgets/feed.dart';
import '../widgets/forum.dart';
import '../widgets/forum_list.dart';
import '../widgets/guide.dart';
import '../widgets/history.dart';
import '../widgets/page.dart';
import '../widgets/safe_area.dart';
import '../widgets/scroll.dart';
import '../widgets/tab_list.dart';
import '../widgets/thread.dart';

const Duration _animationDuration = Duration(milliseconds: 200);

class PostList {
  final PostListType postListType;

  final int? id;

  const PostList({required this.postListType, this.id});

  PostList.fromController(PostListController controller)
      : this(postListType: controller.postListType, id: controller.id);

  PostList.fromForumData(ForumData forum)
      : this(
            postListType:
                forum.isTimeline ? PostListType.timeline : PostListType.forum,
            id: forum.id);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PostList &&
          postListType == other.postListType &&
          id == other.id);

  @override
  int get hashCode => Object.hash(postListType, id);
}

enum PostListScrollState {
  outOfMinScrollExtent,
  inAppBarRange,
  outOfAppBarRange;

  bool get isOutOfMinScrollExtent => this == outOfMinScrollExtent;

  bool get isInAppBarRange => this == inAppBarRange;

  bool get isOutOfAppBarRange => this == outOfAppBarRange;
}

typedef OnPageCallback = void Function(int page);

typedef OnHeightCallback = void Function(double height);

typedef OnOffsetCallback = void Function(double offset);

typedef AppBarCallback = void Function([VoidCallback? callback]);

typedef GetPositionCallback = double? Function();

abstract class PostListController extends ChangeNotifier {
  static final Rx<ScrollDirection> _scrollDirection = Rx(ScrollDirection.idle);

  static final RxBool _scrollingDown = false.obs;

  static final RxDouble _appBarHeight = PostListAppBar.height.obs;

  static AppBarCallback? _showAppBar;

  static AppBarCallback? _hideAppBar;

  static VoidCallback? _stopAppBarAnimation;

  static set scrollDirection(ScrollDirection direction) {
    _scrollDirection.value = direction;

    switch (direction) {
      case ScrollDirection.forward:
        _scrollingDown.value = false;
        break;
      case ScrollDirection.reverse:
        _scrollingDown.value = true;
        break;
      default:
    }
  }

  static bool get isScrollingDown => _scrollingDown.value;

  static double get appBarHeight => _appBarHeight.value;

  static void showAppBar([VoidCallback? callback]) {
    if (_showAppBar != null) {
      _showAppBar!(callback);
    }
  }

  static void hideAppBar([VoidCallback? callback]) {
    if (_hideAppBar != null) {
      _hideAppBar!(callback);
    }
  }

  static void stopAppBarAnimation() {
    if (_stopAppBarAnimation != null) {
      _stopAppBarAnimation!();
    }
  }

  final RxInt _page;

  VoidCallback? save;

  bool _isDisposed = false;

  final Rx<PostListScrollState> _scrollState =
      Rx(PostListScrollState.inAppBarRange);

  final RxDouble _headerHeight = appBarHeight.obs;

  OnHeightCallback? _setAppBarHeight;

  OnOffsetCallback? correctScrollOffset;

  GetPositionCallback? getTopPosition;

  PostListType get postListType;

  int? get id;

  int get page => _page.value;

  set page(int page) => _page.value = page;

  PostListScrollState get scrollState => _scrollState.value;

  set scrollState(PostListScrollState status) => _scrollState.value = status;

  double get headerHeight =>
      _headerHeight.value.clamp(0.0, PostListAppBar.height);

  set headerHeight(double height) {
    final height_ = height.clamp(0.0, PostListAppBar.height);
    _headerHeight.value = height_;
    _appBarHeight.value = height_;
  }

  double? get topPosition => getTopPosition != null ? getTopPosition!() : null;

  bool get isThread => postListType.isThread;

  bool get isOnlyPoThread => postListType.isOnlyPoThread;

  bool get isForum => postListType.isForum;

  bool get isTimeline => postListType.isTimeline;

  bool get isFeed => postListType.isFeed;

  bool get isHistory => postListType.isHistory;

  bool get isThreadType => postListType.isThreadType;

  bool get isForumType => postListType.isForumType;

  bool get hasForumId => postListType.hasForumId;

  bool get canPost => postListType.canPost;

  bool get isXdnmbApi => postListType.isXdnmbApi;

  int? get forumOrTimelineId => isThreadType
      ? (this as ThreadTypeController).post?.forumId
      : (isForumType ? id : null);

  int? get forumId => hasForumId ? forumOrTimelineId : null;

  PostListController(int page) : _page = page.obs;

  static PostListController get([int? index]) =>
      ControllerStacksService.to.getController(index);

  void refresh() {
    if (!_isDisposed) {
      notifyListeners();
    } else {
      debugPrint(
          'PostListController\'s refresh() is called after being disposed');
    }
  }

  void refreshPage([int page = 1]) {
    this.page = page;
    refresh();
  }

  void trySave() {
    if (save != null) {
      save!();
    }
  }

  void setAppBarHeight(double height) {
    if (_setAppBarHeight != null) {
      _setAppBarHeight!(height);
    }
  }

  void jumpToOffset(double offset) {
    if (correctScrollOffset != null) {
      correctScrollOffset!(offset);
    }
  }

  StreamSubscription<int> listenPage(OnPageCallback onPage) =>
      _page.listen(onPage);

  StreamSubscription<double> listenHeaderHeight(
          OnHeightCallback onHeaderHeight) =>
      _headerHeight.listen(onHeaderHeight);

  @override
  void dispose() {
    _isDisposed = true;

    super.dispose();
  }

  @override
  void addListener(VoidCallback listener) {
    if (!_isDisposed) {
      super.addListener(listener);
    } else {
      debugPrint(
          'PostListController\'s addListener() is called after being disposed');
    }
  }
}

class PostListBinding implements Bindings {
  @override
  void dependencies() {
    final uri = Uri.parse(Get.currentRoute);

    late final PostListController controller;
    switch (uri.path) {
      case AppRoutes.thread:
        controller = threadController(Get.parameters, Get.arguments);
        break;
      case AppRoutes.onlyPoThread:
        controller = onlyPoThreadController(Get.parameters, Get.arguments);
        break;
      case AppRoutes.forum:
        controller = forumController(Get.parameters);
        break;
      case AppRoutes.timeline:
        controller = timelineController(Get.parameters);
        break;
      case AppRoutes.feed:
        controller = feedController(Get.parameters);
        break;
      case AppRoutes.history:
        controller = historyController(Get.parameters);
        break;
      default:
        throw '未知URI: $uri';
    }

    final stacks = ControllerStacksService.to;
    if (stacks.isReady.value && stacks.length >= 1) {
      stacks.pushController(controller);
    }
  }
}

// TODO: AppBar动画
class PostListAppBar extends StatelessWidget implements PreferredSizeWidget {
  static const double height = kToolbarHeight;

  static const double defaultElevation = 4.0;

  static BottomSheetController get _tabAndForumListController =>
      BottomSheetController._tabAndForumListController;

  static BackdropController get _backdropController =>
      BackdropController.controller;

  const PostListAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final stacks = ControllerStacksService.to;
    final settings = SettingsService.to;

    return NotifyBuilder(
      animation: stacks.notifier,
      builder: (context, child) {
        final controller = PostListController.get();

        final Widget button = IconButton(
            tooltip: '菜单',
            icon: const Icon(Icons.menu),
            onPressed: () {
              if (SettingsService.isBackdropUI) {
                _backdropController.showBackLayer();
              } else if (SettingsService.isShowBottomBar &&
                  !_tabAndForumListController.isShowed) {
                _tabAndForumListController.show();
              } else {
                Scaffold.of(context).openDrawer();
              }
            });

        late final Widget title;
        switch (controller.postListType) {
          case PostListType.thread:
          case PostListType.onlyPoThread:
            final mainPost = (controller as ThreadTypeController).post;
            // 检查主串或饼干有没有被屏蔽
            if (mainPost != null && mainPost.isBlocked()) {
              WidgetsBinding.instance
                  .addPostFrameCallback((timeStamp) => controller.refresh());
            }

            title = ThreadAppBarTitle(controller);
            break;
          case PostListType.forum:
          case PostListType.timeline:
            title = ForumAppBarTitle(controller as ForumTypeController);
            break;
          case PostListType.feed:
            title = const FeedAppBarTitle();
            break;
          case PostListType.history:
            title = HistoryAppBarTitle(controller as HistoryController);
            break;
        }

        return Obx(() {
          final Widget appBar = GestureDetector(
            onTap: (SettingsService.isBackdropUI &&
                    (_backdropController.isShowBackLayer))
                ? _backdropController.toggleFrontLayer
                : (!_tabAndForumListController.isShowed
                    ? (controller.isThreadType
                        ? controller.refresh
                        : controller.refreshPage)
                    : null),
            onDoubleTap: SettingsService.isBackdropUI
                ? _backdropController.toggleFrontLayer
                : (SettingsService.isShowBottomBar
                    ? _tabAndForumListController.toggle
                    : null),
            child: AppBar(
              primary: !(_backdropController.isShowBackLayer ||
                  SettingsService.isAutoHideAppBar),
              elevation:
                  (SettingsService.isAutoHideAppBar || controller.isHistory)
                      ? 0.0
                      : null,
              leading: !(_backdropController.isShowBackLayer ||
                      _tabAndForumListController.isShowed)
                  ? (stacks.controllersCount() > 1
                      ? const BackButton(onPressed: postListPop)
                      : (settings.shouldShowGuide
                          ? AppBarMenuGuide(button)
                          : button))
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _tabAndForumListController.isShowed
                          ? _tabAndForumListController.close
                          : _backdropController.hideBackLayer),
              title: settings.shouldShowGuide ? AppBarTitleGuide(title) : title,
              actions: !(_backdropController.isShowBackLayer ||
                      _tabAndForumListController.isShowed)
                  ? [
                      if (controller.isXdnmbApi)
                        settings.shouldShowGuide
                            ? AppBarPageButtonGuide(
                                PageButton(controller: controller))
                            : PageButton(controller: controller),
                      if (controller.isThreadType)
                        NotifyBuilder(
                            animation: controller,
                            builder: (context, child) =>
                                settings.shouldShowGuide
                                    ? AppBarPopupMenuGuide(
                                        ThreadAppBarPopupMenuButton(
                                            controller as ThreadTypeController))
                                    : ThreadAppBarPopupMenuButton(
                                        controller as ThreadTypeController)),
                      if (controller.isForumType)
                        settings.shouldShowGuide
                            ? AppBarPopupMenuGuide(ForumAppBarPopupMenuButton(
                                controller as ForumTypeController))
                            : ForumAppBarPopupMenuButton(
                                controller as ForumTypeController),
                      if (controller.isHistory)
                        HistoryDateRangePicker(controller as HistoryController),
                      if (controller.isHistory)
                        settings.shouldShowGuide
                            ? AppBarPopupMenuGuide(HistoryAppBarPopupMenuButton(
                                controller as HistoryController))
                            : HistoryAppBarPopupMenuButton(
                                controller as HistoryController),
                    ]
                  : const [SizedBox.shrink()],
            ),
          );

          return SettingsService.isAutoHideAppBar
              ? SizedBox(
                  height: height,
                  child: _AnimatedAppBar(controller: controller, child: appBar))
              : appBar;
        });
      },
    );
  }
}

class _AnimatedAppBar extends StatefulWidget {
  final PostListController controller;

  final Widget child;

  const _AnimatedAppBar(
      // ignore: unused_element
      {super.key,
      required this.controller,
      required this.child});

  @override
  State<_AnimatedAppBar> createState() => _AnimatedAppBarState();
}

class _AnimatedAppBarState extends State<_AnimatedAppBar>
    with SingleTickerProviderStateMixin<_AnimatedAppBar> {
  late final AnimationController _animationController;

  late final Animation<Offset> _slideAnimation;

  late final StreamSubscription<bool> _backdropSubscription;

  double get _height =>
      (_animationController.upperBound - _animationController.value) *
      PostListAppBar.height;

  set _height(double height) => _animationController.value =
      (PostListAppBar.height - height) / PostListAppBar.height;

  PostListScrollState get _scrollState => widget.controller.scrollState;

  double get _headerHeight => widget.controller.headerHeight;

  set _headerHeight(double height) => widget.controller.headerHeight = height;

  void _show([VoidCallback? callback]) {
    _animationController
        .animateBack(_animationController.lowerBound,
            duration: _animationDuration *
                (_animationController.value - _animationController.lowerBound),
            curve: AppTheme.slideCurve)
        .whenCompleteOrCancel(callback ?? () {});
  }

  void _hide([VoidCallback? callback]) {
    _animationController
        .animateTo(_animationController.upperBound,
            duration: _animationDuration *
                (_animationController.upperBound - _animationController.value),
            curve: AppTheme.slideCurve)
        .whenCompleteOrCancel(callback ?? () {});
  }

  void _setAppBarHeight(double height) => _height = height;

  void _setHeaderHeight() => _headerHeight = _height;

  void _update() {
    final height = _height;
    if (!_scrollState.isOutOfAppBarRange) {
      if (height <= _headerHeight) {
        _height = _headerHeight;
      } else {
        widget.controller.scrollState = PostListScrollState.outOfAppBarRange;
        _headerHeight = height;
        widget.controller.jumpToOffset(height - _headerHeight);
      }
    } else {
      final topPosition = widget.controller.topPosition;
      if (topPosition != null &&
          topPosition >= 0.0 &&
          topPosition <= PostListAppBar.height) {
        _height = max(height, PostListAppBar.height - topPosition);
      } else {
        _headerHeight = height;
      }
    }
  }

  double _elevation(double? elevation) => !widget.controller.isHistory
      ? ((_animationController.upperBound - _animationController.value) *
          (elevation ?? PostListAppBar.defaultElevation))
      : 0.0;

  @override
  void initState() {
    super.initState();

    _animationController =
        AnimationController(vsync: this, duration: _animationDuration);
    _setHeaderHeight();
    _animationController.addListener(_setHeaderHeight);
    PostListController._showAppBar = _show;
    PostListController._hideAppBar = _hide;
    PostListController._stopAppBarAnimation = _animationController.stop;

    _slideAnimation = Tween(begin: Offset.zero, end: const Offset(0.0, -1.0))
        .animate(_animationController);

    widget.controller._setAppBarHeight = _setAppBarHeight;
    _backdropSubscription = BackdropController.controller.listen((isShowed) {
      if (isShowed) {
        widget.controller.scrollState = PostListScrollState.outOfAppBarRange;
        _show();
        PostListController.scrollDirection = ScrollDirection.idle;
      }
    });
  }

  @override
  void didUpdateWidget(covariant _AnimatedAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      oldWidget.controller._setAppBarHeight = null;
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) => _update());
      widget.controller._setAppBarHeight = _setAppBarHeight;
    }
  }

  @override
  void dispose() {
    widget.controller._setAppBarHeight = null;
    _backdropSubscription.cancel();
    _animationController.removeListener(_setHeaderHeight);
    PostListController._appBarHeight.value = PostListAppBar.height;
    PostListController._showAppBar = null;
    PostListController._hideAppBar = null;
    PostListController._stopAppBarAnimation = null;
    _animationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SlideTransition(
      position: _slideAnimation,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) => PhysicalModel(
          elevation: _elevation(theme.appBarTheme.elevation),
          color: theme.primaryColor,
          shadowColor: theme.appBarTheme.shadowColor ?? Colors.black,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

class _PostListHeader extends StatelessWidget {
  final PostListController controller;

  // ignore: unused_element
  const _PostListHeader({super.key, required this.controller});

  @override
  Widget build(BuildContext context) =>
      Obx(() => SizedBox(height: controller.headerHeight));
}

/* class _PostListGetPageRoute<T> extends GetPageRoute<T> {
  bool _maintainState = false;

  @override
  bool get maintainState => _maintainState;

  @override
  GetPageBuilder? get page => super.page != null
      ? () {
          _active();

          return super.page!();
        }
      : null;

  _PostListGetPageRoute({super.settings, super.transition, super.page});

  void _active() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (isActive) {
        _maintainState = true;
        changedInternalState();
      }
    });
  }
} */

class _PostListPage<T> extends Page<T> {
  final PostListController controller;

  const _PostListPage({super.key, required this.controller});

  Widget _buildWidget() {
    final settings = SettingsService.to;
    final hasBeenDarkMode = settings.hasBeenDarkMode;
    final postListType = controller.postListType;

    late final Widget body;
    switch (postListType) {
      case PostListType.thread:
      case PostListType.onlyPoThread:
        body = ThreadBody(controller as ThreadTypeController);
        break;
      case PostListType.forum:
      case PostListType.timeline:
        body = ForumBody(controller as ForumTypeController);
        break;
      case PostListType.feed:
        body = FeedBody(controller as FeedController);
        break;
      case PostListType.history:
        body = HistoryBody(controller as HistoryController);
        break;
    }

    return Obx(
      () {
        final theme = Get.theme;

        return Material(
          color: hasBeenDarkMode.value
              ? (postListType.isThreadType
                  ? theme.cardColor
                  : theme.scaffoldBackgroundColor)
              : theme.scaffoldBackgroundColor,
          child: SettingsService.isAutoHideAppBar
              ? Column(
                  children: [
                    _PostListHeader(controller: controller),
                    Expanded(child: body),
                  ],
                )
              : body,
        );
      },
    );
  }

  @override
  Route<T> createRoute(BuildContext context) => AppSwipeablePageRoute(
        settings: this,
        builder: (context) => _buildWidget(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _PostListPage<T> &&
          key == other.key &&
          controller == other.controller);

  @override
  int get hashCode => Object.hash(key, controller);
}

class PostListPage extends StatefulWidget {
  static final GlobalKey<PostListPageState> pageKey =
      GlobalKey<PostListPageState>();

  const PostListPage({super.key});

  @override
  State<PostListPage> createState() => PostListPageState();
}

class PostListPageState extends State<PostListPage> {
  late final PageController _pageController;

  void _openDrawer() => Scaffold.of(context).openDrawer();

  void _closeDrawer() => Scaffold.of(context).closeDrawer();

  void _openEndDrawer() => Scaffold.of(context).openEndDrawer();

  void _closeEndDrawer() => Scaffold.of(context).closeEndDrawer();

  void jumpToPage(int page) {
    _pageController.jumpToPage(page);
    ControllerStacksService.to.index = page;
  }

  void jumpToLast() => jumpToPage(ControllerStacksService.to.length - 1);

  Widget _buildNavigator(BuildContext context, int index) {
    debugPrint('build navigator: $index');

    final stacks = ControllerStacksService.to;

    return NotifyBuilder(
      animation: stacks.getStackNotifier(index),
      builder: (context, child) => Navigator(
        key: Get.nestedKey(stacks.getKeyId(index)),
        pages: [
          for (final controller in stacks.getControllers(index))
            _PostListPage(
              key: ValueKey(controller.key),
              controller: controller.controller,
            ),
        ],
        onPopPage: (route, result) {
          stacks.popController(index);

          return route.didPop(result);
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _pageController =
        PageController(initialPage: ControllerStacksService.to.index);
  }

  @override
  void dispose() {
    _pageController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //final settings = SettingsService.to;
    final stacks = ControllerStacksService.to;
    final scaffold = Scaffold.of(context);

    debugPrint('build page');

    final Widget page = Obx(
      () => PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: stacks.length,
        itemBuilder: (context, index) => _buildNavigator(context, index),
      ),
    );

    return GetPlatform.isDesktop
        ? SwipeDetector(
            onSwipeLeft: (offset) => scaffold.openEndDrawer(),
            onSwipeRight: !SettingsService.isBackdropUI
                ? (offset) => scaffold.openDrawer()
                : null,
            child: page,
          )
        : page;
  }
}

class _SaveDraftDialog extends StatelessWidget {
  final EditPostController controller;

  final bool canPost;

  const _SaveDraftDialog(
      // ignore: unused_element
      {super.key,
      required this.controller,
      required this.canPost});

  @override
  Widget build(BuildContext context) => AlertDialog(
        actionsPadding:
            const EdgeInsets.only(left: 10.0, right: 10.0, bottom: 10.0),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        content: (controller.hasText && controller.isImagePainted)
            ? const Text('保存草稿或图片？')
            : (controller.hasText ? const Text('保存草稿？') : const Text('保存图片？')),
        actions: [
          TextButton(
              onPressed: () => Get.back<bool>(result: true),
              child: const Text('关闭')),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canPost)
                TextButton(
                    onPressed: () => Get.back<bool>(result: false),
                    child: const Text('取消')),
              if (controller.isImagePainted)
                TextButton(
                  onPressed: () async {
                    await saveImageData(controller.imageData!);

                    if (!controller.hasText) {
                      Get.back<bool>(result: true);
                    }
                  },
                  child: controller.hasText
                      ? const Text('保存图片')
                      : const Text('保存'),
                ),
              if (controller.hasText)
                TextButton(
                  onPressed: () async {
                    await PostDraftListService.to
                        .addDraft(PostDraftData.fromController(controller));
                    showToast('已保存为草稿');

                    if (!controller.isImagePainted) {
                      Get.back<bool>(result: true);
                    }
                  },
                  child: controller.isImagePainted
                      ? const Text('保存草稿')
                      : const Text('保存'),
                ),
            ],
          ),
        ],
      );
}

class _EditPostBottomSheet extends StatelessWidget {
  final EditPostController? controller;

  final double height;

  const _EditPostBottomSheet(
      // ignore: unused_element
      {super.key,
      this.controller,
      required this.height});

  @override
  Widget build(BuildContext context) {
    if (controller != null) {
      return SingleChildScrollViewWithScrollbar(
        child: EditPost.fromController(
          controller: controller!,
          height: height,
        ),
      );
    } else {
      final controller = PostListController.get();

      return SingleChildScrollViewWithScrollbar(
        child: EditPost(
          postList: PostList.fromController(controller),
          height: height,
          forumId: controller.forumId,
        ),
      );
    }
  }
}

class BottomSheetController<T> {
  static final EditPostBottomSheetController editPostController =
      EditPostBottomSheetController();

  static final BottomSheetController _tabAndForumListController =
      BottomSheetController();

  final Rxn<PersistentBottomSheetController<T>> _bottomSheetController =
      Rxn(null);

  VoidCallback? _show;

  set _controller(PersistentBottomSheetController<T>? controller) =>
      _bottomSheetController.value = controller;

  bool get isShowed => _bottomSheetController.value != null;

  Future<T>? get closed =>
      isShowed ? _bottomSheetController.value!.closed : null;

  BottomSheetController();

  void toggle() {
    if (isShowed) {
      close();
    } else {
      show();
    }
  }

  void show() {
    if (!isShowed && _show != null) {
      _show!();
    }
  }

  void close() {
    if (isShowed) {
      _bottomSheetController.value!.close();
    }
  }
}

typedef _ShowEditPostBottomSheetCallback = void Function(
    [EditPostController? controller]);

class EditPostBottomSheetController<T> extends BottomSheetController<T> {
  _ShowEditPostBottomSheetCallback? _showEditPost;

  EditPostBottomSheetController();

  void showEditPost([EditPostController? controller]) {
    if (_showEditPost != null) {
      _showEditPost!(controller);
    }
  }
}

class _PostListFloatingButton extends StatefulWidget {
  final double bottomSheetHeight;

  final double topPadding;

  const _PostListFloatingButton(
      // ignore: unused_element
      {super.key,
      required this.bottomSheetHeight,
      required this.topPadding});

  @override
  State<_PostListFloatingButton> createState() =>
      _PostListFloatingButtonState();
}

class _PostListFloatingButtonState extends State<_PostListFloatingButton> {
  static const double _diameter = 56.0;

  static EditPostBottomSheetController get _editPostController =>
      BottomSheetController.editPostController;

  static BottomSheetController get _tabAndForumListController =>
      BottomSheetController._tabAndForumListController;

  static bool get _hasBottomSheet => _editPostController.isShowed;

  static EditPostCallback? get _editPost => EditPostCallback.bottomSheet;

  void _toggleEditPostBottomSheet([EditPostController? controller]) {
    if (mounted) {
      if (!_hasBottomSheet) {
        if (_tabAndForumListController.isShowed) {
          _tabAndForumListController.close();
        }

        _editPostController._controller = showBottomSheet(
          context: context,
          shape: Border(
              top: BorderSide(
                  width: 0.5,
                  color: DividerTheme.of(context).color ??
                      Theme.of(context).dividerColor)),
          builder: (context) => _EditPostBottomSheet(
              controller: controller, height: widget.bottomSheetHeight),
        );

        _editPostController.closed?.then((value) async {
          _editPostController._controller = null;

          if (_editPost != null) {
            final isPosted = _editPost!.isPosted();
            if (!isPosted) {
              final controller = _editPost!.toController();
              final postListController = PostListController.get();
              if ((controller.hasText || controller.isImagePainted) &&
                  !(await Get.dialog<bool>(_SaveDraftDialog(
                          controller: controller,
                          canPost: postListController.canPost)) ??
                      false)) {
                if (postListController.canPost) {
                  _toggleEditPostBottomSheet(controller);
                }
              }
            }
          }
        });
      } else {
        _editPostController.close();
      }
    }
  }

  void _refreshBottomSheet() {
    if (_hasBottomSheet) {
      final controller = PostListController.get();
      if (controller.canPost && _editPost != null) {
        _editPost!.setPostList(
            PostList.fromController(controller), controller.forumId);
      } else {
        _editPostController.close();
      }
    }
  }

  void _showTabAndForumList() => _TabAndForumListButton._showTabAndForumList(
      topPadding: widget.topPadding);

  @override
  void initState() {
    super.initState();

    _editPostController._show = _toggleEditPostBottomSheet;
    _editPostController._showEditPost = _toggleEditPostBottomSheet;

    if (SettingsService.isShowBottomBar && !SettingsService.isBackdropUI) {
      _tabAndForumListController._show = _showTabAndForumList;
    }

    ControllerStacksService.to.notifier.addListener(_refreshBottomSheet);
  }

  @override
  void dispose() {
    _editPostController._show = null;
    _editPostController._showEditPost = null;

    if (SettingsService.isShowBottomBar && !SettingsService.isBackdropUI) {
      _tabAndForumListController._show = null;
    }

    ControllerStacksService.to.notifier.removeListener(_refreshBottomSheet);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return NotifyBuilder(
      animation: Listenable.merge([
        ControllerStacksService.to.notifier,
        settings.hideFloatingButtonListenable,
        settings.autoHideFloatingButtonListenable,
      ]),
      builder: (context, child) => Obx(() {
        final Widget floatingButton = FloatingActionButton(
          tooltip: _hasBottomSheet ? '收起' : '发串',
          onPressed: _toggleEditPostBottomSheet,
          child: Icon(
            _hasBottomSheet ? Icons.arrow_downward : Icons.edit,
          ),
        );

        return AnimatedSwitcher(
          duration: _animationDuration,
          child: ((_hasBottomSheet ||
                      !(SettingsService.isShowBottomBar ||
                          settings.hideFloatingButton ||
                          (settings.autoHideFloatingButton &&
                              PostListController.isScrollingDown))) &&
                  PostListController.get().canPost)
              ? Padding(
                  padding: EdgeInsets.only(
                      bottom: _hasBottomSheet ? _diameter : 0.0),
                  child: SettingsService.isShowGuide
                      ? EditPostGuide(floatingButton)
                      : floatingButton,
                )
              : const SizedBox.shrink(),
        );
      }),
    );
  }
}

const double _tabBarDefaultHeight = 46.0;

class _CompactTabAndForumListTabBar extends StatelessWidget {
  final bool smallTabBar;

  // ignore: unused_element
  const _CompactTabAndForumListTabBar({super.key, this.smallTabBar = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      height: smallTabBar ? _tabBarDefaultHeight : PostListAppBar.height,
      color: theme.primaryColor,
      child: DefaultTextStyle.merge(
        style: (smallTabBar
                ? theme.textTheme.bodyLarge
                : theme.textTheme.titleLarge)
            ?.apply(color: theme.colorScheme.onPrimary),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const [Text('标签'), SizedBox.shrink(), Text('版块')],
        ),
      ),
    );
  }
}

class _CompactTabAndForumList extends StatelessWidget {
  final bool smallTabBar;

  final double? topPadding;

  final double? bottomPadding;

  final VoidCallback onTap;

  const _CompactTabAndForumList(
      // ignore: unused_element
      {super.key,
      this.smallTabBar = false,
      this.topPadding,
      this.bottomPadding,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final Widget column = LayoutBuilder(
      builder: (context, constraints) => Obx(
        () => SizedBox(
          height: (SettingsService.isAutoHideAppBar &&
                  !SettingsService.isBackdropUI &&
                  topPadding != null)
              ? (constraints.maxHeight -
                  topPadding! -
                  PostListController.appBarHeight)
              : constraints.maxHeight,
          child: Column(
            children: [
              _CompactTabAndForumListTabBar(smallTabBar: smallTabBar),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: TabList(onTapEnd: onTap)),
                    const VerticalDivider(width: 1.0, thickness: 1.0),
                    Flexible(child: ForumList(onTapEnd: onTap)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Material(
      child: bottomPadding != null
          ? Padding(
              padding: EdgeInsets.only(bottom: bottomPadding!), child: column)
          : column,
    );
  }
}

class _TabAndForumListController {
  static final _TabAndForumListController _controller =
      _TabAndForumListController();

  TabController? _tabController;

  int? _lastIndex;

  bool get _isShowed => _tabController != null;

  int? get _index => _isShowed ? _tabController!.index : null;

  _TabAndForumListController();

  void _animateTo(int index) {
    if (_isShowed) {
      _tabController!.animateTo(index);
    }
  }
}

class _TabAndForumList extends StatefulWidget {
  final int initialIndex;

  final bool smallTabBar;

  final double? topPadding;

  final double? bottomPadding;

  final VoidCallback onTap;

  const _TabAndForumList(
      // ignore: unused_element
      {super.key,
      this.initialIndex = 0,
      this.smallTabBar = false,
      this.topPadding,
      this.bottomPadding,
      required this.onTap});

  @override
  State<_TabAndForumList> createState() => _TabAndForumListState();
}

class _TabAndForumListState extends State<_TabAndForumList>
    with SingleTickerProviderStateMixin<_TabAndForumList> {
  static _TabAndForumListController get _tabAndForumListController =>
      _TabAndForumListController._controller;

  late final TabController _tabController;

  void _setLastIndex() =>
      _tabAndForumListController._lastIndex = _tabController.index;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
        initialIndex: widget.initialIndex, length: 2, vsync: this);
    _tabAndForumListController._tabController = _tabController;
    _setLastIndex();
    _tabController.addListener(_setLastIndex);
  }

  @override
  void dispose() {
    _tabController.removeListener(_setLastIndex);
    _tabAndForumListController._tabController = null;
    _tabController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final Widget column = LayoutBuilder(
      builder: (context, constraints) => Obx(
        () => SizedBox(
          height: (SettingsService.isAutoHideAppBar &&
                  !SettingsService.isBackdropUI &&
                  widget.topPadding != null)
              ? (constraints.maxHeight -
                  widget.topPadding! -
                  PostListController.appBarHeight)
              : constraints.maxHeight,
          child: Column(
            children: [
              Material(
                elevation: 4,
                color: Theme.of(context).primaryColor,
                child: TabBar(
                  controller: _tabController,
                  labelStyle: widget.smallTabBar
                      ? textTheme.bodyLarge
                      : textTheme.titleLarge,
                  tabs: [
                    Tab(
                      text: '标签',
                      height: widget.smallTabBar
                          ? _tabBarDefaultHeight
                          : PostListAppBar.height,
                    ),
                    Tab(
                      text: '版块',
                      height: widget.smallTabBar
                          ? _tabBarDefaultHeight
                          : PostListAppBar.height,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    TabList(onTapEnd: widget.onTap),
                    ForumList(onTapEnd: widget.onTap),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Material(
      child: widget.bottomPadding != null
          ? Padding(
              padding: EdgeInsets.only(bottom: widget.bottomPadding!),
              child: column)
          : column,
    );
  }
}

enum _TabAndForumListButtonType {
  tabList,
  forumList,
  compact;

  bool get _isTabList => this == tabList;

  bool get _isForumList => this == forumList;

  bool get _isCompact => this == compact;
}

class _TabAndForumListButton extends StatelessWidget {
  static BottomSheetController get _bottomSheetController =>
      BottomSheetController._tabAndForumListController;

  static _TabAndForumListController get _tabAndForumListController =>
      _TabAndForumListController._controller;

  static BottomSheetController get _editPostBottomSheetController =>
      BottomSheetController.editPostController;

  static void _showTabAndForumList(
      {_TabAndForumListButtonType? buttonType, double? topPadding}) {
    final settings = SettingsService.to;
    final double? topPadding_ = settings.autoHideAppBar ? topPadding : null;
    final double? bottomPadding =
        settings.autoHideBottomBar ? PostListBottomBar.height : null;
    final state = PostListView._scaffoldKey.currentState;

    if (state != null) {
      if (_editPostBottomSheetController.isShowed) {
        _editPostBottomSheetController.close();
      }

      _bottomSheetController._controller = buttonType != null
          ? state.showBottomSheet(
              (context) => buttonType._isCompact
                  ? _CompactTabAndForumList(
                      smallTabBar: true,
                      topPadding: topPadding_,
                      bottomPadding: bottomPadding,
                      onTap: _closeBottomSheet)
                  : _TabAndForumList(
                      initialIndex: buttonType._isTabList ? 0 : 1,
                      smallTabBar: true,
                      topPadding: topPadding_,
                      bottomPadding: bottomPadding,
                      onTap: _closeBottomSheet,
                    ),
            )
          : state.showBottomSheet(
              (context) => SettingsService.to.isCompactTabAndForumList
                  ? _CompactTabAndForumList(
                      smallTabBar: true,
                      topPadding: topPadding_,
                      bottomPadding: bottomPadding,
                      onTap: _closeBottomSheet)
                  : _TabAndForumList(
                      initialIndex: _tabAndForumListController._lastIndex ?? 0,
                      smallTabBar: true,
                      topPadding: topPadding_,
                      bottomPadding: bottomPadding,
                      onTap: _closeBottomSheet,
                    ),
            );

      _bottomSheetController.closed
          ?.then((value) => _bottomSheetController._controller = null);
    }
  }

  static void _closeBottomSheet() => _bottomSheetController.close();

  final _TabAndForumListButtonType buttonType;

  const _TabAndForumListButton(
      // ignore: unused_element
      {super.key,
      required this.buttonType});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onPrimary;
    final topPadding = MediaQuery.of(context).padding.top;

    return IconButton(
      tooltip: buttonType._isTabList
          ? '标签页'
          : (buttonType._isForumList ? '版块' : '标签页/版块'),
      onPressed: () {
        if (!_bottomSheetController.isShowed) {
          _showTabAndForumList(buttonType: buttonType, topPadding: topPadding);
        } else {
          if (!buttonType._isCompact && _tabAndForumListController._isShowed) {
            if (buttonType._isTabList) {
              if (_tabAndForumListController._index != 0) {
                _tabAndForumListController._animateTo(0);
              } else {
                _closeBottomSheet();
              }
            } else if (buttonType._isForumList) {
              if (_tabAndForumListController._index != 1) {
                _tabAndForumListController._animateTo(1);
              } else {
                _closeBottomSheet();
              }
            }
          } else {
            _closeBottomSheet();
          }
        }
      },
      icon: buttonType._isTabList
          ? Transform.scale(
              scaleX: -1.0,
              child: Icon(Icons.auto_awesome_motion_outlined, color: color),
            )
          : Icon(Icons.density_medium, color: color),
    );
  }
}

/// 显示隐藏的组件
void showHidden() {
  PostListController.showAppBar();
  PostListController.scrollDirection = ScrollDirection.forward;
}

class PostListBottomBar extends StatelessWidget {
  static const double height = 48.0;

  static EditPostBottomSheetController get _editPostController =>
      BottomSheetController.editPostController;

  static BottomSheetController get _tabAndForumListController =>
      BottomSheetController._tabAndForumListController;

  static bool get isShowed =>
      !(_editPostController.isShowed ||
          (!_tabAndForumListController.isShowed &&
              PostListController.isScrollingDown)) &&
      SettingsService.to.isAutoHideBottomBar;

  const PostListBottomBar({super.key});

  void _closeBottomSheet() => _tabAndForumListController.close();

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;
    final color = Theme.of(context).colorScheme.onPrimary;
    final hideOffset = (height + getViewPadding().bottom) / height;

    final Widget searchButton = SearchButton(
      iconColor: color,
      onTapPrelude: _closeBottomSheet,
    );
    final Widget settingsButton = SettingsButton(
      iconColor: color,
      onTapPrelude: _closeBottomSheet,
    );
    final Widget? compactListButton =
        (!SettingsService.isBackdropUI && settings.compactTabAndForumList)
            ? const _TabAndForumListButton(
                buttonType: _TabAndForumListButtonType.compact)
            : null;
    final Widget? tabListButton =
        !(SettingsService.isBackdropUI || settings.compactTabAndForumList)
            ? const _TabAndForumListButton(
                buttonType: _TabAndForumListButtonType.tabList)
            : null;
    final Widget? forumListButton =
        !(SettingsService.isBackdropUI || settings.compactTabAndForumList)
            ? const _TabAndForumListButton(
                buttonType: _TabAndForumListButtonType.forumList)
            : null;
    final Widget historyButton = HistoryButton(
      iconColor: color,
      onTapPrelude: _closeBottomSheet,
    );
    final Widget feedButton = FeedButton(
      iconColor: color,
      onTapPrelude: _closeBottomSheet,
    );
    final Widget editPostButton = IconButton(
      onPressed: () {
        final controller = PostListController.get();
        if (controller.canPost) {
          // 会先关闭标签页和版块列表
          _editPostController.showEditPost();
        }
      },
      tooltip: '发串',
      icon: const Icon(Icons.edit),
      color: color,
    );

    final Widget bottomAppBar = Container(
      color: Theme.of(context).primaryColor,
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Flexible(
            child: settings.shouldShowGuide
                ? SearchGuide(searchButton)
                : searchButton,
          ),
          Flexible(
            child: settings.shouldShowGuide
                ? SettingsGuide(settingsButton)
                : settingsButton,
          ),
          if (!SettingsService.isBackdropUI &&
              settings.compactTabAndForumList &&
              compactListButton != null)
            Flexible(
              child: settings.shouldShowGuide
                  ? CompactListButtonGuide(compactListButton)
                  : compactListButton,
            ),
          if (!(SettingsService.isBackdropUI ||
                  settings.compactTabAndForumList) &&
              tabListButton != null)
            Flexible(
              child: settings.shouldShowGuide
                  ? TabListButtonGuide(tabListButton)
                  : tabListButton,
            ),
          if (!(SettingsService.isBackdropUI ||
                  settings.compactTabAndForumList) &&
              forumListButton != null)
            Flexible(
              child: settings.shouldShowGuide
                  ? ForumListButtonGuide(forumListButton)
                  : forumListButton,
            ),
          Flexible(
            child:
                settings.shouldShowGuide ? FeedGuide(feedButton) : feedButton,
          ),
          Flexible(
            child: settings.shouldShowGuide
                ? HistoryGuide(historyButton)
                : historyButton,
          ),
          Flexible(
            child: settings.shouldShowGuide
                ? EditPostGuide(editPostButton)
                : editPostButton,
          ),
          Flexible(
            child: SponsorButton(
              onlyText: false,
              showLabel: false,
              iconColor: color,
              onTapPrelude: _closeBottomSheet,
            ),
          ),
        ],
      ),
    );

    final Widget bottomBar = Obx(
      () => settings.autoHideBottomBar
          ? AnimatedSlide(
              offset: Offset(
                  0,
                  (_editPostController.isShowed ||
                          (!_tabAndForumListController.isShowed &&
                              PostListController.isScrollingDown))
                      ? hideOffset
                      : 0),
              curve: AppTheme.slideCurve,
              duration: _animationDuration,
              child: bottomAppBar,
            )
          : (!_editPostController.isShowed
              ? bottomAppBar
              : const SizedBox.shrink()),
    );

    return settings.autoHideBottomBar
        ? NotifyBuilder(
            animation: ControllerStacksService.to.notifier,
            builder: (context, child) => bottomBar,
          )
        : bottomBar;
  }
}

class PostListView extends StatefulWidget {
  static final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  const PostListView({super.key});

  @override
  State<PostListView> createState() => _PostListViewState();
}

class _PostListViewState extends State<PostListView>
    with WidgetsBindingObserver {
  static const Duration _delayDuration = Duration(milliseconds: 300);

  static bool _isInitial = true;

  static EditPostBottomSheetController get _editPostBSController =>
      BottomSheetController.editPostController;

  /* static BottomSheetController get _tabAndForumListBSController =>
      BottomSheetController._tabAndForumListController; */

  static _TabAndForumListController get _tabAndForumListController =>
      _TabAndForumListController._controller;

  static BackdropController get _backdropController =>
      BackdropController.controller;

  DateTime? _lastPressBackTime;

  ShowCaseWidgetState? showCase;

  Future<bool> _onWillPop(BuildContext context) async {
    if (_backdropController.isShowBackLayer) {
      _backdropController.hideBackLayer();

      return false;
    }

    if (Navigator.canPop(context)) {
      Get.back();

      return false;
    }

    if (postListkey()?.currentState?.canPop() ?? false) {
      postListPop();

      return false;
    }

    final now = DateTime.now();
    if (_lastPressBackTime == null ||
        now.difference(_lastPressBackTime!) > const Duration(seconds: 2)) {
      _lastPressBackTime = now;

      showToast('再按一次退出');
      return false;
    }

    return true;
  }

  void _startDrawerGuide() => WidgetsBinding.instance.addPostFrameCallback(
        (timeStamp) => Future.delayed(_delayDuration, () {
          if (mounted) {
            showCase?.startShowCase(Guide.drawerGuides);
          }
        }),
      );

  void _startEndDrawerGuide() => WidgetsBinding.instance.addPostFrameCallback(
        (timeStamp) => Future.delayed(_delayDuration, () {
          if (mounted) {
            showCase?.startShowCase(SettingsService.to.showGuide
                ? Guide.endDrawerGuides
                : Guide.backdropEndDrawerGuides);
          }
        }),
      );

  void _startBottomBarGuide() =>
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        if (mounted) {
          showCase?.startShowCase(Guide.bottomBarGuides);
        }
      });

  void _showCase() {
    if (SettingsService.isShowBottomBar) {
      if (Guide.isShowForumGuides) {
        Guide.isShowForumGuides = false;
        Guide.isShowBottomBarGuides = true;
        _startBottomBarGuide();
      } else if (Guide.isShowBottomBarGuides) {
        Guide.isShowBottomBarGuides = false;
        SettingsService.to.showGuide = false;
        CheckAppVersionService.to.checkAppVersion();
        PersistentDataService.to.showNotice();
      }
    } else {
      if (Guide.isShowForumGuides) {
        Guide.isShowForumGuides = false;
        Guide.isShowDrawerGuides = true;
        PostListPage.pageKey.currentState!._openDrawer();
        _startDrawerGuide();
      } else if (Guide.isShowDrawerGuides) {
        Guide.isShowDrawerGuides = false;
        PostListPage.pageKey.currentState!._closeDrawer();
        Guide.isShowEndDrawerGuides = true;
        PostListPage.pageKey.currentState!._openEndDrawer();
        _startEndDrawerGuide();
      } else if (Guide.isShowEndDrawerGuides) {
        Guide.isShowEndDrawerGuides = false;
        PostListPage.pageKey.currentState!._closeEndDrawer();
        SettingsService.to.showGuide = false;
        CheckAppVersionService.to.checkAppVersion();
        PersistentDataService.to.showNotice();
      }
    }
  }

  void _startBackdropTabListGuide() =>
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
        await Future.delayed(_delayDuration);

        if (mounted) {
          if (!SettingsService.to.compactTabAndForumList &&
              _tabAndForumListController._isShowed) {
            if (_tabAndForumListController._index != 0) {
              _tabAndForumListController._animateTo(0);
              await Future.delayed(_delayDuration);
            }
          }

          showCase?.startShowCase(Guide.backLayerTabListGuides);
        }
      });

  void _startBackdropForumListGuide() =>
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
        if (mounted) {
          if (!SettingsService.to.compactTabAndForumList &&
              _tabAndForumListController._isShowed) {
            if (_tabAndForumListController._index != 1) {
              _tabAndForumListController._animateTo(1);
              await Future.delayed(_delayDuration);
            }
          }

          if (mounted) {
            showCase?.startShowCase(Guide.backLayerForumListGuides);
          }
        }
      });

  void _backdropShowCase() {
    if (Guide.isShowForumGuides) {
      Guide.isShowForumGuides = false;
      if (SettingsService.isShowBottomBar) {
        Guide.isShowBottomBarGuides = true;
        _startBottomBarGuide();
      } else {
        Guide.isShowEndDrawerGuides = true;
        PostListPage.pageKey.currentState!._openEndDrawer();
        _startEndDrawerGuide();
      }
    } else if (Guide.isShowEndDrawerGuides) {
      Guide.isShowEndDrawerGuides = false;
      PostListPage.pageKey.currentState!._closeEndDrawer();
      Guide.isShowBackLayerTabListGuides = true;
      _backdropController.showBackLayer();
      _startBackdropTabListGuide();
    } else if (Guide.isShowBottomBarGuides) {
      Guide.isShowBottomBarGuides = false;
      Guide.isShowBackLayerTabListGuides = true;
      _backdropController.showBackLayer();
      _startBackdropTabListGuide();
    } else if (Guide.isShowBackLayerTabListGuides) {
      Guide.isShowBackLayerTabListGuides = false;
      Guide.isShowBackLayerForumListGuides = true;
      _startBackdropForumListGuide();
    } else if (Guide.isShowBackLayerForumListGuides) {
      Guide.isShowBackLayerForumListGuides = false;
      _backdropController.hideBackLayer();
      SettingsService.to.showBackdropGuide = false;
      CheckAppVersionService.to.checkAppVersion();
      PersistentDataService.to.showNotice();
    }
  }

  @override
  void didChangeMetrics() => PersistentDataService.to.updateKeyboardHeight();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blacklist = BlacklistService.to;
    final client = XdnmbClientService.to;
    final data = PersistentDataService.to;
    final drafts = PostDraftListService.to;
    final emoticons = EmoticonListService.to;
    final forums = ForumListService.to;
    final history = PostHistoryService.to;
    final settings = SettingsService.to;
    final stacks = ControllerStacksService.to;
    final user = UserService.to;

    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: ColoredSafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final theme = Theme.of(context);
          final topPadding = MediaQuery.of(context).padding.top;
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final bottomSheetHeight = height * 0.4;

          return Obx(() {
            if (blacklist.isReady.value &&
                data.isReady.value &&
                drafts.isReady.value &&
                emoticons.isReady.value &&
                forums.isReady.value &&
                history.isReady.value &&
                settings.isReady.value &&
                stacks.isReady.value &&
                user.isReady.value &&
                (!PersistentDataService.isFirstLaunched ||
                    client.isReady.value)) {
              if (_isInitial) {
                // 出现用户指导时更新和公告延后显示
                if (!settings.shouldShowGuide) {
                  WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                    if (mounted) {
                      CheckAppVersionService.to.checkAppVersion();
                    }
                  });

                  // 公告的显示需要postList的navigator
                  WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                    if (mounted) {
                      data.showNotice();
                    }
                  });
                }

                data.firstLaunched = false;
                _isInitial = false;
              }

              Widget body = Column(
                children: [
                  Expanded(child: PostListPage(key: PostListPage.pageKey)),
                  if (_editPostBSController.isShowed)
                    SizedBox(height: bottomSheetHeight),
                ],
              );

              if (SettingsService.isAutoHideAppBar) {
                body = Stack(
                  children: [
                    if (topPadding > 0.0)
                      Padding(
                        padding: !_backdropController.isShowBackLayer
                            ? EdgeInsets.only(top: topPadding)
                            : EdgeInsets.zero,
                        child: body,
                      )
                    else
                      body,
                    if (topPadding > 0.0)
                      Padding(
                        padding: !_backdropController.isShowBackLayer
                            ? EdgeInsets.only(top: topPadding)
                            : EdgeInsets.zero,
                        child: const PostListAppBar(),
                      )
                    else
                      const PostListAppBar(),
                    if (!_backdropController.isShowBackLayer &&
                        topPadding > 0.0)
                      Container(
                        width: double.infinity,
                        height: topPadding,
                        color: theme.primaryColor,
                      ),
                  ],
                );
              }

              final Widget? bottomBar = SettingsService.isShowBottomBar
                  ? ValueListenableBuilder<Box>(
                      valueListenable:
                          settings.compactTabAndForumListListenable,
                      builder: (context, value, child) => PostListBottomBar(
                        key: ValueKey<bool>(settings.compactTabAndForumList),
                      ),
                    )
                  : null;

              Widget scaffold = Scaffold(
                key: PostListView._scaffoldKey,
                primary: !(_backdropController.isShowBackLayer ||
                    SettingsService.isAutoHideAppBar),
                appBar: !SettingsService.isAutoHideAppBar
                    ? const PostListAppBar()
                    : null,
                body: body,
                drawerEnableOpenDragGesture:
                    !(SettingsService.isSwipeablePage ||
                        data.isKeyboardVisible.value),
                endDrawerEnableOpenDragGesture:
                    !(SettingsService.isShowBottomBar ||
                        data.isKeyboardVisible.value),
                drawerEdgeDragWidth: !SettingsService.isShowBottomBar
                    ? width * settings.drawerDragRatio
                    : null,
                drawer: !SettingsService.isSwipeablePage
                    ? const AppDrawer(appBarHeight: PostListAppBar.height)
                    : null,
                endDrawer: !SettingsService.isShowBottomBar
                    ? AppEndDrawer(
                        width: width, appBarHeight: PostListAppBar.height)
                    : null,
                floatingActionButton: _PostListFloatingButton(
                    bottomSheetHeight: bottomSheetHeight,
                    topPadding: topPadding),
                bottomNavigationBar: (SettingsService.isShowBottomBar &&
                        !settings.isAutoHideBottomBar &&
                        bottomBar != null)
                    ? bottomBar
                    : null,
              );

              if (SettingsService.isShowBottomBar &&
                  settings.isAutoHideBottomBar &&
                  bottomBar != null) {
                scaffold = Stack(
                    alignment: Alignment.bottomCenter,
                    children: [scaffold, bottomBar]);
              }

              if (SettingsService.isBackdropUI) {
                scaffold = Backdrop(
                  height: height,
                  appBarHeight: PostListAppBar.height,
                  topPadding: topPadding,
                  frontLayer: _backdropController.isShowBackLayer
                      ? Column(
                          children: [
                            Expanded(child: scaffold),
                            SizedBox(height: topPadding),
                          ],
                        )
                      : scaffold,
                  backLayer: settings.isCompactTabAndForumList
                      ? _CompactTabAndForumList(
                          onTap: _backdropController.hideBackLayer)
                      : _TabAndForumList(
                          onTap: _backdropController.hideBackLayer,
                        ),
                );
              }

              return SettingsService.isShowGuide
                  ? ShowCaseWidget(
                      onFinish:
                          settings.showGuide ? _showCase : _backdropShowCase,
                      builder: Builder(builder: (context) {
                        showCase = ShowCaseWidget.of(context);

                        return scaffold;
                      }))
                  : scaffold;
            } else {
              return Material(
                child: Center(
                  child: Text(
                    PersistentDataService.isFirstLaunched
                        ? '启动中，请授予本应用相应权限'
                        : '启动中',
                    style: AppTheme.boldRed,
                  ),
                ),
              );
            }
          });
        }),
      ),
    );
  }
}
