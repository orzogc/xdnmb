import 'dart:collection';

import 'package:flutter/material.dart';
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
import '../modules/edit_post.dart';
import '../routes/routes.dart';
import '../utils/image.dart';
import '../utils/navigation.dart';
import '../utils/notify.dart';
import '../utils/theme.dart';
import '../utils/toast.dart';
import '../widgets/page.dart';
import '../widgets/drawer.dart';
import '../widgets/edit_post.dart';
import '../widgets/end_drawer.dart';
import '../widgets/feed.dart';
import '../widgets/forum.dart';
import '../widgets/guide.dart';
import '../widgets/history.dart';
import '../widgets/scroll.dart';
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

abstract class PostListController extends ChangeNotifier {
  final RxInt _page;

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

  void refresh() => notifyListeners();

  void refreshPage([int page = 1]) {
    this.page = page;
    refresh();
  }
}

class PostListBinding implements Bindings {
  @override
  void dependencies() {
    late final PostListController controller;
    final uri = Uri.parse(Get.currentRoute);
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

class _PostListAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _PostListAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final data = PersistentDataService.to;
    final stacks = ControllerStacksService.to;
    final scaffold = Scaffold.of(context);

    return NotifyBuilder(
      animation: stacks.notifier,
      builder: (context, child) {
        final controller = PostListController.get();

        late final Widget button;
        if (stacks.controllersCount() > 1) {
          button = const BackButton(onPressed: postListPop);
        } else {
          button = IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => scaffold.openDrawer(),
          );
        }

        late final Widget title;
        switch (controller.postListType) {
          case PostListType.thread:
          case PostListType.onlyPoThread:
            title = ThreadAppBarTitle(controller as ThreadTypeController);
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

        return GestureDetector(
          onTap: controller.isThreadType
              ? controller.refresh
              : controller.refreshPage,
          child: AppBar(
            leading: button,
            title: data.showGuide ? AppBarTitleGuide(title) : title,
            actions: [
              if (controller.isXdnmbApi)
                controller.isThreadType
                    ? Obx(() {
                        final post = (controller as ThreadTypeController).post;

                        return PageButton(
                            controller: controller,
                            maxPage: post?.replyCount != null
                                ? (post!.replyCount! != 0
                                    ? (post.replyCount! / 19).ceil()
                                    : 1)
                                : null);
                      })
                    : data.showGuide
                        ? AppBarPageButtonGuide(
                            PageButton(controller: controller))
                        : PageButton(controller: controller),
              if (controller.isThreadType)
                NotifyBuilder(
                    animation: controller,
                    builder: (context, child) => ThreadAppBarPopupMenuButton(
                        controller as ThreadTypeController)),
              if (controller.isForumType)
                data.showGuide
                    ? AppBarMenuGuide(ForumAppBarPopupMenuButton(
                        controller as ForumTypeController))
                    : ForumAppBarPopupMenuButton(
                        controller as ForumTypeController),
              if (controller.isHistory)
                HistoryDateRangePicker(controller as HistoryController),
              if (controller.isHistory)
                HistoryAppBarPopupMenuButton(controller as HistoryController),
            ],
          ),
        );
      },
    );
  }
}

class _PostListPage<T> extends Page<T> {
  final PostListController controller;

  final bool maintainState;

  const _PostListPage(
      {super.key, required this.controller, this.maintainState = true});

  Route<T> _buildRoute() => GetPageRoute(
        settings: this,
        transition: Transition.rightToLeft,
        maintainState: maintainState,
        page: () {
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
        },
      );

  @override
  Route<T> createRoute(BuildContext context) => _buildRoute();
}

class _PageKey {
  final int key;

  final bool maintainState;

  const _PageKey(this.key, this.maintainState);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _PageKey &&
          key == other.key &&
          maintainState == other.maintainState);

  @override
  int get hashCode => Object.hash(key, maintainState);
}

/// 根据[DefaultTransitionDelegate]修改
class _PostListTransitionDelegate<T> extends TransitionDelegate<T> {
  /// Creates a transition delegate.
  const _PostListTransitionDelegate();

