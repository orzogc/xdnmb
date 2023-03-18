import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/models/controller.dart';
import '../data/models/history.dart';
import '../data/models/post.dart';
import '../data/models/reply.dart';
import '../data/services/settings.dart';
import '../data/services/time.dart';
import '../modules/post_list.dart';
import '../routes/routes.dart';
import '../utils/extensions.dart';
import '../utils/history.dart';
import '../utils/image.dart';
import '../utils/navigation.dart';
import '../utils/post.dart';
import '../utils/regex.dart';
import '../utils/theme.dart';
import '../utils/time.dart';
import '../utils/toast.dart';
import 'bilistview.dart';
import 'dialog.dart';
import 'listenable.dart';
import 'list_tile.dart';
import 'page_view.dart';
import 'post.dart';
import 'post_list.dart';
import 'time.dart';

const int _historyPageCount = 3;

const int _historyEachPage = 20;

extension _IndexExtension on int? {
  bool get isValid => this == null || (this! >= 0 && this! < _historyPageCount);
}

class _HistoryKey {
  final DateTimeRange? range;

  final Search? search;

  final int refresh;

  final bool value;

  const _HistoryKey(this.range, this.search, this.refresh, this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _HistoryKey &&
          range == other.range &&
          search == other.search &&
          refresh == other.refresh &&
          value == other.value);

  @override
  int get hashCode => Object.hash(range, search, refresh, value);
}

class HistoryController extends PostListController {
  static int __index = 0;

  static int get _index => __index.clamp(0, _historyPageCount - 1);

  static set _index(int index) =>
      __index = index.clamp(0, _historyPageCount - 1);

  final RxInt _pageIndex;

  final Rx<List<DateTimeRange?>> _dateRange;

  final Rx<List<Search?>> _search;

  final RxList<int?> _counts = RxList(List.filled(_historyPageCount, null));

  final List<ListenableNotifier> _notifiers = [
    ListenableNotifier(),
    ListenableNotifier(),
    ListenableNotifier(),
  ];

  final RxDouble _headerHeight = 0.0.obs;

  @override
  PostListType get postListType => PostListType.history;

  @override
  int? get id => null;

  int get pageIndex => _pageIndex.value.clamp(0, _historyPageCount - 1);

  set pageIndex(int index) =>
      _pageIndex.value = index.clamp(0, _historyPageCount - 1);

  List<DateTimeRange?> get dateRange => _dateRange.value;

  set dateRange(List<DateTimeRange?> range) => _dateRange.value = range;

  List<Search?> get search => _search.value;

  set search(List<Search?> search) => _search.value = search;

  HistoryController(
      {required int page,
      int? pageIndex,
      List<DateTimeRange?>? dateRange,
      List<Search?>? search})
      : assert(pageIndex.isValid),
        _pageIndex = (pageIndex ?? _index).clamp(0, _historyPageCount - 1).obs,
        _dateRange = Rx(dateRange ?? List.filled(_historyPageCount, null)),
        _search = Rx(search ?? List.filled(_historyPageCount, null)),
        super(page);

  ListenableNotifier _getNotifier([int? index]) {
    assert(index.isValid);

    return _notifiers[index ?? pageIndex];
  }

  void _notify([int? index]) {
    _getNotifier(index).notify();
    _pageIndex.refresh();
  }

  void _trigger([int? index]) {
    _getNotifier(index).trigger();
    _pageIndex.refresh();
  }

  DateTimeRange? _getDateRange([int? index]) {
    assert(index.isValid);

    return dateRange[index ?? pageIndex];
  }

  void _setDateRange(DateTimeRange? range, [int? index]) {
    assert(index.isValid);

    dateRange[index ?? pageIndex] = range;
    _notify(index);
  }

  Search? _getSearch([int? index]) {
    assert(index.isValid);

    return search[index ?? pageIndex];
  }

  void _setSearch(Search? search, [int? index]) {
    assert(index.isValid);

    this.search[index ?? pageIndex] = search;
    _notify(index);
  }

