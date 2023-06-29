import 'dart:async';

import 'package:anchor_scroll_controller/anchor_scroll_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../data/models/controller.dart';
import '../data/models/history.dart';
import '../data/services/blacklist.dart';
import '../data/services/settings.dart';
import '../data/services/time.dart';
import '../data/services/xdnmb_client.dart';
import '../modules/edit_post.dart';
import '../modules/post_list.dart';
import '../routes/routes.dart';
import '../utils/exception.dart';
import '../utils/extensions.dart';
import '../utils/history.dart';
import '../utils/navigation.dart';
import '../utils/post.dart';
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

  @override
  PostType get postType => PostType.other;

  const _DumbPost();
}

class _DumpTip extends _DumbPost {
  const _DumpTip();
}

abstract class ThreadTypeController extends PostListController {
  @override
  final int id;

  final Rxn<PostBase> _mainPost;

  final bool cancelAutoJump;

  int? browsePostId;

  VoidCallback? _loadMore;

  PostBase? get mainPost => _mainPost.value;

  set mainPost(PostBase? post) => _mainPost.value = post;

  int? get jumpToId;

  ThreadTypeController(
      {required this.id,
      required int page,
      PostBase? mainPost,
      this.cancelAutoJump = false})
      : _mainPost = Rxn(mainPost),
        super(page);

  factory ThreadTypeController.fromPost(
          {required PostBase mainPost, int page = 1, isOnlyPoThread = false}) =>
      isOnlyPoThread
          ? OnlyPoThreadController(
              id: mainPost.id, page: page, mainPost: mainPost)
          : ThreadController(id: mainPost.id, page: page, mainPost: mainPost);

  ThreadTypeController copyPage([int? jumpToId]);

  void loadMore() => _loadMore?.call();
}

class ThreadController extends ThreadTypeController {
  @override
  final int? jumpToId;

  @override
  PostListType get postListType => PostListType.thread;

  ThreadController(
      {required int id,
      required int page,
      PostBase? mainPost,
      bool cancelAutoJump = false,
      this.jumpToId})
      : super(
            id: id,
            page: page,
            mainPost: mainPost,
            cancelAutoJump: cancelAutoJump);

  @override
  ThreadTypeController copyPage([int? jumpToId]) => ThreadController(
      id: id, page: page, mainPost: mainPost, jumpToId: jumpToId);
}

class OnlyPoThreadController extends ThreadTypeController {
  @override
  final int? jumpToId;

  @override
  PostListType get postListType => PostListType.onlyPoThread;

  OnlyPoThreadController(
      {required int id,
      required int page,
      PostBase? mainPost,
      bool cancelAutoJump = false,
      this.jumpToId})
      : super(
            id: id,
            page: page,
            mainPost: mainPost,
            cancelAutoJump: cancelAutoJump);

  @override
  ThreadTypeController copyPage([int? jumpToId]) => OnlyPoThreadController(
      id: id, page: page, mainPost: mainPost, jumpToId: jumpToId);
}

ThreadController threadController(
        Map<String, String?> parameters, Object? arguments) =>
    ThreadController(
        id: parameters['mainPostId'].tryParseInt() ?? 0,
        page: parameters['page'].tryParseInt() ?? 1,
        mainPost: arguments is PostBase ? arguments : null,
        cancelAutoJump: parameters['cancelAutoJump'].tryParseBool() ?? false,
        jumpToId: parameters['jumpToId'].tryParseInt());

