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
import '../utils/notify.dart';
import '../utils/theme.dart';
import '../utils/time.dart';
import '../utils/toast.dart';
import 'bilistview.dart';
import 'dialog.dart';
import 'post.dart';
import 'post_list.dart';

const int _historyEachPage = 20;

class _HistoryKey {
  final DateTimeRange? range;

  final int refresh;

  final bool value;

  const _HistoryKey(this.range, this.refresh, this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _HistoryKey &&
          range == other.range &&
          refresh == other.refresh &&
          value == other.value);

  @override
  int get hashCode => Object.hash(range, refresh, value);
}

class HistoryBottomBarKey {
  final int index;

  final DateTimeRange? range;

  const HistoryBottomBarKey(this.index, this.range);

  HistoryBottomBarKey.fromController(HistoryController controller)
      : assert(controller.bottomBarIndex < 3),
        index = controller.bottomBarIndex,
        range = controller._getDateRange();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HistoryBottomBarKey &&
          index == other.index &&
          range == other.range);

  @override
  int get hashCode => Object.hash(index, range);
}

class HistoryController extends PostListController {
  final RxInt _bottomBarIndex;

  final Rx<List<DateTimeRange?>> _dateRange;

  final List<ListenableNotifier> _notifiers = [
    ListenableNotifier(),
    ListenableNotifier(),
    ListenableNotifier(),
  ];

  @override
  PostListType get postListType => PostListType.history;

  @override
  int? get id => null;

  int get bottomBarIndex => _bottomBarIndex.value;

  set bottomBarIndex(int index) => _bottomBarIndex.value = index;

  List<DateTimeRange?> get dateRange => _dateRange.value;

  set dateRange(List<DateTimeRange?> range) => _dateRange.value = range;

  HistoryController(
      {required int page,
      int bottomBarIndex = 0,
      required List<DateTimeRange?> dateRange})
      : _bottomBarIndex = bottomBarIndex.obs,
        _dateRange = Rx(dateRange),
        super(page);

  ListenableNotifier _getNotifier([int? index]) {
    assert(index == null || index < 3);

    return _notifiers[index ?? bottomBarIndex];
  }

  void _notify([int? index]) {
    _getNotifier(index).notify();
    _bottomBarIndex.refresh();
  }

  void _trigger([int? index]) {
    _getNotifier(index).trigger();
    _bottomBarIndex.refresh();
  }

  DateTimeRange? _getDateRange([int? index]) {
    assert(index == null || index < 3);

    return dateRange[index ?? bottomBarIndex];
  }

  void _setDateRange(DateTimeRange? range, [int? index]) {
    assert(index == null || index < 3);

    dateRange[index ?? bottomBarIndex] = range;
    _notify(index);
  }
}

HistoryController historyController(Map<String, String?> parameters) =>
    HistoryController(
        page: parameters['page'].tryParseInt() ?? 1,
        bottomBarIndex: parameters['index'].tryParseInt() ?? 0,
        dateRange: List.filled(3, null));

class HistoryAppBarTitle extends StatelessWidget {
  final HistoryController controller;

  const HistoryAppBarTitle(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final history = PostHistoryService.to;

    return FutureBuilder<int?>(future: Future(() {
      switch (controller.bottomBarIndex) {
        case _BrowseHistoryBody._index:
          return history.browseHistoryCount(controller._getDateRange());
        case _PostHistoryBody._index:
          return history.postDataCount(controller._getDateRange());
        case _ReplyHistoryBody._index:
          return history.replyDataCount(controller._getDateRange());
        default:
          debugPrint('未知bottomBarIndex：${controller.bottomBarIndex}');
          return null;
      }
    }), builder: (context, snapshot) {
      late final String text;
      switch (controller.bottomBarIndex) {
        case _BrowseHistoryBody._index:
          text = '浏览';
          break;
        case _PostHistoryBody._index:
          text = '主题';
          break;
        case _ReplyHistoryBody._index:
          text = '回复';
          break;
        default:
          text = '历史记录';
      }

      if (snapshot.connectionState == ConnectionState.done &&
          snapshot.hasData) {
        return Text('$text（${snapshot.data}）');
      }

      if (snapshot.connectionState == ConnectionState.done &&
          snapshot.hasError) {
        showToast('读取历史记录失败：${snapshot.error}');
      }

      return Text(text);
    });
  }
}