  int? _getCount([int? index]) {
    assert(index.isValid);

    return _counts[index ?? pageIndex].notNegative;
  }

  void _setCount(int? count, [int? index]) {
    assert(index.isValid);

    _counts[index ?? pageIndex] = count.notNegative;
  }

  void _decreaseCount([int? index]) {
    assert(index.isValid);

    final count = _getCount(index);
    _setCount(count != null ? count - 1 : null);
  }

  String text([String unknown = '未知', int? index]) {
    index ??= pageIndex;

    switch (index) {
      case _BrowseHistoryBody._index:
        return '浏览';
      case _PostHistoryBody._index:
        return '主题';
      case _ReplyHistoryBody._index:
        return '回复';
      default:
        debugPrint('未知index：$index');
        return unknown;
    }
  }

  /// 设置没有搜索时的数据数量
  Future<void> _setDataCount([int? index]) async {
    index ??= pageIndex;
    final range = _getDateRange(index);

    if (_getSearch(index) == null) {
      switch (index) {
        case _BrowseHistoryBody._index:
          _setCount(await BrowseDataHistory.browseDataCount(range), index);
          break;
        case _PostHistoryBody._index:
          _setCount(await PostHistory.postDataCount(range), index);
          break;
        case _ReplyHistoryBody._index:
          _setCount(await ReplyHistory.replyDataCount(range), index);
          break;
        default:
          debugPrint('未知index：$index');
      }
    }
  }

  Future<void> _clear([int? index]) async {
    index ??= pageIndex;
    final range = _getDateRange(index);
    final search = _getSearch(index);

    switch (index) {
      case _BrowseHistoryBody._index:
        await BrowseDataHistory.clearBrowseData(range: range, search: search);
        break;
      case _PostHistoryBody._index:
        await PostHistory.clearPostData(range: range, search: search);
        break;
      case _ReplyHistoryBody._index:
        await ReplyHistory.clearReplyData(range: range, search: search);
        break;
      default:
        debugPrint('未知index：$index');
    }

    _setCount(0, index);
    _trigger(index);
  }

  @override
  void dispose() {
    //_pageIndex.close();
    //_dateRange.close();
    for (final notifier in _notifiers) {
      notifier.dispose();
    }

    super.dispose();
  }
}

HistoryController historyController(Map<String, String?> parameters) =>
    HistoryController(
        page: parameters['page'].tryParseInt() ?? 1,
        pageIndex: parameters['index'].tryParseInt());

class HistoryAppBarTitle extends StatelessWidget {
  final HistoryController controller;

  const HistoryAppBarTitle(this.controller, {super.key});

  @override
  Widget build(BuildContext context) => Obx(() {
        final text = controller.text('历史记录');
        final count = controller._getCount();

        return count != null ? Text('$text・$count') : Text(text);
      });
}

class HistoryAppBarPopupMenuButton extends StatelessWidget {
  static final DateTime _firstDate = DateTime(2022, 6, 19);

  final HistoryController controller;

  const HistoryAppBarPopupMenuButton(this.controller, {super.key});

  @override
  Widget build(BuildContext context) => PopupMenuButton(
        itemBuilder: (context) => [
          PopupMenuItem(
            onTap: () => WidgetsBinding.instance.addPostFrameCallback(
              (timeStamp) async {
                final range = await showDateRangePicker(
                    context: context,
                    initialDateRange: controller._getDateRange(),
                    firstDate: _firstDate,
                    lastDate: DateTime.now(),
                    initialEntryMode: DatePickerEntryMode.calendarOnly,
                    locale: WidgetsBinding.instance.platformDispatcher.locale);

                if (range != null) {
                  controller._setDateRange(range);
                }
              },
            ),
            child: const Text('日期'),
          ),
          PopupMenuItem(
            onTap: () => postListDialog(SearchDialog(
              search: controller._getSearch(),
              onSearch: (search) => controller._setSearch(search),
            )),
            child: const Text('搜索'),
          ),
          if ((controller._getCount() ?? 0) > 0)
            PopupMenuItem(
              onTap: () => postListDialog(ClearDialog(
                text: '${controller.text()}记录',
                onClear: controller._clear,
              )),
              child: const Text('清空'),
            ),
        ],
      );
}

