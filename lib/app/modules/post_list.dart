import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_swipe_detector/flutter_swipe_detector.dart';
import 'package:get/get.dart';
import 'package:showcaseview/showcaseview.dart';

import '../data/models/controller.dart';
import '../data/models/draft.dart';
import '../data/models/forum.dart';
import '../data/services/blacklist.dart';
import '../data/services/draft.dart';
import '../data/services/emoticon.dart';
import '../data/services/forum.dart';
import '../data/services/persistent.dart';
import '../data/services/settings.dart';
import '../data/services/stack.dart';
import '../data/services/tag.dart';
import '../data/services/time.dart';
import '../data/services/user.dart';
import '../data/services/version.dart';
import '../data/services/xdnmb_client.dart';
import '../modules/edit_post.dart';
import '../routes/routes.dart';
import '../utils/extensions.dart';
import '../utils/image.dart';
import '../utils/navigation.dart';
import '../utils/padding.dart';
import '../utils/theme.dart';
import '../utils/toast.dart';
import '../widgets/buttons.dart';
import '../widgets/drawer.dart';
import '../widgets/edit_post.dart';
import '../widgets/feed.dart';
import '../widgets/forum.dart';
import '../widgets/forum_list.dart';
import '../widgets/guide.dart';
import '../widgets/history.dart';
import '../widgets/listenable.dart';
import '../widgets/page.dart';
import '../widgets/page_view.dart';
import '../widgets/scroll.dart';
import '../widgets/tab_list.dart';
import '../widgets/tagged.dart';
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

abstract class PostListController extends ChangeNotifier {
  static final Rx<ScrollDirection> _scrollDirection = Rx(ScrollDirection.idle);

  static final RxBool _scrollingDown = false.obs;

  static double _latestAppBarHeight = PostListAppBar.height;

  static VoidCallback? _showAppBar;

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

  static void showAppBar() => _showAppBar?.call();

  static double? getScrollPosition() {
    final controller = PostListController.get();
    final scrollController = controller.scrollController;
    if (scrollController != null) {
      final pixels = scrollController.position.pixels;

      return SettingsService.to.autoHideAppBar
          ? (pixels + controller.appBarHeight)
          : pixels;
    }

    return null;
  }

  final RxInt _page;

  VoidCallback? save;

  bool _isDisposed = false;

  final Rxn<ScrollController> _scrollController = Rxn(null);

  final RxDouble _appBarHeight = _latestAppBarHeight.obs;

  PostListType get postListType;

  int? get id;

  int get page => _page.value;

  set page(int page) => _page.value = page;

  ScrollController? get scrollController => _scrollController.value;

  set scrollController(ScrollController? controller) =>
      _scrollController.value = controller;

  double get appBarHeight =>
      _appBarHeight.value.clamp(0.0, PostListAppBar.height);

  set appBarHeight(double height) {
    final height_ = height.clamp(0.0, PostListAppBar.height);
    _appBarHeight.value = height_;
    _latestAppBarHeight = height_;
  }

  bool get isThread => postListType.isThread;

  bool get isOnlyPoThread => postListType.isOnlyPoThread;

  bool get isForum => postListType.isForum;

  bool get isTimeline => postListType.isTimeline;

  bool get isFeed => postListType.isFeed;

  bool get isHistory => postListType.isHistory;

  bool get isTaggedPostList => postListType.isTaggedPostList;

  bool get isThreadType => postListType.isThreadType;

  bool get isForumType => postListType.isForumType;

  bool get hasForumId => postListType.hasForumId;

  bool get canPost => postListType.canPost;

  bool get isXdnmbApi => postListType.isXdnmbApi;

  int? get forumOrTimelineId => isThreadType
      ? (this as ThreadTypeController).mainPost?.forumId
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

  void trySave() => save?.call();

  /// [onPage]参数为页数
  StreamSubscription<int> listenPage(ValueChanged<int> onPage) =>
      _page.listen(onPage);

  // [onAppBarHeight]参数是标题栏显示的高度
  /* StreamSubscription<double> listenAppBarHeight(
          ValueChanged<double> onAppBarHeight) =>
      _appBarHeight.listen(onAppBarHeight); */

