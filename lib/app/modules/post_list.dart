import 'package:flutter/material.dart';
import 'package:flutter_swipe_detector/flutter_swipe_detector.dart';
import 'package:get/get.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../data/models/draft.dart';
import '../data/models/forum.dart';
import '../data/services/drafts.dart';
import '../data/services/forum.dart';
import '../data/services/persistent.dart';
import '../data/services/history.dart';
import '../data/services/settings.dart';
import '../data/services/user.dart';
import '../modules/edit_post.dart';
import '../routes/routes.dart';
import '../utils/navigation.dart';
import '../utils/toast.dart';
import '../widgets/button.dart';
import '../widgets/drawer.dart';
import '../widgets/edit_post.dart';
import '../widgets/end_drawer.dart';
import '../widgets/feed.dart';
import '../widgets/forum.dart';
import '../widgets/history.dart';
import '../widgets/scroll.dart';
import '../widgets/thread.dart';
import 'stack_cache.dart';

enum PostListType {
  thread,
  onlyPoThread,
  forum,
  timeline,
  feed,
  history;

  bool isThread() => this == thread;

  bool isOnlyPoThread() => this == onlyPoThread;

  bool isForum() => this == forum;

  bool isTimeline() => this == timeline;

  bool isFeed() => this == feed;

  bool isHistory() => this == history;

  bool isThreadType() => isThread() || isOnlyPoThread();

  bool isForumType() => isForum() || isTimeline();

  bool hasForumId() => isThreadType() || isForum();

  bool canPost() => isThreadType() || isForumType();

  bool isXdnmbApi() => isThreadType() || isForumType() || isFeed();
}

class PostList {
  final PostListType postListType;

  final int? id;

  final int page;

  const PostList({required this.postListType, this.id, this.page = 1});

  PostList.fromController(PostListController controller)
      : postListType = controller.postListType.value,
        id = controller.id.value,
        page = controller.page.value;

  PostList.fromPost(PostBase post)
      : postListType = PostListType.thread,
        id = post.id,
        page = 1;

  PostList.fromThread({required Thread thread, bool isThread = true})
      : postListType =
            isThread ? PostListType.thread : PostListType.onlyPoThread,
        id = thread.mainPost.id,
        page = 1;

  PostList.fromForumData(ForumData forum)
      : postListType =
            forum.isTimeline ? PostListType.timeline : PostListType.forum,
        id = forum.id,
        page = 1;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PostList &&
          postListType == other.postListType &&
          id == other.id &&
          page == other.page);

  @override
  int get hashCode => Object.hash(postListType, id, page);
}

class PostListController extends GetxController {
  final Rx<PostListType> postListType;

  final RxnInt id;

  final RxInt page;

  final RxInt currentPage;

  final RxnInt bottomBarIndex;

  final Rxn<PostBase> post;

  int? get forumOrTimelineId => postListType.value.isThreadType()
      ? post.value?.forumId
      : postListType.value.isForumType()
          ? id.value
          : null;

  int? get forumId =>
      postListType.value.hasForumId() ? forumOrTimelineId : null;

  PostListController(
      {required PostListType postListType,
      int? id,
      int page = 1,
      int? currentPage,
      int? bottomBarIndex,
      PostBase? post})
      : postListType = postListType.obs,
        id = RxnInt(id),
        page = page.obs,
        currentPage = currentPage != null ? currentPage.obs : page.obs,
        bottomBarIndex = RxnInt(bottomBarIndex),
        post = Rxn(post);

  PostListController.fromPostList({required PostList postList, PostBase? post})
      : postListType = postList.postListType.obs,
        id = RxnInt(postList.id),
        page = postList.page.obs,
        currentPage = postList.page.obs,
        bottomBarIndex = RxnInt(null),
        post = Rxn(post);

  PostListController.fromPost({required PostBase post, int page = 1})
      : postListType = PostListType.thread.obs,
        id = RxnInt(post.id),
        page = page.obs,
        currentPage = page.obs,
        bottomBarIndex = RxnInt(null),
        post = Rxn(post);

  PostListController.fromThread(
      {required Thread thread, bool isThread = true, int page = 1})
      : postListType =
            (isThread ? PostListType.thread : PostListType.onlyPoThread).obs,
        id = RxnInt(thread.mainPost.id),
        page = page.obs,
        currentPage = page.obs,
        bottomBarIndex = RxnInt(null),
        post = Rxn(thread.mainPost);

