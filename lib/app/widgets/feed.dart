import 'package:anchor_scroll_controller/anchor_scroll_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../data/services/settings.dart';
import '../data/services/xdnmb_client.dart';
import '../modules/post_list.dart';
import '../routes/routes.dart';
import '../utils/exception.dart';
import '../utils/extensions.dart';
import '../utils/misc.dart';
import '../utils/navigation.dart';
import '../utils/theme.dart';
import '../utils/toast.dart';
import 'bilistview.dart';
import 'dialog.dart';
import 'post.dart';
import 'post_list.dart';

class _FeedKey {
  final int refresh;

  final String feedId;

  _FeedKey(this.refresh) : feedId = SettingsService.to.feedId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _FeedKey && refresh == other.refresh && feedId == other.feedId);

  @override
  int get hashCode => Object.hash(refresh, feedId);
}

class FeedController extends PostListController {
  @override
  PostListType get postListType => PostListType.feed;

  @override
  int? get id => null;

  FeedController(int page) : super(page);
}

FeedController feedController(Map<String, String?> parameters) =>
    FeedController(parameters['page'].tryParseInt() ?? 1);

class FeedAppBarTitle extends StatelessWidget {
  const FeedAppBarTitle({super.key});

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
                    .deleteFeed(SettingsService.to.feedId, post.id);
                showToast('取消订阅 ${post.id.toPostNumber()} 成功');
                onDelete();
              } catch (e) {
                showToast(
                    '取消订阅 ${post.id.toPostNumber()} 失败：${exceptionMessage(e)}');
              }
            },
            child: Text('取消订阅', style: Theme.of(context).textTheme.subtitle1),
          ),
          CopyPostId(post.id),
          CopyPostReference(post.id),
          CopyPostContent(post),
          NewTab(post),
          NewTabBackground(post),
        ],
      );
}

class FeedBody extends StatelessWidget {
  final FeedController controller;

  const FeedBody(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final client = XdnmbClientService.to.client;
    final settings = SettingsService.to;

    return ValueListenableBuilder<Box>(
      valueListenable: settings.feedIdListenable,
      builder: (context, value, child) => PostListAnchorRefresher(
        controller: controller,
        builder: (context, anchorController, refresh) =>
            BiListView<Visible<PostWithPage>>(
          key: ValueKey<_FeedKey>(_FeedKey(refresh)),
          controller: anchorController,
          initialPage: controller.page,
          canLoadMoreAtBottom: false,
          fetch: (page) async =>
              (await client.getFeed(settings.feedId, page: page))
                  .map((feed) => Visible(PostWithPage(feed, page)))
                  .toList(),
          itemBuilder: (context, feed, index) => Obx(
            () => feed.isVisible.value
                ? AnchorItemWrapper(
                    key: feed.item.toValueKey(),
                    controller: anchorController,
                    index: feed.item.toIndex(),
                    child: PostCard(
                      child: PostInkWell(
                        post: feed.item.post,
                        showFullTime: false,
                        showPostId: false,
                        contentMaxLines: 8,
                        poUserHash: feed.item.post.userHash,
                        onTap: (post) => AppRoutes.toThread(
                            mainPostId: feed.item.post.id,
                            mainPost: feed.item.post),
                        onLongPress: (post) => postListDialog(
                          _FeedDialog(
                            post: post,
                            onDelete: () => feed.isVisible.value = false,
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          noItemsFoundBuilder: (context) => const Center(
            child: Text('没有订阅', style: AppTheme.boldRed),
          ),
        ),
      ),
    );
  }
}