class _HeaderKey {
  final DateTimeRange? range;

  final Search? search;

  const _HeaderKey({this.range, this.search});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _HeaderKey && range == other.range && search == other.search);

  @override
  int get hashCode => Object.hash(range, search);
}

class _HistoryHeader extends StatelessWidget {
  final HistoryController controller;

  // ignore: unused_element
  const _HistoryHeader(this.controller, {super.key});

  @override
  Widget build(BuildContext context) => Obx(() {
        final range = controller._getDateRange();
        final search = controller._getSearch();

        return PostListHeader(
          key: ValueKey<_HeaderKey>(_HeaderKey(range: range, search: search)),
          onSize: (value) => controller._headerHeight.value = value.height,
          child: (range != null || search != null)
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (range != null)
                      TightListTile(
                        title: Center(
                          child: range.start != range.end
                              ? Text(
                                  '${formatDay(range.start)} - ${formatDay(range.end)}',
                                )
                              : Text(formatDay(range.start)),
                        ),
                        trailing: IconButton(
                          onPressed: () => controller._setDateRange(null),
                          icon: const Icon(Icons.close),
                        ),
                      ),
                    if (range != null && search != null)
                      const Divider(height: 1.0, thickness: 1.0),
                    if (search != null)
                      SearchListTile(
                        search: search,
                        onCancel: () => controller._setSearch(null),
                      ),
                  ],
                )
              : const SizedBox.shrink(),
        );
      });
}

class _BrowseHistoryItem extends StatefulWidget {
  final Visible<BrowseHistory> browse;

  final Search? search;

  final VoidCallback decreaseCount;

  const _BrowseHistoryItem(
      // ignore: unused_element
      {super.key,
      required this.browse,
      this.search,
      required this.decreaseCount});

  @override
  State<_BrowseHistoryItem> createState() => _BrowseHistoryItemState();
}

class _BrowseHistoryItemState extends State<_BrowseHistoryItem> {
  Future<void>? _getBrowseHistoryImage;

  BrowseHistory get _history => widget.browse.item;

  void _setGetBrowseHistoryImage() => _getBrowseHistoryImage = _history.hasImage
      ? Future(() async {
          final image =
              await ReferenceImageCache.getImage(_history.id, _history.id);
          if (image != null) {
            _history.image = image.image;
            _history.imageExtension = image.imageExtension;
          }
        })
      : null;

  @override
  void initState() {
    super.initState();

    _setGetBrowseHistoryImage();

    final time = TimeService.to;
    if (SettingsService.to.showRelativeTime &&
        _history.browseTime.isAfter(time.now)) {
      time.updateTime();
    }
  }

