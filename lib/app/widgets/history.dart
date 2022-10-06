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
import '../utils/key.dart';
import '../utils/navigation.dart';
import '../utils/time.dart';
import '../utils/toast.dart';
import 'bilistview.dart';
import 'dialog.dart';
import 'post.dart';

const int _historyEachPage = 20;

class HistoryBottomBarKey {
  final int index;

  final DateTimeRange? range;

  const HistoryBottomBarKey(this.index, this.range);

  HistoryBottomBarKey.fromController(PostListController controller)
      : assert(controller.bottomBarIndex.value != null &&
            controller.bottomBarIndex.value! < 3),
        index = controller.bottomBarIndex.value!,
        range = controller.getDateRange();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HistoryBottomBarKey &&
          index == other.index &&
          range == other.range);

  @override
  int get hashCode => Object.hash(index, range);
}

PostListController historyController(Map<String, String?> parameters) =>
    PostListController(
        postListType: PostListType.history,
        page: parameters['page'].tryParseInt() ?? 1,
        bottomBarIndex: parameters['index'].tryParseInt() ?? 0,
        dateRange: List.filled(3, null));

class HistoryAppBarTitle extends StatelessWidget {
  final PostListController controller;

  const HistoryAppBarTitle(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final history = PostHistoryService.to;

    return FutureBuilder<int?>(future: Future(() {
      switch (controller.bottomBarIndex.value) {
        case _BrowseHistoryBody._index:
          return history.browseHistoryCount(controller.getDateRange());
        case _PostHistoryBody._index:
          return history.postDataCount(controller.getDateRange());
        case _ReplyHistoryBody._index:
          return history.replyDataCount(controller.getDateRange());
        default:
          debugPrint('未知bottomBarIndex：${controller.bottomBarIndex.value}');
          return null;
      }
    }), builder: (context, snapshot) {
      late final String text;
      switch (controller.bottomBarIndex.value) {
        case _BrowseHistoryBody._index:
          text = '浏览历史记录';
          break;
        case _PostHistoryBody._index:
          text = '主题历史记录';
          break;
        case _ReplyHistoryBody._index:
          text = '回复历史记录';
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

  final PostListController controller;

  const HistoryDateRangePicker(this.controller, {super.key});

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: () async {
          final range = await showDateRangePicker(
              context: context,
              initialDateRange: controller.getDateRange(),
              firstDate: _firstDate,
              lastDate: DateTime.now(),
              initialEntryMode: DatePickerEntryMode.calendarOnly,
              locale: WidgetsBinding.instance.platformDispatcher.locale);

          if (range != null) {
            controller.setDateRange(range);
            controller.refreshPage();
          }
        },
        icon: const Icon(Icons.calendar_month),
      );
}

class HistoryAppBarPopupMenuButton extends StatelessWidget {
  final PostListController controller;

  const HistoryAppBarPopupMenuButton(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final history = PostHistoryService.to;

    return PopupMenuButton(
      itemBuilder: (context) => [
        PopupMenuItem(
          onTap: () {
            switch (controller.bottomBarIndex.value) {
              case _BrowseHistoryBody._index:
                postListDialog(ConfirmCancelDialog(
                  content: '确定清空浏览记录？',
                  onConfirm: () async {
                    await history.clearBrowseHistory(controller.getDateRange());
                    controller.refreshPage();
                    showToast('清空浏览记录');
                    postListBack();
                  },
                  onCancel: () => postListBack(),
                ));
                break;
              case _PostHistoryBody._index:
                postListDialog(ConfirmCancelDialog(
                  content: '确定清空主题记录？',
                  onConfirm: () async {
                    await history.clearPostData(controller.getDateRange());
                    controller.refreshPage();
                    showToast('清空主题记录');
                    postListBack();
                  },
                  onCancel: () => postListBack(),
                ));
                break;
              case _ReplyHistoryBody._index:
                postListDialog(ConfirmCancelDialog(
                  content: '确定清空回复记录？',
                  onConfirm: () async {
                    await history.clearReplyData(controller.getDateRange());
                    controller.refreshPage();
                    showToast('清空回复记录');
                    postListBack();
                  },
                  onCancel: () => postListBack(),
                ));
                break;
              default:
                debugPrint(
                    '未知bottomBarIndex：${controller.bottomBarIndex.value}');
            }
          },
          child: const Text('清空'),
        ),
      ],
    );
  }
}

class HistoryBottomBar extends StatelessWidget {
  final PostListController controller;

  const HistoryBottomBar(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final index = controller.bottomBarIndex;

    return Obx(
      () => BottomNavigationBar(
        currentIndex: index.value ?? 0,
        onTap: (value) {
          if (index.value != value) {
            popAllPopup();
            index.value = value;
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
}

class HistoryBody extends StatefulWidget {
  final PostListController controller;

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

    _controller = PageController(
        initialPage: widget.controller.bottomBarIndex.value ?? 0);
    _subscription = widget.controller.bottomBarIndex.listen((index) {
      if (index != null) {
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
              final range = widget.controller.getDateRange();

              return range != null
                  ? ListTile(
                      title: Center(
                        child: range.start != range.end
                            ? Text(
                                '${dateRangeFormatTime(range.start)} - ${dateRangeFormatTime(range.end)}',
                              )
                            : Text(dateRangeFormatTime(range.start)),
                      ),
                      trailing: IconButton(
                        onPressed: () {
                          widget.controller.setDateRange(null);
                          widget.controller.refreshPage();
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
                      child: Text(
                        '未知记录',
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    );
                }
              },
            ),
          )
        ],
      );
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
                onConfirm: () {
                  onDelete();
                  postListBack<bool>(result: true);
                },
                onCancel: () => postListBack<bool>(result: false),
              ));

              if (result ?? false) {
                postListBack();
              }
            } else {
              onDelete();
              postListBack();
            }
          },
          child: Text('删除', style: Theme.of(context).textTheme.subtitle1),
        ),
        if (hasPostId) CopyPostId(postHistory),
        if (hasPostId) CopyPostReference(postHistory),
        CopyPostContent(postHistory),
        if (post != null) CopyPostId(mainPost, text: '复制主串串号'),
        if (post != null) CopyPostReference(mainPost, text: '复制主串串号引用'),
        if (mainPost.id > 0)
          NewTab(mainPost, text: post != null ? '在新标签页打开主串' : null),
        if (mainPost.id > 0)
          NewTabBackground(mainPost, text: post != null ? '在新标签页后台打开主串' : null),
      ],
    );
  }
}

