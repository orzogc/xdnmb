import 'package:anchor_scroll_controller/anchor_scroll_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../data/models/page.dart';
import '../data/services/settings.dart';
import '../data/services/xdnmb_client.dart';
import '../modules/post_list.dart';
import '../routes/routes.dart';
import '../utils/exception.dart';
import '../utils/extensions.dart';
import '../utils/hidden_text.dart';
import '../utils/navigation.dart';
import '../utils/theme.dart';
import '../utils/toast.dart';
import 'bilistview.dart';
import 'dialog.dart';
import 'post.dart';
import 'post_list.dart';

class _FeedKey {
  final int refresh;

  final String uuid;

  _FeedKey(this.refresh) : uuid = SettingsService.to.feedUuid;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _FeedKey && refresh == other.refresh && uuid == other.uuid);

  @override
  int get hashCode => Object.hash(refresh, uuid);
}

class FeedController extends PostListController {
  @override
  PostListType get postListType => PostListType.feed;

  @override
  int? get id => null;

  @override
  PostBase? get post => null;

  @override
  set post(PostBase? post) {}

  @override
  int? get bottomBarIndex => null;

  @override
  set bottomBarIndex(int? index) {}

  @override
  List<DateTimeRange?>? get dateRange => null;

  @override
  set dateRange(List<DateTimeRange?>? range) {}

  @override
  bool? get cancelAutoJump => null;

  @override
  int? get jumpToId => null;

  FeedController({required int page}) : super(page);

  @override
  void refreshDateRange() {}
}

FeedController feedController(Map<String, String?> parameters) =>
    FeedController(page: parameters['page'].tryParseInt() ?? 1);

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
                    .deleteFeed(SettingsService.to.feedUuid, post.id);
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
      valueListenable: settings.feedUuidListenable,
      builder: (context, value, child) => PostListAnchorRefresher(
        controller: controller,
        builder: (context, anchorController, refresh) =>
            BiListView<PostWithPage>(
          key: ValueKey<_FeedKey>(_FeedKey(refresh)),
          controller: anchorController,
          initialPage: controller.page,
          canRefreshAtBottom: false,
          fetch: (page) async =>
              (await client.getFeed(settings.feedUuid, page: page))
                  .map((feed) => PostWithPage(feed, page))
                  .toList(),
          itemBuilder: (context, feed, index) {
            final isVisible = true.obs;

            return Obx(
              () => isVisible.value
                  ? AnchorItemWrapper(
                      key: feed.toValueKey(),
                      controller: anchorController,
                      index: feed.toIndex(),
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        elevation: 1.5,
                        child: PostCard(
                          post: feed.post,
                          contentMaxLines: 8,
                          poUserHash: feed.post.userHash,
                          onTap: (post) => AppRoutes.toThread(
                              mainPostId: feed.post.id, mainPost: feed.post),
                          onLongPress: (post) => postListDialog(
                            _FeedDialog(
                              post: post,
                              onDelete: () => isVisible.value = false,
                            ),
                          ),
                          onHiddenText: (context, element, textStyle) =>
                              onHiddenText(
                                  context: context,
                                  element: element,
                                  textStyle: textStyle),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            );
          },
          noItemsFoundBuilder: (context) => const Center(
            child: Text('没有订阅', style: AppTheme.boldRed),
          ),
        ),
      ),
    );
  }
}