  @override
  void dispose() {
    save = null;
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
      case AppRoutes.taggedPostList:
        controller = taggedPostListController(Get.parameters);
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

  const PostListAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final stacks = ControllerStacksService.to;
    final settings = SettingsService.to;

    return ListenBuilder(
      listenable: stacks.notifier,
      builder: (context, child) {
        final controller = PostListController.get();

        final Widget menuButton = IconButton(
            tooltip: '菜单',
            icon: const Icon(Icons.menu),
            onPressed: () {
              if (settings.hasDrawerRx) {
                Scaffold.of(context).openDrawer();
              } else if (settings.bottomBarHasTabOrForumListButtonRx) {
                if (!_tabAndForumListController.isShownRx) {
                  _tabAndForumListController.show();
                }
              } else if (settings.hasEndDrawerRx) {
                Scaffold.of(context).openEndDrawer();
              }
            });

        late final Widget title;
        switch (controller.postListType) {
          case PostListType.thread:
          case PostListType.onlyPoThread:
            final mainPost = (controller as ThreadTypeController).mainPost;
            // 检查主串或饼干有没有被屏蔽
            if (mainPost?.isBlocked() ?? false) {
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
            title = FeedAppBarTitle(controller as FeedController);
            break;
          case PostListType.history:
            title = HistoryAppBarTitle(controller as HistoryController);
            break;
          case PostListType.taggedPostList:
            title = TaggedPostListAppBarTitle(
                controller as TaggedPostListController);
            break;
        }

        return Obx(() {
          final Widget appBar = GestureDetector(
            onTap: () {
              if (!_tabAndForumListController.isShownRx) {
                if (controller.isThreadType) {
                  controller.refresh();
                } else {
                  controller.refreshPage();
                }
              }
            },
            onDoubleTap: () {
              if (settings.bottomBarHasTabOrForumListButtonRx) {
                _tabAndForumListController.toggle();
              }
            },
            child: AppBar(
              primary: !settings.autoHideAppBarRx,
              elevation: (settings.autoHideAppBarRx ||
                      controller.isFeed ||
                      controller.isHistory)
                  ? 0.0
                  : null,
              leading: !_tabAndForumListController.isShownRx
                  ? (stacks.controllersCount() > 1
                      ? const BackButton(onPressed: postListPop)
                      : AppBarMenuGuide(menuButton))
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _tabAndForumListController.isShownRx
                          ? _tabAndForumListController.close
                          : null),
              title: AppBarTitleGuide(title),
              actions: !_tabAndForumListController.isShownRx
                  ? [
                      if (controller.isThreadType ||
                          controller.isForumType ||
                          (controller.isFeed &&
                              (controller as FeedController).isFeedPage))
                        AppBarPageButtonGuide(
                            PageButton(controller: controller)),
                      if (controller.isThreadType)
                        ListenBuilder(
                          listenable: controller,
                          builder: (context, child) => AppBarPopupMenuGuide(
                            ThreadAppBarPopupMenuButton(
                              controller as ThreadTypeController,
                            ),
                          ),
                        ),
                      if (controller.isForumType)
                        AppBarPopupMenuGuide(ForumAppBarPopupMenuButton(
                          controller as ForumTypeController,
                        )),
                      if (controller.isHistory)
                        AppBarPopupMenuGuide(HistoryAppBarPopupMenuButton(
                          controller as HistoryController,
                        )),
                      if (controller.isTaggedPostList)
                        AppBarPopupMenuGuide(
                          TaggedPostListAppBarPopupMenuButton(
                            controller as TaggedPostListController,
                          ),
                        ),
                    ]
                  : const [SizedBox.shrink()],
            ),
          );

          return settings.autoHideAppBarRx
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

  ScrollController? _scrollController;

  late StreamSubscription<ScrollController?> _scrollControllerSubscription;

  bool _isShowing = false;

  bool _isHiding = false;

  double get _height =>
      (_animationController.upperBound - _animationController.value) *
      PostListAppBar.height;

  set _height(double height) => _animationController.value =
      (PostListAppBar.height - height) / PostListAppBar.height;

  void _show() {
    if (!_isShowing) {
      _isShowing = true;

      _animationController
          .animateBack(_animationController.lowerBound,
              duration: _animationDuration *
                  (_animationController.value -
                      _animationController.lowerBound),
              curve: AppTheme.slideCurve)
          .whenCompleteOrCancel(() => _isShowing = false);
    }
  }

  void _hide() {
    if (!_isHiding) {
      _isHiding = true;

      _animationController
          .animateTo(_animationController.upperBound,
              duration: _animationDuration *
                  (_animationController.upperBound -
                      _animationController.value),
              curve: AppTheme.slideCurve)
          .whenCompleteOrCancel(() => _isHiding = false);
    }
  }

  void _updateController([double? preHeight]) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (_scrollController?.hasClients ?? false) {
        final position = _scrollController!.position;
        final offset = position.pixels - position.minScrollExtent;

        if (preHeight != null) {
          if (offset >= 0.0 && offset <= PostListAppBar.height) {
            _height = max(preHeight, PostListAppBar.height - offset);
          }
        }
      }

      _setHeight();
    });
  }

  void _updateHeight() {
    if (_scrollController?.hasClients ?? false) {
      final height = _height;
      final position = _scrollController!.position;
      final offset = position.pixels - position.minScrollExtent;

      if (offset >= 0.0 && offset <= PostListAppBar.height) {
        if ((position.userScrollDirection != ScrollDirection.forward ||
                height != PostListAppBar.height) &&
            !_isShowing) {
          _height = PostListAppBar.height - offset;
        }
      } else if (offset < 0.0) {
        _height = PostListAppBar.height;
      } else {
        switch (position.userScrollDirection) {
          case ScrollDirection.forward:
            if (offset > 2 * PostListAppBar.height) {
              if (height < PostListAppBar.height) {
                _show();
              }
            }

            break;
          case ScrollDirection.reverse:
            if (height > 0.0) {
              _hide();
            }

            break;
          default:
        }
      }
    }
  }

  void _updateScrollController(ScrollController? controller) {
    if (_scrollController != controller) {
      _scrollController?.removeListener(_updateHeight);
      _scrollController = controller;
      _updateController();
      _scrollController?.addListener(_updateHeight);
    }
  }

  void _setHeight() => widget.controller.appBarHeight = _height;

  double _elevation(double? elevation) =>
      !(widget.controller.isFeed || widget.controller.isHistory)
          ? ((_animationController.upperBound - _animationController.value) *
              (elevation ?? PostListAppBar.defaultElevation))
          : 0.0;

  @override
  void initState() {
    super.initState();

    _animationController =
        AnimationController(vsync: this, duration: _animationDuration);
    _animationController.addListener(_setHeight);

    _slideAnimation = Tween(begin: Offset.zero, end: const Offset(0.0, -1.0))
        .animate(_animationController);

    PostListController._showAppBar = _show;
    _scrollController = widget.controller.scrollController;
    _updateController();
    _scrollController?.addListener(_updateHeight);
    _scrollControllerSubscription =
        widget.controller._scrollController.listen(_updateScrollController);
  }

  @override
  void didUpdateWidget(covariant _AnimatedAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller.scrollController !=
        oldWidget.controller.scrollController) {
      _scrollControllerSubscription.cancel();
      _scrollController?.removeListener(_updateHeight);

      _scrollController = widget.controller.scrollController;
      _scrollController?.addListener(_updateHeight);
      _scrollControllerSubscription =
          widget.controller._scrollController.listen(_updateScrollController);
    }

    if (widget.controller != oldWidget.controller) {
      _updateController(oldWidget.controller.appBarHeight);
    }
  }

  @override
  void dispose() {
    PostListController._showAppBar = null;
    _scrollControllerSubscription.cancel();
    _scrollController?.removeListener(_updateHeight);
    _scrollController = null;
    _animationController.removeListener(_setHeight);
    _animationController.dispose();
    PostListController._latestAppBarHeight = PostListAppBar.height;
    WidgetsBinding.instance.addPostFrameCallback(
        (timeStamp) => ControllerStacksService.to.resetAppBarHeight());

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

class _PostListPage<T> extends Page<T> {
  final PostListController controller;

  const _PostListPage({super.key, required this.controller});

  Widget _buildWidget() {
    final settings = SettingsService.to;
    final hasBeenDarkMode = settings.isDarkModeRx;
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
      case PostListType.taggedPostList:
        body = TaggedPostListBody(controller as TaggedPostListController);
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
          child: body,
        );
      },
    );
  }

