import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_swipe_detector/flutter_swipe_detector.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';

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
import '../utils/theme.dart';
import '../utils/toast.dart';
import '../widgets/backdrop.dart';
import '../widgets/drawer.dart';
import '../widgets/edit_post.dart';
import '../widgets/end_drawer.dart';
import '../widgets/feed.dart';
import '../widgets/forum.dart';
import '../widgets/forum_list.dart';
import '../widgets/guide.dart';
import '../widgets/history.dart';
import '../widgets/page.dart';
import '../widgets/scroll.dart';
import '../widgets/tab_list.dart';
import '../widgets/thread.dart';

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

typedef OnPageCallback = void Function(int page);

abstract class PostListController extends ChangeNotifier {
  final RxInt _page;

  VoidCallback? save;

  bool _isDisposed = false;

  PostListType get postListType;

  int? get id;

  int get page => _page.value;

  set page(int page) => _page.value = page;

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

  StreamSubscription<int> listenPage(OnPageCallback onPage) =>
      _page.listen(onPage);

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
class _PostListAppBar extends StatelessWidget implements PreferredSizeWidget {
  static const double _height = kToolbarHeight;

  final BackdropController? backdropController;

  // ignore: unused_element
  const _PostListAppBar({super.key, this.backdropController});

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final stacks = ControllerStacksService.to;
    final settings = SettingsService.to;

    return NotifyBuilder(
      animation: stacks.notifier,
      builder: (context, child) {
        final controller = PostListController.get();

        final Widget button = IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              if (backdropController != null) {
                backdropController!.showBackLayer();
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
            title = Obx(() {
              final controller_ = controller as HistoryController;

              return HistoryAppBarTitle(controller_,
                  key: ValueKey<HistoryBottomBarKey>(
                      HistoryBottomBarKey.fromController(controller_)));
            });
            break;
        }

        final dump = false.obs;

        return Obx(() {
          // 为了不让Obx因为没有Rx出错
          dump.value;

          return GestureDetector(
            onTap: (SettingsService.isBackdropUI &&
                    (backdropController?.isShowBackLayer ?? false))
                ? backdropController?.toggleFrontLayer
                : (controller.isThreadType
                    ? controller.refresh
                    : controller.refreshPage),
            onDoubleTap: SettingsService.isBackdropUI
                ? backdropController?.toggleFrontLayer
                : null,
            child: AppBar(
              primary: !(backdropController?.isShowBackLayer ?? false),
              elevation: controller.isHistory ? 0 : null,
              leading: !(backdropController?.isShowBackLayer ?? false)
                  ? (stacks.controllersCount() > 1
                      ? const BackButton(onPressed: postListPop)
                      : (settings.shouldShowGuide
                          ? AppBarMenuGuide(button)
                          : button))
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: backdropController?.hideBackLayer),
              title: settings.shouldShowGuide ? AppBarTitleGuide(title) : title,
              actions: !(backdropController?.isShowBackLayer ?? false)
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
        });
      },
    );
  }
}

class _PostListGetPageRoute<T> extends GetPageRoute<T> {
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
}

class _PostListSwipeablePageRoute<T> extends SwipeablePageRoute<T> {
  bool _maintainState = false;

  @override
  bool get maintainState => _maintainState;

  @override
  WidgetBuilder get builder => (context) {
        _active();

        return super.builder(context);
      };

  _PostListSwipeablePageRoute(
      {super.settings,
      super.canOnlySwipeFromEdge,
      super.backGestureDetectionWidth,
      super.backGestureDetectionStartOffset,
      required super.builder});

  void _active() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (isActive) {
        _maintainState = true;
        changedInternalState();
      }
    });
  }
}

class _PostListPage<T> extends Page<T> {
  final PostListController controller;

  final double? backGestureDetectionWidth;

  const _PostListPage(
      {super.key, required this.controller, this.backGestureDetectionWidth});