OnlyPoThreadController onlyPoThreadController(
        Map<String, String?> parameters, Object? arguments) =>
    OnlyPoThreadController(
        id: parameters['mainPostId'].tryParseInt() ?? 0,
        page: parameters['page'].tryParseInt() ?? 1,
        mainPost: arguments is PostBase ? arguments : null,
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
              if (controller.mainPost?.isSage ?? false)
                const Flexible(child: Text('SAGE', style: AppTheme.boldRed)),
            ].withSpaceBetween(width: 5.0),
          ),
        ),
        DefaultTextStyle.merge(
          style: theme.textTheme.bodyMedium!
              .apply(color: theme.colorScheme.onPrimary),
          child: Obx(
            () {
              final forumId = controller.mainPost?.forumId;

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
          if (!post.isTipType)
            SimpleDialogOption(
              onPressed: () {
                _replyPost(controller, post.id);
                postListBack();
              },
              child: Text('回复', style: Theme.of(context).textTheme.titleMedium),
            ),
          if (!post.isTipType) Report(post.id),
          if (!post.isTipType && controller.mainPost != null)
            SharePost(
              mainPostId: controller.mainPost!.id,
              isOnlyPo: controller.isOnlyPoThread,
              page: page,
              postId: post.id,
            ),
          if (!post.isTipType) AddOrReplacePostTag(post: post),
          if (!post.isTipType && !post.isAdmin)
            BlockPost(
              postId: post.id,
              onBlock: () {
                if (controller.mainPost?.id == post.id) {
                  controller.refresh();
                }
              },
            ),
          if (!post.isTipType && !post.isAdmin)
            BlockUser(
              userHash: post.userHash,
              onBlock: () {
                if (controller.mainPost?.userHash == post.userHash) {
                  controller.refresh();
                }
              },
            ),
          if (!post.isTipType) CopyPostReference(post.id),
          CopyPostContent(post),
        ],
      );
}

class ThreadAppBarPopupMenuButton extends StatelessWidget {
  final ThreadTypeController controller;

