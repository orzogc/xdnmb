import 'dart:async';

import 'package:anchor_scroll_controller/anchor_scroll_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../data/models/controller.dart';
import '../data/services/settings.dart';
import '../data/services/time.dart';
import '../data/services/xdnmb_client.dart';
import '../modules/post_list.dart';
import '../routes/routes.dart';
import '../utils/exception.dart';
import '../utils/extensions.dart';
import '../utils/navigation.dart';
import '../utils/post_list.dart';
import '../utils/reference.dart';
import '../utils/theme.dart';
import '../utils/time.dart';
import '../utils/toast.dart';
import 'bilistview.dart';
import 'dialog.dart';
import 'listenable.dart';
import 'post.dart';
import 'post_list.dart';
import 'time.dart';

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
  Widget build(BuildContext context) => const Text('订阅');
}

class _FeedDialog extends StatelessWidget {
  final FeedController controller;

  final PostBase post;

  final VoidCallback onDelete;

  const _FeedDialog(
      // ignore: unused_element
      {super.key,
      required this.controller,
      required this.post,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;
    final client = XdnmbClientService.to.client;
    final textStyle = Theme.of(context).textTheme.titleMedium;

    return SimpleDialog(
      title: Text(post.toPostNumber()),
      children: [
        Report(post.id),
        SharePost(mainPostId: post.id),
        AddPostTag(post),
        SimpleDialogOption(
          onPressed: () async {
            postListBack();

            try {
              await client.deleteFeed(settings.feedId, post.id);

              showToast('取消订阅 ${post.toPostNumber()} 成功');
              onDelete();
            } catch (e) {
              showToast(
                  '取消订阅 ${post.toPostNumber()} 失败：${exceptionMessage(e)}');
            }
          },
          child: Text('取消订阅', style: textStyle),
        ),
        CopyPostReference(post.id),
        CopyPostContent(post),
        SimpleDialogOption(
          onPressed: () async {
            postListBack();

            try {
              await client.deleteFeed(settings.feedId, post.id);
              await client.addFeed(settings.feedId, post.id);

              showToast('提升 ${post.toPostNumber()} 至订阅最上方成功');
              controller.refreshPage();
            } catch (e) {
              showToast(
                  '提升至订阅最上方失败，请手动重新订阅 ${post.toPostNumber()} ：${exceptionMessage(e)}');

              try {
                await client.addFeed(settings.feedId, post.id);
              } catch (e) {
                debugPrint(
                    '订阅 ${post.toPostNumber()} 失败：${exceptionMessage(e)}');
              }
            }
          },
          child: Text('提升至最上方', style: textStyle),
        ),
        NewTab(post),
        NewTabBackground(post),
      ],
    );
  }
}

class _FeedItem extends StatefulWidget {
  final FeedController controller;

  final Visible<PostWithPage<Feed>> feed;

  // ignore: unused_element
  const _FeedItem({super.key, required this.controller, required this.feed});

  @override
  State<_FeedItem> createState() => _FeedItemState();
}

class _FeedItemState extends State<_FeedItem> {
  Future<DateTime?>? _getLatestPostTime;

  void _setGetLatestPostTime() {
    final settings = SettingsService.to;
    final client = XdnmbClientService.to;
    final time = TimeService.to;

    _getLatestPostTime = !settings.isNotShowedLatestPostTimeInFeed
        ? Future(() async {
            for (final postId in widget.feed.item.post.recentReplies.reversed) {
              try {
                DateTime? postTime =
                    (await ReferenceDatabase.getReference(postId))?.postTime;

                if (postTime == null) {
                  debugPrint(
                      '开始获取订阅 ${widget.feed.item.post.id} 最新回复引用 $postId');

                  final reference = await client.getReference(postId,
                      mainPostId: widget.feed.item.post.id);
                  postTime = reference.postTime;
                }

                if (settings.isShowedLatestRelativePostTimeInFeed &&
                    postTime.isAfter(time.now)) {
                  time.updateTime();
                }

                return postTime;
              } catch (e) {
                debugPrint('获取订阅最新回复引用出错：${exceptionMessage(e)}');

                await Future.delayed(const Duration(seconds: 1));
              }
            }

            return null;
          })
        : null;
  }

