import 'dart:async';

import 'package:anchor_scroll_controller/anchor_scroll_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../data/models/controller.dart';
import '../data/models/history.dart';
import '../data/services/blacklist.dart';
import '../data/services/history.dart';
import '../data/services/settings.dart';
import '../data/services/time.dart';
import '../data/services/xdnmb_client.dart';
import '../modules/edit_post.dart';
import '../modules/post_list.dart';
import '../routes/routes.dart';
import '../utils/exception.dart';
import '../utils/extensions.dart';
import '../utils/navigation.dart';
import '../utils/post_list.dart';
import '../utils/theme.dart';
import '../utils/toast.dart';
import '../utils/url.dart';
import 'bilistview.dart';
import 'dialog.dart';
import 'edit_post.dart';
import 'forum_name.dart';
import 'listenable.dart';
import 'loading.dart';
import 'post.dart';
import 'post_list.dart';

class _DumbPost implements PostBase {
  @override
  int get id => 0;

  @override
  int? get forumId => null;

  @override
  int? get replyCount => null;

  @override
  String get image => '';

  @override
  String get imageExtension => '';

  @override
  DateTime get postTime => TimeService.to.now;

  @override
  String get userHash => '';

  @override
  String get name => '';

  @override
  String get title => '';

  @override
  String get content => '';

  @override
  bool? get isSage => null;

  @override
  bool get isAdmin => false;

  @override
  bool? get isHidden => null;

  const _DumbPost();
}

class _DumpTip extends _DumbPost {
  const _DumpTip();
}

abstract class ThreadTypeController extends PostListController {
  @override
  final int id;

  final Rxn<PostBase> _post;

  final bool cancelAutoJump;

  int? browsePostId;

  PostBase? get post => _post.value;

  set post(PostBase? post) => _post.value = post;

  int? get jumpToId;

  ThreadTypeController(
      {required this.id,
      required int page,
      PostBase? post,
      this.cancelAutoJump = false})
      : _post = Rxn(post),
        super(page);

  factory ThreadTypeController.fromPost(
          {required PostBase post, int page = 1, isOnlyPoThread = false}) =>
      isOnlyPoThread
          ? OnlyPoThreadController(id: post.id, page: page, post: post)
          : ThreadController(id: post.id, page: page, post: post);

  ThreadTypeController copyPage([int? jumpToId]);
}

class ThreadController extends ThreadTypeController {
  @override
  final int? jumpToId;

  VoidCallback? _loadMore;

  @override
  PostListType get postListType => PostListType.thread;

  ThreadController(
      {required int id,
      required int page,
      PostBase? post,
      bool cancelAutoJump = false,
      this.jumpToId})
      : super(id: id, page: page, post: post, cancelAutoJump: cancelAutoJump);

  @override
  ThreadTypeController copyPage([int? jumpToId]) =>
      ThreadController(id: id, page: page, post: post, jumpToId: jumpToId);

  void loadMore() => _loadMore?.call();
}

class OnlyPoThreadController extends ThreadTypeController {
  @override
  final int? jumpToId;

  @override
  PostListType get postListType => PostListType.onlyPoThread;

  OnlyPoThreadController(
      {required int id,
      required int page,
      PostBase? post,
      bool cancelAutoJump = false,
      this.jumpToId})
      : super(id: id, page: page, post: post, cancelAutoJump: cancelAutoJump);

  @override
  ThreadTypeController copyPage([int? jumpToId]) => OnlyPoThreadController(
      id: id, page: page, post: post, jumpToId: jumpToId);
}

ThreadController threadController(
        Map<String, String?> parameters, Object? arguments) =>
    ThreadController(
        id: parameters['mainPostId'].tryParseInt() ?? 0,
        page: parameters['page'].tryParseInt() ?? 1,
        post: arguments is PostBase ? arguments : null,
        cancelAutoJump: parameters['cancelAutoJump'].tryParseBool() ?? false,
        jumpToId: parameters['jumpToId'].tryParseInt());

OnlyPoThreadController onlyPoThreadController(
        Map<String, String?> parameters, Object? arguments) =>
    OnlyPoThreadController(
        id: parameters['mainPostId'].tryParseInt() ?? 0,
        page: parameters['page'].tryParseInt() ?? 1,
        post: arguments is PostBase ? arguments : null,
        cancelAutoJump: parameters['cancelAutoJump'].tryParseBool() ?? false,
        jumpToId: parameters['jumpToId'].tryParseInt());

