import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../data/models/history.dart';
import '../data/models/post.dart';
import '../data/models/reply.dart';
import '../data/services/history.dart';
import '../modules/post_list.dart';
import '../routes/routes.dart';
import '../utils/extensions.dart';
import '../utils/hidden_text.dart';
import '../utils/navigation.dart';
import '../utils/time.dart';
import '../utils/toast.dart';
import 'bilistview.dart';
import 'dialog.dart';
import 'post.dart';

const int _historyEachPage = 20;

PostListController historyController(Map<String, String?> parameters) =>
    PostListController(
        postListType: PostListType.history,
        bottomBarIndex: int.tryParse(parameters['index'] ?? '0') ?? 0);

class HistoryAppBarTitle extends StatelessWidget {
  const HistoryAppBarTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('历史记录');
  }
}

class HistoryAppBarPopupMenuButton extends StatelessWidget {
  final PostListController controller;

  const HistoryAppBarPopupMenuButton(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      tooltip: '菜单',
      itemBuilder: (context) => [
        PopupMenuItem(
          onTap: () {},
          child: const Text('清空'),
        ),
      ],
    );
  }
}

class HistoryBottomBar extends StatelessWidget {
  final PostListController controller;

  const HistoryBottomBar(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final index = controller.bottomBarIndex;

    return Obx(
      () => BottomNavigationBar(
        currentIndex: index.value ?? 0,
        onTap: (value) {
          if (index.value != value) {
            popAllPopup();
            index.value = value;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: SizedBox.shrink(), label: '浏览'),
          BottomNavigationBarItem(icon: SizedBox.shrink(), label: '主题'),
          BottomNavigationBarItem(icon: SizedBox.shrink(), label: '回复'),
        ],
      ),
    );
  }
}

class HistoryBody extends StatefulWidget {
  final PostListController controller;

  const HistoryBody(this.controller, {super.key});

  @override
  State<HistoryBody> createState() => _HistoryBodyState();
}

class _HistoryBodyState extends State<HistoryBody> {
  late final PageController _controller;

  late final StreamSubscription<int?> _subscription;

