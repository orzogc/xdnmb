import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../data/models/controller.dart';
import '../data/models/history.dart';
import '../data/models/post.dart';
import '../data/models/reply.dart';
import '../data/services/history.dart';
import '../data/services/settings.dart';
import '../data/services/time.dart';
import '../data/services/xdnmb_client.dart';
import '../modules/post_list.dart';
import '../routes/routes.dart';
import '../utils/exception.dart';
import '../utils/extensions.dart';
import '../utils/hash.dart';
import '../utils/navigation.dart';
import '../utils/post_list.dart';
import '../utils/regex.dart';
import '../utils/theme.dart';
import '../utils/time.dart';
import '../utils/toast.dart';
import 'bilistview.dart';
import 'checkbox.dart';
import 'dialog.dart';
import 'listenable.dart';
import 'page_view.dart';
import 'post.dart';
import 'post_list.dart';
import 'size.dart';
import 'time.dart';

const int _historyEachPage = 20;

class _Image {
  static final HashMap<int, _Image?> _images = intHashMap<_Image?>();

  static Future<_Image?> _getImage(int postId, int? mainPostId) async {
    if (!_images.containsKey(postId)) {
      debugPrint('历史记录里的串 ${postId.toPostNumber()} 有图片，开始获取其引用');

      try {
        final reference = await XdnmbClientService.to
            .getReference(postId, mainPostId: mainPostId);
        if (reference.hasImage) {
          _images[postId] = _Image(
              image: reference.image, imageExtension: reference.imageExtension);
        } else {
          _images[postId] = null;
        }
      } catch (e) {
        final message = exceptionMessage(e);
        if (message.contains('该串不存在')) {
          _images[postId] = null;
        }

        rethrow;
      }
    }

    return _images[postId];
  }

  final String image;

  final String imageExtension;

  const _Image({required this.image, required this.imageExtension});
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
  final RxInt _pageIndex;

  final Rx<List<DateTimeRange?>> _dateRange;

  final Rx<List<Search?>> _search;

  final RxList<int?> _counts = RxList(List.filled(3, null));

  final List<ListenableNotifier> _notifiers = [
    ListenableNotifier(),
    ListenableNotifier(),
    ListenableNotifier(),
  ];

  final PageController _pageController;

  final RxDouble _height = 0.0.obs;

  @override
  PostListType get postListType => PostListType.history;

  @override
  int? get id => null;

  int get pageIndex => _pageIndex.value;

  set pageIndex(int index) => _pageIndex.value = index;

  List<DateTimeRange?> get dateRange => _dateRange.value;

  set dateRange(List<DateTimeRange?> range) => _dateRange.value = range;

  List<Search?> get search => _search.value;

  set search(List<Search?> search) => _search.value = search;

  HistoryController(
      {required int page,
      int pageIndex = 0,
      List<DateTimeRange?>? dateRange,
      List<Search?>? search})
      : assert(pageIndex >= 0 && pageIndex <= 2),
        _pageIndex = pageIndex.obs,
        _dateRange = Rx(dateRange ?? List.filled(3, null)),
        _search = Rx(search ?? List.filled(3, null)),
        _pageController = PageController(initialPage: pageIndex),
        super(page);

  ListenableNotifier _getNotifier([int? index]) {
    assert(index == null || index < 3);

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
    assert(index == null || index < 3);

    return dateRange[index ?? pageIndex];
  }

  void _setDateRange(DateTimeRange? range, [int? index]) {
    assert(index == null || index < 3);

    dateRange[index ?? pageIndex] = range;
    _notify(index);
  }

  Search? _getSearch([int? index]) {
    assert(index == null || index < 3);

    return search[index ?? pageIndex];
  }

  void _setSearch(Search? searchText, [int? index]) {
    assert(index == null || index < 3);

    search[index ?? pageIndex] = searchText;
    _notify(index);
  }

  int? _getCount([int? index]) {
    assert(index == null || index < 3);

    return _counts[index ?? pageIndex];
  }