  @override
  void initState() {
    super.initState();

    _setGetLatestPostTime();
  }

  @override
  void didUpdateWidget(covariant _FeedItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.feed != oldWidget.feed) {
      _setGetLatestPostTime();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;
    final time = TimeService.to;

    return PostCard(
      child: FutureBuilder<DateTime?>(
        future: _getLatestPostTime,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasError) {
            debugPrint('获取订阅最新回复引用出错：${exceptionMessage(snapshot.error!)}');
          }

          final replyTime = snapshot.data;

          return PostInkWell(
            post: widget.feed.item.post,
            poUserHash: widget.feed.item.post.userHash,
            contentMaxLines: 8,
            showFullTime: false,
            showPostId: false,
            footer: (!settings.isNotShowedLatestPostTimeInFeed &&
                    snapshot.connectionState == ConnectionState.done &&
                    replyTime != null)
                ? (textStyle) => Align(
                      alignment: Alignment.centerRight,
                      child: (settings.isShowedLatestAbsolutePostTimeInFeed
                          ? Text(
                              '最新回复 ${formatTime(replyTime)}',
                              style: textStyle ?? AppTheme.postHeaderTextStyle,
                              strutStyle: AppTheme.postHeaderStrutStyle,
                            )
                          : TimerRefresher(
                              builder: (context) => Text(
                                '最新回复 ${time.relativeTime(replyTime)}',
                                style:
                                    textStyle ?? AppTheme.postHeaderTextStyle,
                                strutStyle: AppTheme.postHeaderStrutStyle,
                              ),
                            )),
                    )
                : null,
            onTap: (post) => AppRoutes.toThread(
                mainPostId: widget.feed.item.post.id,
                mainPost: widget.feed.item.post),
            onLongPress: (post) => postListDialog(
              _FeedDialog(
                controller: widget.controller,
                post: post,
                onDelete: () => widget.feed.isVisible = false,
              ),
            ),
          );
        },
      ),
    );
  }
}

class FeedBody extends StatefulWidget {
  final FeedController controller;

  const FeedBody(this.controller, {super.key});

  @override
  State<FeedBody> createState() => _FeedBodyState();
}

class _FeedBodyState extends State<FeedBody> {
  late StreamSubscription<int> _pageSubscription;

  void _trySave(int page) => widget.controller.trySave();

  @override
  void initState() {
    super.initState();

    _pageSubscription = widget.controller.listenPage(_trySave);
  }

  @override
  void didUpdateWidget(covariant FeedBody oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      _pageSubscription.cancel();
      _pageSubscription = widget.controller.listenPage(_trySave);
    }
  }

  @override
  void dispose() {
    _pageSubscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final client = XdnmbClientService.to;
    final settings = SettingsService.to;

    return ListenableBuilder(
      listenable: settings.feedIdListenable,
      builder: (context, child) => PostListScrollView(
        controller: widget.controller,
        builder: (context, scrollController, refresh) =>
            BiListView<Visible<PostWithPage<Feed>>>(
          key: ValueKey<_FeedKey>(_FeedKey(refresh)),
          scrollController: scrollController,
          postListController: widget.controller,
          initialPage: widget.controller.page,
          canLoadMoreAtBottom: false,
          fetch: (page) async =>
              (await client.getFeed(settings.feedId, page: page))
                  .map((feed) => Visible(PostWithPage<Feed>(feed, page)))
                  .toList(),
          itemBuilder: (context, feed, index) => Obx(
            () => feed.isVisible
                ? AnchorItemWrapper(
                    key: feed.item.toValueKey(),
                    controller: scrollController,
                    index: feed.item.toIndex(),
                    child: _FeedItem(
                      controller: widget.controller,
                      feed: feed,
                      key: ValueKey<int>(settings.isShowLatestPostTimeInFeed),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          noItemsFoundBuilder: (context) => Center(
            child: Text(
              '没有订阅',
              style: AppTheme.boldRedPostContentTextStyle,
              strutStyle: AppTheme.boldRedPostContentStrutStyle,
            ),
          ),
        ),
      ),
    );
  }
}