class _BrowseHistoryBody extends StatefulWidget {
  static const _index = 0;

  final PostListController controller;

  const _BrowseHistoryBody(this.controller, {super.key});

  @override
  State<_BrowseHistoryBody> createState() => _BrowseHistoryBodyState();
}

class _BrowseHistoryBodyState extends State<_BrowseHistoryBody> {
  late final StreamSubscription<int> _pageSubscription;

  int _refresh = 0;

  @override
  void initState() {
    super.initState();

    _pageSubscription = widget.controller.page.listen((page) {
      if (widget.controller.bottomBarIndex.value == _BrowseHistoryBody._index) {
        _refresh++;
      }
    });
  }

  @override
  void dispose() {
    _pageSubscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history = PostHistoryService.to;

    return Obx(
      () => BiListView<BrowseHistory>(
        key: getPostListKey(
            PostList.fromController(widget.controller), _refresh),
        initialPage: widget.controller.page.value,
        fetch: (page) => history.browseHistoryList(
            (page - 1) * _historyEachPage,
            page * _historyEachPage,
            widget.controller.getDateRange()),
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
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      '最后浏览时间：${postFormatTime(browse.browseTime)}',
                                    ),
                                  ),
                                  if (browsePage != null &&
                                      browsePostId != null)
                                    Flexible(
                                      child: Text(
                                        '浏览到：第$browsePage页 ${browsePostId.toPostNumber()}',
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          PostContent(
                            post: browse,
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
          child: Text(
            '没有浏览记录',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
        canRefreshAtBottom: false,
      ),
    );
  }
}

class _PostHistoryBody extends StatefulWidget {
  static const _index = 1;

  final PostListController controller;

  const _PostHistoryBody(this.controller, {super.key});

  @override
  State<_PostHistoryBody> createState() => _PostHistoryBodyState();
}

class _PostHistoryBodyState extends State<_PostHistoryBody> {
  late final StreamSubscription<int> _pageSubscription;

  int _refresh = 0;

  @override
  void initState() {
    super.initState();

    _pageSubscription = widget.controller.page.listen((page) {
      if (widget.controller.bottomBarIndex.value == _PostHistoryBody._index) {
        _refresh++;
      }
    });
  }

  @override
  void dispose() {
    _pageSubscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history = PostHistoryService.to;

    return Obx(
      () => BiListView<PostData>(
        key: getPostListKey(
            PostList.fromController(widget.controller), _refresh),
        initialPage: widget.controller.page.value,
        fetch: (page) => history.postDataList((page - 1) * _historyEachPage,
            page * _historyEachPage, widget.controller.getDateRange()),
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
          child: Text(
            '没有主题记录',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
        canRefreshAtBottom: false,
      ),
    );
  }
}

class _ReplyHistoryBody extends StatefulWidget {
  static const _index = 2;

  final PostListController controller;

  const _ReplyHistoryBody(this.controller, {super.key});

  @override
  State<_ReplyHistoryBody> createState() => _ReplyHistoryBodyState();
}

class _ReplyHistoryBodyState extends State<_ReplyHistoryBody> {
  late final StreamSubscription<int> _pageSubscription;

  int _refresh = 0;

  @override
  void initState() {
    super.initState();

    _pageSubscription = widget.controller.page.listen((page) {
      if (widget.controller.bottomBarIndex.value == _ReplyHistoryBody._index) {
        _refresh++;
      }
    });
  }

  @override
  void dispose() {
    _pageSubscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history = PostHistoryService.to;

    return Obx(
      () => BiListView<ReplyData>(
        key: getPostListKey(
            PostList.fromController(widget.controller), _refresh),
        initialPage: widget.controller.page.value,
        fetch: (page) => history.replyDataList((page - 1) * _historyEachPage,
            page * _historyEachPage, widget.controller.getDateRange()),
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
                                            '主串：${reply.mainPostId.toPostNumber()}')),
                                    if (reply.page != null)
                                      Flexible(
                                          child: Text('第 ${reply.page} 页')),
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
          child: Text(
            '没有回复记录',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
        canRefreshAtBottom: false,
      ),
    );
  }
}