  Widget _buildWidget() {
    final hasBeenDarkMode = SettingsService.to.hasBeenDarkMode;
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
          child: body,
        );
      },
    );
  }

  Route<T> _buildRoute() =>
      (SettingsService.isBackdropUI && backGestureDetectionWidth != null)
          ? _PostListSwipeablePageRoute(
              settings: this,
              canOnlySwipeFromEdge: true,
              backGestureDetectionWidth: backGestureDetectionWidth!,
              builder: (context) => _buildWidget(),
            )
          : _PostListGetPageRoute(
              settings: this,
              transition: Transition.rightToLeft,
              page: _buildWidget,
            );

  @override
  Route<T> createRoute(BuildContext context) => _buildRoute();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _PostListPage<T> &&
          key == other.key &&
          controller == other.controller &&
          backGestureDetectionWidth == other.backGestureDetectionWidth);

  @override
  int get hashCode => Object.hash(key, controller, backGestureDetectionWidth);
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

    final settings = SettingsService.to;
    final stacks = ControllerStacksService.to;
    final media = MediaQuery.of(context);

    final double? backGestureDetectionWidth = SettingsService.isBackdropUI
        ? media.size.width * settings.swipeablePageDragWidthRatio
        : null;

    return NotifyBuilder(
      animation: stacks.getStackNotifier(index),
      builder: (context, child) => Navigator(
        key: Get.nestedKey(stacks.getKeyId(index)),
        pages: [
          for (final controller in stacks.getControllers(index))
            _PostListPage(
              key: ValueKey(controller.key),
              controller: controller.controller,
              backGestureDetectionWidth: backGestureDetectionWidth,
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

class _PostListBottomSheet extends StatelessWidget {
  final GlobalKey<EditPostState> editKey;

  final EditPostController? controller;

  final double height;

  const _PostListBottomSheet(
      // ignore: unused_element
      {super.key,
      required this.editKey,
      this.controller,
      required this.height});

  @override
  Widget build(BuildContext context) {
    if (controller != null) {
      return SingleChildScrollViewWithScrollbar(
        child: EditPost.fromController(
          key: editKey,
          controller: controller!,
          height: height,
        ),
      );
    } else {
      final controller = PostListController.get();

      return SingleChildScrollViewWithScrollbar(
        child: EditPost(
          key: editKey,
          postList: PostList.fromController(controller),
          height: height,
          forumId: controller.forumId,
        ),
      );
    }
  }
}

void bottomSheet([EditPostController? controller]) {
  final button = FloatingButton.buttonKey.currentState;
  if (button != null && button.mounted && !button.hasBottomSheet) {
    button.bottomSheet(controller);
  }
}

class FloatingButton extends StatefulWidget {
  static final GlobalKey<FloatingButtonState> buttonKey =
      GlobalKey<FloatingButtonState>();

  final Rxn<PersistentBottomSheetController> bottomSheetController;

  final double bottomSheetHeight;

  const FloatingButton(
      {super.key,
      required this.bottomSheetController,
      required this.bottomSheetHeight});

  @override
  State<FloatingButton> createState() => FloatingButtonState();
}

class FloatingButtonState extends State<FloatingButton> {
  bool get hasBottomSheet => widget.bottomSheetController.value != null;

  void bottomSheet([EditPostController? controller]) {
    if (!hasBottomSheet) {
      widget.bottomSheetController.value = showBottomSheet(
        context: context,
        shape: Border(
            top: BorderSide(
                width: 0.5,
                color: DividerTheme.of(context).color ??
                    Theme.of(context).dividerColor)),
        builder: (context) => _PostListBottomSheet(
            editKey: EditPost.bottomSheetkey,
            controller: controller,
            height: widget.bottomSheetHeight),
      );

      widget.bottomSheetController.value!.closed.then((value) async {
        widget.bottomSheetController.value = null;

        final state = EditPost.bottomSheetkey.currentState!;
        final isPosted = state.isPosted;
        if (!isPosted) {
          final controller = state.toController();
          final postListController = PostListController.get();
          if ((controller.hasText || controller.isImagePainted) &&
              !(await Get.dialog<bool>(_SaveDraftDialog(
                      controller: controller,
                      canPost: postListController.canPost)) ??
                  false)) {
            if (postListController.canPost) {
              bottomSheet(controller);
            }
          }
        }
      });
    } else {
      Get.back();
    }
  }

  void _refreshBottomSheet() {
    if (hasBottomSheet) {
      final controller = PostListController.get();
      if (controller.canPost) {
        EditPost.bottomSheetkey.currentState!.setPostList(
            PostList.fromController(controller), controller.forumId);
      } else {
        widget.bottomSheetController.value!.close();
      }
    }
  }

  @override
  void initState() {
    super.initState();

    ControllerStacksService.to.notifier.addListener(_refreshBottomSheet);
  }

  @override
  void dispose() {
    ControllerStacksService.to.notifier.removeListener(_refreshBottomSheet);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return NotifyBuilder(
      animation: ControllerStacksService.to.notifier,
      builder: (context, child) => ValueListenableBuilder<Box>(
        valueListenable: settings.hideFloatingButtonListenable,
        builder: (context, value, child) => Obx(() {
          final Widget floatingButton = FloatingActionButton(
            tooltip: hasBottomSheet ? '收起' : '发串',
            onPressed: bottomSheet,
            child: Icon(
              hasBottomSheet ? Icons.arrow_downward : Icons.edit,
            ),
          );

          return ((hasBottomSheet || !settings.hideFloatingButton) &&
                  PostListController.get().canPost)
              ? Padding(
                  padding: EdgeInsets.only(bottom: hasBottomSheet ? 56.0 : 0.0),
                  child: SettingsService.isShowGuide
                      ? FloatingButtonGuide(floatingButton)
                      : floatingButton,
                )
              : const SizedBox.shrink();
        }),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  // ignore: unused_element
  const _BottomBar({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
  /* NotifyBuilder(
        animation: ControllerStacksService.to.notifier,
        builder: (context, child) {
          final controller = PostListController.get();

          return controller.isHistory
              ? HistoryBottomBar(controller as HistoryController)
              : const SizedBox.shrink();
        },
      ); */
}

class _PostListCompactBackdropTabBar extends StatelessWidget {
  // ignore: unused_element
  const _PostListCompactBackdropTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      height: _PostListAppBar._height,
      color: theme.primaryColor,
      child: DefaultTextStyle.merge(
        style: theme.textTheme.titleLarge
            ?.apply(color: theme.colorScheme.onPrimary),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const [
            Text('标签'),
            SizedBox.shrink(),
            Text('版块'),
          ],
        ),
      ),
    );
  }
}

class _PostListCompactBackdrop extends StatelessWidget {
  final BackdropController backdropController;

  // ignore: unused_element
  const _PostListCompactBackdrop({super.key, required this.backdropController});

  @override
  Widget build(BuildContext context) => Material(
        child: Column(
          children: [
            const _PostListCompactBackdropTabBar(),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                      child: TabList(backdropController: backdropController)),
                  const VerticalDivider(width: 1.0, thickness: 1.0),
                  Flexible(
                    child: ForumList(backdropController: backdropController),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _PostListBackdrop extends StatefulWidget {
  final BackdropController backdropController;

  const _PostListBackdrop({super.key, required this.backdropController});

  @override
  State<_PostListBackdrop> createState() => _PostListBackdropState();
}

class _PostListBackdropState extends State<_PostListBackdrop>
    with SingleTickerProviderStateMixin<_PostListBackdrop> {
  late final TabController _controller;

  int get _index => _controller.index;

  void _animateTo(int index) => _controller.animateTo(index);

  @override
  void initState() {
    super.initState();

    _controller = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Material(
        child: Column(
          children: [
            Material(
              elevation: 4,
              color: Theme.of(context).primaryColor,
              child: TabBar(
                controller: _controller,
                labelStyle: Theme.of(context).textTheme.titleLarge,
                tabs: const [
                  Tab(text: '标签', height: _PostListAppBar._height),
                  Tab(text: '版块', height: _PostListAppBar._height),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _controller,
                children: [
                  TabList(backdropController: widget.backdropController),
                  ForumList(backdropController: widget.backdropController),
                ],
              ),
            ),
          ],
        ),
      );
}

class PostListView extends StatefulWidget {
  const PostListView({super.key});

  @override
  State<PostListView> createState() => _PostListViewState();
}

class _PostListViewState extends State<PostListView>
    with WidgetsBindingObserver {
  static bool _isInitial = true;

  DateTime? _lastPressBackTime;

  final Rxn<PersistentBottomSheetController> _bottomSheetController = Rxn(null);

  GlobalKey<_PostListBackdropState>? _backdropKey;

  final BackdropController? _backdropController =
      SettingsService.isBackdropUI ? BackdropController() : null;

  ShowCaseWidgetState? showCase;

  Future<bool> _onWillPop(BuildContext context) async {
    if (_backdropController?.isShowBackLayer ?? false) {
      _backdropController?.hideBackLayer();

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
      (timeStamp) => Future.delayed(const Duration(milliseconds: 300),
          () => showCase?.startShowCase(Guide.drawerGuides)));

  void _startEndDrawerGuide() => WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) => Future.delayed(
          const Duration(milliseconds: 300),
          () => showCase?.startShowCase(SettingsService.to.showGuide
              ? Guide.endDrawerGuides
              : Guide.backdropEndDrawerGuides)));

  void _showCase() {
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

  void _startBackdropTabListGuide() =>
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
        await Future.delayed(const Duration(milliseconds: 300));

        if (!SettingsService.to.compactBackdrop && _backdropKey != null) {
          final state = _backdropKey!.currentState;
          if (state != null && state._index != 0) {
            state._animateTo(0);
            await Future.delayed(const Duration(milliseconds: 300));
          }
        }

        showCase?.startShowCase(Guide.backLayerTabListGuides);
      });

  void _startBackdropForumListGuide() =>
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
        if (!SettingsService.to.compactBackdrop && _backdropKey != null) {
          final state = _backdropKey!.currentState;
          if (state != null && state._index != 1) {
            state._animateTo(1);
            await Future.delayed(const Duration(milliseconds: 300));
          }
        }

        showCase?.startShowCase(Guide.backLayerForumListGuides);
      });

  void _backdropShowCase() {
    if (_backdropController != null) {
      if (Guide.isShowForumGuides) {
        Guide.isShowForumGuides = false;
        Guide.isShowEndDrawerGuides = true;
        PostListPage.pageKey.currentState!._openEndDrawer();
        _startEndDrawerGuide();
      } else if (Guide.isShowEndDrawerGuides) {
        Guide.isShowEndDrawerGuides = false;
        PostListPage.pageKey.currentState!._closeEndDrawer();
        Guide.isShowBackLayerTabListGuides = true;
        _backdropController!.showBackLayer();
        _startBackdropTabListGuide();
      } else if (Guide.isShowBackLayerTabListGuides) {
        Guide.isShowBackLayerTabListGuides = false;
        Guide.isShowBackLayerForumListGuides = true;
        _startBackdropForumListGuide();
      } else if (Guide.isShowBackLayerForumListGuides) {
        Guide.isShowBackLayerForumListGuides = false;
        _backdropController!.hideBackLayer();
        SettingsService.to.showBackdropGuide = false;
        CheckAppVersionService.to.checkAppVersion();
        PersistentDataService.to.showNotice();
      }
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
      child: SafeArea(
        left: false,
        top: false,
        right: false,
        child: LayoutBuilder(builder: (context, constraints) {
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
                if (SettingsService.isBackdropUI &&
                    !SettingsService.to.compactBackdrop) {
                  _backdropKey = GlobalKey<_PostListBackdropState>();
                }

                if (settings.showBackdropGuide && _backdropController != null) {
                  Get.put<BackdropController>(_backdropController!);
                }

                // 出现用户指导时更新和公告延后显示
                if (!settings.shouldShowGuide) {
                  WidgetsBinding.instance.addPostFrameCallback((timeStamp) =>
                      CheckAppVersionService.to.checkAppVersion());

                  // 公告的显示需要postList的navigator
                  WidgetsBinding.instance
                      .addPostFrameCallback((timeStamp) => data.showNotice());
                }

                data.firstLaunched = false;
                _isInitial = false;
              }

              Widget scaffold = Obx(
                () => Scaffold(
                  primary: !(_backdropController?.isShowBackLayer ?? false),
                  appBar:
                      _PostListAppBar(backdropController: _backdropController),
                  body: Column(
                    children: [
                      Expanded(child: PostListPage(key: PostListPage.pageKey)),
                      if (_bottomSheetController.value != null)
                        SizedBox(height: bottomSheetHeight),
                    ],
                  ),
                  drawerEnableOpenDragGesture: !SettingsService.isBackdropUI &&
                      !data.isKeyboardVisible.value,
                  endDrawerEnableOpenDragGesture: !data.isKeyboardVisible.value,
                  drawerEdgeDragWidth: width * settings.drawerDragRatio,
                  drawer: !SettingsService.isBackdropUI
                      ? const AppDrawer(appBarHeight: _PostListAppBar._height)
                      : null,
                  endDrawer: AppEndDrawer(
                      width: width, appBarHeight: _PostListAppBar._height),
                  floatingActionButton: FloatingButton(
                    key: FloatingButton.buttonKey,
                    bottomSheetController: _bottomSheetController,
                    bottomSheetHeight: bottomSheetHeight,
                  ),
                  bottomNavigationBar: const _BottomBar(),
                ),
              );

              if (SettingsService.isBackdropUI && _backdropController != null) {
                scaffold = Backdrop(
                  controller: _backdropController!,
                  height: height,
                  appBarHeight: _PostListAppBar._height,
                  frontLayer: scaffold,
                  backLayer: ValueListenableBuilder(
                    valueListenable: settings.compactBackdropListenable,
                    builder: (context, value, child) => settings.compactBackdrop
                        ? _PostListCompactBackdrop(
                            backdropController: _backdropController!)
                        : _PostListBackdrop(
                            key: _backdropKey,
                            backdropController: _backdropController!,
                          ),
                  ),
                );
              }

              return SettingsService.isShowGuide
                  ? (settings.showGuide
                      ? ShowCaseWidget(
                          onFinish: _showCase,
                          builder: Builder(builder: (context) {
                            showCase = ShowCaseWidget.of(context);

                            return scaffold;
                          }))
                      : ShowCaseWidget(
                          onFinish: _backdropShowCase,
                          builder: Builder(builder: (context) {
                            showCase = ShowCaseWidget.of(context);

                            return scaffold;
                          })))
                  : scaffold;
            } else {
              return Center(
                  child: Text(
                      PersistentDataService.isFirstLaunched
                          ? '启动中，请授予本应用相应权限'
                          : '启动中',
                      style: AppTheme.boldRed));
            }
          });
        }),
      ),
    );
  }
}
