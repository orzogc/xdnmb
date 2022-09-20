import 'package:anchor_scroll_controller/anchor_scroll_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../data/models/history.dart';
import '../data/models/page.dart';
import '../data/services/history.dart';
import '../data/services/settings.dart';
import '../data/services/xdnmb_client.dart';
import '../modules/edit_post.dart';
import '../modules/post_list.dart';
import '../routes/routes.dart';
import '../utils/extensions.dart';
import '../utils/hidden_text.dart';
import '../utils/navigation.dart';
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
        id: int.tryParse(parameters['mainPostId'] ?? '0') ?? 0,
        page: int.tryParse(parameters['page'] ?? '1') ?? 1,
        post: arguments is PostBase ? arguments : null);

PostListController onlyPoThreadController(
        Map<String, String?> parameters, Object? arguments) =>
    PostListController(
        postListType: PostListType.onlyPoThread,
        id: int.tryParse(parameters['mainPostId'] ?? '0') ?? 0,
        page: int.tryParse(parameters['page'] ?? '1') ?? 1,
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
                    ? Flexible(child: ForumName(forumId: forumId))
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
          SimpleDialogOption(
            onPressed: () {
              _replyPost(controller, post.id);
              postListBack();
            },
            child: Text(
              '回复该串',
              style: TextStyle(
                  fontSize: Theme.of(context).textTheme.subtitle1?.fontSize),
            ),
          ),
          CopyPostId(post),
          CopyPostNumber(post),
          CopyPostContent(post),
        ],
      );
}

class ThreadAppBarPopupMenuButton extends StatelessWidget {
  final PostListController controller;

  const ThreadAppBarPopupMenuButton(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final postId = controller.id.value!;
    final postListType = controller.postListType.value;

    return PopupMenuButton(
      tooltip: '菜单',
      itemBuilder: (context) => [
        PopupMenuItem(
          onTap: () async {
            try {
              await XdnmbClientService.to.client
                  .addFeed(SettingsService.to.feedUuid, postId);
              showToast('订阅 ${postId.toPostNumber()} 成功');
            } catch (e) {
              showToast('订阅 ${postId.toPostNumber()} 失败：$e');
            }
          },
          child: const Text('订阅'),
        ),
        if (postListType.isThread())
          PopupMenuItem(
            onTap: () => AppRoutes.toOnlyPoThread(
                mainPostId: controller.id.value!,
                mainPost: controller.post.value),
            child: const Text('只看Po'),
          ),
        if (postListType.isOnlyPoThread())
          PopupMenuItem(
            onTap: () => AppRoutes.toThread(
                mainPostId: controller.id.value!,
                mainPost: controller.post.value),
            child: const Text('取消只看Po'),
          ),
        PopupMenuItem(
          onTap: () {
            openNewTab(controller.copyKeepingPage());

            showToast('已在新标签页打开 ${postId.toPostNumber()}');
          },
          child: const Text('在新标签页打开'),
        ),
        PopupMenuItem(
          onTap: () {
            openNewTabBackground(controller.copyKeepingPage());

            showToast('已在新标签页后台打开 ${postId.toPostNumber()}');
          },
          child: const Text('在新标签页后台打开'),
        ),
      ],
    );
  }
}