  PostListController.fromForumData({required ForumData forum, int page = 1})
      : postListType =
            (forum.isTimeline ? PostListType.timeline : PostListType.forum).obs,
        id = RxnInt(forum.id),
        page = page.obs,
        currentPage = page.obs,
        bottomBarIndex = RxnInt(null),
        post = Rxn(null);

  /* void onlyPoThreadToThread({int page = 1}) {
    postListType.value = PostListType.thread;
    this.page.value = page;
    currentPage.value = page;
  }

  void threadToOnlyPoThread({int page = 1}) {
    postListType.value = PostListType.onlyPoThread;
    this.page.value = page;
    currentPage.value = page;
  } */

  /* void toForum({required int forumId, int page = 1}) {
    postListType.value = PostListType.forum;
    id.value = forumId;
    this.page.value = page;
    currentPage.value = page;
    post.value = null;
  }

  void toTimeline({required int timelineId, int page = 1}) {
    postListType.value = PostListType.timeline;
    id.value = timelineId;
    this.page.value = page;
    currentPage.value = page;
    post.value = null;
  } */

  /* void fromPostList({required PostList postList, PostBase? post}) {
    postListType.value = postList.postListType;
    id.value = postList.id;
    page.value = postList.page;
    currentPage.value = postList.page;
    this.post.value = post;
  } */

  PostListController copyKeepingPage() => PostListController(
      postListType: postListType.value,
      id: id.value,
      page: currentPage.value,
      currentPage: currentPage.value,
      post: post.value);
}

class PostListBinding implements Bindings {
  @override
  void dependencies() {
    Get.create<PostListController>(() {
      final uri = Uri.parse(Get.currentRoute);

      switch (uri.path) {
        case AppRoutes.thread:
          return threadController(Get.parameters, Get.arguments);
        case AppRoutes.onlyPoThread:
          return onlyPoThreadController(Get.parameters, Get.arguments);
        case AppRoutes.forum:
          return forumController(Get.parameters);
        case AppRoutes.timeline:
          return timelineController(Get.parameters);
        case AppRoutes.feed:
          return feedController(Get.parameters);
        case AppRoutes.history:
          return historyController(Get.parameters);
        default:
          throw '未知URI: $uri';
      }
    }, permanent: false);
  }
}

class _PostListAppBar extends StatefulWidget implements PreferredSizeWidget {
  static final GlobalKey<_PostListAppBarState> _appBarKey =
      GlobalKey<_PostListAppBarState>();

  const _PostListAppBar({super.key});

  @override
  State<_PostListAppBar> createState() => _PostListAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _PostListAppBarState extends State<_PostListAppBar> {
  void refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold.of(context);
    final controller = StackCacheView.getController() as PostListController;
    final postListType = controller.postListType;

    Widget button = IconButton(
      icon: const Icon(Icons.menu),
      onPressed: () => scaffold.openDrawer(),
      tooltip: '标签',
    );
    if (PostListPage.pageKey.currentState?._isBuilt == true) {
      if (StackCacheView.controllersCount() > 1) {
        button = BackButton(onPressed: () {
          popOnce();
          FloatingButton.buttonKey.currentState!.refresh();
          _BottomBar._bottomBarKey.currentState!.refresh();
          if (mounted) {
            setState(() {});
          }
        });
      }
    }

    return Obx(
      () {
        final post = controller.post.value;

        late final Widget title;
        int? maxPage;
        switch (postListType.value) {
          case PostListType.thread:
          case PostListType.onlyPoThread:
            title = ThreadAppBarTitle(controller);
            maxPage = post?.replyCount != null
                ? post!.replyCount! != 0
                    ? (post.replyCount! / 19).ceil()
                    : 1
                : null;
            break;
          case PostListType.forum:
          case PostListType.timeline:
            title = ForumAppBarTitle(controller);
            break;
          case PostListType.feed:
            title = const FeedAppBarTitle();
            break;
          case PostListType.history:
            title = const HistoryAppBarTitle();
            break;
        }

        return AppBar(
          leading: button,
          title: title,
          actions: [
            if (postListType.value.isXdnmbApi())
              PageButton(controller: controller, maxPage: maxPage),
            if (postListType.value.isThreadType())
              ThreadAppBarPopupMenuButton(controller),
            if (postListType.value.isForumType())
              ForumAppBarPopupMenuButton(controller),
          ],
        );
      },
    );
  }
}