  @override
  Route<T> createRoute(BuildContext context) => AppSwipeablePageRoute(
        settings: this,
        maintainState: false,
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

  void jumpToPage(int page) {
    _pageController.jumpToPage(page);
    ControllerStacksService.to.index = page;
  }

  void jumpToLast() => jumpToPage(ControllerStacksService.to.length - 1);

  Widget _buildNavigator(int index) {
    debugPrint('build navigator: $index');

    final stacks = ControllerStacksService.to;

    // 需要Navigator显示公告
    if (!PersistentDataService.isNavigatorReady) {
      WidgetsBinding.instance.addPostFrameCallback(
          (timeStamp) => PersistentDataService.isNavigatorReady = true);
    }

    return ListenBuilder(
      listenable: stacks.getStackNotifier(index),
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
    final stacks = ControllerStacksService.to;
    final settings = SettingsService.to;
    final scaffold = Scaffold.of(context);

    debugPrint('build page');

    final Widget page = Obx(
      () => PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: stacks.length,
        itemBuilder: (context, index) => _buildNavigator(index),
      ),
    );

    return (GetPlatform.isDesktop && settings.hasDrawerOrEndDrawerRx)
        ? SwipeDetector(
            onSwipeLeft: settings.hasEndDrawerRx
                ? (offset) => scaffold.openEndDrawer()
                : null,
            onSwipeRight:
                settings.hasDrawerRx ? (offset) => scaffold.openDrawer() : null,
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
          if (canPost)
            TextButton(
                onPressed: () => Get.back<bool>(result: false),
                child: const Text('返回')),
          TextButton(
              onPressed: () => Get.back<bool>(result: true),
              child: const Text('不保存')),
          if (controller.isImagePainted)
            TextButton(
              onPressed: () async {
                await saveImageData(controller.imageData!);

                if (!controller.hasText) {
                  Get.back<bool>(result: true);
                }
              },
              child: controller.hasText ? const Text('保存图片') : const Text('保存'),
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
          poUserHash: controller is ThreadTypeController
              ? controller.mainPost?.userHash
              : null,
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

  bool get isShownRx => _bottomSheetController.value != null;

  Future<T>? get closed =>
      isShownRx ? _bottomSheetController.value!.closed : null;

  BottomSheetController();

  void toggle() {
    if (isShownRx) {
      close();
    } else {
      show();
    }
  }

  void show() {
    if (!isShownRx && _show != null) {
      _show!();
    }
  }

  void close() {
    if (isShownRx) {
      _bottomSheetController.value!.close();
    }
  }
}

typedef _ShowEditPostBottomSheetCallback = void Function(
    [EditPostController? controller]);

class EditPostBottomSheetController<T> extends BottomSheetController<T> {
  _ShowEditPostBottomSheetCallback? _showEditPost;

  EditPostBottomSheetController();

  void showEditPost([EditPostController? controller]) =>
      _showEditPost?.call(controller);
}

class _PostListFloatingButton extends StatefulWidget {
  final double bottomSheetHeight;

  // ignore: unused_element
  const _PostListFloatingButton({super.key, required this.bottomSheetHeight});

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

  static bool get _hasBottomSheet => _editPostController.isShownRx;

  static EditPostCallback? get _editPost => EditPostCallback.bottomSheet;

  final Listenable _listenable = SettingsService.to.endDrawerSettingListenable;

  void _toggleEditPostBottomSheet([EditPostController? controller]) {
    if (mounted) {
      if (!_hasBottomSheet) {
        if (_tabAndForumListController.isShownRx) {
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
            PostList.fromController(controller),
            controller.forumId,
            controller is ThreadTypeController
                ? controller.mainPost?.userHash
                : null);
      } else {
        _editPostController.close();
      }
    }
  }

  void _setTabAndForumListController() {
    if (SettingsService.to.bottomBarHasTabOrForumListButtonRx) {
      _tabAndForumListController._show =
          TabAndForumListButton._showTabAndForumList;
    } else {
      _tabAndForumListController._show = null;
    }
  }

  @override
  void initState() {
    super.initState();

    _editPostController._show = _toggleEditPostBottomSheet;
    _editPostController._showEditPost = _toggleEditPostBottomSheet;

    _setTabAndForumListController();
    _listenable.addListener(_setTabAndForumListController);

    ControllerStacksService.to.notifier.addListener(_refreshBottomSheet);
  }

  @override
  void dispose() {
    _editPostController._show = null;
    _editPostController._showEditPost = null;

    _listenable.removeListener(_setTabAndForumListController);
    _tabAndForumListController._show = null;

    ControllerStacksService.to.notifier.removeListener(_refreshBottomSheet);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ListenBuilder(
      listenable: Listenable.merge([
        ControllerStacksService.to.notifier,
        settings.floatingButtonSettingListenable,
      ]),
      builder: (context, child) => Obx(() {
        final Widget floatingButton = FloatingActionButton(
          heroTag: null,
          tooltip: _hasBottomSheet ? '收起' : '发串',
          onPressed: _toggleEditPostBottomSheet,
          child: Icon(
            _hasBottomSheet ? Icons.arrow_downward : Icons.edit,
          ),
        );

        return AnimatedSwitcher(
          duration: _animationDuration,
          child: ((_hasBottomSheet ||
                      !(!settings.hasFloatingButton ||
                          settings.hideFloatingButton ||
                          (settings.autoHideFloatingButton &&
                              PostListController.isScrollingDown))) &&
                  PostListController.get().canPost)
              ? Padding(
                  padding: EdgeInsets.only(
                      bottom: _hasBottomSheet ? _diameter : 0.0),
                  child: FloatingButtonGuide(floatingButton),
                )
              : const SizedBox.shrink(),
        );
      }),
    );
  }
}

class _ListInBottomSheet extends StatelessWidget {
  final List<Widget> children;

  // ignore: unused_element
  const _ListInBottomSheet({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;
    final controller = PostListController.get();

    final Widget list = LayoutBuilder(
      builder: (context, constraints) => Obx(() {
        final topPadding = TabAndForumListButton._topPadding(context);

        return SizedBox(
          height: (settings.autoHideAppBarRx && topPadding != null)
              ? (constraints.maxHeight - topPadding - controller.appBarHeight)
              : constraints.maxHeight,
          child: Column(children: children),
        );
      }),
    );

    return Material(
      child: Obx(() {
        final bottomPadding = TabAndForumListButton._bottomPadding(context);

        return (bottomPadding != null && bottomPadding > 0.0)
            ? Padding(
                padding: EdgeInsets.only(bottom: bottomPadding), child: list)
            : list;
      }),
    );
  }
}

const double _tabBarDefaultHeight = 46.0;

class _CompactTabAndForumListTabBar extends StatelessWidget {
  // ignore: unused_element
  const _CompactTabAndForumListTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      height: PageViewTabBar.height,
      color: theme.primaryColor,
      child: DefaultTextStyle.merge(
        style: theme.textTheme.bodyLarge
            ?.apply(color: theme.colorScheme.onPrimary),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [Text('标签'), SizedBox.shrink(), Text('版块')],
        ),
      ),
    );
  }
}

class _CompactTabAndForumList extends StatelessWidget {
  // ignore: unused_element
  const _CompactTabAndForumList({super.key});

  @override
  Widget build(BuildContext context) => const _ListInBottomSheet(children: [
        _CompactTabAndForumListTabBar(),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: TabList(
                  onTapEnd: TabAndForumListButton.closeBottomSheet,
                ),
              ),
              VerticalDivider(width: 1.0, thickness: 1.0),
              Flexible(
                child: ForumList(
                  onTapEnd: TabAndForumListButton.closeBottomSheet,
                ),
              ),
            ],
          ),
        ),
      ]);
}

