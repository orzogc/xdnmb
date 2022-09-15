import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../data/services/settings.dart';
import '../data/services/xdnmb_client.dart';
import '../modules/post_list.dart';
import '../modules/stack_cache.dart';
import '../routes/routes.dart';
import '../utils/extensions.dart';
import '../utils/hidden_text.dart';
import '../utils/navigation.dart';
import '../utils/toast.dart';
import 'bilistview.dart';
import 'dialog.dart';
import 'post.dart';

class _FeedKey {
  PostListType postListType;

  int page;

  String uuid;

  _FeedKey({required this.postListType, required this.page})
      : uuid = SettingsService.to.feedUuid;

  _FeedKey.fromController(PostListController controller)
      : postListType = controller.postListType.value,
        page = controller.page.value,
        uuid = SettingsService.to.feedUuid;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _FeedKey &&
          postListType == other.postListType &&
          page == other.page &&
          uuid == other.uuid);

  @override
  int get hashCode => Object.hash(postListType, page, uuid);
}

PostListController feedController(Map<String, String?> parameters) =>
    PostListController(
        postListType: PostListType.feed,
        page: int.tryParse(parameters['page'] ?? '1') ?? 1);

class FeedAppBarTitle extends StatelessWidget {
  final PostListController controller;

  const FeedAppBarTitle(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('订阅');
  }
}

class _FeedDialog extends StatelessWidget {
  final PostBase post;

  final VoidCallback onDelete;

  const _FeedDialog({super.key, required this.post, required this.onDelete});

  @override
  Widget build(BuildContext context) => SimpleDialog(
        title: Text(post.toPostNumber()),
        children: [
          SimpleDialogOption(
            onPressed: () async {
              postListBack();
              try {
                await XdnmbClientService.to.client
                    .deleteFeed(SettingsService.to.feedUuid, post.id);
                showToast('取消订阅 ${post.id.toPostNumber()} 成功');
                onDelete();
              } catch (e) {
                showToast('取消订阅 ${post.id.toPostNumber()} 失败：$e');
              }
            },
            child: Text(
              '取消订阅该串',
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

class FeedBody extends StatelessWidget {
  final PostListController controller;

  const FeedBody(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final client = XdnmbClientService.to.client;
    final settings = SettingsService.to;

    return ValueListenableBuilder<Box>(
      valueListenable: settings.feedUuidListenable,
      builder: (context, value, child) => Obx(
        () => BiListView<Feed>(
          key: ValueKey<_FeedKey>(_FeedKey.fromController(controller)),
          initialPage: controller.page.value,
          fetch: (page) => client.getFeed(settings.feedUuid, page: page),
          itemBuilder: (context, feed, index) {
            final isVisible = true.obs;

            return Obx(
              () => isVisible.value
                  ? Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      elevation: 1.5,
                      child: PostCard(
                        key: feed.toValueKey(index),
                        post: feed,
                        contentMaxLines: 8,
                        poUserHash: feed.userHash,
                        onTap: (post) => Get.toNamed(
                          AppRoutes.thread,
                          id: StackCacheView.getKeyId(),
                          arguments: feed,
                          parameters: {
                            'mainPostId': '${feed.id}',
                            'page': '1',
                          },
                        ),
                        onLongPress: (post) => postListDialog<bool>(
                          _FeedDialog(
                            post: post,
                            onDelete: () => isVisible.value = false,
                          ),
                        ),
                        onLinkTap: null,
                        onHiddenText: (context, element, textStyle) =>
                            onHiddenText(
                                context: context,
                                element: element,
                                textStyle: textStyle,
                                poUserHash: feed.userHash),
                      ),
                    )
                  : const SizedBox.shrink(),
            );
          },
          separator: const SizedBox.shrink(),
          noItemsFoundBuilder: (context) => const Center(
            child: Text(
              '没有订阅',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
