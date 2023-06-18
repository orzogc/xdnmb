import 'dart:async';

import 'package:anchor_scroll_controller/anchor_scroll_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../data/models/controller.dart';
import '../data/models/tag.dart';
import '../data/services/settings.dart';
import '../data/services/tag.dart';
import '../data/services/time.dart';
import '../data/services/user.dart';
import '../data/services/xdnmb_client.dart';
import '../modules/post_list.dart';
import '../routes/routes.dart';
import '../utils/exception.dart';
import '../utils/extensions.dart';
import '../utils/navigation.dart';
import '../utils/post.dart';
import '../utils/reference.dart';
import '../utils/theme.dart';
import '../utils/time.dart';
import '../utils/toast.dart';
import 'bilistview.dart';
import 'dialog.dart';
import 'listenable.dart';
import 'page_view.dart';
import 'post.dart';
import 'post_list.dart';
import 'tag.dart';
import 'time.dart';

const int _feedPageCount = 2;

class _FeedKey {
  final int refresh;

  final String? feedId;

  final String? userHash;

  _FeedKey(this.refresh)
      : feedId =
            !SettingsService.to.useHtmlFeed ? SettingsService.to.feedId : null,
        userHash = SettingsService.to.useHtmlFeed
            ? UserService.to.browseCookie?.userHash
            : null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _FeedKey &&
          refresh == other.refresh &&
          feedId == other.feedId &&
          userHash == other.userHash);

  @override
  int get hashCode => Object.hash(refresh, feedId, userHash);
}

class FeedController extends PostListController {
  static int __index = 0;

  static int get _index => __index.clamp(0, _feedPageCount - 1);

  static set _index(int index) => __index = index.clamp(0, _feedPageCount - 1);

  final RxInt _pageIndex;

  int? _maxPage;

  @override
  PostListType get postListType => PostListType.feed;

  @override
  int? get id => null;

  int get pageIndex => _pageIndex.value.clamp(0, _feedPageCount - 1);

  set pageIndex(int index) =>
      _pageIndex.value = index.clamp(0, _feedPageCount - 1);

  int? get maxPage => _maxPage;

  bool get isFeedPage => pageIndex == _FeedBody._index;

  FeedController({required int page, int? pageIndex})
      : _pageIndex = (pageIndex ?? _index).clamp(0, _feedPageCount - 1).obs,
        super(page);

  String text([bool showCount = false, int? index]) {
    index ??= pageIndex;

    switch (index) {
      case _FeedBody._index:
        return '订阅';
      case _TagListBody._index:
        if (showCount) {
          final count = TagService.to.tagsCount;

          return '标签・$count';
        }

        return '标签';
      default:
        debugPrint('未知index：$index');
        return '';
    }
  }
}

FeedController feedController(Map<String, String?> parameters) =>
    FeedController(
        page: parameters['page'].tryParseInt() ?? 1,
        pageIndex: parameters['index'].tryParseInt());

class FeedAppBarTitle extends StatelessWidget {
  final FeedController controller;

  const FeedAppBarTitle(this.controller, {super.key});

  @override
  Widget build(BuildContext context) => ListenBuilder(
      listenable: TagService.to.tagListenable(null),
      builder: (context, child) => Obx(() => Text(controller.text(true))));
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
    final client = XdnmbClientService.to;
    final textStyle = Theme.of(context).textTheme.titleMedium;

    return SimpleDialog(
      title: Text(post.toPostNumber()),
      children: [
        Report(post.id),
        SharePost(mainPostId: post.id),
        AddOrReplacePostTag(post: post),
        SimpleDialogOption(
          onPressed: () async {
            postListBack();

            try {
              await client.deleteFeed(post.id);

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
              await client.deleteFeed(post.id);
              await client.addFeed(post.id);

              showToast('提升 ${post.toPostNumber()} 至订阅最上方成功');
              controller.refreshPage();
            } catch (e) {
              showToast(
                  '提升至订阅最上方失败，请手动重新订阅 ${post.toPostNumber()} ：${exceptionMessage(e)}');

              try {
                await client.addFeed(post.id);
              } catch (e) {
                debugPrint(
                    '订阅 ${post.toPostNumber()} 失败：${exceptionMessage(e)}');
              }
            }
          },
          child: Text('提升至最上方', style: textStyle),
        ),
        NewTab(mainPostId: post.id, mainPost: post),
        NewTabBackground(mainPostId: post.id, mainPost: post),
      ],
    );
  }
}