  @override
  void didUpdateWidget(covariant _BrowseHistoryItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.browse != oldWidget.browse) {
      _setGetBrowseHistoryImage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;
    final time = TimeService.to;

    return FutureBuilder<void>(
      future: _getBrowseHistoryImage,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasError) {
          debugPrint('获取串 ${_history.toPostNumber()} 的引用出错：${snapshot.error}');
        }

        final browsePage = _history.browsePage ?? _history.onlyPoBrowsePage;
        final browsePostId =
            _history.browsePostId ?? _history.onlyPoBrowsePostId;

        return Obx(
          () => widget.browse.isVisible
              ? PostCard(
                  key: ValueKey<int>(_history.id),
                  child: PostInkWell(
                    post: _history,
                    poUserHash: _history.userHash,
                    contentMaxLines: 8,
                    onText: !(widget.search?.useWildcard ?? true)
                        ? (context, text) => Regex.onSearchText(
                            text: text, search: widget.search!)
                        : null,
                    showFullTime: false,
                    showReplyCount: false,
                    header: (textStyle) => PostHeader(children: [
                      if (settings.showRelativeTime)
                        TimerRefresher(
                          builder: (context) => Text(
                            '最后浏览时间：${time.relativeTime(_history.browseTime)}',
                            style: AppTheme.postHeaderTextStyle,
                            strutStyle: AppTheme.postHeaderStrutStyle,
                          ),
                        )
                      else
                        Text(
                          '最后浏览时间：${fullFormatTime(_history.browseTime)}',
                          style: AppTheme.postHeaderTextStyle,
                          strutStyle: AppTheme.postHeaderStrutStyle,
                        ),
                      if (browsePage != null && browsePostId != null)
                        Text(
                          '浏览到：第$browsePage页 ${browsePostId.toPostNumber()}',
                          style: AppTheme.postHeaderTextStyle,
                          strutStyle: AppTheme.postHeaderStrutStyle,
                        ),
                    ]),
                    onTap: (post) =>
                        AppRoutes.toThread(mainPostId: post.id, mainPost: post),
                    onLongPress: (post) => postListDialog(SavedPostDialog(
                      post: post,
                      mainPostId: post.id,
                      confirmDelete: false,
                      onDelete: () async {
                        await BrowseDataHistory.deleteBrowseData(post.id);
                        widget.decreaseCount();
                        showToast('删除 ${post.toPostNumber()} 的浏览记录');
                        widget.browse.isVisible = false;
                      },
                    )),
                  ),
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }
}

class _BrowseHistoryBody extends StatelessWidget {
  static const _index = 0;

  final HistoryController controller;

  // ignore: unused_element
  const _BrowseHistoryBody(this.controller, {super.key});

  @override
  Widget build(BuildContext context) => PostListScrollView(
        controller: controller,
        builder: (context, scrollController, refresh) =>
            ValueListenableBuilder<bool>(
          valueListenable: controller._getNotifier(_index),
          builder: (context, value, child) {
            final range = controller._getDateRange(_index);
            final search = controller._getSearch(_index);

            return BiListView<Visible<BrowseHistory>>(
              key: ValueKey<_HistoryKey>(
                  _HistoryKey(range, search, refresh, value)),
              scrollController: scrollController,
              postListController: controller,
              initialPage: controller.page,
              canLoadMoreAtBottom: false,
              fetch: (page) async {
                if (page == 1) {
                  WidgetsBinding.instance.addPostFrameCallback(
                      (timeStamp) => controller._setCount(null, _index));
                }

                final data = (search == null || page == 1)
                    ? (await BrowseDataHistory.browseDataList(
                            start: search == null
                                ? (page - 1) * _historyEachPage
                                : null,
                            end:
                                search == null ? page * _historyEachPage : null,
                            range: range,
                            search: search))
                        .map((history) => Visible(history))
                        .toList()
                    : <Visible<BrowseHistory>>[];

                if (page == 1) {
                  if (search != null) {
                    controller._setCount(data.length, _index);
                  } else {
                    await controller._setDataCount(_index);
                  }
                }

                return data;
              },
              itemBuilder: (context, browse, index) => _BrowseHistoryItem(
                browse: browse,
                search: search,
                decreaseCount: () => controller._decreaseCount(_index),
              ),
              noItemsFoundBuilder: (context) => Center(
                child: Text(
                  '没有浏览记录',
                  style: AppTheme.boldRedPostContentTextStyle,
                  strutStyle: AppTheme.boldRedPostContentStrutStyle,
                ),
              ),
            );
          },
        ),
      );
}

class _PostHistoryItem extends StatefulWidget {
  final Visible<PostData> mainPost;

  final Search? search;

  final VoidCallback decreaseCount;

  const _PostHistoryItem(
      // ignore: unused_element
      {super.key,
      required this.mainPost,
      this.search,
      required this.decreaseCount});

  @override
  State<_PostHistoryItem> createState() => _PostHistoryItemState();
}

class _PostHistoryItemState extends State<_PostHistoryItem> {
  Future<void>? _getPostHistoryImage;

  PostData get _post => widget.mainPost.item;

  void _setGetPostHistoryImage() =>
      _getPostHistoryImage = (_post.hasPostId && _post.hasImage)
          ? Future(() async {
              final image = await ReferenceImageCache.getImage(
                  _post.postId!, _post.postId!);
              if (image != null) {
                _post.image = image.image;
                _post.imageExtension = image.imageExtension;
              }
            })
          : null;

  @override
  void initState() {
    super.initState();

    _setGetPostHistoryImage();
  }

  @override
  void didUpdateWidget(covariant _PostHistoryItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.mainPost != oldWidget.mainPost) {
      _setGetPostHistoryImage();
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
        future: _getPostHistoryImage,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasError) {
            debugPrint(
                '获取串 ${_post.postId?.toPostNumber()} 的引用出错：${snapshot.error}');
          }

          return Obx(
            () => widget.mainPost.isVisible
                ? PostCard(
                    key: ValueKey<int>(_post.id),
                    child: PostInkWell(
                      post: _post.toPost(),
                      poUserHash: _post.userHash,
                      contentMaxLines: 8,
                      onText: !(widget.search?.useWildcard ?? true)
                          ? (context, text) => Regex.onSearchText(
                              text: text, search: widget.search!)
                          : null,
                      showPostId: _post.hasPostId,
                      showReplyCount: false,
                      onTap: _post.hasPostId
                          ? (post) {
                              if (post.isNormalPost) {
                                AppRoutes.toThread(
                                    mainPostId: post.id, mainPost: post);
                              }
                            }
                          : null,
                      onLongPress: (post) => postListDialog(SavedPostDialog(
                        post: post,
                        mainPostId: post.postId,
                        onDelete: () async {
                          await PostHistory.deletePostData(_post.id);
                          widget.decreaseCount();
                          showToast(_post.hasPostId
                              ? '删除主题 ${_post.postId?.toPostNumber()} 的记录'
                              : '删除主题记录');
                          widget.mainPost.isVisible = false;
                        },
                      )),
                    ),
                  )
                : const SizedBox.shrink(),
          );
        },
      );
}