  @override
  Iterable<RouteTransitionRecord> resolve({
    required List<RouteTransitionRecord> newPageRouteHistory,
    required Map<RouteTransitionRecord?, RouteTransitionRecord>
        locationToExitingPageRoute,
    required Map<RouteTransitionRecord?, List<RouteTransitionRecord>>
        pageRouteToPagelessRoutes,
  }) {
    final List<RouteTransitionRecord> results = <RouteTransitionRecord>[];
    // This method will handle the exiting route and its corresponding pageless
    // route at this location. It will also recursively check if there is any
    // other exiting routes above it and handle them accordingly.
    void handleExitingRoute(RouteTransitionRecord? location, bool isLast) {
      final RouteTransitionRecord? exitingPageRoute =
          locationToExitingPageRoute[location];
      if (exitingPageRoute == null) {
        return;
      }
      if (exitingPageRoute.isWaitingForExitingDecision) {
        final bool hasPagelessRoute =
            pageRouteToPagelessRoutes.containsKey(exitingPageRoute);
        final bool isLastExitingPageRoute =
            isLast && !locationToExitingPageRoute.containsKey(exitingPageRoute);
        if (isLastExitingPageRoute && !hasPagelessRoute) {
          exitingPageRoute.markForPop(exitingPageRoute.route.currentResult);
        } else {
          exitingPageRoute
              .markForComplete(exitingPageRoute.route.currentResult);
        }
        if (hasPagelessRoute) {
          final List<RouteTransitionRecord> pagelessRoutes =
              pageRouteToPagelessRoutes[exitingPageRoute]!;
          for (final RouteTransitionRecord pagelessRoute in pagelessRoutes) {
            // It is possible that a pageless route that belongs to an exiting
            // page-based route does not require exiting decision. This can
            // happen if the page list is updated right after a Navigator.pop.
            if (pagelessRoute.isWaitingForExitingDecision) {
              if (isLastExitingPageRoute &&
                  pagelessRoute == pagelessRoutes.last) {
                pagelessRoute.markForPop(pagelessRoute.route.currentResult);
              } else {
                pagelessRoute
                    .markForComplete(pagelessRoute.route.currentResult);
              }
            }
          }
        }
      }
      results.add(exitingPageRoute);

      // It is possible there is another exiting route above this exitingPageRoute.
      handleExitingRoute(exitingPageRoute, isLast);
    }

    // Handles exiting route in the beginning of list.
    handleExitingRoute(null, newPageRouteHistory.isEmpty);

    for (final RouteTransitionRecord pageRoute in newPageRouteHistory) {
      final bool isLastIteration = newPageRouteHistory.last == pageRoute;
      if (pageRoute.isWaitingForEnteringDecision) {
        // 根据controller判断是否同一个route
        final isSame = locationToExitingPageRoute.values.any((record) {
          final locationPage = record.route.settings;
          final newPage = pageRoute.route.settings;

          if (locationPage is _PostListPage && newPage is _PostListPage) {
            return locationPage.controller == newPage.controller;
          }

          return false;
        });

        if (!isSame &&
            !locationToExitingPageRoute.containsKey(pageRoute) &&
            isLastIteration) {
          pageRoute.markForPush();
        } else {
          pageRoute.markForAdd();
        }
      }
      results.add(pageRoute);
      handleExitingRoute(pageRoute, isLastIteration);
    }

    return results;
  }
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

  final HashMap<int, bool> _maintainStateMap = HashMap();

  void _openDrawer() => Scaffold.of(context).openDrawer();

  void _closeDrawer() => Scaffold.of(context).closeDrawer();

  void _openEndDrawer() => Scaffold.of(context).openEndDrawer();

  void _closeEndDrawer() => Scaffold.of(context).closeEndDrawer();