class _TabAndForumListController {
  static final _TabAndForumListController _controller =
      _TabAndForumListController();

  TabController? _tabController;

  int? _lastIndex;

  bool get _isShown => _tabController != null;

  int? get _index => _isShown ? _tabController!.index : null;

  _TabAndForumListController();

  void _animateTo(int index) {
    if (_isShown) {
      _tabController!.animateTo(index);
    }
  }
}

class _TabAndForumList extends StatefulWidget {
  final int initialIndex;

  // ignore: unused_element
  const _TabAndForumList({super.key, this.initialIndex = 0});

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
        initialIndex: widget.initialIndex.clamp(0, 1), length: 2, vsync: this);
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
    final theme = Theme.of(context);

    return _ListInBottomSheet(children: [
      Material(
        elevation: 4,
        color: theme.primaryColor,
        child: TabBar(
          controller: _tabController,
          labelStyle: theme.textTheme.bodyLarge,
          tabs: const [
            Tab(text: '标签', height: _tabBarDefaultHeight),
            Tab(text: '版块', height: _tabBarDefaultHeight),
          ],
        ),
      ),
      Expanded(
        child: TabBarView(
          controller: _tabController,
          children: const [
            TabList(onTapEnd: TabAndForumListButton.closeBottomSheet),
            ForumList(onTapEnd: TabAndForumListButton.closeBottomSheet),
          ],
        ),
      ),
    ]);
  }
}