class HistoryDateRangePicker extends StatelessWidget {
  static final DateTime _firstDate = DateTime(2022, 6, 19);

  final HistoryController controller;

  const HistoryDateRangePicker(this.controller, {super.key});

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: () async {
          final range = await showDateRangePicker(
              context: context,
              initialDateRange: controller._getDateRange(),
              firstDate: _firstDate,
              lastDate: DateTime.now(),
              initialEntryMode: DatePickerEntryMode.calendarOnly,
              locale: WidgetsBinding.instance.platformDispatcher.locale);

          if (range != null) {
            controller._setDateRange(range);
            //controller.refreshPage();
          }
        },
        icon: const Icon(Icons.calendar_month),
      );
}

class HistoryAppBarPopupMenuButton extends StatelessWidget {
  final HistoryController controller;

  const HistoryAppBarPopupMenuButton(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final history = PostHistoryService.to;

    return PopupMenuButton(
      itemBuilder: (context) => [
        PopupMenuItem(
          onTap: () async {
            final range = controller._getDateRange();

            switch (controller.bottomBarIndex) {
              case _BrowseHistoryBody._index:
                if (await history.browseHistoryCount(range) > 0) {
                  postListDialog(ConfirmCancelDialog(
                    content: '确定清空浏览记录？',
                    onConfirm: () async {
                      await history.clearBrowseHistory(range);
                      controller._trigger();
                      showToast('清空浏览记录');
                      postListBack();
                    },
                    onCancel: () => postListBack(),
                  ));
                }

                break;
              case _PostHistoryBody._index:
                if (await history.postDataCount(range) > 0) {
                  postListDialog(ConfirmCancelDialog(
                    content: '确定清空主题记录？',
                    onConfirm: () async {
                      await history.clearPostData(range);
                      controller._trigger();
                      showToast('清空主题记录');
                      postListBack();
                    },
                    onCancel: () => postListBack(),
                  ));
                }

                break;
              case _ReplyHistoryBody._index:
                if (await history.replyDataCount(range) > 0) {
                  postListDialog(ConfirmCancelDialog(
                    content: '确定清空回复记录？',
                    onConfirm: () async {
                      await history.clearReplyData(range);
                      controller._trigger();
                      showToast('清空回复记录');
                      postListBack();
                    },
                    onCancel: () => postListBack(),
                  ));
                }

                break;
              default:
                debugPrint('未知bottomBarIndex：${controller.bottomBarIndex}');
            }
          },
          child: const Text('清空'),
        ),
      ],
    );
  }
}

class _HistoryDialog extends StatelessWidget {
  final PostBase mainPost;

  final PostBase? post;

  final bool confirmDelete;

  final VoidCallback onDelete;