Route buildRoute(PostListController controller) => GetPageRoute(
      page: () {
        final hasBeenDarkMode = SettingsService.to.hasBeenDarkMode;
        final postListType = controller.postListType;

        return Obx(
          () {
            final theme = Get.theme;

            late final Widget body;
            switch (postListType.value) {
              case PostListType.thread:
              case PostListType.onlyPoThread:
                body = ThreadBody(controller);
                break;
              case PostListType.forum:
              case PostListType.timeline:
                body = ForumBody(controller);
                break;
              case PostListType.feed:
                body = FeedBody(controller);
                break;
              case PostListType.history:
                body = HistoryBody(controller);
                break;
            }

            return Material(
              color: hasBeenDarkMode.value
                  ? (postListType.value.isThreadType()
                      ? theme.cardColor
                      : theme.scaffoldBackgroundColor)
                  : theme.scaffoldBackgroundColor,
              child: body,
            );
          },
        );
      },
      transition: Transition.rightToLeft,
    );

Widget buildNavigator(int index) {
  final controller =
      StackCacheView.getFirstController(index) as PostListController;

  debugPrint('build navigator: $index');

  late final String initialRoute;
  switch (controller.postListType.value) {
    case PostListType.thread:
      initialRoute = AppRoutes.threadUrl(controller.id.value!,
          page: controller.page.value);
      break;
    case PostListType.onlyPoThread:
      initialRoute = AppRoutes.onlyPoThreadUrl(controller.id.value!,
          page: controller.page.value);
      break;
    case PostListType.forum:
      initialRoute =
          AppRoutes.forumUrl(controller.id.value!, page: controller.page.value);
      break;
    case PostListType.timeline:
      initialRoute = AppRoutes.timelineUrl(controller.id.value!,
          page: controller.page.value);
      break;
    case PostListType.feed:
      initialRoute = AppRoutes.feedUrl(page: controller.page.value);
      break;
    case PostListType.history:
      initialRoute =
          AppRoutes.historyUrl(index: controller.bottomBarIndex.value ?? 0);
      break;
  }

  return Navigator(
    key: Get.nestedKey(StackCacheView.getKeyId(index)),
    initialRoute: initialRoute,
    onGenerateInitialRoutes: (navigator, initialRoute) {
      final controller =
          StackCacheView.getController(index) as PostListController;

      return [buildRoute(controller)];
    },
    onGenerateRoute: (settings) {
      final uri = Uri.parse(settings.name!);
      final parameters = uri.queryParameters;

      late final PostListController controller;
      switch (uri.path) {
        case AppRoutes.thread:
          controller = threadController(parameters, settings.arguments);
          break;
        case AppRoutes.onlyPoThread:
          controller = onlyPoThreadController(parameters, settings.arguments);
          break;
        case AppRoutes.forum:
          controller = forumController(parameters);
          break;
        case AppRoutes.timeline:
          controller = timelineController(parameters);
          break;
        case AppRoutes.feed:
          controller = feedController(parameters);
          break;
        case AppRoutes.history:
          controller = historyController(parameters);
          break;
        default:
          throw '未知PostList';
      }

      StackCacheView.pushController(controller, index);
      _PostListAppBar._appBarKey.currentState!.refresh();
      FloatingButton.buttonKey.currentState!.refresh();
      _BottomBar._bottomBarKey.currentState!.refresh();

      return buildRoute(controller);
    },
  );
}

class PostListPage extends StatefulWidget {
  static final GlobalKey<PostListPageState> pageKey =
      GlobalKey<PostListPageState>();

  const PostListPage({super.key});

  @override
  State<PostListPage> createState() => PostListPageState();
}

class PostListPageState extends State<PostListPage> {
  final PageController _pageController = PageController();

  bool _isBuilt = false;

  void jumpToPage(int page) {
    _pageController.jumpToPage(page);
    StackCacheView.index = page;

    _PostListAppBar._appBarKey.currentState!.refresh();
    FloatingButton.buttonKey.currentState!.refresh();
    _BottomBar._bottomBarKey.currentState!.refresh();
  }

  void jumpToLast() => jumpToPage(StackCacheView.length.value - 1);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback((timeStamp) => _isBuilt = true);
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