  const ThreadAppBarPopupMenuButton(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;
    final client = XdnmbClientService.to.client;
    final blacklist = BlacklistService.to;
    final postId = controller.id;

    return Obx(() {
      final mainPost = controller.mainPost;
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
                await client.xdnmbAddFeed(postId);
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
          if (settings.addDeleteFeedInThread)
            PopupMenuItem(
              onTap: () => postListDialog(ConfirmCancelDialog(
                content: '确定取消订阅 ${postId.toPostNumber()} ？',
                onConfirm: () async {
                  postListBack();

                  try {
                    await client.xdnmbDeleteFeed(postId);
                    showToast('取消订阅 ${postId.toPostNumber()} 成功');
                  } catch (e) {
                    showToast(
                        '取消订阅 ${postId.toPostNumber()} 失败：${exceptionMessage(e)}');
                  }
                },
                onCancel: postListBack,
              )),
              child: const Text('取消订阅'),
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
                  onCancel: postListBack,
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
                onCancel: postListBack,
              )),
              child: const Text('屏蔽Po饼干'),
            ),
          if (controller.isOnlyPoThread && !isBlockedPost && !isBlockedUser)
            PopupMenuItem(
              onTap: () =>
                  AppRoutes.toThread(mainPostId: postId, mainPost: mainPost),
              child: const Text('取消只看Po'),
            ),
          if (mainPost != null)
            PopupMenuItem(
              onTap: () =>
                  postListDialog(AddOrReplacePostTagDialog(post: mainPost)),
              child: const Text('添加主串标签'),
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
          PopupMenuItem(
            onTap: () async {
              await Clipboard.setData(
                  ClipboardData(text: postId.toPostReference()));
              showToast('已复制 ${postId.toPostReference()}');
            },
            child: const Text('复制主串串号引用'),
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

  late PostListScrollController _anchorController;

  /// 第一次加载是否要跳转
  final RxBool _isToJump = false.obs;

  bool _isNoMoreItems = false;

  int _maxPage = 1;

  late StreamSubscription<int> _pageSubscription;

  final BiListViewController _biListViewController = BiListViewController();

  late Future<void> _getHistory;

  ThreadTypeController get _controller => widget.controller;

  Future<void> _saveBrowseHistory() async {
    if (!_isSavingBrowseHistory) {
      _isSavingBrowseHistory = true;

      try {
        await Future.delayed(_saveBrowseHistoryPeriod, () async {
          final post = _controller.mainPost;
          final browsePostId = _controller.browsePostId;
          if (_history != null && post is Post && browsePostId != null) {
            _history!.update(
                mainPost: post,
                browsePage: _controller.page,
                browsePostId: browsePostId,
                isOnlyPo: _controller.isOnlyPoThread);
            await BrowseDataHistory.saveBrowseData(_history!);
          }
        });
      } finally {
        _isSavingBrowseHistory = false;
      }
    }
  }

  void _saveHistoryAndJumpToIndex(Thread thread, int firstPage, int page) {
    if (page == firstPage) {
      final jumpToId = _controller.jumpToId;
      final isOnlyPoThread = _controller.isOnlyPoThread;

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
            BrowseDataHistory.saveBrowseData(_history!);
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
            final id = index.postIdFromPostIndex;
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
                            id != _controller.browsePostId &&
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
          if (!_biListViewController.isLoadingMore) {
            updateHistory();
          }
        }
      } else {
        _isToJump.value = false;
      }
    }
  }

  Future<List<PostWithPage<PostBase>>> _fetch(int firstPage, int page) async {
    final client = XdnmbClientService.to.client;
    final blacklist = BlacklistService.to;
    final postId = _controller.id;

    final thread = _controller.isThread
        ? await client.getThread(postId,
            page: page, isFirstPage: firstPage == page)
        : await client.getOnlyPoThread(postId,
            page: page, isFirstPage: firstPage == page);
    final mainPost = thread.mainPost;

    _maxPage = thread.maxPage;
    _controller.mainPost = mainPost;
    // 发现Po饼干被屏蔽就刷新页面
    if (page == firstPage &&
        !mainPost.isAdmin &&
        blacklist.hasUser(mainPost.userHash)) {
      _controller.refresh();
    }

    if (page != 1 && thread.replies.isEmpty) {
      if (page == firstPage) {
        _isToJump.value = false;
      }
      return [];
    }

    _saveHistoryAndJumpToIndex(thread, firstPage, page);

    final List<PostWithPage<PostBase>> posts = [];
    if (page == 1) {
      posts.add(PostWithPage(mainPost, page));
    }
    if (thread.tip != null) {
      posts.add(PostWithPage(thread.tip!, page));
    } else {
      posts.add(PostWithPage(const _DumpTip(), page));
    }
    if (thread.replies.isNotEmpty) {
      posts.addAll(thread.replies.map((post) =>
          PostWithPage(PostOverideForumId(post, mainPost.forumId), page)));
    }

    return posts;
  }

  Widget _itemBuilder(
      BuildContext context, PostWithPage<PostBase> postWithPage) {
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
    final mainPost = _controller.mainPost;

    final Widget item = PostInkWell(
      key: post.isTipType ? UniqueKey() : null,
      post: post,
      poUserHash: mainPost?.userHash,
      onTapLink: (context, link, text) => parseUrl(
          url: link, mainPostId: mainPost?.id, poUserHash: mainPost?.userHash),
      onPaintImage: (imageData) => _replyWithImage(_controller, imageData),
      canReturnImageData: true,
      canTapHiddenText: true,
      showForumName: false,
      showReplyCount: false,
      showPoTag: true,
      onTapPostId:
          !post.isTipType ? (postId) => _replyPost(_controller, postId) : null,
      onTap: (post) {},
      onLongPress: (post) => postListDialog(_ThreadDialog(
        controller: _controller,
        post: post,
        page: postWithPage.page,
      )),
      mouseCursor: SystemMouseCursors.basic,
      hoverColor:
          Get.isDarkMode ? theme.cardColor : theme.scaffoldBackgroundColor,
    );

    return !post.isTipType
        ? ListenBuilder(
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
    final postId = _controller.id;

    return PostListScrollView(
      controller: _controller,
      scrollController: _anchorController,
      builder: (context, scrollController, refresh) {
        final firstPage = _controller.page;

        bool isBlocked() {
          final mainPost = _controller.mainPost;

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
                    if (_isToJump.value) const LoadingIndicator(),
                    Visibility(
                      visible: !_isToJump.value,
                      maintainState: true,
                      maintainAnimation: true,
                      maintainSize: true,
                      child: BiListView<PostWithPage<PostBase>>(
                        key: ValueKey<int>(refresh),
                        controller: _biListViewController,
                        scrollController: scrollController,
                        postListController: _controller,
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
                        onRefresh: () {
                          if (isBlocked()) {
                            _controller.refresh();
                          }
                        },
                        onLoadMore: () {
                          if (isBlocked()) {
                            _controller.refresh();
                          }
                        },
                        fetchFallback: (page) => Future.value(
                          [PostWithPage<PostBase>(const _DumbPost(), page)],
                        ),
                        getMaxPage: () => _maxPage,
                      ),
                    ),
                  ],
                ),
              )
            : GestureDetector(
                onTap: _controller.refresh,
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
    _controller.removeListener(_cancelJump);
    _controller.addListener(_cancelJump);
  }

  void _trySave(int page) => _controller.trySave();

  void _setGetHistory() => _getHistory = Future(() async {
        final settings = SettingsService.to;

        _history = await BrowseDataHistory.getBrowseData(_controller.id);

        if (_controller.jumpToId == null) {
          if (!_controller.cancelAutoJump &&
              settings.isJumpToLastBrowsePage &&
              _history != null) {
            final page = _controller.isThread
                ? _history!.browsePage
                : _history!.onlyPoBrowsePage;
            if (page != null) {
              _controller.page = page;

              if (settings.isJumpToLastBrowsePosition) {
                _setToJump();
              }
            }
          }
        } else {
          _setToJump();
        }
      });

  void _setAnchorController() {
    final settings = SettingsService.to;

    _anchorController = PostListScrollController(
      getInitialScrollOffset: () =>
          settings.autoHideAppBar ? -_controller.appBarHeight : 0.0,
      getAnchorOffset: () =>
          settings.autoHideAppBar ? _controller.appBarHeight : 0.0,
      onIndexChanged: (index, userScroll) {
        _controller.page = index.pageFromPostIndex;
        _controller.browsePostId = index.postIdFromPostIndex;

        _saveBrowseHistory();
      },
    );
  }

  @override
  void initState() {
    super.initState();

    _setAnchorController();

    _pageSubscription = _controller.listenPage(_trySave);
    _maxPage = _controller.mainPost?.maxPage ?? 1;
    _controller._loadMore = _biListViewController.loadMore;
    _controller.scrollController = _anchorController;

    _setGetHistory();
  }

  @override
  void didUpdateWidget(covariant ThreadBody oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      oldWidget.controller._loadMore = null;
      oldWidget.controller.scrollController = null;
      oldWidget.controller.removeListener(_cancelJump);

      _anchorController.dispose();
      _setAnchorController();

      _pageSubscription.cancel();
      _pageSubscription = widget.controller.listenPage(_trySave);
      _maxPage = widget.controller.mainPost?.maxPage ?? 1;
      widget.controller._loadMore = _biListViewController.loadMore;
      widget.controller.scrollController = _anchorController;

      _setGetHistory();
    }
  }

  @override
  void dispose() {
    _controller._loadMore = null;
    _controller.scrollController = null;

    _isToJump.value = false;
    _anchorController.dispose();
    _controller.removeListener(_cancelJump);
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

          if (snapshot.connectionState == ConnectionState.done) {
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
  if (editPostController.isShownRx) {
    EditPostCallback.bottomSheet?.insertText(text);
  } else {
    editPostController.showEditPost(EditPostController(
        postListType: controller.postListType,
        id: controller.id,
        forumId: controller.forumId,
        poUserHash: controller.mainPost?.userHash,
        content: text));
  }
}

void _replyWithImage(ThreadTypeController controller, Uint8List imageData) {
  final editPostController = BottomSheetController.editPostController;
  if (editPostController.isShownRx) {
    EditPostCallback.bottomSheet?.insertImage(imageData);
  } else {
    editPostController.showEditPost(EditPostController(
        postListType: controller.postListType,
        id: controller.id,
        forumId: controller.forumId,
        poUserHash: controller.mainPost?.userHash,
        imageData: imageData));
  }
}