  const _HistoryDialog(
      {super.key,
      required this.mainPost,
      this.post,
      this.confirmDelete = true,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final hasPostId =
        (post != null && post!.id > 0) || (post == null && mainPost.id > 0);
    final postHistory = post != null ? post! : mainPost;

    return SimpleDialog(
      title: hasPostId ? Text(postHistory.toPostNumber()) : null,
      children: [
        SimpleDialogOption(
          onPressed: () async {
            if (confirmDelete) {
              final result = await postListDialog<bool>(ConfirmCancelDialog(
                content: '确定删除？',
                onConfirm: () => postListBack<bool>(result: true),
                onCancel: () => postListBack<bool>(result: false),
              ));

              if (result ?? false) {
                onDelete();
                postListBack();
              }
            } else {
              onDelete();
              postListBack();
            }
          },
          child: Text('删除', style: Theme.of(context).textTheme.subtitle1),
        ),
        if (hasPostId) CopyPostId(postHistory.id),
        if (hasPostId) CopyPostReference(postHistory.id),
        CopyPostContent(postHistory),
        if (post != null) CopyPostId(mainPost.id, text: '复制主串串号'),
        if (post != null) CopyPostReference(mainPost.id, text: '复制主串串号引用'),
        if (mainPost.id > 0)
          NewTab(mainPost, text: post != null ? '在新标签页打开主串' : null),
        if (mainPost.id > 0)
          NewTabBackground(mainPost, text: post != null ? '在新标签页后台打开主串' : null),
      ],
    );
  }
}

class _BrowseHistoryBody extends StatelessWidget {
  static const _index = 0;

  final HistoryController controller;

  const _BrowseHistoryBody(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final history = PostHistoryService.to;

    return PostListRefresher(
      controller: controller,
      builder: (context, refresh) => ValueListenableBuilder<bool>(
        valueListenable: controller._getNotifier(_BrowseHistoryBody._index),
        builder: (context, value, child) => BiListView<BrowseHistory>(
          key: ValueKey<_HistoryKey>(_HistoryKey(
              controller._getDateRange(_BrowseHistoryBody._index),
              refresh,
              value)),
          initialPage: controller.page,
          canRefreshAtBottom: false,
          fetch: (page) => history.browseHistoryList(
              (page - 1) * _historyEachPage,
              page * _historyEachPage,
              controller._getDateRange(_BrowseHistoryBody._index)),
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
                            confirmDelete: false,
                            onDelete: () async {
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
                                child: OverflowBar(
                                  spacing: 5.0,
                                  alignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '最后浏览时间：${formatTime(browse.browseTime)}',
                                    ),
                                    if (browsePage != null &&
                                        browsePostId != null)
                                      Text(
                                        '浏览到：第$browsePage页 ${browsePostId.toPostNumber()}',
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            PostContent(
                              post: browse,
                              showFullTime: false,
                              showReplyCount: false,
                              contentMaxLines: 8,
                              poUserHash: browse.userHash,
                              onHiddenText: (context, element, textStyle) =>
                                  onHiddenText(
                                context: context,
                                element: element,
                                textStyle: textStyle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            );
          },
          noItemsFoundBuilder: (context) => const Center(
            child: Text('没有浏览记录', style: AppTheme.boldRed),
          ),
        ),
      ),
    );
  }
}

class _PostHistoryBody extends StatelessWidget {
  static const _index = 1;

  final HistoryController controller;

  const _PostHistoryBody(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final history = PostHistoryService.to;

    return PostListRefresher(
      controller: controller,
      builder: (context, refresh) => ValueListenableBuilder<bool>(
        valueListenable: controller._getNotifier(_PostHistoryBody._index),
        builder: (context, value, child) => BiListView<PostData>(
          key: ValueKey<_HistoryKey>(_HistoryKey(
              controller._getDateRange(_PostHistoryBody._index),
              refresh,
              value)),
          initialPage: controller.page,
          canRefreshAtBottom: false,
          fetch: (page) => history.postDataList(
              (page - 1) * _historyEachPage,
              page * _historyEachPage,
              controller._getDateRange(_PostHistoryBody._index)),
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
                        showFullTime: false,
                        showPostId: mainPost.postId != null ? true : false,
                        showReplyCount: false,
                        contentMaxLines: 8,
                        poUserHash: mainPost.userHash,
                        onTap: (post) {
                          if (post.id > 0) {
                            AppRoutes.toThread(
                                mainPostId: post.id, mainPost: post);
                          }
                        },
                        onLongPress: (post) => postListDialog(_HistoryDialog(
                            mainPost: post,
                            onDelete: () async {
                              await history.deletePostData(mainPost.id);
                              mainPost.postId != null
                                  ? showToast(
                                      '删除主题 ${mainPost.postId!.toPostNumber()} 的记录')
                                  : showToast('删除主题记录');
                              isVisible.value = false;
                            })),
                        onHiddenText: (context, element, textStyle) =>
                            onHiddenText(
                                context: context,
                                element: element,
                                textStyle: textStyle),
                      ),
                    )
                  : const SizedBox.shrink(),
            );
          },
          noItemsFoundBuilder: (context) => const Center(
            child: Text('没有主题记录', style: AppTheme.boldRed),
          ),
        ),
      ),
    );
  }
}