  @override
  void initState() {
    super.initState();

    _controller = PageController(
        initialPage: widget.controller.bottomBarIndex.value ?? 0);
    _subscription = widget.controller.bottomBarIndex.listen((index) {
      if (index != null) {
        _controller.jumpToPage(index);
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageView.builder(
        controller: _controller,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        itemBuilder: (context, index) {
          switch (index) {
            case 0:
              return const _BrowseHistoryBody();
            case 1:
              return const _PostHistoryBody();
            case 2:
              return const _ReplyHistoryBody();
            default:
              return const Center(
                child: Text(
                  '未知记录',
                  style:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              );
          }
        },
      );
}

class _HistoryDialog extends StatelessWidget {
  final PostBase mainPost;

  final PostBase? post;

  final VoidCallback onDelete;

  const _HistoryDialog(
      {super.key, required this.mainPost, this.post, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final hasPostId =
        (post != null && post!.id > 0) || (post == null && mainPost.id > 0);
    final postHistory = post != null ? post! : mainPost;

    return SimpleDialog(
      title: hasPostId ? Text(postHistory.toPostNumber()) : null,
      children: [
        SimpleDialogOption(
          onPressed: onDelete,
          child: Text(
            '删除',
            style: TextStyle(
                fontSize: Theme.of(context).textTheme.subtitle1?.fontSize),
          ),
        ),
        if (mainPost.id > 0)
          AddFeed(mainPost, text: post != null ? '订阅主串' : null),
        if (hasPostId) CopyPostId(postHistory),
        if (hasPostId) CopyPostReference(postHistory),
        CopyPostContent(postHistory),
        if (post != null) CopyPostId(mainPost, text: '复制主串串号'),
        if (post != null) CopyPostReference(mainPost, text: '复制主串串号引用'),
        if (mainPost.id > 0)
          NewTab(mainPost, text: post != null ? '在新标签页打开主串' : null),
        if (mainPost.id > 0)
          NewTabBackground(mainPost, text: post != null ? '在新标签页后台打开主串' : null),
      ],
    );
  }
}

class _BrowseHistoryBody extends StatelessWidget {
  const _BrowseHistoryBody({super.key});

  @override
  Widget build(BuildContext context) {
    final history = PostHistoryService.to;

    return BiListView<BrowseHistory>(
      initialPage: 1,
      fetch: (page) => history.browseHistoryList(
          (page - 1) * _historyEachPage, page * _historyEachPage),
      itemBuilder: (context, browse, index) {
        final isVisible = true.obs;

        int? browsePage;
        int? browsePostId;
        if (browse.browsePage != null) {
          browsePage = browse.browsePage;
          browsePostId = browse.browsePostId;
        } else {
          browsePage = browse.onlyPoBrowsePage;
          browsePostId = browse.onlyPoBrowsePostId;
        }

        return Obx(
          () => isVisible.value
              ? Card(
                  key: ValueKey(browse.id),
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  elevation: 1.5,
                  child: InkWell(
                    onTap: () => AppRoutes.toThread(
                        mainPostId: browse.id, mainPost: browse),
                    onLongPress: () => postListDialog(
                      _HistoryDialog(
                        mainPost: browse,
                        onDelete: () async {
                          postListBack();
                          await history.deleteBrowseHistory(browse.id);
                          showToast('删除 ${browse.id.toPostNumber()} 的浏览记录');
                          isVisible.value = false;
                        },
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 10.0, top: 5.0, right: 10.0),
                          child: DefaultTextStyle.merge(
                            style: Theme.of(context).textTheme.caption,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    '最后浏览时间：${formatTime(browse.browseTime)}',
                                  ),
                                ),
                                if (browsePage != null && browsePostId != null)
                                  Flexible(
                                    child: Text(
                                      '浏览到：第$browsePage页 ${browsePostId.toPostNumber()}',
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        PostContent(
                          post: browse,
                          showReplyCount: false,
                          contentMaxLines: 8,
                          poUserHash: browse.userHash,
                          onHiddenText: (context, element, textStyle) =>
                              onHiddenText(
                                  context: context,
                                  element: element,
                                  textStyle: textStyle),
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        );
      },
      noItemsFoundBuilder: (context) => const Center(
        child: Text(
          '没有浏览记录',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
      ),
      canRefreshAtBottom: false,
    );
  }
}

class _PostHistoryBody extends StatelessWidget {
  const _PostHistoryBody({super.key});

  @override
  Widget build(BuildContext context) {
    final history = PostHistoryService.to;

    return BiListView<PostData>(
      initialPage: 1,
      fetch: (page) => history.postDataList(
          (page - 1) * _historyEachPage, page * _historyEachPage),
      itemBuilder: (context, mainPost, index) {
        final isVisible = true.obs;

        return Obx(
          () => isVisible.value
              ? Card(
                  key: ValueKey(mainPost.id),
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  elevation: 1.5,
                  child: PostCard(
                    post: mainPost.toPost(),
                    showPostId: mainPost.postId != null ? true : false,
                    showReplyCount: false,
                    contentMaxLines: 8,
                    poUserHash: mainPost.userHash,
                    onTap: (post) {
                      if (post.id > 0) {
                        AppRoutes.toThread(mainPostId: post.id, mainPost: post);
                      }
                    },
                    onLongPress: (post) => postListDialog(_HistoryDialog(
                        mainPost: post,
                        onDelete: () async {
                          postListBack();
                          await history.deletePostData(mainPost.id);
                          mainPost.postId != null
                              ? showToast(
                                  '删除主题 ${mainPost.postId!.toPostNumber()} 的记录')
                              : showToast('删除主题记录');
                          isVisible.value = false;
                        })),
                    onHiddenText: (context, element, textStyle) => onHiddenText(
                        context: context,
                        element: element,
                        textStyle: textStyle),
                  ),
                )
              : const SizedBox.shrink(),
        );
      },
      noItemsFoundBuilder: (context) => const Center(
        child: Text(
          '没有主题记录',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
      ),
      canRefreshAtBottom: false,
    );
  }
}

class _ReplyHistoryBody extends StatelessWidget {
  const _ReplyHistoryBody({super.key});

  @override
  Widget build(BuildContext context) {
    final history = PostHistoryService.to;

    return BiListView<ReplyData>(
      initialPage: 1,
      fetch: (page) => history.replyDataList(
          (page - 1) * _historyEachPage, page * _historyEachPage),
      itemBuilder: (context, reply, index) {
        final isVisible = true.obs;

        return Obx(
          () {
            final post = reply.toPost();

            return isVisible.value
                ? Card(
                    key: ValueKey(reply.id),
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    elevation: 1.5,
                    child: InkWell(
                      onTap: () => AppRoutes.toThread(
                          mainPostId: reply.mainPostId,
                          page: reply.page ?? 1,
                          jumpToId: (reply.page != null && reply.postId != null)
                              ? reply.postId
                              : null),
                      onLongPress: () => postListDialog(_HistoryDialog(
                          mainPost: reply.toMainPost(),
                          post: post,
                          onDelete: () async {
                            postListBack();
                            await history.deletePostData(reply.id);
                            reply.postId != null
                                ? showToast(
                                    '删除回复 ${reply.postId!.toPostNumber()} 的记录')
                                : showToast('删除回复记录');
                            isVisible.value = false;
                          })),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 10.0, top: 5.0, right: 10.0),
                            child: DefaultTextStyle.merge(
                              style: Theme.of(context).textTheme.caption,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                      child: Text(
                                          '主串：${reply.mainPostId.toPostNumber()}')),
                                  if (reply.page != null)
                                    Flexible(child: Text('第 ${reply.page} 页')),
                                ],
                              ),
                            ),
                          ),
                          PostContent(
                            post: post,
                            showPostId: reply.postId != null ? true : false,
                            showReplyCount: false,
                            contentMaxLines: 8,
                            onHiddenText: (context, element, textStyle) =>
                                onHiddenText(
                                    context: context,
                                    element: element,
                                    textStyle: textStyle),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink();
          },
        );
      },
      noItemsFoundBuilder: (context) => const Center(
        child: Text(
          '没有回复记录',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
      ),
      canRefreshAtBottom: false,
    );
  }
}