class _PostHistoryBody extends StatelessWidget {
  static const _index = 1;

  final HistoryController controller;

  // ignore: unused_element
  const _PostHistoryBody(this.controller, {super.key});

  @override
  Widget build(BuildContext context) => PostListScrollView(
        controller: controller,
        builder: (context, scrollController, refresh) =>
            ValueListenableBuilder<bool>(
          valueListenable: controller._getNotifier(_index),
          builder: (context, value, child) {
            final range = controller._getDateRange(_index);
            final search = controller._getSearch(_index);

            return BiListView<Visible<PostData>>(
              key: ValueKey<_HistoryKey>(
                  _HistoryKey(range, search, refresh, value)),
              scrollController: scrollController,
              postListController: controller,
              initialPage: controller.page,
              canLoadMoreAtBottom: false,
              fetch: (page) async {
                if (page == 1) {
                  WidgetsBinding.instance.addPostFrameCallback(
                      (timeStamp) => controller._setCount(null, _index));
                }

                final data = (search == null || page == 1)
                    ? (await PostHistory.postDataList(
                            start: search == null
                                ? (page - 1) * _historyEachPage
                                : null,
                            end:
                                search == null ? page * _historyEachPage : null,
                            range: range,
                            search: search))
                        .map((mainPost) => Visible(mainPost))
                        .toList()
                    : <Visible<PostData>>[];

                if (page == 1) {
                  if (search != null) {
                    controller._setCount(data.length, _index);
                  } else {
                    await controller._setDataCount(_index);
                  }
                }

                return data;
              },
              itemBuilder: (context, mainPost, index) => _PostHistoryItem(
                mainPost: mainPost,
                search: search,
                decreaseCount: () => controller._decreaseCount(_index),
              ),
              noItemsFoundBuilder: (context) => Center(
                child: Text(
                  '没有主题记录',
                  style: AppTheme.boldRedPostContentTextStyle,
                  strutStyle: AppTheme.boldRedPostContentStrutStyle,
                ),
              ),
            );
          },
        ),
      );
}