class ThreadAppBarTitle extends StatelessWidget {
  final ThreadTypeController controller;

  const ThreadAppBarTitle(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(
          () => Row(
            children: [
              Text(controller.id.toPostNumber()),
              if (controller.isOnlyPoThread) const Flexible(child: Text('Po')),
              if (controller.post?.isSage ?? false)
                const Flexible(child: Text('SAGE', style: AppTheme.boldRed)),
            ].withSpaceBetween(width: 5.0),
          ),
        ),
        DefaultTextStyle.merge(
          style: theme.textTheme.bodyMedium!
              .apply(color: theme.colorScheme.onPrimary),
          child: Obx(
            () {
              final forumId = controller.post?.forumId;

              return Row(
                children: [
                  const Text('X岛 nmbxd.com'),
                  if (forumId != null)
                    Flexible(
                      child: ForumName(
                        forumId: forumId,
                        isDisplay: false,
                        maxLines: 1,
                      ),
                    ),
                ].withSpaceBetween(width: 5.0),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ThreadDialog extends StatelessWidget {
  final ThreadTypeController controller;

  final PostBase post;

  final int page;

  const _ThreadDialog(
      // ignore: unused_element
      {super.key,
      required this.controller,
      required this.post,
      required this.page});

  @override
  Widget build(BuildContext context) => SimpleDialog(
        title: Text(post.toPostNumber()),
        children: [
          if (post is! Tip)
            SimpleDialogOption(
              onPressed: () {
                _replyPost(controller, post.id);
                postListBack();
              },
              child: Text('回复', style: Theme.of(context).textTheme.titleMedium),
            ),
          if (post is! Tip) Report(post.id),
          if (post is! Tip && controller.post != null)
            SharePost(
              mainPostId: controller.post!.id,
              isOnlyPo: controller.isOnlyPoThread,
              page: page,
              postId: post.id,
            ),
          if (post is! Tip && !post.isAdmin)
            BlockPost(
              postId: post.id,
              onBlock: () {
                if (controller.post?.id == post.id) {
                  controller.refresh();
                }
              },
            ),
          if (post is! Tip && !post.isAdmin)
            BlockUser(
              userHash: post.userHash,
              onBlock: () {
                if (controller.post?.userHash == post.userHash) {
                  controller.refresh();
                }
              },
            ),
          if (post is! Tip) CopyPostId(post.id),
          if (post is! Tip) CopyPostReference(post.id),
          CopyPostContent(post),
        ],
      );
}

class ThreadAppBarPopupMenuButton extends StatelessWidget {
  final ThreadTypeController controller;

  const ThreadAppBarPopupMenuButton(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final blacklist = BlacklistService.to;
    final postId = controller.id;

    return Obx(() {
      final mainPost = controller.post;
      final isBlockedPost = blacklist.hasPost(postId);
      final isBlockedUser =
          mainPost != null ? blacklist.hasUser(mainPost.userHash) : false;

      return PopupMenuButton(
        itemBuilder: (context) => [
          if (mainPost != null && mainPost.forumId != null)
            PopupMenuItem(
              onTap: () => showForumRuleDialog(mainPost.forumId!),
              child: const Text('版规'),
            ),
          PopupMenuItem(
              onTap: BottomSheetController.editPostController.showEditPost,
              child: const Text('回复')),
          PopupMenuItem(
            onTap: () async {
              try {
                await XdnmbClientService.to.client
                    .addFeed(SettingsService.to.feedId, postId);
                showToast('订阅 ${postId.toPostNumber()} 成功');
              } catch (e) {
                showToast(
                    '订阅 ${postId.toPostNumber()} 失败：${exceptionMessage(e)}');
              }
            },
            child: const Text('订阅'),
          ),
          PopupMenuItem(
            onTap: () => WidgetsBinding.instance.addPostFrameCallback(
              (timeStamp) => AppRoutes.toEditPost(
                postListType: PostListType.forum,
                id: EditPost.dutyRoomId,
                forumId: EditPost.dutyRoomId,
                content: '${postId.toPostReference()}\n',
              ),
            ),
            child: const Text('举报'),
          ),
          PopupMenuItem(
            onTap: () async {
              await Clipboard.setData(ClipboardData(
                  text: Urls.threadUrl(
                      mainPostId: postId,
                      isOnlyPo: controller.isOnlyPoThread)));
              showToast('已复制串 ${postId.toPostNumber()} 链接');
            },
            child: const Text('分享'),
          ),
          if (controller.isThread && !isBlockedPost && !isBlockedUser)
            PopupMenuItem(
              onTap: () => AppRoutes.toOnlyPoThread(
                  mainPostId: postId, mainPost: mainPost),
              child: const Text('只看Po'),
            ),
          if (((mainPost != null && !mainPost.isAdmin) || mainPost == null) &&
              !isBlockedPost)
            PopupMenuItem(
              onTap: () => postListDialog(
                ConfirmCancelDialog(
                  content: '确定屏蔽主串 ${postId.toPostNumber()} ？',
                  onConfirm: () async {
                    await blacklist.blockPost(postId);
                    controller.refresh();
                    showToast('屏蔽主串 ${postId.toPostNumber()}');
                    postListBack();
                  },
                  onCancel: () => postListBack(),
                ),
              ),
              child: const Text('屏蔽主串'),
            ),
          if (mainPost != null && !mainPost.isAdmin && !isBlockedUser)
            PopupMenuItem(
              onTap: () => postListDialog(ConfirmCancelDialog(
                content: '确定屏蔽Po饼干 ${mainPost.userHash} ？',
                onConfirm: () async {
                  await blacklist.blockUser(mainPost.userHash);
                  controller.refresh();
                  showToast('屏蔽Po饼干 ${mainPost.userHash}');
                  postListBack();
                },
                onCancel: () => postListBack(),
              )),
              child: const Text('屏蔽Po饼干'),
            ),
          if (controller.isOnlyPoThread && !isBlockedPost && !isBlockedUser)
            PopupMenuItem(
              onTap: () =>
                  AppRoutes.toThread(mainPostId: postId, mainPost: mainPost),
              child: const Text('取消只看Po'),
            ),
          if (isBlockedPost)
            PopupMenuItem(
              onTap: () async {
                await blacklist.unblockPost(postId);
                controller.refresh();
                showToast('取消屏蔽主串 ${postId.toPostNumber()}');
              },
              child: const Text('取消屏蔽主串'),
            ),
          if (isBlockedUser)
            PopupMenuItem(
              onTap: () async {
                await blacklist.unblockUser(mainPost.userHash);
                controller.refresh();
                showToast('取消屏蔽Po饼干 ${mainPost.userHash}');
              },
              child: const Text('取消屏蔽Po饼干'),
            ),
          if (!isBlockedPost && !isBlockedUser)
            PopupMenuItem(
              onTap: () {
                openNewTab(controller.copyPage());

                showToast('已在新标签页打开 ${postId.toPostNumber()}');
              },
              child: const Text('在新标签页打开'),
            ),
          if (!isBlockedPost && !isBlockedUser)
            PopupMenuItem(
              onTap: () {
                openNewTabBackground(controller.copyPage());

                showToast('已在新标签页后台打开 ${postId.toPostNumber()}');
              },
              child: const Text('在新标签页后台打开'),
            ),
        ],
      );
    });
  }
}

class ThreadBody extends StatefulWidget {
  final ThreadTypeController controller;

  const ThreadBody(this.controller, {super.key});

  @override
  State<ThreadBody> createState() => _ThreadBodyState();
}

class _ThreadBodyState extends State<ThreadBody> {
  static const Duration _saveBrowseHistoryPeriod = Duration(seconds: 2);

  bool _isSavingBrowseHistory = false;

  BrowseHistory? _history;

  late final PostListScrollController _anchorController;

  /// 第一次加载是否要跳转
  final RxBool _isToJump = false.obs;

  bool _isNoMoreItems = false;

  int _maxPage = 1;

  late StreamSubscription<int> _pageSubscription;

  final BiListViewController biListViewController = BiListViewController();

  late final Future<void> _getHistory;

  ThreadTypeController get controller => widget.controller;

  Future<void> _saveBrowseHistory() async {
    if (!_isSavingBrowseHistory) {
      _isSavingBrowseHistory = true;

      try {
        await Future.delayed(_saveBrowseHistoryPeriod, () async {
          final post = controller.post;
          final browsePostId = controller.browsePostId;
          if (_history != null && post is Post && browsePostId != null) {
            _history!.update(
                mainPost: post,
                browsePage: controller.page,
                browsePostId: browsePostId,
                isOnlyPo: controller.isOnlyPoThread);
            await PostHistoryService.to.saveBrowseHistory(_history!);
          }
        });
      } finally {
        _isSavingBrowseHistory = false;
      }
    }
  }

  void _saveHistoryAndJumpToIndex(Thread thread, int firstPage, int page) {
    if (page == firstPage) {
      final history = PostHistoryService.to;
      final jumpToId = controller.jumpToId;
      final isOnlyPoThread = controller.isOnlyPoThread;

      if (page == 1 || thread.replies.isNotEmpty) {
        final Post firstPost =
            page == 1 ? thread.mainPost : thread.replies.first;

        void updateHistory() {
          if (_history != null) {
            _history!.update(
                mainPost: thread.mainPost,
                browsePage: page,
                browsePostId: firstPost.id,
                isOnlyPo: isOnlyPoThread);
            history.saveBrowseHistory(_history!);
          }
        }

        _history ??= BrowseHistory.fromPost(
            mainPost: thread.mainPost,
            browsePage: page,
            browsePostId: firstPost.id,
            isOnlyPo: isOnlyPoThread);

        if (_isToJump.value) {
          final index = jumpToId?.postIdToPostIndex(page) ??
              _history!.toIndex(isOnlyPo: isOnlyPoThread);
          if (index != null) {
            final postIds = thread.replies
                .where((post) => !post.isBlocked())
                .map((post) => post.id);
            final id = index.getPostIdFromPostIndex();
            if (postIds.contains(id)) {
              // 存在目标ID时
              WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                Future.delayed(const Duration(milliseconds: 50), () async {
                  try {
                    if (mounted && _isToJump.value) {
                      await _anchorController.scrollToIndex(
                          index: index, scrollSpeed: 10.0);

                      if (firstPost.id != id) {
                        while (mounted &&
                            _isToJump.value &&
                            id != controller.browsePostId &&
                            !_isNoMoreItems) {
                          await Future.delayed(const Duration(milliseconds: 50),
                              () async {
                            if (mounted && _isToJump.value) {
                              await _anchorController.scrollToIndex(
                                  index: index, scrollSpeed: 10.0);
                            }
                          });
                        }
                      } else {
                        updateHistory();
                      }
                    } else {
                      updateHistory();
                    }
                  } catch (e) {
                    showToast('跳转到串号 $id 失败：$e');
                  } finally {
                    _isToJump.value = false;
                  }
                }).timeout(
                  const Duration(seconds: 2),
                  onTimeout: () {
                    showToast('跳转到串号 $id 超时');
                    _isToJump.value = false;
                  },
                );
              });
            } else {
              updateHistory();
              _isToJump.value = false;
            }
          } else {
            updateHistory();
            _isToJump.value = false;
          }
        } else {
          // 用户主动加载的不要保存
          if (!biListViewController.isLoadingMore) {
            updateHistory();
          }
        }
      } else {
        _isToJump.value = false;
      }
    }
  }

  Future<List<PostWithPage>> _fetch(int firstPage, int page) async {
    final client = XdnmbClientService.to.client;
    final blacklist = BlacklistService.to;
    final postId = controller.id;

    final thread = controller.isThread
        ? await client.getThread(postId, page: page)
        : await client.getOnlyPoThread(postId, page: page);
    final mainPost = thread.mainPost;

    _maxPage = thread.maxPage;
    controller.post = mainPost;
    // 发现Po饼干被屏蔽就刷新页面
    if (page == firstPage &&
        !mainPost.isAdmin &&
        blacklist.hasUser(mainPost.userHash)) {
      controller.refresh();
    }

    if (page != 1 && thread.replies.isEmpty) {
      if (page == firstPage) {
        _isToJump.value = false;
      }
      return [];
    }

    _saveHistoryAndJumpToIndex(thread, firstPage, page);

    final List<PostWithPage> posts = [];
    if (page == 1) {
      posts.add(PostWithPage(mainPost, page));
    }
    if (thread.tip != null) {
      posts.add(PostWithPage(thread.tip!, page));
    } else {
      posts.add(PostWithPage(const _DumpTip(), page));
    }
    if (thread.replies.isNotEmpty) {
      posts.addAll(thread.replies.map((post) => PostWithPage(post, page)));
    }

    return posts;
  }

  Widget _itemBuilder(BuildContext context, PostWithPage postWithPage) {
    final post = postWithPage.post;

    if (post is _DumpTip) {
      return const SizedBox.shrink();
    } else if (post is _DumbPost) {
      return _itemWithDivider(Center(
        child: Text(
          '第${postWithPage.page}页 空页',
          style: AppTheme.boldRedPostContentTextStyle,
          strutStyle: AppTheme.boldRedPostContentStrutStyle,
        ),
      ));
    }

    final theme = Theme.of(context);
    final mainPost = controller.post;

    final Widget item = PostInkWell(
      key: post is Tip ? UniqueKey() : null,
      post: post,
      poUserHash: mainPost?.userHash,
      onLinkTap: (context, link, text) => parseUrl(
          url: link, mainPostId: mainPost?.id, poUserHash: mainPost?.userHash),
      onImagePainted: (imageData) => _replyWithImage(controller, imageData),
      canReturnImageData: true,
      canTapHiddenText: true,
      showForumName: false,
      showReplyCount: false,
      showPoTag: true,
      onPostIdTap:
          post is! Tip ? (postId) => _replyPost(controller, postId) : null,
      onTap: (post) {},
      onLongPress: (post) => postListDialog(_ThreadDialog(
        controller: controller,
        post: post,
        page: postWithPage.page,
      )),
      mouseCursor: SystemMouseCursors.basic,
      hoverColor:
          Get.isDarkMode ? theme.cardColor : theme.scaffoldBackgroundColor,
    );

    return post is! Tip
        ? ListenableBuilder(
            listenable: BlacklistService.to.postAndUserBlacklistNotifier,
            builder: (context, child) => !post.isBlocked()
                ? _itemWithDivider(
                    AnchorItemWrapper(
                      key: postWithPage.toValueKey(),
                      controller: _anchorController,
                      index: postWithPage.toIndex(),
                      child: item,
                    ),
                  )
                : const SizedBox.shrink(),
          )
        : _itemWithDivider(item);
  }

  Widget _body() {
    final blacklist = BlacklistService.to;
    final postId = controller.id;

    return PostListScrollView(
      controller: controller,
      scrollController: _anchorController,
      builder: (context, scrollController, refresh) {
        final firstPage = controller.page;

        bool isBlocked() {
          final mainPost = controller.post;

          return (mainPost == null || !mainPost.isAdmin) &&
              (blacklist.hasPost(postId) ||
                  (mainPost != null && blacklist.hasUser(mainPost.userHash)));
        }

        if (isBlocked()) {
          WidgetsBinding.instance
              .addPostFrameCallback((timeStamp) => showHidden());
        }

        return !isBlocked()
            ? Obx(
                () => Stack(
                  children: [
                    if (_isToJump.value) const QuotationLoadingIndicator(),
                    Visibility(
                      visible: !_isToJump.value,
                      maintainState: true,
                      maintainAnimation: true,
                      maintainSize: true,
                      child: BiListView<PostWithPage>(
                        key: ValueKey<int>(refresh),
                        controller: biListViewController,
                        scrollController: scrollController,
                        postListController: controller,
                        initialPage: firstPage,
                        fetch: (page) async {
                          try {
                            return await _fetch(firstPage, page);
                          } catch (e) {
                            _isToJump.value = false;
                            rethrow;
                          }
                        },
                        itemBuilder: (context, post, index) =>
                            _itemBuilder(context, post),
                        noItemsFoundBuilder: (context) => Center(
                          child: Text(
                            '没有串',
                            style: AppTheme.boldRedPostContentTextStyle,
                            strutStyle: AppTheme.boldRedPostContentStrutStyle,
                          ),
                        ),
                        onNoMoreItems: () => _isNoMoreItems = true,
                        onRefreshAndLoadMore: () {
                          if (isBlocked()) {
                            controller.refresh();
                          }
                        },
                        fetchFallback: (page) => Future.value(
                          [PostWithPage(const _DumbPost(), page)],
                        ),
                        getMaxPage: () => _maxPage,
                      ),
                    ),
                  ],
                ),
              )
            : GestureDetector(
                onTap: controller.refresh,
                child: Center(
                  child: Text(
                    '本串已被屏蔽',
                    style: AppTheme.boldRedPostContentTextStyle,
                    strutStyle: AppTheme.boldRedPostContentStrutStyle,
                  ),
                ),
              );
      },
    );
  }

  void _cancelJump() => _isToJump.value = false;

  void _setToJump() {
    _isToJump.value = true;
    controller.removeListener(_cancelJump);
    controller.addListener(_cancelJump);
  }

  void _trySave(int page) => controller.trySave();

  @override
  void initState() {
    super.initState();

    final settings = SettingsService.to;

    _anchorController = PostListScrollController(
      getInitialScrollOffset: () =>
          settings.autoHideAppBar ? -controller.appBarHeight : 0.0,
      getAnchorOffset: () =>
          settings.autoHideAppBar ? controller.appBarHeight : 0.0,
      onIndexChanged: (index, userScroll) {
        controller.page = index.getPageFromPostIndex();
        controller.browsePostId = index.getPostIdFromPostIndex();

        _saveBrowseHistory();
      },
    );

    _pageSubscription = controller.listenPage(_trySave);

    final replyCount = controller.post?.replyCount;
    if (replyCount != null) {
      _maxPage = replyCount > 0 ? (replyCount / 19).ceil() : 1;
    }

    if (controller.isThread) {
      (controller as ThreadController)._loadMore =
          biListViewController.loadMore;
    }

    _getHistory = Future(() async {
      final settings = SettingsService.to;

      _history = await PostHistoryService.to.getBrowseHistory(controller.id);

      if (controller.jumpToId == null) {
        if (!controller.cancelAutoJump &&
            settings.isJumpToLastBrowsePage &&
            _history != null) {
          final page = controller.isThread
              ? _history!.browsePage
              : _history!.onlyPoBrowsePage;
          if (page != null) {
            controller.page = page;

            if (settings.isJumpToLastBrowsePosition) {
              _setToJump();
            }
          }
        }
      } else {
        _setToJump();
      }
    });
  }

  @override
  void didUpdateWidget(covariant ThreadBody oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (controller != oldWidget.controller) {
      if (oldWidget.controller.isThread) {
        (oldWidget.controller as ThreadController)._loadMore = null;
      }
      oldWidget.controller.removeListener(_cancelJump);

      _pageSubscription.cancel();
      _pageSubscription = controller.listenPage(_trySave);
      if (controller.isThread) {
        (controller as ThreadController)._loadMore =
            biListViewController.loadMore;
      }
    }
  }

  @override
  void dispose() {
    if (controller.isThread) {
      (controller as ThreadController)._loadMore = null;
    }

    _isToJump.value = false;
    _anchorController.dispose();
    controller.removeListener(_cancelJump);
    _pageSubscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
        future: _getHistory,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasError) {
            showToast('读取数据库出错：${snapshot.error!}');
          }

          if (snapshot.connectionState == ConnectionState.none ||
              snapshot.connectionState == ConnectionState.done) {
            return _body();
          }

          return const SizedBox.shrink();
        },
      );
}

Widget _itemWithDivider(Widget widget) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [widget, const Divider(height: 10.0, thickness: 1.0)],
    );

void _replyPost(ThreadTypeController controller, int postId) {
  final text = '${postId.toPostReference()}\n';

  final editPostController = BottomSheetController.editPostController;
  if (editPostController.isShowed) {
    EditPostCallback.bottomSheet?.insertText(text);
  } else {
    editPostController.showEditPost(EditPostController(
        postListType: controller.postListType,
        id: controller.id,
        forumId: controller.forumId,
        poUserHash: controller.post?.userHash,
        content: text));
  }
}

void _replyWithImage(ThreadTypeController controller, Uint8List imageData) {
  final editPostController = BottomSheetController.editPostController;
  if (editPostController.isShowed) {
    EditPostCallback.bottomSheet?.insertImage(imageData);
  } else {
    editPostController.showEditPost(EditPostController(
        postListType: controller.postListType,
        id: controller.id,
        forumId: controller.forumId,
        poUserHash: controller.post?.userHash,
        imageData: imageData));
  }
}