class _ReplyHistoryBody extends StatelessWidget {
  static const _index = 2;

  final HistoryController controller;

  const _ReplyHistoryBody(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final history = PostHistoryService.to;

    return PostListRefresher(
      controller: controller,
      builder: (context, refresh) => ValueListenableBuilder<bool>(
        valueListenable: controller._getNotifier(_ReplyHistoryBody._index),
        builder: (context, value, child) => BiListView<ReplyData>(
          key: ValueKey<_HistoryKey>(_HistoryKey(
              controller._getDateRange(_ReplyHistoryBody._index),
              refresh,
              value)),
          initialPage: controller.page,
          canRefreshAtBottom: false,
          fetch: (page) => history.replyDataList(
              (page - 1) * _historyEachPage,
              page * _historyEachPage,
              controller._getDateRange(_ReplyHistoryBody._index)),
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
                              jumpToId:
                                  (reply.page != null && reply.postId != null)
                                      ? reply.postId
                                      : null),
                          onLongPress: () => postListDialog(_HistoryDialog(
                              mainPost: reply.toMainPost(),
                              post: post,
                              onDelete: () async {
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
                                          '主串：${reply.mainPostId.toPostNumber()}',
                                        ),
                                      ),
                                      if (reply.page != null)
                                        Flexible(
                                          child: Text('第 ${reply.page} 页'),
                                        ),
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
                                  textStyle: textStyle,
                                ),
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
            child: Text('没有回复记录', style: AppTheme.boldRed),
          ),
        ),
      ),
    );
  }
}

class HistoryBody extends StatefulWidget {
  final HistoryController controller;

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

    _controller = PageController(initialPage: widget.controller.bottomBarIndex);
    _subscription = widget.controller._bottomBarIndex.listen((index) {
      if (index >= 0 && index <= 2) {
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
  Widget build(BuildContext context) => Column(
        children: [
          Obx(
            () {
              final range = widget.controller._getDateRange();

              return range != null
                  ? ListTile(
                      title: Center(
                        child: range.start != range.end
                            ? Text(
                                '${formatDay(range.start)} - ${formatDay(range.end)}',
                              )
                            : Text(formatDay(range.start)),
                      ),
                      trailing: IconButton(
                        onPressed: () {
                          widget.controller._setDateRange(null);
                          //widget.controller.refreshPage();
                        },
                        icon: const Icon(Icons.close),
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (context, index) {
                switch (index) {
                  case _BrowseHistoryBody._index:
                    return _BrowseHistoryBody(widget.controller);
                  case _PostHistoryBody._index:
                    return _PostHistoryBody(widget.controller);
                  case _ReplyHistoryBody._index:
                    return _ReplyHistoryBody(widget.controller);
                  default:
                    return const Center(
                      child: Text('未知记录', style: AppTheme.boldRed),
                    );
                }
              },
            ),
          )
        ],
      );
}

class HistoryBottomBar extends StatelessWidget {
  final HistoryController controller;

  const HistoryBottomBar(this.controller, {super.key});

  @override
  Widget build(BuildContext context) => Obx(
        () => BottomNavigationBar(
          currentIndex: controller.bottomBarIndex,
          onTap: (value) {
            if (controller.bottomBarIndex != value) {
              popAllPopup();
              controller.bottomBarIndex = value;
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
