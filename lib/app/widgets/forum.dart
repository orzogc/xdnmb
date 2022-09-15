import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../data/services/forum.dart';
import '../data/services/xdnmb_client.dart';
import '../modules/post_list.dart';
import '../modules/stack_cache.dart';
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

class ForumBody extends StatelessWidget {
  final PostListController controller;

  const ForumBody(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final client = XdnmbClientService.to.client;
    final forums = ForumListService.to;

    return Obx(
      () => BiListView<ForumThread>(
        key: ValueKey<PostList>(PostList.fromController(controller)),
        initialPage: controller.page.value,
        lastPage: forums.maxPage(controller.id.value!,
                isTimeline: controller.postListType.value.isTimeline()) ??
            100,
        fetch: controller.postListType.value.isTimeline()
            ? (page) => client.getTimeline(controller.id.value!, page: page)
            : (page) => client.getForum(controller.id.value!, page: page),
        itemBuilder: (context, thread, index) => Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          elevation: 1.5,
          child: PostCard(
            key: thread.mainPost.toValueKey(index),
            post: thread.mainPost,
            showForumName: controller.postListType.value.isTimeline(),
            contentMaxLines: 8,
            poUserHash: thread.mainPost.userHash,
            onTap: (post) => Get.toNamed(
              AppRoutes.thread,
              id: StackCacheView.getKeyId(),
              arguments: thread.mainPost,
              parameters: {
                'mainPostId': '${thread.mainPost.id}',
                'page': '1',
              },
            ),
            onLongPress: (post) => postListDialog(_ForumDialog(post)),
            onLinkTap: null,
            onHiddenText: (context, element, textStyle) => onHiddenText(
              context: context,
              element: element,
              textStyle: textStyle,
              poUserHash: thread.mainPost.userHash,
            ),
          ),
        ),
        separator: const SizedBox.shrink(),
        noItemsFoundBuilder: (context) => const Center(
          child: Text(
            '这个板块没有帖子',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
