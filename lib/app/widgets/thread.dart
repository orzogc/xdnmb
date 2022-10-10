import 'dart:async';
import 'dart:typed_data';

import 'package:anchor_scroll_controller/anchor_scroll_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../data/models/history.dart';
import '../data/models/page.dart';
import '../data/services/blacklist.dart';
import '../data/services/history.dart';
import '../data/services/settings.dart';
import '../data/services/xdnmb_client.dart';
import '../modules/edit_post.dart';
import '../modules/post_list.dart';
import '../routes/routes.dart';
import '../utils/exception.dart';
import '../utils/extensions.dart';
import '../utils/hidden_text.dart';
import '../utils/key.dart';
import '../utils/navigation.dart';
import '../utils/theme.dart';
import '../utils/toast.dart';
import '../utils/url.dart';
import 'bilistview.dart';
import 'dialog.dart';
import 'edit_post.dart';
import 'forum_name.dart';
import 'loading.dart';
import 'post.dart';

PostListController threadController(
        Map<String, String?> parameters, Object? arguments) =>
    PostListController(
        postListType: PostListType.thread,
        id: parameters['mainPostId'].tryParseInt() ?? 0,
        page: parameters['page'].tryParseInt() ?? 1,
        post: arguments is PostBase ? arguments : null,
        jumpToId: parameters['jumpToId'].tryParseInt());

PostListController onlyPoThreadController(
        Map<String, String?> parameters, Object? arguments) =>
    PostListController(
        postListType: PostListType.onlyPoThread,
        id: parameters['mainPostId'].tryParseInt() ?? 0,
        page: parameters['page'].tryParseInt() ?? 1,
        post: arguments is PostBase ? arguments : null);

class ThreadAppBarTitle extends StatelessWidget {
  final PostListController controller;