    final page = Obx(
      () => PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: StackCacheView.length.value,
        itemBuilder: (context, index) => buildNavigator(index),
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

  const _SaveDraftDialog(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      actionsPadding:
          const EdgeInsets.only(left: 10.0, right: 10.0, bottom: 10.0),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      content: const Text('保存为草稿？'),
      actions: [
        TextButton(
            onPressed: () => Get.back<bool>(result: true),
            child: const Text('不保存')),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
                onPressed: () => Get.back<bool>(result: false),
                child: const Text('返回')),
            TextButton(
                onPressed: () async {
                  await PostDraftsService.to
                      .addDraft(PostDraftData.fromController(controller));

                  showToast('已保存为草稿');
                  return Get.back<bool>(result: true);
                },
                child: const Text('保存')),
          ],
        )
      ],
    );
  }
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
      final controller = StackCacheView.getController() as PostListController;

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

  void refresh() {
    if (mounted) {
      final controller = StackCacheView.getController() as PostListController;

      setState(() {
        if (!controller.postListType.value.canPost() &&
            widget.bottomSheetController.value != null) {
          widget.bottomSheetController.value!.close();
        }
      });
    }
  }

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
          if (controller.hasText() &&
              !(await Get.dialog<bool>(_SaveDraftDialog(controller)) ??
                  false)) {
            final controller_ =
                StackCacheView.getController() as PostListController;
            if (!controller_.postListType.value.canPost()) {
              popOnce();
              _PostListAppBar._appBarKey.currentState!.refresh();
              _BottomBar._bottomBarKey.currentState!.refresh();
              if (mounted) {
                setState(() {});
              }
            }

            bottomSheet(controller);
          }
        }
      });
    } else {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = StackCacheView.getController() as PostListController;
    final postListType = controller.postListType;

    return Obx(
      () => postListType.value.canPost()
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
    );
  }
}

class _BottomBar extends StatefulWidget {
  static final GlobalKey<_BottomBarState> _bottomBarKey =
      GlobalKey<_BottomBarState>();

  const _BottomBar({super.key});

  @override
  State<_BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<_BottomBar> {
  void refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = StackCacheView.getController() as PostListController;
    final postListType = controller.postListType;

    return Obx(() => postListType.value.isHistory()
        ? HistoryBottomBar(controller)
        : const SizedBox.shrink());
  }
}

class PostListView extends StackCacheView<PostListController> {
  final Rxn<DateTime> _lastPressBackTime = Rxn(null);

  final Rxn<PersistentBottomSheetController> _bottomSheetController = Rxn(null);

  PostListView({super.key});

  Future<bool> _onWillPop(BuildContext context) async {
    if (Navigator.canPop(context)) {
      Get.back();

      return false;
    }
    if (postListkey()?.currentState?.canPop() ?? false) {
      popOnce();
      _PostListAppBar._appBarKey.currentState!.refresh();
      FloatingButton.buttonKey.currentState!.refresh();
      _BottomBar._bottomBarKey.currentState!.refresh();

      return false;
    }

    final now = DateTime.now();
    if (_lastPressBackTime.value == null ||
        now.difference(_lastPressBackTime.value!) >
            const Duration(seconds: 2)) {
      _lastPressBackTime.value = now;

      showToast('再按一次退出');
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomSheetHeight = media.size.height * 0.4;

    final data = PersistentDataService.to;
    final drafts = PostDraftsService.to;
    final forums = ForumListService.to;
    final history = PostHistoryService.to;
    final settings = SettingsService.to;
    final user = UserService.to;

    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: Obx(
        () => (data.isReady.value &&
                drafts.isReady.value &&
                forums.isReady.value &&
                history.isReady.value &&
                settings.isReady.value &&
                user.isReady.value)
            ? Scaffold(
                appBar: _PostListAppBar(key: _PostListAppBar._appBarKey),
                body: Column(
                  children: [
                    Expanded(child: PostListPage(key: PostListPage.pageKey)),
                    Obx(
                      () => (_bottomSheetController.value != null &&
                              !data.isKeyboardVisible.value)
                          ? SizedBox(height: bottomSheetHeight)
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
                drawerEdgeDragWidth: media.size.width / 2.0,
                drawer: const AppDrawer(),
                endDrawer: const AppEndDrawer(),
                floatingActionButton: FloatingButton(
                  key: FloatingButton.buttonKey,
                  bottomSheetController: _bottomSheetController,
                  bottomSheetHeight: bottomSheetHeight,
                ),
                bottomNavigationBar: _BottomBar(key: _BottomBar._bottomBarKey),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
