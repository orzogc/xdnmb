import 'dart:async';

import 'package:anchor_scroll_controller/anchor_scroll_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../data/models/page.dart';
import '../data/services/forum.dart';
import '../data/services/settings.dart';
import '../data/services/xdnmb_client.dart';
import '../modules/post_list.dart';
import '../routes/routes.dart';
import '../utils/exception.dart';
import '../utils/extensions.dart';
import '../utils/hidden_text.dart';
import '../utils/key.dart';
import '../utils/navigation.dart';
import '../utils/toast.dart';
import 'bilistview.dart';
import 'dialog.dart';
import 'edit_post.dart';
import 'forum_name.dart';
import 'post.dart';
import 'reference.dart';

PostListController forumController(Map<String, String?> parameters) =>
    PostListController(
        postListType: PostListType.forum,
        id: parameters['forumId'].tryParseInt() ?? 0,
        page: parameters['page'].tryParseInt() ?? 1);

PostListController timelineController(Map<String, String?> parameters) =>
    PostListController(
        postListType: PostListType.timeline,
        id: parameters['timelineId'].tryParseInt() ?? 0,
        page: parameters['page'].tryParseInt() ?? 1);

class ForumAppBarTitle extends StatelessWidget {
  final PostListController controller;

  const ForumAppBarTitle(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final client = XdnmbClientService.to;
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() => ForumName(
              forumId: controller.id.value!,
              isTimeline: controller.postListType.value.isTimeline(),
            )),
        Text(
          'X岛 nmbxd.com',
          style: theme.textTheme.bodyText2
              ?.apply(color: theme.colorScheme.onPrimary),
        )
      ],
    );
  }
}

class ForumAppBarPopupMenuButton extends StatelessWidget {
  final PostListController controller;

  const ForumAppBarPopupMenuButton(this.controller, {super.key});

  @override
  Widget build(BuildContext context) => PopupMenuButton(
        itemBuilder: (context) => [
          // TODO: 获取实时公告
          const PopupMenuItem(
            onTap: showNoticeDialog,
            child: Text('公告'),
          ),
          PopupMenuItem(
              onTap: () => postListDialog(const Center(
                  child: ReferenceCard(postId: 50000001, poUserHash: 'Admin'))),
              child: const Text('岛规')),
          if (controller.postListType.value.isForum())
            PopupMenuItem(
              onTap: () => showForumRuleDialog(controller),
              child: const Text('版规'),
            ),
        ],
      );
}

class _ForumDialog extends StatelessWidget {
  final PostBase post;

  const _ForumDialog(this.post, {super.key});

  @override
  Widget build(BuildContext context) => SimpleDialog(
        title: Text(post.toPostNumber()),
        children: [
          SimpleDialogOption(
            onPressed: () async {
              postListBack();
              try {
                await XdnmbClientService.to.client
                    .addFeed(SettingsService.to.feedUuid, post.id);
                showToast('订阅 ${post.id.toPostNumber()} 成功');
              } catch (e) {
                showToast(
                    '订阅 ${post.id.toPostNumber()} 失败：${exceptionMessage(e)}');
              }
            },
            child: Text('订阅', style: Theme.of(context).textTheme.subtitle1),
          ),
          Report(post),
          CopyPostId(post),
          CopyPostReference(post),
          CopyPostContent(post),
          NewTab(post),
          NewTabBackground(post),
        ],
      );
}

class ForumBody extends StatefulWidget {
  final PostListController controller;

  const ForumBody(this.controller, {super.key});

  @override
  State<ForumBody> createState() => _ForumBodyState();
}

class _ForumBodyState extends State<ForumBody> {
  late final AnchorScrollController _anchorController;

  late final StreamSubscription<int> _subscription;

  int _refresh = 0;

  @override
  void initState() {
    super.initState();

    _anchorController = AnchorScrollController(
      onIndexChanged: (index, userScroll) =>
          widget.controller.currentPage.value = index.getPageFromIndex(),
    );
    _subscription = widget.controller.page.listen((page) => _refresh++);
  }

  @override
  void dispose() {
    _anchorController.dispose();
    _subscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final client = XdnmbClientService.to.client;
    final forums = ForumListService.to;
    final postListType = widget.controller.postListType;
    final id = widget.controller.id;

    return Obx(
      () => BiListView<ThreadWithPage>(
        key: getPostListKey(
            PostList.fromController(widget.controller), _refresh),
        controller: _anchorController,
        initialPage: widget.controller.page.value,
        lastPage: forums.maxPage(id.value!,
                isTimeline: postListType.value.isTimeline()) ??
            100,
        fetch: (page) async => postListType.value.isTimeline()
            ? (await client.getTimeline(id.value!, page: page))
                .map((thread) => ThreadWithPage(thread, page))
                .toList()
            : (await client.getForum(id.value!, page: page))
                .map((thread) => ThreadWithPage(thread, page))
                .toList(),
        itemBuilder: (context, thread, index) => AnchorItemWrapper(
          key: thread.toValueKey(),
          controller: _anchorController,
          index: thread.toIndex(),
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            elevation: 1.5,
            child: PostCard(
              post: thread.thread.mainPost,
              showForumName: postListType.value.isTimeline(),
              contentMaxLines: 8,
              poUserHash: thread.thread.mainPost.userHash,
              onTap: (post) => AppRoutes.toThread(
                  mainPostId: thread.thread.mainPost.id,
                  mainPost: thread.thread.mainPost),
              onLongPress: (post) => postListDialog(_ForumDialog(post)),
              onHiddenText: (context, element, textStyle) => onHiddenText(
                  context: context, element: element, textStyle: textStyle),
            ),
          ),
        ),
        noItemsFoundBuilder: (context) => const Center(
          child: Text(
            '没有串',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