  void _startDrawerGuide() => WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) => Future.delayed(const Duration(milliseconds: 200),
          () => ShowCaseWidget.of(context).startShowCase(Guide.drawerGuides)));

  void _startEndDrawerGuide() => WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) => Future.delayed(
          const Duration(milliseconds: 200),
          () =>
              ShowCaseWidget.of(context).startShowCase(Guide.endDrawerGuides)));

  void jumpToPage(int page) {
    _pageController.jumpToPage(page);
    ControllerStacksService.to.index = page;
  }

  void jumpToLast() => jumpToPage(ControllerStacksService.to.length - 1);

  Widget _buildNavigator(int index) {
    final stacks = ControllerStacksService.to;

    debugPrint('build navigator: $index');

    return NotifyBuilder(
      animation: stacks.getStackNotifier(index),
      builder: (context, child) {
        final controllers = stacks.getControllers(index);
        if (controllers.isNotEmpty) {
          final key = controllers.last.key;
          final maintainState = _maintainStateMap[key];
          if (maintainState != null && !maintainState) {
            _maintainStateMap[key] = true;
          }
        }

        return Navigator(
          key: Get.nestedKey(stacks.getKeyId(index)),
          transitionDelegate: const _PostListTransitionDelegate(),
          pages: [
            for (final controller in controllers)
              _PostListPage(
                key: ValueKey(_PageKey(
                    controller.key, _maintainStateMap[controller.key] ?? true)),
                controller: controller.controller,
                maintainState: _maintainStateMap[controller.key] ?? true,
              ),
          ],
          onPopPage: (route, result) {
            stacks.popController(index);

            return route.didPop(result);
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    final stacks = ControllerStacksService.to;
    _pageController = PageController(initialPage: stacks.index);
    for (final key in stacks.getControllerKeys()) {
      _maintainStateMap[key] = false;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold.of(context);

    debugPrint('build page');

    final Widget page = Obx(
      () => PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: ControllerStacksService.to.length,
        itemBuilder: (context, index) => _buildNavigator(index),
      ),
    );

    return GetPlatform.isDesktop
        ? SwipeDetector(
            onSwipeLeft: (offset) => scaffold.openEndDrawer(),
            onSwipeRight: (offset) => scaffold.openDrawer(),
            child: page,
          )
        : page;
  }
}

class _SaveDraftDialog extends StatelessWidget {
  final EditPostController controller;

  final bool canPost;

  const _SaveDraftDialog(
      {super.key, required this.controller, required this.canPost});

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
        builder: (context, value, child) => (PostListController.get().canPost &&
                (!settings.hideFloatingButton || hasBottomSheet))
            ? Padding(
                padding: EdgeInsets.only(bottom: hasBottomSheet ? 56.0 : 0.0),
                child: FloatingActionButton(
                  tooltip: hasBottomSheet ? '收起' : '发串',
                  onPressed: bottomSheet,
                  child: Icon(
                    hasBottomSheet ? Icons.arrow_downward : Icons.edit,
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({super.key});

  @override
  Widget build(BuildContext context) => NotifyBuilder(
        animation: ControllerStacksService.to.notifier,
        builder: (context, child) {
          final controller = PostListController.get();

          return controller.isHistory
              ? HistoryBottomBar(controller as HistoryController)
              : const SizedBox.shrink();
        },
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
    final media = MediaQuery.of(context);
    final bottomSheetHeight = media.size.height * 0.4;

    final blacklist = BlacklistService.to;
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
      child: Obx(
        () {
          if (blacklist.isReady.value &&
              data.isReady.value &&
              drafts.isReady.value &&
              emoticons.isReady.value &&
              forums.isReady.value &&
              history.isReady.value &&
              settings.isReady.value &&
              stacks.isReady.value &&
              user.isReady.value) {
            if (_isInitial) {
              //data.showGuide = true;

              // 出现用户指导时更新和公告延后显示
              if (!data.showGuide) {
                WidgetsBinding.instance.addPostFrameCallback(
                    (timeStamp) => CheckAppVersionService.to.checkAppVersion());

                // 公告的显示需要postList的navigator
                WidgetsBinding.instance
                    .addPostFrameCallback((timeStamp) => data.showNotice());
              }

              _isInitial = false;
            }

            final floatingButton = FloatingButton(
              key: FloatingButton.buttonKey,
              bottomSheetController: _bottomSheetController,
              bottomSheetHeight: bottomSheetHeight,
            );

            final scaffold = Scaffold(
              appBar: const _PostListAppBar(),
              body: Column(
                children: [
                  Expanded(child: PostListPage(key: PostListPage.pageKey)),
                  if (_bottomSheetController.value != null)
                    SizedBox(height: bottomSheetHeight),
                ],
              ),
              drawerEnableOpenDragGesture: !data.isKeyboardVisible.value,
              endDrawerEnableOpenDragGesture: !data.isKeyboardVisible.value,
              drawerEdgeDragWidth: media.size.width * settings.drawerDragRatio,
              drawer: const AppDrawer(),
              endDrawer: const AppEndDrawer(),
              floatingActionButton: data.showGuide
                  ? FloatingButtonGuide(floatingButton)
                  : floatingButton,
              bottomNavigationBar: const _BottomBar(),
            );

            return data.showGuide
                ? ShowCaseWidget(
                    onFinish: () {
                      if (Guide.isShowForumGuides) {
                        Guide.isShowForumGuides = false;
                        Guide.isShowDrawerGuides = true;
                        PostListPage.pageKey.currentState!._openDrawer();
                        PostListPage.pageKey.currentState!._startDrawerGuide();
                      } else if (Guide.isShowDrawerGuides) {
                        Guide.isShowDrawerGuides = false;
                        PostListPage.pageKey.currentState!._closeDrawer();
                        Guide.isShowEndDrawerGuides = true;
                        PostListPage.pageKey.currentState!._openEndDrawer();
                        PostListPage.pageKey.currentState!
                            ._startEndDrawerGuide();
                      } else if (Guide.isShowEndDrawerGuides) {
                        Guide.isShowEndDrawerGuides = false;
                        PostListPage.pageKey.currentState!._closeEndDrawer();
                        data.showGuide = false;
                        CheckAppVersionService.to.checkAppVersion();
                        data.showNotice();
                      }
                    },
                    builder: Builder(builder: (context) => scaffold))
                : scaffold;
          } else {
            return const Center(child: Text('启动中', style: AppTheme.boldRed));
          }
        },
      ),
    );
  }
}