class _ReplyHistoryItem extends StatefulWidget {
  final Visible<ReplyData> reply;

  final Search? search;

  final VoidCallback decreaseCount;

  const _ReplyHistoryItem(
      // ignore: unused_element
      {super.key,
      required this.reply,
      this.search,
      required this.decreaseCount});

  @override
  State<_ReplyHistoryItem> createState() => _ReplyHistoryItemState();
}

class _ReplyHistoryItemState extends State<_ReplyHistoryItem> {
  Future<void>? _getReplyHistoryImage;

  ReplyData get _reply => widget.reply.item;

  void setGetReplyHistoryImage() =>
      _getReplyHistoryImage = (_reply.hasPostId && _reply.hasImage)
          ? Future(() async {
              final image = await ReferenceImageCache.getImage(
                  _reply.postId!, _reply.mainPostId);
              if (image != null) {
                _reply.image = image.image;
                _reply.imageExtension = image.imageExtension;
              }
            })
          : null;

  @override
  void initState() {
    super.initState();

    setGetReplyHistoryImage();
  }

  @override
  void didUpdateWidget(covariant _ReplyHistoryItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.reply != oldWidget.reply) {
      setGetReplyHistoryImage();
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
        future: _getReplyHistoryImage,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasError) {
            debugPrint(
                '获取串 ${_reply.postId?.toPostNumber()} 的引用出错：${snapshot.error}');
          }

          return Obx(
            () => widget.reply.isVisible
                ? PostCard(
                    key: ValueKey<int>(_reply.id),
                    child: PostInkWell(
                      post: _reply.toPost(),
                      contentMaxLines: 8,
                      onText: !(widget.search?.useWildcard ?? true)
                          ? (context, text) => Regex.onSearchText(
                              text: text, search: widget.search!)
                          : null,
                      showPostId: _reply.hasPostId,
                      showReplyCount: false,
                      header: (textStyle) => PostHeader(children: [
                        Text(
                          '主串：${_reply.mainPostId.toPostNumber()}',
                          style: AppTheme.postHeaderTextStyle,
                          strutStyle: AppTheme.postHeaderStrutStyle,
                        ),
                        if (_reply.page != null)
                          Text(
                            '第 ${_reply.page} 页',
                            style: AppTheme.postHeaderTextStyle,
                            strutStyle: AppTheme.postHeaderStrutStyle,
                          ),
                      ]),
                      onTap: (post) => AppRoutes.toThread(
                          mainPostId: _reply.mainPostId,
                          page: _reply.page ?? 1,
                          jumpToId: _reply.isComplete ? _reply.postId : null),
                      onLongPress: (post) => postListDialog(SavedPostDialog(
                        post: post,
                        mainPostId: _reply.mainPostId,
                        page: _reply.page,
                        onDelete: () async {
                          await PostHistory.deletePostData(_reply.id);
                          widget.decreaseCount();
                          showToast(_reply.hasPostId
                              ? '删除回复 ${_reply.postId?.toPostNumber()} 的记录'
                              : '删除回复记录');
                          widget.reply.isVisible = false;
                        },
                      )),
                    ),
                  )
                : const SizedBox.shrink(),
          );
        },
      );
}

class _ReplyHistoryBody extends StatelessWidget {
  static const _index = 2;

  final HistoryController controller;

  // ignore: unused_element
  const _ReplyHistoryBody(this.controller, {super.key});