  const ThreadAppBarTitle(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() => Text(controller.id.value!.toPostNumber())),
        DefaultTextStyle.merge(
          style: theme.textTheme.bodyText2!
              .apply(color: theme.colorScheme.onPrimary),
          child: Row(
            children: [
              const Text('X岛 nmbxd.com '),
              Obx(() {
                final forumId = controller.post.value?.forumId;

                return forumId != null
                    ? Flexible(child: ForumName(forumId: forumId, maxLines: 1))
                    : const SizedBox.shrink();
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThreadDialog extends StatelessWidget {
  final PostListController controller;

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
            BlockPost(postId: post.id, onBlock: controller.refreshCurrentPage),
          if (post is! Tip && !post.isAdmin)
            BlockUser(
              userHash: post.userHash,
              onBlock: controller.refreshCurrentPage,
            ),
          if (post is! Tip) CopyPostId(post.id),
          if (post is! Tip) CopyPostReference(post.id),
          CopyPostContent(post),
        ],
      );
}

class ThreadAppBarPopupMenuButton extends StatefulWidget {
  final PostListController controller;

  final VoidCallback refresh;

  const ThreadAppBarPopupMenuButton(
      {super.key, required this.controller, required this.refresh});

  @override
  State<ThreadAppBarPopupMenuButton> createState() =>
      _ThreadAppBarPopupMenuButtonState();
}

class _ThreadAppBarPopupMenuButtonState
    extends State<ThreadAppBarPopupMenuButton> {
  @override
  Widget build(BuildContext context) {
    final blacklist = BlacklistService.to;
    final postListType = widget.controller.postListType.value;
    final postId = widget.controller.id.value!;
    final mainPost = widget.controller.post.value;

    final isBlockedPost = blacklist.hasPost(postId);
    final isBlockedUser =
        mainPost != null ? blacklist.hasUser(mainPost.userHash) : false;

    return PopupMenuButton(
      itemBuilder: (context) => [
        PopupMenuItem(
          onTap: () async {
            try {
              await XdnmbClientService.to.client
                  .addFeed(SettingsService.to.feedUuid, postId);
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
        if (postListType.isThread() && !isBlockedPost && !isBlockedUser)
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
                  widget.controller.refreshPage();
                  if (mounted) {
                    setState(() {});
                  }
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
                widget.controller.refreshPage();
                if (mounted) {
                  setState(() {});
                }
                showToast('屏蔽Po饼干 ${mainPost.userHash}');
                postListBack();
              },
              onCancel: () => postListBack(),
            )),
            child: const Text('屏蔽Po饼干'),
          ),
        if (postListType.isOnlyPoThread() && !isBlockedPost && !isBlockedUser)
          PopupMenuItem(
            onTap: () =>
                AppRoutes.toThread(mainPostId: postId, mainPost: mainPost),
            child: const Text('取消只看Po'),
          ),
        if (isBlockedPost)
          PopupMenuItem(
            onTap: () async {
              await blacklist.unblockPost(postId);
              widget.controller.refreshPage();
              if (mounted) {
                setState(() {});
              }
              showToast('取消屏蔽主串 ${postId.toPostNumber()}');
            },
            child: const Text('取消屏蔽主串'),
          ),
        if (isBlockedUser)
          PopupMenuItem(
            onTap: () async {
              await blacklist.unblockUser(mainPost.userHash);
              widget.controller.refreshPage();
              if (mounted) {
                setState(() {});
              }
              showToast('取消屏蔽Po饼干 ${mainPost.userHash}');
            },
            child: const Text('取消屏蔽Po饼干'),
          ),
        if (!isBlockedPost && !isBlockedUser)
          PopupMenuItem(
            onTap: () {
              openNewTab(widget.controller.copyKeepingPage());

              showToast('已在新标签页打开 ${postId.toPostNumber()}');
            },
            child: const Text('在新标签页打开'),
          ),
        if (!isBlockedPost && !isBlockedUser)
          PopupMenuItem(
            onTap: () {
              openNewTabBackground(widget.controller.copyKeepingPage());

              showToast('已在新标签页后台打开 ${postId.toPostNumber()}');
            },
            child: const Text('在新标签页后台打开'),
          ),
      ],
    );
  }
}

class ThreadBody extends StatefulWidget {
  final PostListController controller;

  const ThreadBody(this.controller, {super.key});

  @override
  State<ThreadBody> createState() => _ThreadBodyState();
}

class _ThreadBodyState extends State<ThreadBody> {
  late int _browsePostId;

  bool _isSavingBrowseHistory = false;

  BrowseHistory? _history;

  AnchorScrollController? _anchorController;

  /// 第一次加载是否要跳转
  final RxBool _isToJump = false.obs;

  int _refresh = 0;

  late final StreamSubscription<int> _refreshSubscription;

  StreamSubscription<int>? _jumpSubscription;

  bool _isNoMoreItems = false;

  Future<void> _saveBrowseHistory() async {
    _isSavingBrowseHistory = true;
    await Future.delayed(const Duration(seconds: 5), () async {
      _history!.update(
          mainPost: widget.controller.post.value as Post,
          browsePage: widget.controller.currentPage.value,
          browsePostId: _browsePostId,
          isOnlyPo: widget.controller.postListType.value.isOnlyPoThread());
      await PostHistoryService.to.saveBrowseHistory(_history!);
    });
    _isSavingBrowseHistory = false;
  }

  void _saveHistoryAndJumpToIndex(Thread thread, int page) {
    final settings = SettingsService.to;
    final history = PostHistoryService.to;
    final postListType = widget.controller.postListType;
    final postPage = widget.controller.page;
    final jumpToId = widget.controller.jumpToId;

    if (postPage.value == page) {
      final firstPost = page == 1
          ? thread.mainPost
          : (thread.replies.isNotEmpty
              ? thread.replies.first
              : thread.mainPost);
      if (_history == null) {
        _history = BrowseHistory.fromPost(
            mainPost: thread.mainPost,
            browsePage: page,
            browsePostId: firstPost.id,
            isOnlyPo: postListType.value.isOnlyPoThread());
        history.saveBrowseHistory(_history!);
        _isToJump.value = false;
      } else if (!_isToJump.value) {
        // 除了第一次跳转，其他跳转都更新
        _history!.update(
            mainPost: thread.mainPost,
            browsePage: page,
            browsePostId: firstPost.id,
            isOnlyPo: postListType.value.isOnlyPoThread());
        history.saveBrowseHistory(_history!);
      } else if (jumpToId != null ||
          (settings.isJumpToLastBrowsePage &&
              settings.isJumpToLastBrowsePosition)) {
        final index = jumpToId?.toIndex(page) ??
            _history!.toIndex(isOnlyPo: postListType.value.isOnlyPoThread());
        if (index != null) {
          final postIds = thread.replies.map((post) => post.id);
          final id = index.getIdFromIndex();
          if (postIds.contains(id)) {
            WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
              Future.delayed(const Duration(milliseconds: 50), () async {
                try {
                  if (_isToJump.value) {
                    await _anchorController?.scrollToIndex(
                        index: index, scrollSpeed: 10.0);

                    if (firstPost.id != id) {
                      while (id != _browsePostId && !_isNoMoreItems) {
                        if (_isToJump.value) {
                          await Future.delayed(const Duration(milliseconds: 50),
                              () async {
                            if (_isToJump.value) {
                              await _anchorController?.scrollToIndex(
                                  index: index, scrollSpeed: 10.0);
                            }
                          });
                        } else {
                          break;
                        }
                      }
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
          } else {
            _isToJump.value = false;
          }
        } else {
          _isToJump.value = false;
        }
      } else {
        _isToJump.value = false;
      }
    }
  }

  Widget _body() {
    final theme = Theme.of(context);
    final client = XdnmbClientService.to.client;
    final blacklist = BlacklistService.to;
    final postListType = widget.controller.postListType;
    final postId = widget.controller.id;
    final postPage = widget.controller.page;
    final mainPost = widget.controller.post;

    return Obx(
      () {
        _anchorController?.dispose();
        _anchorController = AnchorScrollController(
          onIndexChanged: (index, userScroll) {
            widget.controller.currentPage.value = index.getPageFromIndex();
            _browsePostId = index.getIdFromIndex();

            if (!_isSavingBrowseHistory) {
              _saveBrowseHistory();
            }
          },
        );

        // 方便刷新
        postPage.value = postPage.value;

        return ((mainPost.value != null && mainPost.value!.isAdmin) ||
                !(blacklist.hasPost(postId.value!) ||
                    (mainPost.value != null &&
                        blacklist.hasUser(mainPost.value!.userHash))))
            ? Stack(
                children: [
                  if (_isToJump.value) const QuotationLoadingIndicator(),
                  Visibility(
                    visible: !_isToJump.value,
                    maintainState: true,
                    maintainAnimation: true,
                    maintainSize: true,
                    child: BiListView<PostWithPage>(
                      key: getPostListKey(
                          PostList.fromController(widget.controller), _refresh),
                      controller: _anchorController,
                      initialPage: postPage.value,
                      fetch: (page) async {
                        final thread = postListType.value.isThread()
                            ? await client.getThread(postId.value!, page: page)
                            : await client.getOnlyPoThread(postId.value!,
                                page: page);

                        mainPost.value ??= thread.mainPost;

                        if (page != 1 && thread.replies.isEmpty) {
                          if (postPage.value == page) {
                            _isToJump.value = false;
                          }
                          return [];
                        }

                        thread.replies.retainWhere((post) =>
                            post.isAdmin ||
                            !(blacklist.hasPost(post.id) ||
                                blacklist.hasUser(post.userHash)));

                        _saveHistoryAndJumpToIndex(thread, page);

                        final List<PostWithPage> posts = [];
                        if (page == 1) {
                          posts.add(PostWithPage(thread.mainPost, page));
                        }
                        // TODO: 提示tip是官方信息
                        if (thread.tip != null) {
                          posts.add(PostWithPage(thread.tip!, page));
                        }
                        if (thread.replies.isNotEmpty) {
                          posts.addAll(thread.replies
                              .map((post) => PostWithPage(post, page)));
                        }

                        return posts;
                      },
                      itemBuilder: (context, post, index) {
                        final postCard = PostCard(
                          key: post.post is Tip ? UniqueKey() : null,
                          post: post.post,
                          showForumName: false,
                          showReplyCount: false,
                          poUserHash: mainPost.value?.userHash,
                          onTap: (post) {},
                          onLongPress: (post) => postListDialog(_ThreadDialog(
                              controller: widget.controller, post: post)),
                          onLinkTap: (context, link) => parseUrl(
                              url: link,
                              mainPostId: mainPost.value?.id,
                              poUserHash: mainPost.value?.userHash),
                          onHiddenText: (context, element, textStyle) =>
                              onHiddenText(
                                  context: context,
                                  element: element,
                                  textStyle: textStyle,
                                  canTap: true,
                                  mainPostId: mainPost.value?.id,
                                  poUserHash: mainPost.value?.userHash),
                          onImagePainted: (imageData) =>
                              _replyWithImage(widget.controller, imageData),
                          mouseCursor: SystemMouseCursors.basic,
                          hoverColor: Get.isDarkMode
                              ? theme.cardColor
                              : theme.scaffoldBackgroundColor,
                          canReturnImageData: true,
                          onPostIdTap: post.post is! Tip
                              ? (postId) =>
                                  _replyPost(widget.controller, postId)
                              : null,
                        );

                        return post.post is! Tip
                            ? AnchorItemWrapper(
                                key: ValueKey(_PostKey(
                                    index: post.toIndex(),
                                    isVisible: !_isToJump.value)),
                                controller: _anchorController,
                                index: post.toIndex(),
                                child: postCard,
                              )
                            : postCard;
                      },
                      separator: const Divider(height: 10.0, thickness: 1.0),
                      noItemsFoundBuilder: (context) => const Center(
                        child: Text('没有串', style: AppTheme.boldRed),
                      ),
                      onNoMoreItems: () => _isNoMoreItems = true,
                    ),
                  ),
                ],
              )
            : const Center(child: Text('本串已被屏蔽', style: AppTheme.boldRed));
      },
    );
  }

  void _setToJump() {
    _isToJump.value = true;
    _jumpSubscription?.cancel();
    _jumpSubscription = widget.controller.page.listen((page) {
      _isToJump.value = false;
      _isNoMoreItems = false;
    });
  }

  @override
  void initState() {
    super.initState();

    _browsePostId = widget.controller.id.value!;

    _refreshSubscription = widget.controller.page.listen((page) => _refresh++);
  }

  @override
  void dispose() {
    _refreshSubscription.cancel();
    _isToJump.value = false;
    _anchorController?.dispose();
    _anchorController = null;
    _jumpSubscription?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;
    final postListType = widget.controller.postListType;
    final postId = widget.controller.id;
    final postPage = widget.controller.page;
    final currentPage = widget.controller.currentPage;
    final jumpToId = widget.controller.jumpToId;

    return FutureBuilder(
      future: _history == null
          ? Future(() async {
              _history =
                  await PostHistoryService.to.getBrowseHistory(postId.value!);

              if (jumpToId == null) {
                if (settings.isJumpToLastBrowsePage && _history != null) {
                  final page = postListType.value.isThread()
                      ? _history!.browsePage
                      : _history!.onlyPoBrowsePage;
                  if (page != null) {
                    postPage.value = page;
                    currentPage.value = page;

                    _setToJump();
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

class _PostKey {
  final int index;

  final bool isVisible;

  const _PostKey({required this.index, required this.isVisible});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _PostKey &&
          index == other.index &&
          isVisible == other.isVisible);

  @override
  int get hashCode => Object.hash(index, isVisible);
}

void _replyPost(PostListController controller, int postId) {
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
          postListType: controller.postListType.value,
          id: controller.id.value!,
          forumId: controller.forumId,
          content: text));
    }
  }
}

void _replyWithImage(PostListController controller, Uint8List imageData) {
  final button = FloatingButton.buttonKey.currentState;
  if (button != null && button.mounted) {
    if (button.hasBottomSheet) {
      final bottomSheet = EditPost.bottomSheetkey.currentState;
      if (bottomSheet != null && bottomSheet.mounted) {
        bottomSheet.insertImage(imageData);
      }
    } else {
      button.bottomSheet(EditPostController(
          postListType: controller.postListType.value,
          id: controller.id.value!,
          forumId: controller.forumId,
          imageData: imageData));
    }
  }
}