//typedef _OnPageCallback = void Function(int page);

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

  late AnchorScrollController _anchorController;

  /// 是否第一次跳转
  final RxBool _isJumped = false.obs;

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

  @override
  void initState() {
    super.initState();

    _browsePostId = widget.controller.id.value!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final client = XdnmbClientService.to.client;
    final settings = SettingsService.to;
    final history = PostHistoryService.to;
    final postListType = widget.controller.postListType;
    final postId = widget.controller.id;
    final postPage = widget.controller.page;
    final currentPage = widget.controller.currentPage;
    final mainPost = widget.controller.post;

    return FutureBuilder(
      future: Future(() async {
        _history = await PostHistoryService.to.getBrowseHistory(postId.value!);

        if (settings.isJumpToLastBrowsePage && _history != null) {
          final page = postListType.value.isThread()
              ? _history!.browsePage
              : _history!.onlyPoBrowsePage;
          if (page != null) {
            _isJumped.value = true;
            postPage.value = page;
            currentPage.value = page;
          }
        }
      }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasError) {
          showToast('读取数据库出错：${snapshot.error!}');
        }

        if (snapshot.connectionState == ConnectionState.done) {
          return Obx(
            () {
              _anchorController = AnchorScrollController(
                onIndexChanged: (index, userScroll) {
                  currentPage.value = index.getPageFromIndex();
                  _browsePostId = index.getIdFromIndex();

                  if (!_isSavingBrowseHistory) {
                    _saveBrowseHistory();
                  }
                },
              );

              return Stack(
                children: [
                  if (_isJumped.value) const QuotationLoadingIndicator(),
                  Visibility(
                    visible: !_isJumped.value,
                    maintainState: true,
                    maintainAnimation: true,
                    maintainSize: true,
                    child: BiListView<PostWithPage>(
                      key: ValueKey<PostList>(
                          PostList.fromController(widget.controller)),
                      controller: _anchorController,
                      initialPage: postPage.value,
                      fetch: (page) async {
                        final thread = postListType.value.isThread()
                            ? await client.getThread(postId.value!, page: page)
                            : await client.getOnlyPoThread(postId.value!,
                                page: page);

                        mainPost.value = thread.mainPost;

                        if (page != 1 && thread.replies.isEmpty) {
                          return [];
                        }

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
                            _isJumped.value = false;
                          } else if (!_isJumped.value) {
                            // 除了第一次跳转，其他跳转都更新
                            _history!.update(
                                mainPost: thread.mainPost,
                                browsePage: page,
                                browsePostId: firstPost.id,
                                isOnlyPo: postListType.value.isOnlyPoThread());
                            history.saveBrowseHistory(_history!);
                          } else if (settings.isJumpToLastBrowsePage &&
                              settings.isJumpToLastBrowsePosition) {
                            final index = _history!.toIndex(
                                isOnlyPo: postListType.value.isOnlyPoThread());
                            if (index != null) {
                              final postIds =
                                  thread.replies.map((post) => post.id);
                              final id = index.getIdFromIndex();
                              if (postIds.contains(id)) {
                                SchedulerBinding.instance
                                    .addPostFrameCallback((timeStamp) {
                                  Future.delayed(
                                      const Duration(milliseconds: 50),
                                      () async {
                                    try {
                                      await _anchorController.scrollToIndex(
                                          index: index, scrollSpeed: 10.0);

                                      if (firstPost.id != id) {
                                        var scrollIndex = _browsePostId;
                                        do {
                                          scrollIndex = _browsePostId;
                                          await Future.delayed(
                                              // TODO: 200毫秒只是估算，需要更好的方法
                                              const Duration(milliseconds: 200),
                                              () => _anchorController
                                                  .scrollToIndex(
                                                      index: index,
                                                      scrollSpeed: 10.0));
                                        } while (scrollIndex != _browsePostId);
                                      }
                                    } catch (e) {
                                      showToast(
                                          '跳转到串号 ${id.toPostNumber()} 失败：$e');
                                    } finally {
                                      _isJumped.value = false;
                                    }
                                  }).timeout(
                                    const Duration(seconds: 2),
                                    onTimeout: () {
                                      showToast(
                                          '跳转到串号 ${id.toPostNumber()} 超时');
                                      _isJumped.value = false;
                                    },
                                  );
                                });
                              } else {
                                _isJumped.value = false;
                              }
                            } else {
                              _isJumped.value = false;
                            }
                          } else {
                            _isJumped.value = false;
                          }
                        }

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
                          key: post.post is Tip ? post.toValueKey() : null,
                          post: post.post,
                          showForumName: false,
                          showReplyCount: false,
                          poUserHash: mainPost.value?.userHash,
                          onTap: (post) {},
                          onLongPress: (post) => postListDialog(_ThreadDialog(
                              controller: widget.controller, post: post)),
                          onLinkTap: (context, link) => parseUrl(
                              url: link, poUserHash: mainPost.value?.userHash),
                          onHiddenText: (context, element, textStyle) =>
                              onHiddenText(
                                  context: context,
                                  element: element,
                                  textStyle: textStyle,
                                  canTap: true,
                                  poUserHash: mainPost.value?.userHash),
                          mouseCursor: SystemMouseCursors.basic,
                          hoverColor: Get.isDarkMode
                              ? theme.cardColor
                              : theme.scaffoldBackgroundColor,
                          onPostIdTap: (postId) =>
                              _replyPost(widget.controller, postId),
                        );

                        return post.post is! Tip
                            ? AnchorItemWrapper(
                                key: ValueKey(_PostKey(
                                    index: post.toIndex(),
                                    isVisible: !_isJumped.value)),
                                controller: _anchorController,
                                index: post.toIndex(),
                                child: postCard,
                              )
                            : postCard;
                      },
                    ),
                  ),
                ],
              );
            },
          );
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
        content: text,
      ));
    }
  }
}
