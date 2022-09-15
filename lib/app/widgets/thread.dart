import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../data/services/settings.dart';
import '../data/services/xdnmb_client.dart';
import '../modules/edit_post.dart';
import '../modules/post_list.dart';
import '../modules/stack_cache.dart';
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

// TODO: 取消只看Po
class ThreadAppBarPopupMenuButton extends StatelessWidget {
  final PostListController controller;

  const ThreadAppBarPopupMenuButton(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final post = controller.post.value!;

    return PopupMenuButton(
      tooltip: '菜单',
      itemBuilder: (context) => [
        PopupMenuItem(
          onTap: () async {
            try {
              await XdnmbClientService.to.client
                  .addFeed(SettingsService.to.feedUuid, post.id);
              showToast('订阅 ${post.id.toPostNumber()} 成功');
            } catch (e) {
              showToast('订阅 ${post.id.toPostNumber()} 失败：$e');
            }
          },
          child: const Text('订阅本串'),
        ),
        PopupMenuItem(
          onTap: () {
            openNewTab(controller.copy());

            showToast('已在新标签页打开 ${post.id.toPostNumber()}');
          },
          child: const Text('在新标签页打开本串'),
        ),
        PopupMenuItem(
          onTap: () {
            openNewTabBackground(controller.copy());

            showToast('已在新标签页后台打开 ${post.id.toPostNumber()}');
          },
          child: const Text('在新标签页后台打开本串'),
        ),
      ],
    );
  }
}

class OnlyPoThreadButton extends StatelessWidget {
  final PostListController controller;

  const OnlyPoThreadButton(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextButton(
      onPressed: () {
        Get.toNamed(
          AppRoutes.onlyPoThread,
          id: StackCacheView.getKeyId(),
          arguments: controller.post.value,
          parameters: {
            'mainPostId': '${controller.id.value!}',
            'page': '1',
          },
        );
      },
      child: Text(
        'Po',
        style: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontSize: theme.textTheme.subtitle1?.fontSize),
      ),
    );
  }
}

class ThreadBody extends StatelessWidget {
  final PostListController controller;

  const ThreadBody(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final client = XdnmbClientService.to.client;

    return Obx(
      () => BiListView<PostBase>(
        key: ValueKey<PostList>(PostList.fromController(controller)),
        initialPage: controller.page.value,
        fetch: (page) async {
          final thread = controller.postListType.value.isThread()
              ? await client.getThread(controller.id.value!, page: page)
              : await client.getOnlyPoThread(controller.id.value!, page: page);

          controller.post.value ??= thread.mainPost;
          if (controller.post.value is ReferenceBase) {
            controller.post.value = thread.mainPost;
          }

          if (page != 1 && thread.replies.isEmpty) {
            return [];
          }

          final List<PostBase> posts = [];
          if (page == 1) {
            posts.add(thread.mainPost);
          }
          // TODO: 提示tip是官方信息
          if (thread.tip != null) {
            posts.add(thread.tip!);
          }
          if (thread.replies.isNotEmpty) {
            posts.addAll(thread.replies);
          }

          return posts;
        },
        itemBuilder: (context, post, index) => PostCard(
          key: post.toValueKey(index),
          post: post,
          showForumName: false,
          showReplyCount: false,
          poUserHash: controller.post.value?.userHash,
          onTap: (post) {},
          onLongPress: (post) =>
              postListDialog(_ThreadDialog(controller: controller, post: post)),
          onLinkTap: (context, link) =>
              parseUrl(url: link, poUserHash: controller.post.value?.userHash),
          onHiddenText: (context, element, textStyle) => onHiddenText(
              context: context,
              element: element,
              textStyle: textStyle,
              canTap: true,
              poUserHash: controller.post.value?.userHash),
          mouseCursor: SystemMouseCursors.basic,
          hoverColor:
              Get.isDarkMode ? theme.cardColor : theme.scaffoldBackgroundColor,
          onPostIdTap: (postId) => _replyPost(controller, postId),
        ),
      ),
    );
  }
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