  @override
  Widget build(BuildContext context) => PostListScrollView(
        controller: controller,
        builder: (context, scrollController, refresh) =>
            ValueListenableBuilder<bool>(
          valueListenable: controller._getNotifier(_index),
          builder: (context, value, child) {
            final range = controller._getDateRange(_index);
            final search = controller._getSearch(_index);

            return BiListView<Visible<ReplyData>>(
              key: ValueKey<_HistoryKey>(
                  _HistoryKey(range, search, refresh, value)),
              scrollController: scrollController,
              postListController: controller,
              initialPage: controller.page,
              canLoadMoreAtBottom: false,
              fetch: (page) async {
                if (page == 1) {
                  WidgetsBinding.instance.addPostFrameCallback(
                      (timeStamp) => controller._setCount(null, _index));
                }

                final data = (search == null || page == 1)
                    ? (await ReplyHistory.replyDataList(
                            start: search == null
                                ? (page - 1) * _historyEachPage
                                : null,
                            end:
                                search == null ? page * _historyEachPage : null,
                            range: range,
                            search: search))
                        .map((reply) => Visible(reply))
                        .toList()
                    : <Visible<ReplyData>>[];

                if (page == 1) {
                  if (search != null) {
                    controller._setCount(data.length, _index);
                  } else {
                    await controller._setDataCount(_index);
                  }
                }

                return data;
              },
              itemBuilder: (context, reply, index) => _ReplyHistoryItem(
                reply: reply,
                search: search,
                decreaseCount: () => controller._decreaseCount(_index),
              ),
              noItemsFoundBuilder: (context) => Center(
                child: Text(
                  '没有回复记录',
                  style: AppTheme.boldRedPostContentTextStyle,
                  strutStyle: AppTheme.boldRedPostContentStrutStyle,
                ),
              ),
            );
          },
        ),
      );
}

// TODO: 高亮显示使用通配符的搜索结果
class HistoryBody extends StatefulWidget {
  final HistoryController controller;

  const HistoryBody(this.controller, {super.key});

  @override
  State<HistoryBody> createState() => _HistoryBodyState();
}

class _HistoryBodyState extends State<HistoryBody> {
  late final PageController _pageController;

  late StreamSubscription<int> _pageIndexSubscription;

  late StreamSubscription<List<DateTimeRange?>> _dateRangeSubscription;

  late final int _initialIndex;

  HistoryController get _controller => widget.controller;

  void _updateIndex() {
    final page = _pageController.page;
    if (page != null) {
      _controller.pageIndex = page.round();
    }
  }

  void _trySave(Object object) => _controller.trySave();

  void _onPageIndex(int index) {
    HistoryController._index = index;
    _trySave(index);
  }

  @override
  void initState() {
    super.initState();

    _initialIndex = _controller.pageIndex;
    _pageController = PageController(initialPage: _initialIndex);
    _pageController.addListener(_updateIndex);

    _pageIndexSubscription = _controller._pageIndex.listen(_onPageIndex);
    _dateRangeSubscription = _controller._dateRange.listen(_trySave);
  }

  @override
  void didUpdateWidget(covariant HistoryBody oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      _pageIndexSubscription.cancel();
      _pageIndexSubscription =
          widget.controller._pageIndex.listen(_onPageIndex);
      _dateRangeSubscription.cancel();
      _dateRangeSubscription = widget.controller._dateRange.listen(_trySave);
    }
  }

  @override
  void dispose() {
    _pageIndexSubscription.cancel();
    _dateRangeSubscription.cancel();
    _pageController.removeListener(_updateIndex);
    _pageController.dispose();

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
          tabs: const [Tab(text: '浏览'), Tab(text: '主题'), Tab(text: '回复')],
        ),
        headerHeight: () => _controller._headerHeight.value,
        header: _HistoryHeader(_controller),
        postList: SwipeablePageView(
          controller: _pageController,
          itemCount: _historyPageCount,
          itemBuilder: (context, index) {
            late final Widget body;
            switch (index) {
              case _BrowseHistoryBody._index:
                body = _BrowseHistoryBody(_controller);
                break;
              case _PostHistoryBody._index:
                body = _PostHistoryBody(_controller);
                break;
              case _ReplyHistoryBody._index:
                body = _ReplyHistoryBody(_controller);
                break;
              default:
                body = const Center(
                  child: Text('未知记录', style: AppTheme.boldRed),
                );
            }

            return body;
          },
        ),
      );
}