class _TabOrForumList extends StatelessWidget {
  // ignore: unused_element
  const _TabOrForumList({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;
    final theme = Theme.of(context);

    return Obx(
      () => settings.bottomBarHasSingleTabOrForumListButtonRx
          ? _ListInBottomSheet(
              children: [
                Container(
                  width: double.infinity,
                  height: PageViewTabBar.height,
                  color: theme.primaryColor,
                  child: Center(
                    child: Text(
                      settings.endDrawerSettingRx == 1 ? '标签页' : '版块',
                      style: theme.textTheme.bodyLarge
                          ?.apply(color: theme.colorScheme.onPrimary),
                    ),
                  ),
                ),
                Expanded(
                  child: settings.endDrawerSettingRx == 1
                      ? const TabList(
                          onTapEnd: TabAndForumListButton.closeBottomSheet)
                      : const ForumList(
                          onTapEnd: TabAndForumListButton.closeBottomSheet),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }
}

enum TabAndForumListButtonType {
  tabList,
  forumList,
  compact;

  bool get _isTabList => this == tabList;

  bool get _isForumList => this == forumList;

  bool get _isCompact => this == compact;
}

class TabAndForumListButton extends StatelessWidget {
  static BottomSheetController get _bottomSheetController =>
      BottomSheetController._tabAndForumListController;

  static _TabAndForumListController get _tabAndForumListController =>
      _TabAndForumListController._controller;

  static BottomSheetController get _editPostBottomSheetController =>
      BottomSheetController.editPostController;

  static void closeBottomSheet() => _bottomSheetController.close();

  // 可能需要在Obx里调用
  static double? _topPadding(BuildContext context) =>
      SettingsService.to.autoHideAppBarRx ? getPadding(context).top : null;

  // 可能需要在Obx里调用
  static double? _bottomPadding(BuildContext context) =>
      SettingsService.to.autoHideBottomBarRx
          ? (PostListBottomBar.height + getPadding(context).bottom)
          : null;

  static void _showTabAndForumList({TabAndForumListButtonType? buttonType}) {
    final settings = SettingsService.to;

    if (settings.bottomBarHasTabOrForumListButtonRx) {
      final state = PostListView._scaffoldKey.currentState;
      if (state != null) {
        if (_editPostBottomSheetController.isShownRx) {
          _editPostBottomSheetController.close();
        }

        _bottomSheetController._controller = state.showBottomSheet(
          (context) => settings.bottomBarHasSingleTabOrForumListButtonRx
              ? const _TabOrForumList()
              : (buttonType != null
                  ? (buttonType._isCompact
                      ? const _CompactTabAndForumList()
                      : _TabAndForumList(
                          initialIndex: buttonType._isTabList ? 0 : 1))
                  : (SettingsService.to.compactTabAndForumList
                      ? const _CompactTabAndForumList()
                      : _TabAndForumList(
                          initialIndex:
                              _tabAndForumListController._lastIndex ?? 0))),
        );

        _bottomSheetController.closed
            ?.then((value) => _bottomSheetController._controller = null);
      }
    }
  }

  final TabAndForumListButtonType buttonType;

  // ignore: unused_element
  const TabAndForumListButton({super.key, required this.buttonType});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onPrimary;

    return IconButton(
      padding: PostListBottomBar.iconPadding,
      tooltip: buttonType._isTabList
          ? '标签页'
          : (buttonType._isForumList ? '版块' : '标签页/版块'),
      onPressed: () {
        if (!_bottomSheetController.isShownRx) {
          _showTabAndForumList(buttonType: buttonType);
        } else {
          if (SettingsService.to.endDrawerSetting == 0 &&
              !buttonType._isCompact &&
              _tabAndForumListController._isShown) {
            if (buttonType._isTabList) {
              if (_tabAndForumListController._index != 0) {
                _tabAndForumListController._animateTo(0);
              } else {
                closeBottomSheet();
              }
            } else if (buttonType._isForumList) {
              if (_tabAndForumListController._index != 1) {
                _tabAndForumListController._animateTo(1);
              } else {
                closeBottomSheet();
              }
            }
          } else {
            closeBottomSheet();
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
  PostListBottomBar.toHide = false;
}

class PostListBottomBar extends StatelessWidget {
  static const double height = 48.0;

  static const EdgeInsets iconPadding = EdgeInsets.all(4.0);

  static final RxBool _toHide = false.obs;

  static bool get toHide => _toHide.value;

  static set toHide(bool toHide) => _toHide.value = toHide;

  static EditPostBottomSheetController get _editPostController =>
      BottomSheetController.editPostController;

  static BottomSheetController get _tabAndForumListController =>
      BottomSheetController._tabAndForumListController;

  /// 只在自动隐藏底边栏时有效
  static bool get isShownRx =>
      !(_editPostController.isShownRx ||
          (!_tabAndForumListController.isShownRx &&
              PostListController.isScrollingDown)) &&
      SettingsService.to.autoHideBottomBarRx;

  const PostListBottomBar({super.key});

  void _closeBottomSheet() => _tabAndForumListController.close();

  Widget _buildBottomBar(ThemeData theme, double bottomViewPadding) {
    final settings = SettingsService.to;
    final buttonColor = theme.colorScheme.onPrimary;

    final hideOffset = (height + bottomViewPadding) / height;

    final Widget searchButton = SearchButton(
      iconColor: buttonColor,
      iconPadding: iconPadding,
      onTapPrelude: _closeBottomSheet,
    );
    final Widget settingsButton = SettingsButton(
      iconColor: buttonColor,
      iconPadding: iconPadding,
      onTapPrelude: _closeBottomSheet,
    );
    final Widget? compactListButton =
        (settings.endDrawerSettingRx == 0 && settings.compactTabAndForumListRx)
            ? const TabAndForumListButton(
                buttonType: TabAndForumListButtonType.compact)
            : null;
    final Widget? tabListButton = (settings.endDrawerSettingRx != 2 &&
            settings.endDrawerSettingRx != 3 &&
            (settings.endDrawerSettingRx == 1 ||
                (settings.endDrawerSettingRx == 0 &&
                    !settings.compactTabAndForumListRx)))
        ? const TabAndForumListButton(
            buttonType: TabAndForumListButtonType.tabList)
        : null;
    final Widget? forumListButton = (settings.endDrawerSettingRx != 1 &&
            settings.endDrawerSettingRx != 3 &&
            (settings.endDrawerSettingRx == 2 ||
                (settings.endDrawerSettingRx == 0 &&
                    !settings.compactTabAndForumListRx)))
        ? const TabAndForumListButton(
            buttonType: TabAndForumListButtonType.forumList)
        : null;
    final Widget historyButton = HistoryButton(
      iconColor: buttonColor,
      iconPadding: iconPadding,
      onTapPrelude: _closeBottomSheet,
    );
    final Widget feedButton = FeedButton(
      iconColor: buttonColor,
      iconPadding: iconPadding,
      onTapPrelude: _closeBottomSheet,
    );
    final Widget editPostButton = IconButton(
      padding: iconPadding,
      onPressed: () {
        final controller = PostListController.get();
        if (controller.canPost) {
          // 会先关闭标签页和版块列表
          _editPostController.showEditPost();
        }
      },
      tooltip: '发串',
      icon: const Icon(Icons.edit),
      color: buttonColor,
    );

    final Widget bottomAppBar = SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.only(left: 5.0, right: 5.0, bottom: 6.0),
        child: Material(
          elevation: 4.0,
          color: theme.primaryColor,
          borderRadius: BorderRadius.circular(21.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Flexible(child: SearchGuide(searchButton)),
              Flexible(child: SettingsGuide(settingsButton)),
              if (compactListButton != null)
                Flexible(child: CompactListButtonGuide(compactListButton)),
              if (tabListButton != null)
                Flexible(child: TabListButtonGuide(tabListButton)),
              if (forumListButton != null)
                Flexible(child: ForumListButtonGuide(forumListButton)),
              Flexible(child: FeedGuide(feedButton)),
              Flexible(child: HistoryGuide(historyButton)),
              Flexible(child: EditPostGuide(editPostButton)),
              Flexible(
                child: SponsorButton(
                  iconColor: buttonColor,
                  iconPadding: iconPadding,
                  onTapPrelude: _closeBottomSheet,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return settings.autoHideBottomBar
        ? AnimatedSlide(
            offset: Offset(
                0,
                (toHide ||
                        _editPostController.isShownRx ||
                        (!_tabAndForumListController.isShownRx &&
                            PostListController.isScrollingDown))
                    ? hideOffset
                    : 0),
            curve: AppTheme.slideCurve,
            duration: _animationDuration,
            child: bottomAppBar,
          )
        : (!_editPostController.isShownRx
            ? bottomAppBar
            : const SizedBox.shrink());
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;
    final theme = Theme.of(context);
    final bottomViewPadding = MediaQuery.viewPaddingOf(context).bottom;

    return Obx(() {
      if (bottomViewPadding > 0.0) {
        if (!settings.autoHideBottomBarRx && _editPostController.isShownRx) {
          return const SizedBox.shrink();
        }

        final bottomBar = Padding(
            padding: EdgeInsets.only(bottom: bottomViewPadding),
            child: _buildBottomBar(theme, bottomViewPadding));

        return (!settings.autoHideBottomBarRx &&
                _tabAndForumListController.isShownRx)
            ? ColoredBox(
                color: Get.isDarkMode
                    ? theme.cardColor
                    : theme.scaffoldBackgroundColor,
                child: bottomBar)
            : bottomBar;
      } else {
        return _buildBottomBar(theme, bottomViewPadding);
      }
    });
  }
}

class PostListView extends StatefulWidget {
  static final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  static late Rx<EdgeInsets> padding;

  static late Rx<EdgeInsets> viewPadding;

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

  DateTime? _lastPressBackTime;

  ShowCaseWidgetState? _showCaseState;

  Future<bool> _onWillPop(BuildContext context) async {
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

  void _startShowCase(List<GlobalKey> guides) {
    if (mounted && guides.isNotEmpty) {
      _showCaseState?.startShowCase(guides);
    }
  }

  void _startDrawerGuides() => WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) => Future.delayed(
          _delayDuration, () => _startShowCase(Guide.drawerGuides)));

  void _startEndDrawerHasOnlyOneListGuides() => WidgetsBinding.instance
      .addPostFrameCallback((timeStamp) => Future.delayed(_delayDuration,
          () => _startShowCase(Guide.endDrawerHasOnlyOneListGuides)));

  void _startBottomBarGuides() => WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) => _startShowCase(Guide.bottomBarGuides));

  void _startTabListGuide() => WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) => Future.delayed(_delayDuration, () async {
            if (mounted) {
              await AppEndDrawer.endDrawerAnimateToPage(0);
              _startShowCase(Guide.tabListGuide);
            }
          }));

  void _startForumListGuide() =>
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
        if (mounted) {
          await AppEndDrawer.endDrawerAnimateToPage(1);
          _startShowCase(Guide.forumListGuide);
        }
      });

  void _startEndDrawerBottomGuides() =>
      WidgetsBinding.instance.addPostFrameCallback(
          (timeStamp) => _startShowCase(Guide.endDrawerBottomGuides));

  void _endShowCase() {
    final settings = SettingsService.to;

    if (settings.showDrawerAndEndDrawerGuide) {
      settings.showDrawerAndEndDrawerGuide = false;
    } else if (settings.showOnlyEndDrawerGuide) {
      settings.showOnlyEndDrawerGuide = false;
    } else if (settings.showBottomBarGuide) {
      settings.showBottomBarGuide = false;
    }

    settings.showGuide = false;
    SettingsService.shouldShowGuide = false;
    CheckAppVersionService.to.checkAppVersion();
    PersistentDataService.to.showNotice();
  }

  void _showCase() {
    final settings = SettingsService.to;

    if (Guide.isShowForumGuides) {
      Guide.isShowForumGuides = false;

      final state = PostListView._scaffoldKey.currentState;
      if (state != null && state.mounted) {
        if (state.hasDrawer) {
          Guide.isShowDrawerGuides = true;
          state.openDrawer();
          _startDrawerGuides();
        } else if (settings.hasBottomBar) {
          Guide.isShowBottomBarGuides = true;
          _startBottomBarGuides();
        } else if (state.hasEndDrawer) {
          Guide.isShowTabListGuide = true;
          state.openEndDrawer();
          _startTabListGuide();
        } else {
          _endShowCase();
        }
      }

      return;
    }

    if (Guide.isShowDrawerGuides) {
      Guide.isShowDrawerGuides = false;

      final state = PostListView._scaffoldKey.currentState;
      if (state != null && state.mounted) {
        state.closeDrawer();
        Guide.isShowEndDrawerHasOnlyOneListGuides = true;
        state.openEndDrawer();
        _startEndDrawerHasOnlyOneListGuides();
      }

      return;
    }

    if (Guide.isShowEndDrawerHasOnlyOneListGuides) {
      Guide.isShowEndDrawerHasOnlyOneListGuides = false;
      PostListView._scaffoldKey.currentState?.closeEndDrawer();
      _endShowCase();

      return;
    }

    if (Guide.isShowBottomBarGuides) {
      Guide.isShowBottomBarGuides = false;

      if (settings.hasEndDrawerRx) {
        final state = PostListView._scaffoldKey.currentState;
        if (state != null && state.mounted) {
          if (settings.endDrawerSetting == 3) {
            Guide.isShowTabListGuide = true;
            state.openEndDrawer();
            _startTabListGuide();
          } else {
            Guide.isShowEndDrawerHasOnlyOneListGuides = true;
            state.openEndDrawer();
            _startEndDrawerHasOnlyOneListGuides();
          }
        }
      } else {
        _endShowCase();
      }

      return;
    }

    if (Guide.isShowTabListGuide) {
      Guide.isShowTabListGuide = false;
      if (PostListView._scaffoldKey.currentState?.isEndDrawerOpen ?? false) {
        Guide.isShowForumListGuide = true;
        _startForumListGuide();
      }

      return;
    }

    if (Guide.isShowForumListGuide) {
      Guide.isShowForumListGuide = false;

      final state = PostListView._scaffoldKey.currentState;
      if (state != null && state.mounted) {
        if (settings.hasBottomBar) {
          state.closeEndDrawer();
          _endShowCase();
        } else if (state.isEndDrawerOpen) {
          Guide.isShowEndDrawerBottomGuides = true;
          _startEndDrawerBottomGuides();
        }
      }

      return;
    }

    if (Guide.isShowEndDrawerBottomGuides) {
      Guide.isShowEndDrawerBottomGuides = false;
      PostListView._scaffoldKey.currentState?.closeEndDrawer();
      _endShowCase();
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
    final settings = SettingsService.to;
    final stacks = ControllerStacksService.to;
    final tagService = TagService.to;
    final time = TimeService.to;
    final user = UserService.to;

    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: LayoutBuilder(builder: (context, constraints) {
        final theme = Theme.of(context);
        final media = MediaQuery.of(context);
        PostListView.padding = Rx(media.padding);
        PostListView.viewPadding = Rx(media.viewPadding);
        final topPadding = media.padding.top;
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final bottomSheetHeight = height * 0.4;

        return Obx(() {
          if (blacklist.isReady.value &&
              data.isReady.value &&
              drafts.isReady.value &&
              emoticons.isReady.value &&
              forums.isReady.value &&
              settings.isReady.value &&
              stacks.isReady.value &&
              tagService.isReady.value &&
              time.isReady.value &&
              user.isReady.value &&
              (!PersistentDataService.isFirstLaunched ||
                  client.isReady.value)) {
            if (_isInitial) {
              // 出现用户指导时更新和公告延后显示
              if (!SettingsService.shouldShowGuide) {
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
                if (_editPostBSController.isShownRx)
                  SizedBox(height: bottomSheetHeight),
              ],
            );

            if (settings.autoHideAppBarRx) {
              body = Stack(
                children: [
                  if (topPadding > 0.0)
                    Padding(
                      padding: EdgeInsets.only(top: topPadding),
                      child: body,
                    )
                  else
                    body,
                  if (topPadding > 0.0)
                    Padding(
                      padding: EdgeInsets.only(top: topPadding),
                      child: const PostListAppBar(),
                    )
                  else
                    const PostListAppBar(),
                  if (topPadding > 0.0)
                    Container(
                      width: double.infinity,
                      height: topPadding,
                      color: theme.primaryColor,
                    ),
                ],
              );
            }

            final Widget? bottomBar =
                settings.hasBottomBarRx ? const PostListBottomBar() : null;

            Widget scaffold = Scaffold(
              key: PostListView._scaffoldKey,
              primary: !settings.autoHideAppBarRx,
              appBar:
                  !settings.autoHideAppBarRx ? const PostListAppBar() : null,
              body: body,
              drawerEnableOpenDragGesture:
                  settings.hasDrawerRx && !data.isKeyboardVisible,
              endDrawerEnableOpenDragGesture:
                  settings.hasEndDrawerRx && !data.isKeyboardVisible,
              drawerEdgeDragWidth: settings.hasDrawerOrEndDrawerRx
                  ? width * settings.drawerEdgeDragWidthRatioRx
                  : null,
              extendBody: settings.hasBottomBarRx &&
                  !settings.autoHideBottomBarRx &&
                  bottomBar != null,
              drawer: settings.hasDrawerRx ? AppDrawer(width: width) : null,
              endDrawer:
                  settings.hasEndDrawerRx ? AppEndDrawer(width: width) : null,
              floatingActionButton:
                  _PostListFloatingButton(bottomSheetHeight: bottomSheetHeight),
              bottomNavigationBar: (settings.hasBottomBarRx &&
                      !settings.autoHideBottomBarRx &&
                      bottomBar != null)
                  ? bottomBar
                  : null,
            );

            if (settings.hasBottomBarRx &&
                settings.autoHideBottomBarRx &&
                bottomBar != null) {
              scaffold = Stack(
                  alignment: Alignment.bottomCenter,
                  children: [scaffold, bottomBar]);
            }

            return SettingsService.isShowGuide
                ? ShowCaseWidget(
                    onFinish: _showCase,
                    builder: Builder(builder: (context) {
                      _showCaseState = ShowCaseWidget.of(context);

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
    );
  }
}