  void _setCount(int? count, [int? index]) {
    assert(index == null || index < 3);

    _counts[index ?? pageIndex] = count;
  }

  String _text([String unknown = '未知', int? index]) {
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
    final history = PostHistoryService.to;
    index ??= pageIndex;
    final range = _getDateRange(index);

    if (_getSearch(index) == null) {
      switch (index) {
        case _BrowseHistoryBody._index:
          _setCount(await history.browseHistoryCount(range), index);
          break;
        case _PostHistoryBody._index:
          _setCount(await history.postDataCount(range), index);
          break;
        case _ReplyHistoryBody._index:
          _setCount(await history.replyDataCount(range), index);
          break;
        default:
          debugPrint('未知index：$index');
      }
    }
  }

  Future<void> _clear([int? index]) async {
    final history = PostHistoryService.to;
    index ??= pageIndex;
    final range = _getDateRange(index);
    final search = _getSearch(index);

    switch (index) {
      case _BrowseHistoryBody._index:
        await history.clearBrowseHistory(range: range, search: search);
        break;
      case _PostHistoryBody._index:
        await history.clearPostData(range: range, search: search);
        break;
      case _ReplyHistoryBody._index:
        await history.clearReplyData(range: range, search: search);
        break;
      default:
        debugPrint('未知index：$index');
    }

    _setCount(0, index);
    _trigger(index);
  }

  @override
  void dispose() {
    for (final notifier in _notifiers) {
      notifier.dispose();
    }
    _pageController.dispose();

    super.dispose();
  }
}

HistoryController historyController(Map<String, String?> parameters) =>
    HistoryController(
        page: parameters['page'].tryParseInt() ?? 1,
        pageIndex: parameters['index'].tryParseInt() ?? 0);

class HistoryAppBarTitle extends StatelessWidget {
  final HistoryController controller;

  const HistoryAppBarTitle(this.controller, {super.key});

  @override
  Widget build(BuildContext context) => Obx(() {
        final text = controller._text('历史记录');
        final count = controller._getCount();

        return count != null ? Text('$text（$count）') : Text(text);
      });
}

class _SearchDialog extends StatelessWidget {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final HistoryController controller;

  // ignore: unused_element
  _SearchDialog(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    String? searchText;
    final search = controller._getSearch();
    final caseSensitive = (search?.caseSensitive ?? false).obs;
    final useWildcard = (search?.useWildcard ?? false).obs;

    return InputDialog(
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: '搜索内容'),
              autofocus: true,
              initialValue: search?.text,
              onSaved: (newValue) => searchText = newValue,
              validator: (value) =>
                  (value == null || value.isEmpty) ? '请输入搜索内容' : null,
            ),
            Obx(
              () => Row(
                children: [
                  AppCheckbox(
                    value: caseSensitive.value,
                    onChanged: (value) {
                      if (value != null) {
                        caseSensitive.value = value;
                      }
                    },
                  ),
                  Flexible(child: Text('英文字母区分大小写', style: textStyle)),
                ],
              ),
            ),
            Obx(
              () => Row(
                children: [
                  AppCheckbox(
                    value: useWildcard.value,
                    onChanged: (value) {
                      if (value != null) {
                        useWildcard.value = value;
                      }
                    },
                  ),
                  Flexible(child: Text('使用通配符', style: textStyle)),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            postListDialog(const ConfirmCancelDialog(
              contentWidget: Text.rich(TextSpan(
                text: "搜索内容尽量不要是HTML标签和样式相关字符串，比如'font'、'color'、'br'。\n通配符 ",
                children: [
                  TextSpan(
                    children: [
                      TextSpan(text: '*', style: AppTheme.boldRed),
                      TextSpan(text: ' 匹配零个或多个任意字符。\n通配符 '),
                      TextSpan(text: '?', style: AppTheme.boldRed),
                      TextSpan(text: ' 匹配任意一个字符，通常汉字包含三个或四个字符。'),
                    ],
                  ),
                ],
              )),
              onConfirm: postListBack,
            ));
          },
          child: const Text('搜索说明'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();

              controller._setSearch(Search(
                  text: searchText!,
                  caseSensitive: caseSensitive.value,
                  useWildcard: useWildcard.value));
              postListBack();
            }
          },
          child: const Text('搜索'),
        ),
      ],
    );
  }
}

