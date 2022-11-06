import 'dart:async';
import 'dart:typed_data';

import 'package:anchor_scroll_controller/anchor_scroll_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../data/models/controller.dart';
import '../data/models/history.dart';
import '../data/services/blacklist.dart';
import '../data/services/history.dart';
import '../data/services/settings.dart';
import '../data/services/xdnmb_client.dart';
import '../modules/edit_post.dart';
import '../modules/post_list.dart';
import '../routes/routes.dart';
import '../utils/exception.dart';
import '../utils/extensions.dart';
import '../utils/misc.dart';
import '../utils/navigation.dart';
import '../utils/notify.dart';
import '../utils/theme.dart';
import '../utils/toast.dart';
import '../utils/url.dart';
import 'bilistview.dart';
import 'dialog.dart';
import 'edit_post.dart';
import 'forum_name.dart';
import 'loading.dart';
import 'post.dart';

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
  DateTime get postTime => DateTime.now();

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

  final Notifier _refreshNotifier = Notifier();

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

  @override
  void dispose() {
    _refreshNotifier.dispose();

    super.dispose();
  }
}

class ThreadController extends ThreadTypeController {
  @override
  final int? jumpToId;

  VoidCallback? loadMore;

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
          style: theme.textTheme.bodyText2!
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

  const _ThreadDialog(
      {super.key, required this.controller, required this.post});

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
              child: Text('回复', style: Theme.of(context).textTheme.subtitle1),
            ),
          if (post is! Tip) Report(post.id),
          if (post is! Tip && !post.isAdmin)
            BlockPost(postId: post.id, onBlock: controller.refresh),
          if (post is! Tip && !post.isAdmin)
            BlockUser(userHash: post.userHash, onBlock: controller.refresh),
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

    return NotifyBuilder(
      animation: controller._refreshNotifier,
      builder: (context, child) {
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
            const PopupMenuItem(onTap: bottomSheet, child: Text('回复')),
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
                  content: '${postId.toPostReference()}\n',
                  forumId: EditPost.dutyRoomId,
                ),
              ),
              child: const Text('举报'),
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
                      controller.refreshPage();
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
                    controller.refreshPage();
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
                  controller.refreshPage();
                  showToast('取消屏蔽主串 ${postId.toPostNumber()}');
                },
                child: const Text('取消屏蔽主串'),
              ),
            if (isBlockedUser)
              PopupMenuItem(
                onTap: () async {
                  await blacklist.unblockUser(mainPost.userHash);
                  controller.refreshPage();
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
      },
    );
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

  late final AnchorScrollController _anchorController;

  /// 第一次加载是否要跳转
  final RxBool _isToJump = false.obs;

  int _refresh = 0;

  bool _isNoMoreItems = false;

  int _maxPage = 1;

  late final StreamSubscription<int> _pageSubscription;

  Future<void> _saveBrowseHistory() async {
    if (!_isSavingBrowseHistory) {
      _isSavingBrowseHistory = true;

      try {
        await Future.delayed(_saveBrowseHistoryPeriod, () async {
          final post = widget.controller.post;
          final browsePostId = widget.controller.browsePostId;
          if (post is Post && browsePostId != null) {
            _history!.update(
                mainPost: post,
                browsePage: widget.controller.page,
                browsePostId: browsePostId,
                isOnlyPo: widget.controller.isOnlyPoThread);
            await PostHistoryService.to.saveBrowseHistory(_history!);
          }
        });
      } finally {
        _isSavingBrowseHistory = false;
      }
    }
  }

  void _saveHistoryAndJumpToIndex(Thread thread, int firstPage, int page) {
    final history = PostHistoryService.to;
    final controller = widget.controller;
    final jumpToId = controller.jumpToId;
    final isOnlyPoThread = controller.isOnlyPoThread;

    if (page == firstPage) {
      if (page == 1 || thread.replies.isNotEmpty) {
        final Post firstPost =
            page == 1 ? thread.mainPost : thread.replies.first;

        if (_history == null) {
          _history = BrowseHistory.fromPost(
              mainPost: thread.mainPost,
              browsePage: page,
              browsePostId: firstPost.id,
              isOnlyPo: isOnlyPoThread);
          history.saveBrowseHistory(_history!);
          _isToJump.value = false;
        } else if (_isToJump.value) {
          final index = jumpToId?.postIdToPostIndex(page) ??
              _history!.toIndex(isOnlyPo: isOnlyPoThread);
          if (index != null) {
            final postIds = thread.replies.map((post) => post.id);
            final id = index.getPostIdFromPostIndex();
            if (postIds.contains(id)) {
              WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                Future.delayed(const Duration(milliseconds: 50), () async {
                  try {
                    if (_isToJump.value) {
                      await _anchorController.scrollToIndex(
                          index: index, scrollSpeed: 10.0);

                      if (firstPost.id != id) {
                        while (_isToJump.value &&
                            id != widget.controller.browsePostId &&
                            !_isNoMoreItems) {
                          await Future.delayed(const Duration(milliseconds: 50),
                              () async {
                            if (_isToJump.value) {
                              await _anchorController.scrollToIndex(
                                  index: index, scrollSpeed: 10.0);
                            }
                          });
                        }
                      } else {
                        _history!.update(
                            mainPost: thread.mainPost,
                            browsePage: page,
                            browsePostId: firstPost.id,
                            isOnlyPo: isOnlyPoThread);
                        history.saveBrowseHistory(_history!);
                      }
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
            } else if (page == 1 && thread.mainPost.id == id) {
              _history!.update(
                  mainPost: thread.mainPost,
                  browsePage: page,
                  browsePostId: thread.mainPost.id,
                  isOnlyPo: isOnlyPoThread);
              history.saveBrowseHistory(_history!);
              _isToJump.value = false;
            } else {
              _isToJump.value = false;
            }
          } else {
            _isToJump.value = false;
          }
        } else {
          if (!_isNoMoreItems) {
            _history!.update(
                mainPost: thread.mainPost,
                browsePage: page,
                browsePostId: firstPost.id,
                isOnlyPo: isOnlyPoThread);
            history.saveBrowseHistory(_history!);
          }

          _isToJump.value = false;
        }
      } else {
        _isToJump.value = false;
      }
    }
  }

  Future<List<PostWithPage>> _fetch(int firstPage, int page) async {
    final client = XdnmbClientService.to.client;
    final blacklist = BlacklistService.to;
    final controller = widget.controller;
    final postId = controller.id;

    final thread = controller.isThread
        ? await client.getThread(postId, page: page)
        : await client.getOnlyPoThread(postId, page: page);

    _maxPage = thread.maxPage;
    controller.post = thread.mainPost;
    if (page == firstPage) {
      controller._refreshNotifier.notify();
    }

    if (page != 1 && thread.replies.isEmpty) {
      if (page == firstPage) {
        _isToJump.value = false;
      }
      return [];
    }

    thread.replies.retainWhere((post) =>
        post.isAdmin ||
        !(blacklist.hasPost(post.id) || blacklist.hasUser(post.userHash)));

    _saveHistoryAndJumpToIndex(thread, firstPage, page);

    final List<PostWithPage> posts = [];
    if (page == 1) {
      posts.add(PostWithPage(thread.mainPost, page));
    }
    // TODO: 提示tip是官方信息
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

  Widget _itemBuilder(BuildContext context, PostWithPage post) {
    if (post.post is _DumpTip) {
      return const DumpItem();
    } else if (post.post is _DumbPost) {
      return Center(child: Text('第${post.page}页 空页', style: AppTheme.boldRed));
    }

    final theme = Theme.of(context);
    final controller = widget.controller;
    final mainPost = controller.post;

    final postCard = PostInkWell(
      key: post.post is Tip ? UniqueKey() : null,
      post: post.post,
      showForumName: false,
      showReplyCount: false,
      poUserHash: mainPost?.userHash,
      onTap: (post) {},
      onLongPress: (post) =>
          postListDialog(_ThreadDialog(controller: controller, post: post)),
      onLinkTap: (context, link, text) => parseUrl(
          url: link, mainPostId: mainPost?.id, poUserHash: mainPost?.userHash),
      onImagePainted: (imageData) => _replyWithImage(controller, imageData),
      mouseCursor: SystemMouseCursors.basic,
      hoverColor:
          Get.isDarkMode ? theme.cardColor : theme.scaffoldBackgroundColor,
      canReturnImageData: true,
      canTapHiddenText: true,
      onPostIdTap:
          post.post is! Tip ? (postId) => _replyPost(controller, postId) : null,
    );

    return post.post is! Tip
        ? AnchorItemWrapper(
            key: post.toValueKey(),
            controller: _anchorController,
            index: post.toIndex(),
            child: postCard,
          )
        : postCard;
  }

  Widget _body() {
    final blacklist = BlacklistService.to;
    final controller = widget.controller;
    final postId = controller.id;

    return NotifyBuilder(
      animation: controller,
      builder: (context, child) {
        final firstPage = controller.page;

        return NotifyBuilder(
          animation: controller._refreshNotifier,
          builder: (context, child) {
            final mainPost = controller.post;

            return ((mainPost != null && mainPost.isAdmin) ||
                    !(blacklist.hasPost(postId) ||
                        (mainPost != null &&
                            blacklist.hasUser(mainPost.userHash))))
                ? Obx(
                    () {
                      return Stack(
                        children: [
                          if (_isToJump.value)
                            const QuotationLoadingIndicator(),
                          Visibility(
                            visible: !_isToJump.value,
                            maintainState: true,
                            maintainAnimation: true,
                            maintainSize: true,
                            child: BiListView<PostWithPage>(
                              key: ValueKey<int>(_refresh),
                              controller: _anchorController,
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
                              separator:
                                  const Divider(height: 10.0, thickness: 1.0),
                              noItemsFoundBuilder: (context) => const Center(
                                child: Text('没有串', style: AppTheme.boldRed),
                              ),
                              onNoMoreItems: () => _isNoMoreItems = true,
                              onRefresh: () {
                                final mainPost = controller.post;
                                if ((mainPost == null || !mainPost.isAdmin) &&
                                    (blacklist.hasPost(postId) ||
                                        (mainPost != null &&
                                            blacklist
                                                .hasUser(mainPost.userHash)))) {
                                  controller.refreshPage();
                                }
                              },
                              getLoadMore: controller.isThread
                                  ? (function) =>
                                      (controller as ThreadController)
                                          .loadMore = () {
                                        if (_isNoMoreItems) {
                                          function();
                                        }
                                      }
                                  : null,
                              fetchFallback: (page) => Future.value(
                                [PostWithPage(const _DumbPost(), page)],
                              ),
                              getMaxPage: () => _maxPage,
                            ),
                          ),
                        ],
                      );
                    },
                  )
                : GestureDetector(
                    onTap: controller.refreshPage,
                    child: const Center(
                      child: Text('本串已被屏蔽', style: AppTheme.boldRed),
                    ),
                  );
          },
        );
      },
    );
  }

  void _cancelJump() => _isToJump.value = false;

  void _setToJump() {
    _isToJump.value = true;
    widget.controller.removeListener(_cancelJump);
    widget.controller.addListener(_cancelJump);
  }

  void _addRefresh() {
    _refresh++;
    _isNoMoreItems = false;
  }

  @override
  void initState() {
    super.initState();

    _anchorController = AnchorScrollController(
      onIndexChanged: (index, userScroll) {
        widget.controller.page = index.getPageFromPostIndex();
        widget.controller.browsePostId = index.getPostIdFromPostIndex();

        _saveBrowseHistory();
      },
    );

    widget.controller.addListener(_addRefresh);
    _pageSubscription =
        widget.controller.listenPage((page) => widget.controller.trySave());

    final replyCount = widget.controller.post?.replyCount;
    if (replyCount != null) {
      _maxPage = replyCount > 0 ? (replyCount / 19).ceil() : 1;
    }
  }

  @override
  void dispose() {
    _isToJump.value = false;
    _anchorController.dispose();
    widget.controller.removeListener(_cancelJump);
    widget.controller.removeListener(_addRefresh);
    _pageSubscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;
    final controller = widget.controller;
    final postId = controller.id;
    final cancelAutoJump = controller.cancelAutoJump;
    final jumpToId = controller.jumpToId;

    return FutureBuilder(
      future: _history == null
          ? Future(() async {
              _history = await PostHistoryService.to.getBrowseHistory(postId);

              if (jumpToId == null) {
                if (!cancelAutoJump &&
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
            })
          : null,
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
}

void _replyPost(ThreadTypeController controller, int postId) {
  final button = FloatingButton.buttonKey.currentState;
  if (button != null && button.mounted) {
    final text = '${postId.toPostReference()}\n';

    if (button.hasBottomSheet) {
      final bottomSheet = EditPost.bottomSheetkey.currentState;
      if (bottomSheet != null && bottomSheet.mounted) {
        bottomSheet.insertText(text);
      }
    } else {
      button.bottomSheet(EditPostController(
          postListType: controller.postListType,
          id: controller.id,
          forumId: controller.forumId,
          content: text));
    }
  }
}

void _replyWithImage(ThreadTypeController controller, Uint8List imageData) {
  final button = FloatingButton.buttonKey.currentState;
  if (button != null && button.mounted) {
    if (button.hasBottomSheet) {
      final bottomSheet = EditPost.bottomSheetkey.currentState;
      if (bottomSheet != null && bottomSheet.mounted) {
        bottomSheet.insertImage(imageData);
      }
    } else {
      button.bottomSheet(EditPostController(
          postListType: controller.postListType,
          id: controller.id,
          forumId: controller.forumId,
          imageData: imageData));
    }
  }
}