class _FeedItem extends StatefulWidget {
  final FeedController controller;

  final Visible<PostWithPage<FeedBase>> feed;

  // ignore: unused_element
  const _FeedItem({super.key, required this.controller, required this.feed});

  @override
  State<_FeedItem> createState() => _FeedItemState();
}

class _FeedItemState extends State<_FeedItem> {
  Future<DateTime?>? _getLatestPostTime;

  FeedBase get _feed => widget.feed.item.post;

  void _setGetLatestPostTime() {
    final settings = SettingsService.to;
    final client = XdnmbClientService.to;
    final time = TimeService.to;

    _getLatestPostTime = (_feed is Feed &&
            !settings.isNotShowLatestPostTimeInFeed)
        ? Future(() async {
            for (final postId in (_feed as Feed).recentReplies.reversed) {
              try {
                DateTime? postTime =
                    (await ReferenceDatabase.getReference(postId))?.postTime;

                if (postTime == null) {
                  debugPrint('开始获取订阅 ${_feed.id} 最新回复引用 $postId');

                  final reference =
                      await client.getReference(postId, mainPostId: _feed.id);
                  postTime = reference.postTime;
                }

                if (settings.isShowLatestRelativePostTimeInFeed &&
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

    if (widget.feed.runtimeType != oldWidget.feed.runtimeType ||
        widget.feed != oldWidget.feed) {
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
            post: _feed,
            poUserHash: _feed.userHash,
            contentMaxLines: 8,
            showFullTime: false,
            showPostId: false,
            footer: (!settings.isNotShowLatestPostTimeInFeed &&
                    snapshot.connectionState == ConnectionState.done &&
                    replyTime != null)
                ? (textStyle) => Align(
                      alignment: Alignment.centerRight,
                      child: (settings.isShowLatestAbsolutePostTimeInFeed
                          ? Text(
                              '最新回复 ${formatTime(replyTime)}',
                              style: textStyle ?? AppTheme.postHeaderTextStyle,
                              strutStyle: textStyle != null
                                  ? StrutStyle.fromTextStyle(textStyle)
                                  : AppTheme.postHeaderStrutStyle,
                            )
                          : TimerRefresher(
                              builder: (context) => Text(
                                '最新回复 ${time.relativeTime(replyTime)}',
                                style:
                                    textStyle ?? AppTheme.postHeaderTextStyle,
                                strutStyle: textStyle != null
                                    ? StrutStyle.fromTextStyle(textStyle)
                                    : AppTheme.postHeaderStrutStyle,
                              ),
                            )),
                    )
                : null,
            onTap: (post) =>
                AppRoutes.toThread(mainPostId: _feed.id, mainPost: _feed),
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

class _FeedBody extends StatelessWidget {
  static const int _index = 0;

  final FeedController controller;

  final PostListScrollController scrollController;

  const _FeedBody(
      // ignore: unused_element
      {super.key,
      required this.controller,
      required this.scrollController});

  @override
  Widget build(BuildContext context) {
    final client = XdnmbClientService.to;
    final settings = SettingsService.to;

    return ListenBuilder(
      listenable: Listenable.merge(
          [UserService.to.browseCookieListenable, settings.feedIdListenable]),
      builder: (context, child) => PostListScrollView(
        controller: controller,
        scrollController: scrollController,
        builder: (context, scrollController, refresh) =>
            BiListView<Visible<PostWithPage<FeedBase>>>(
          key: ValueKey<_FeedKey>(_FeedKey(refresh)),
          scrollController: scrollController,
          postListController: controller,
          initialPage: controller.page,
          canLoadMoreAtBottom: false,
          fetch: (page) async {
            if (settings.useHtmlFeed) {
              final (feeds, maxPage) = await client.getHtmlFeed(page: page);
              controller._maxPage = maxPage;

              return feeds
                  .map((feed) => Visible(PostWithPage<FeedBase>(feed, page)))
                  .toList();
            } else {
              controller._maxPage = null;

              return (await client.getFeed(settings.feedId, page: page))
                  .map((feed) => Visible(PostWithPage<FeedBase>(feed, page)))
                  .toList();
            }
          },
          itemBuilder: (context, feed, index) => Obx(
            () => feed.isVisible
                ? AnchorItemWrapper(
                    key: feed.item.toValueKey(),
                    controller: scrollController,
                    index: feed.item.toIndex(),
                    child: _FeedItem(
                      key: ValueKey<int>(settings.showLatestPostTimeInFeedRx),
                      controller: controller,
                      feed: feed,
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

class _TagListDialog extends StatelessWidget {
  final TagData tag;

  final int? count;

  final VoidCallback onAddedTag;

  const _TagListDialog(
      // ignore: unused_element
      {super.key,
      required this.tag,
      this.count,
      required this.onAddedTag});

  @override
  Widget build(BuildContext context) => SimpleDialog(
        // 为了不让Tag占领整行的空间
        title: Align(
          alignment: Alignment.centerLeft,
          child: Tag.fromTagData(tag: tag),
        ),
        children: [
          AddOrEditTag(onAdded: onAddedTag),
          AddOrEditTag(editedTag: tag),
          DeleteTag(tag),
          if (count == null || count! > 0) ToTaggedPostList(tag.id),
          if (count == null || count! > 0) NewTabToTaggedPostList(tag),
          if (count == null || count! > 0)
            NewTabBackgroundToTaggedPostList(tag),
        ],
      );
}

class _TagListItem extends StatefulWidget {
  final FeedController controller;

  final int tagId;

  const _TagListItem(
      // ignore: unused_element
      {super.key,
      required this.controller,
      required this.tagId});

  @override
  State<_TagListItem> createState() => _TagListItemState();
}

class _TagListItemState extends State<_TagListItem> {
  late Future<int> _getCount;

  late ValueListenable<Box<TagData>> _listenable;

  int get _tagId => widget.tagId;

  void _setData() {
    _getCount = Future(() => TagService.getTaggedPostCount(_tagId));
    _listenable = TagService.to.tagListenable([_tagId]);
  }

  @override
  void initState() {
    super.initState();

    _setData();
  }

  @override
  void didUpdateWidget(covariant _TagListItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.tagId != oldWidget.tagId) {
      _setData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tagService = TagService.to;

    return FutureBuilder<int>(
      future: _getCount,
      builder: (context, snapshot) {
        int? count;

        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasError) {
          count = null;
          showToast('获取标签数量出现错误：${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          count = snapshot.data;
        }

        return ListenBuilder(
          listenable: _listenable,
          builder: (context, child) {
            final tag = tagService.getTagData(_tagId);

            return tag != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        // 为了不让Tag占领整行的空间
                        title: Align(
                          alignment: Alignment.centerLeft,
                          child: Tag.fromTagData(
                            tag: tag,
                            textStyle: AppTheme.postContentTextStyle,
                            strutStyle: AppTheme.postContentStrutStyle,
                          ),
                        ),
                        trailing: count != null
                            ? Text('$count',
                                style: AppTheme.postContentTextStyle,
                                strutStyle: AppTheme.postContentStrutStyle)
                            : null,
                        onTap: (count == null || count > 0)
                            ? () => AppRoutes.toTaggedPostList(tagId: _tagId)
                            : null,
                        onLongPress: () => postListDialog(_TagListDialog(
                          tag: tag,
                          count: count,
                          onAddedTag: widget.controller.refreshPage,
                        )),
                      ),
                      const Divider(height: 10.0, thickness: 1.0),
                    ],
                  )
                : const SizedBox.shrink();
          },
        );
      },
    );
  }
}

class _TagListBody extends StatelessWidget {
  static const int _index = 1;

  final FeedController controller;

  final PostListScrollController scrollController;

  const _TagListBody(
      // ignore: unused_element
      {super.key,
      required this.controller,
      required this.scrollController});

  @override
  Widget build(BuildContext context) => PostListScrollView(
        controller: controller,
        scrollController: scrollController,
        builder: (context, scrollController, refresh) => BiListView<int>(
          key: ValueKey<int>(refresh),
          scrollController: scrollController,
          postListController: controller,
          initialPage: 1,
          canLoadMoreAtBottom: false,
          fetch: (page) async =>
              page == 1 ? TagService.to.allTagsId.toList() : <int>[],
          itemBuilder: (context, tagId, index) =>
              _TagListItem(controller: controller, tagId: tagId),
          noItemsFoundBuilder: (context) => Center(
            child: Text(
              '没有标签',
              style: AppTheme.boldRedPostContentTextStyle,
              strutStyle: AppTheme.boldRedPostContentStrutStyle,
            ),
          ),
        ),
      );
}

class FeedBody extends StatefulWidget {
  final FeedController controller;

  const FeedBody(this.controller, {super.key});

  @override
  State<FeedBody> createState() => _FeedBodyState();
}

class _FeedBodyState extends State<FeedBody> {
  late final PageController _pageController;

  late StreamSubscription<int> _pageIndexSubscription;

  late final int _initialIndex;

  late final List<PostListScrollController> _scrollControllerList;

  FeedController get _controller => widget.controller;

  void _updateIndex() {
    final page = _pageController.page;
    if (page != null) {
      _controller.pageIndex = page.round();
    }
  }

  void _onPageIndex(int index) {
    index = index.clamp(0, _feedPageCount - 1);
    FeedController._index = index;
    _controller.scrollController = _scrollControllerList[index];

    _controller.trySave();
  }

  @override
  void initState() {
    super.initState();

    _initialIndex = _controller.pageIndex;
    _pageController = PageController(initialPage: _initialIndex);
    _pageController.addListener(_updateIndex);
    _scrollControllerList = List.generate(
        _feedPageCount,
        (index) =>
            PostListScrollController.fromPostListController(_controller));

    _pageIndexSubscription = _controller._pageIndex.listen(_onPageIndex);
  }

  @override
  void didUpdateWidget(covariant FeedBody oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      _pageIndexSubscription.cancel();
      _pageIndexSubscription =
          widget.controller._pageIndex.listen(_onPageIndex);
    }
  }

  @override
  void dispose() {
    _pageIndexSubscription.cancel();
    _pageController.removeListener(_updateIndex);
    _pageController.dispose();
    _controller.scrollController = null;
    for (final scrollController in _scrollControllerList) {
      scrollController.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PostListWithTabBarOrHeader(
        controller: _controller,
        tabBarHeight: () => PageViewTabBar.height,
        tabBar: PageViewTabBar(
          pageController: _pageController,
          initialIndex: _initialIndex,
          onIndex: (index) {
            if (_controller.pageIndex != index) {
              popAllPopup();
              _pageController.animateToPage(index,
                  duration: PageViewTabBar.animationDuration,
                  curve: Curves.easeIn);
            }
          },
          tabs: const [Tab(text: '订阅'), Tab(text: '标签')],
        ),
        postList: SwipeablePageView(
          controller: _pageController,
          itemCount: _feedPageCount,
          itemBuilder: (context, index) {
            late final Widget body;
            switch (index) {
              case _FeedBody._index:
                body = _FeedBody(
                  controller: _controller,
                  scrollController: _scrollControllerList[_FeedBody._index],
                );
                break;
              case _TagListBody._index:
                body = _TagListBody(
                  controller: _controller,
                  scrollController: _scrollControllerList[_TagListBody._index],
                );
                break;
              default:
                body = const Center(
                  child: Text('未知页面', style: AppTheme.boldRed),
                );
            }

            return body;
          },
        ),
      );
}