class _ClearDialog extends StatelessWidget {
  final HistoryController controller;

  // ignore: unused_element
  const _ClearDialog(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final text = controller._text();

    return LoaderOverlay(
      child: ConfirmCancelDialog(
        content: '确定清空$text记录？',
        onConfirm: () async {
          final overlay = context.loaderOverlay;
          try {
            overlay.show();

            await controller._clear();
            showToast('清空$text记录');
          } catch (e) {
            showToast('清空$text记录失败：$e');
          } finally {
            if (overlay.visible) {
              overlay.hide();
            }
          }

          WidgetsBinding.instance
              .addPostFrameCallback((timeStamp) => postListBack());
        },
        onCancel: () => postListBack(),
      ),
    );
  }
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
            onTap: () => postListDialog(_SearchDialog(controller)),
            child: const Text('搜索'),
          ),
          PopupMenuItem(
            onTap: () {
              if ((controller._getCount() ?? 0) > 0) {
                postListDialog(_ClearDialog(controller));
              }
            },
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
  const _HistoryHeader({super.key, required this.controller});

  @override
  Widget build(BuildContext context) => Obx(() {
        final range = controller._getDateRange();
        final search = controller._getSearch();

        return ChildSizeNotifier(
          key: ValueKey<_HeaderKey>(_HeaderKey(range: range, search: search)),
          builder: (context, size, child) {
            WidgetsBinding.instance.addPostFrameCallback(
                (timeStamp) => controller._height.value = size.height);

            return child!;
          },
          child: (range != null || search != null)
              ? Material(
                  elevation: 2.0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (range != null)
                        ListTile(
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
                        const Divider(height: 10.0, thickness: 1.0),
                      if (search != null)
                        ListTile(
                          title: Center(
                            child: Text.rich(
                              TextSpan(
                                text: '搜索内容：',
                                children: [
                                  TextSpan(
                                    text: search.text,
                                    style: AppTheme.boldRed,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          subtitle: (search.caseSensitive || search.useWildcard)
                              ? OverflowBar(
                                  alignment: MainAxisAlignment.spaceAround,
                                  overflowSpacing: 5.0,
                                  overflowAlignment:
                                      OverflowBarAlignment.center,
                                  children: [
                                    if (search.caseSensitive)
                                      const Text('英文字母区分大小写'),
                                    if (search.useWildcard) const Text('使用通配符'),
                                  ],
                                )
                              : null,
                          trailing: IconButton(
                            onPressed: () => controller._setSearch(null),
                            icon: const Icon(Icons.close),
                          ),
                        )
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        );
      });
}

class _HistoryDialog extends StatelessWidget {
  final PostBase mainPost;

  final PostBase? post;

  final bool confirmDelete;

  final VoidCallback onDelete;

  final int? page;

  const _HistoryDialog(
      // ignore: unused_element
      {super.key,
      required this.mainPost,
      this.post,
      this.confirmDelete = true,
      required this.onDelete,
      this.page});

  @override
  Widget build(BuildContext context) {
    final hasMainPostId = mainPost.id > 0;
    final hasPostId = post != null && post!.id > 0;
    final hasPostIdOrMainPostId = hasPostId || (post == null && hasMainPostId);
    final postHistory = post ?? mainPost;

    return SimpleDialog(
      title: hasPostIdOrMainPostId ? Text(postHistory.toPostNumber()) : null,
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
          child: Text('删除', style: Theme.of(context).textTheme.titleMedium),
        ),
        if (hasMainPostId)
          SharePost(
            mainPostId: mainPost.id,
            page: page,
            postId: hasPostId ? post!.id : null,
          ),
        if (hasPostIdOrMainPostId) CopyPostId(postHistory.id),
        if (hasPostIdOrMainPostId) CopyPostReference(postHistory.id),
        CopyPostContent(postHistory),
        if (post != null) CopyPostId(mainPost.id, text: '复制主串串号'),
        if (post != null) CopyPostReference(mainPost.id, text: '复制主串串号引用'),
        if (hasMainPostId)
          NewTab(mainPost, text: post != null ? '在新标签页打开主串' : null),
        if (hasMainPostId)
          NewTabBackground(mainPost, text: post != null ? '在新标签页后台打开主串' : null),
      ],
    );
  }
}

class _BrowseHistoryItem extends StatefulWidget {
  final Visible<BrowseHistory> browse;

  final Search? search;

  // ignore: unused_element
  const _BrowseHistoryItem({super.key, required this.browse, this.search});

  @override
  State<_BrowseHistoryItem> createState() => _BrowseHistoryItemState();
}

class _BrowseHistoryItemState extends State<_BrowseHistoryItem> {
  late Future<void> _getBrowseHistory;

  Visible<BrowseHistory> get browse => widget.browse;

  void _setGetBrowseHistory() => _getBrowseHistory = Future(() async {
        if (browse.item.hasImage) {
          final image = await _Image._getImage(browse.item.id, browse.item.id);
          if (image != null) {
            browse.item.image = image.image;
            browse.item.imageExtension = image.imageExtension;
          }
        }
      });

  @override
  void initState() {
    super.initState();

    _setGetBrowseHistory();

    final time = TimeService.to;
    if (SettingsService.to.showRelativeTime &&
        browse.item.browseTime.isAfter(time.now)) {
      time.updateTime();
    }
  }

  @override
  void didUpdateWidget(covariant _BrowseHistoryItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.browse != oldWidget.browse) {
      _setGetBrowseHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;
    final time = TimeService.to;

    return FutureBuilder<void>(
      future: _getBrowseHistory,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasError) {
          debugPrint(
              '获取串 ${browse.item.toPostNumber()} 的引用出错：${snapshot.error}');
        }

        final browsePage =
            browse.item.browsePage ?? browse.item.onlyPoBrowsePage;
        final browsePostId =
            browse.item.browsePostId ?? browse.item.onlyPoBrowsePostId;

        return Obx(
          () => browse.isVisible
              ? PostCard(
                  key: ValueKey<int>(browse.item.id),
                  child: InkWell(
                    onTap: () => AppRoutes.toThread(
                        mainPostId: browse.item.id, mainPost: browse.item),
                    onLongPress: () => postListDialog(_HistoryDialog(
                      mainPost: browse.item,
                      confirmDelete: false,
                      onDelete: () async {
                        await PostHistoryService.to
                            .deleteBrowseHistory(browse.item.id);
                        showToast('删除 ${browse.item.toPostNumber()} 的浏览记录');
                        browse.isVisible = false;
                      },
                    )),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 10.0, top: 5.0, right: 10.0),
                          child: PostHeader(
                            fontSize: AppTheme.postHeaderTextStyle.fontSize,
                            child: OverflowBar(
                              spacing: 5.0,
                              alignment: MainAxisAlignment.spaceBetween,
                              overflowSpacing: 5.0,
                              children: [
                                if (settings.showRelativeTime)
                                  TimerRefresher(
                                    builder: (context) => Text(
                                      '最后浏览时间：${time.relativeTime(browse.item.browseTime)}',
                                      style: AppTheme.postHeaderTextStyle,
                                      strutStyle: AppTheme.postHeaderStrutStyle,
                                    ),
                                  )
                                else
                                  Text(
                                    '最后浏览时间：${fullFormatTime(browse.item.browseTime)}',
                                    style: AppTheme.postHeaderTextStyle,
                                    strutStyle: AppTheme.postHeaderStrutStyle,
                                  ),
                                if (browsePage != null && browsePostId != null)
                                  Text(
                                    '浏览到：第$browsePage页 ${browsePostId.toPostNumber()}',
                                    style: AppTheme.postHeaderTextStyle,
                                    strutStyle: AppTheme.postHeaderStrutStyle,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        PostContent(
                          post: browse.item,
                          poUserHash: browse.item.userHash,
                          contentMaxLines: 8,
                          onText: !(widget.search?.useWildcard ?? true)
                              ? (context, text) => Regex.onSearchText(
                                  text: text, search: widget.search!)
                              : null,
                          showFullTime: false,
                          showReplyCount: false,
                        ),
                      ],
                    ),
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
  const _BrowseHistoryBody({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final history = PostHistoryService.to;

    return PostListScrollView(
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
                  ? (await history.browseHistoryList(
                          start: search == null
                              ? (page - 1) * _historyEachPage
                              : null,
                          end: search == null ? page * _historyEachPage : null,
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
            itemBuilder: (context, browse, index) =>
                _BrowseHistoryItem(browse: browse, search: search),
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
}

class _PostHistoryItem extends StatefulWidget {
  final Visible<PostData> mainPost;

  final Search? search;

  // ignore: unused_element
  const _PostHistoryItem({super.key, required this.mainPost, this.search});

  @override
  State<_PostHistoryItem> createState() => _PostHistoryItemState();
}

class _PostHistoryItemState extends State<_PostHistoryItem> {
  Visible<PostData> get mainPost => widget.mainPost;

  late Future<void> _getPostHistory;

  void _setGetPostHistory() => _getPostHistory = Future(() async {
        if (mainPost.item.postId != null && mainPost.item.hasImage) {
          final image = await _Image._getImage(
              mainPost.item.postId!, mainPost.item.postId!);
          if (image != null) {
            mainPost.item.image = image.image;
            mainPost.item.imageExtension = image.imageExtension;
          }
        }
      });

  @override
  void initState() {
    super.initState();

    _setGetPostHistory();
  }

  @override
  void didUpdateWidget(covariant _PostHistoryItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.mainPost != oldWidget.mainPost) {
      _setGetPostHistory();
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
        future: _getPostHistory,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasError) {
            debugPrint(
                '获取串 ${mainPost.item.postId?.toPostNumber()} 的引用出错：${snapshot.error}');
          }

          return Obx(
            () => mainPost.isVisible
                ? PostCard(
                    key: ValueKey<int>(mainPost.item.id),
                    child: PostInkWell(
                      post: mainPost.item.toPost(),
                      poUserHash: mainPost.item.userHash,
                      contentMaxLines: 8,
                      onText: !(widget.search?.useWildcard ?? true)
                          ? (context, text) => Regex.onSearchText(
                              text: text, search: widget.search!)
                          : null,
                      showPostId: mainPost.item.postId != null,
                      showReplyCount: false,
                      onTap: (post) {
                        if (post.id > 0) {
                          AppRoutes.toThread(
                              mainPostId: post.id, mainPost: post);
                        }
                      },
                      onLongPress: (post) => postListDialog(_HistoryDialog(
                        mainPost: post,
                        onDelete: () async {
                          await PostHistoryService.to
                              .deletePostData(mainPost.item.id);
                          showToast(mainPost.item.postId != null
                              ? '删除主题 ${mainPost.item.postId?.toPostNumber()} 的记录'
                              : '删除主题记录');
                          mainPost.isVisible = false;
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
  const _PostHistoryBody({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final history = PostHistoryService.to;

    return PostListScrollView(
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
                  ? (await history.postDataList(
                          start: search == null
                              ? (page - 1) * _historyEachPage
                              : null,
                          end: search == null ? page * _historyEachPage : null,
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
            itemBuilder: (context, mainPost, index) =>
                _PostHistoryItem(mainPost: mainPost, search: search),
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
}

class _ReplyHistoryItem extends StatefulWidget {
  final Visible<ReplyData> reply;

  final Search? search;

  // ignore: unused_element
  const _ReplyHistoryItem({super.key, required this.reply, this.search});

  @override
  State<_ReplyHistoryItem> createState() => _ReplyHistoryItemState();
}

class _ReplyHistoryItemState extends State<_ReplyHistoryItem> {
  late Future<void> _getReplyHistory;

  Visible<ReplyData> get reply => widget.reply;

  void setGetReplyHistory() => _getReplyHistory = Future(() async {
        if (reply.item.postId != null && reply.item.hasImage) {
          final image =
              await _Image._getImage(reply.item.postId!, reply.item.mainPostId);
          if (image != null) {
            reply.item.image = image.image;
            reply.item.imageExtension = image.imageExtension;
          }
        }
      });

  @override
  void initState() {
    super.initState();

    setGetReplyHistory();
  }

  @override
  void didUpdateWidget(covariant _ReplyHistoryItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.reply != oldWidget.reply) {
      setGetReplyHistory();
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
        future: _getReplyHistory,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasError) {
            debugPrint(
                '获取串 ${reply.item.postId?.toPostNumber()} 的引用出错：${snapshot.error}');
          }

          return Obx(
            () {
              final post = reply.item.toPost();

              return reply.isVisible
                  ? PostCard(
                      key: ValueKey<int>(reply.item.id),
                      child: InkWell(
                        onTap: () => AppRoutes.toThread(
                            mainPostId: reply.item.mainPostId,
                            page: reply.item.page ?? 1,
                            jumpToId: (reply.item.page != null &&
                                    reply.item.postId != null)
                                ? reply.item.postId
                                : null),
                        onLongPress: () => postListDialog(_HistoryDialog(
                          mainPost: reply.item.toMainPost(),
                          post: post,
                          onDelete: () async {
                            await PostHistoryService.to
                                .deletePostData(reply.item.id);
                            showToast(reply.item.postId != null
                                ? '删除回复 ${reply.item.postId?.toPostNumber()} 的记录'
                                : '删除回复记录');
                            reply.isVisible = false;
                          },
                          page: reply.item.page,
                        )),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 10.0,
                                top: 5.0,
                                right: 10.0,
                              ),
                              child: PostHeader(
                                fontSize: AppTheme.postHeaderTextStyle.fontSize,
                                child: OverflowBar(
                                  spacing: 5.0,
                                  alignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '主串：${reply.item.mainPostId.toPostNumber()}',
                                      style: AppTheme.postHeaderTextStyle,
                                      strutStyle: AppTheme.postHeaderStrutStyle,
                                    ),
                                    if (reply.item.page != null)
                                      Text(
                                        '第 ${reply.item.page} 页',
                                        style: AppTheme.postHeaderTextStyle,
                                        strutStyle:
                                            AppTheme.postHeaderStrutStyle,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            PostContent(
                              post: post,
                              contentMaxLines: 8,
                              onText: !(widget.search?.useWildcard ?? true)
                                  ? (context, text) => Regex.onSearchText(
                                      text: text, search: widget.search!)
                                  : null,
                              showPostId: reply.item.postId != null,
                              showReplyCount: false,
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink();
            },
          );
        },
      );
}

class _ReplyHistoryBody extends StatelessWidget {
  static const _index = 2;

  final HistoryController controller;

  // ignore: unused_element
  const _ReplyHistoryBody({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final history = PostHistoryService.to;

    return PostListScrollView(
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
                  ? (await history.replyDataList(
                          start: search == null
                              ? (page - 1) * _historyEachPage
                              : null,
                          end: search == null ? page * _historyEachPage : null,
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
            itemBuilder: (context, reply, index) =>
                _ReplyHistoryItem(reply: reply, search: search),
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
}

// TODO: 高亮显示使用通配符的搜索结果
class HistoryBody extends StatefulWidget {
  final HistoryController controller;

  const HistoryBody(this.controller, {super.key});

  @override
  State<HistoryBody> createState() => _HistoryBodyState();
}

class _HistoryBodyState extends State<HistoryBody> {
  late StreamSubscription<int> _pageIndexSubscription;

  late StreamSubscription<List<DateTimeRange?>> _dateRangeSubscription;

  late final int _initialIndex;

  void _updateIndex() {
    final page = widget.controller._pageController.page;
    if (page != null) {
      widget.controller.pageIndex = page.round();
    }
  }

  void _trySave(Object object) => widget.controller.trySave();

  @override
  void initState() {
    super.initState();

    _initialIndex = widget.controller.pageIndex;

    _pageIndexSubscription = widget.controller._pageIndex.listen(_trySave);
    _dateRangeSubscription = widget.controller._dateRange.listen(_trySave);

    widget.controller._pageController.addListener(_updateIndex);
  }

  @override
  void didUpdateWidget(covariant HistoryBody oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      _pageIndexSubscription.cancel();
      _pageIndexSubscription = widget.controller._pageIndex.listen(_trySave);
      _dateRangeSubscription.cancel();
      _dateRangeSubscription = widget.controller._dateRange.listen(_trySave);

      oldWidget.controller._pageController.removeListener(_updateIndex);
      widget.controller._pageController.addListener(_updateIndex);
    }
  }

  @override
  void dispose() {
    _pageIndexSubscription.cancel();
    _dateRangeSubscription.cancel();
    widget.controller._pageController.removeListener(_updateIndex);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;
    final theme = Theme.of(context);

    final Widget tabBar = Material(
      elevation: theme.appBarTheme.elevation ?? PostListAppBar.defaultElevation,
      color: theme.primaryColor,
      child: PageViewTabBar(
        pageController: widget.controller._pageController,
        initialIndex: _initialIndex,
        onIndex: (index) {
          if (widget.controller.pageIndex != index) {
            popAllPopup();
            widget.controller._pageController.animateToPage(index,
                duration: PageViewTabBar.animationDuration,
                curve: Curves.easeIn);
          }
        },
        tabs: const [Tab(text: '浏览'), Tab(text: '主题'), Tab(text: '回复')],
      ),
    );

    return Stack(
      children: [
        Obx(
          () => Padding(
            padding: EdgeInsets.only(
                top: PageViewTabBar.height + widget.controller._height.value),
            child: SwipeablePageView(
              controller: widget.controller._pageController,
              itemCount: 3,
              itemBuilder: (context, index) {
                late final Widget body;
                switch (index) {
                  case _BrowseHistoryBody._index:
                    body = _BrowseHistoryBody(controller: widget.controller);
                    break;
                  case _PostHistoryBody._index:
                    body = _PostHistoryBody(controller: widget.controller);
                    break;
                  case _ReplyHistoryBody._index:
                    body = _ReplyHistoryBody(controller: widget.controller);
                    break;
                  default:
                    body = const Center(
                      child: Text('未知记录', style: AppTheme.boldRed),
                    );
                }

                return body;
              },
            ),
          ),
        ),
        Obx(() => settings.isAutoHideAppBar
            ? Positioned(
                left: 0.0,
                top: widget.controller.appBarHeight + PageViewTabBar.height,
                right: 0.0,
                child: _HistoryHeader(controller: widget.controller),
              )
            : Positioned(
                left: 0.0,
                top: PageViewTabBar.height,
                right: 0.0,
                child: _HistoryHeader(controller: widget.controller),
              )),
        Obx(
          () => settings.isAutoHideAppBar
              ? Positioned(
                  left: 0.0,
                  top: widget.controller.appBarHeight,
                  right: 0.0,
                  child: tabBar,
                )
              : tabBar,
        ),
      ],
    );
  }
}
