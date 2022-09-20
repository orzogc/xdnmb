import 'package:anchor_scroll_controller/anchor_scroll_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../data/models/page.dart';
import '../data/services/forum.dart';
import '../data/services/xdnmb_client.dart';
import '../modules/post_list.dart';
import '../routes/routes.dart';
import '../utils/extensions.dart';
import '../utils/hidden_text.dart';
import 'bilistview.dart';
import 'dialog.dart';
import 'forum_name.dart';
import 'post.dart';
import 'reference.dart';

PostListController forumController(Map<String, String?> parameters) =>
    PostListController(
        postListType: PostListType.forum,
        id: int.tryParse(parameters['forumId'] ?? '0') ?? 0,
        page: int.tryParse(parameters['page'] ?? '1') ?? 1);

PostListController timelineController(Map<String, String?> parameters) =>
    PostListController(
        postListType: PostListType.timeline,
        id: int.tryParse(parameters['timelineId'] ?? '0') ?? 0,
        page: int.tryParse(parameters['page'] ?? '1') ?? 1);

// TODO: double tap
class ForumAppBarTitle extends StatelessWidget {
  final PostListController controller;

  const ForumAppBarTitle(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
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
        tooltip: '菜单',
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
          AddFeed(post),
          CopyPostId(post),
          CopyPostNumber(post),
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

  @override
  void initState() {
    super.initState();

    _anchorController = AnchorScrollController(
      onIndexChanged: (index, userScroll) =>
          widget.controller.currentPage.value = index.getPageFromIndex(),
    );
  }

  @override
  void dispose() {
    _anchorController.dispose();

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
        key: ValueKey<PostList>(PostList.fromController(widget.controller)),
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
        separator: const SizedBox.shrink(),
        noItemsFoundBuilder: (context) => const Center(
          child: Text(
            '这里没有串',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

/* class ForumBody extends StatelessWidget {
  final PostListController controller;

  const ForumBody(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final client = XdnmbClientService.to.client;
    final forums = ForumListService.to;

    return Obx(
      () {
        final anchorController = AnchorScrollController(
          onIndexChanged: (index, userScroll) =>
              controller.currentPage.value = index.getPageFromIndex(),
        );

        return BiListView<ThreadWithPage>(
          key: ValueKey<PostList>(PostList.fromController(controller)),
          controller: anchorController,
          initialPage: controller.page.value,
          lastPage: forums.maxPage(controller.id.value!,
                  isTimeline: controller.postListType.value.isTimeline()) ??
              100,
          fetch: (page) async => controller.postListType.value.isTimeline()
              ? (await client.getTimeline(controller.id.value!, page: page))
                  .map((thread) => ThreadWithPage(thread, page))
                  .toList()
              : (await client.getForum(controller.id.value!, page: page))
                  .map((thread) => ThreadWithPage(thread, page))
                  .toList(),
          itemBuilder: (context, thread, index) => AnchorItemWrapper(
            key: thread.toValueKey(),
            controller: anchorController,
            index: thread.toIndex(),
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              elevation: 1.5,
              child: PostCard(
                post: thread.thread.mainPost,
                showForumName: controller.postListType.value.isTimeline(),
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
          separator: const SizedBox.shrink(),
          noItemsFoundBuilder: (context) => const Center(
            child: Text(
              '这里没有串',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
} */
