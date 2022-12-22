import 'dart:async';

import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../data/services/settings.dart';
import '../data/services/user.dart';
import '../modules/post_list.dart';
import '../routes/routes.dart';
import '../utils/exception.dart';
import '../utils/theme.dart';
import '../utils/toast.dart';
import 'listenable.dart';
import 'loading.dart';

class _MinHeightIndicator extends StatelessWidget {
  static const double _minHeight = 90.0;

  final Widget child;

  // ignore: unused_element
  const _MinHeightIndicator({super.key, required this.child});

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _minHeight),
        child: child,
      );
}

class _BiListViewRefreshHeader extends MaterialHeader {
  final PostListController postListController;

  const _BiListViewRefreshHeader(
      {required this.postListController, super.clamping});

  @override
  Widget build(BuildContext context, IndicatorState state) {
    final settings = SettingsService.to;

    return Obx(() => settings.isAutoHideAppBar
        ? Padding(
            padding: EdgeInsets.only(top: postListController.appBarHeight),
            child: super.build(context, state),
          )
        : super.build(context, state));
  }
}

class _BiListViewHeader extends StatelessWidget {
  // ignore: unused_element
  const _BiListViewHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return Obx(() => settings.isAutoHideAppBar
        ? const SizedBox(height: PostListAppBar.height)
        : const SizedBox.shrink());
  }
}

/// 什么都不显示的[Widget]
class DumpItem extends StatelessWidget {
  const DumpItem({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

typedef FetchPage<T> = Future<List<T>> Function(int page);

typedef GetPageCallback = int Function();

class BiListViewController {
  bool _isLoadingMore = false;

  VoidCallback? _loadMore;

  /// 正在加载更多
  bool get isLoadingMore => _isLoadingMore;

  BiListViewController();

  void loadMore() {
    if (_loadMore != null) {
      _loadMore!();
    }
  }
}

class BiListView<T> extends StatefulWidget {
  final BiListViewController? controller;

  final ScrollController? scrollController;

  final PostListController postListController;

  final int initialPage;

  final int firstPage;

  final int? lastPage;

  final bool canLoadMoreAtBottom;

  final FetchPage<T> fetch;

  final ItemWidgetBuilder<T> itemBuilder;

  final Widget? separator;

  final WidgetBuilder? noItemsFoundBuilder;

  final VoidCallback? onNoMoreItems;

  final VoidCallback? onRefreshAndLoadMore;

  final FetchPage<T>? fetchFallback;

  final GetPageCallback? getMaxPage;

  const BiListView(
      {super.key,
      this.controller,
      this.scrollController,
      required this.postListController,
      required this.initialPage,
      this.firstPage = 1,
      this.lastPage,
      this.canLoadMoreAtBottom = true,
      required this.fetch,
      required this.itemBuilder,
      this.separator,
      this.noItemsFoundBuilder,
      this.onNoMoreItems,
      this.onRefreshAndLoadMore,
      this.fetchFallback,
      this.getMaxPage})
      : assert(
            getMaxPage == null || (lastPage == null && fetchFallback != null));

  @override
  State<BiListView<T>> createState() => _BiListViewState<T>();
}

class _BiListViewState<T> extends State<BiListView<T>>
    with AutomaticKeepAliveClientMixin<BiListView<T>> {
  late final int _initialPage;

  PagingController<int, T>? _pagingUpController;

  PagingController<int, T>? _pagingDownController;

  final Key _upKey = UniqueKey();

  final Key _downKey = UniqueKey();

  EasyRefreshController? _refreshController = EasyRefreshController(
    controlFinishRefresh: true,
    controlFinishLoad: true,
  );

  int _itemListLength = 0;

  late ScrollController _scrollController;

  final RxBool _isOutOfBoundary = true.obs;

  /// 正在加载更多
  final RxBool _isLoadingMore = false.obs;

  /// 正在上拉加载更多
  bool _isLoading = false;

  /// 正在下拉刷新
  bool _isRefreshing = false;

  int _lastPage = 0;

  bool _isFetchingUp = false;

  bool _isFetchingDown = false;

  StreamSubscription<bool>? _isLoadingMoreSubscription;

  String? _pagingUpError;

  String? _pagingDownError;

  Future<void> _fetchUpPage(int page, [bool rethrowError = false]) async {
    if (!_isFetchingUp) {
      _isFetchingUp = true;
      _pagingUpError = null;

      try {
        final lastPage = widget.lastPage;
        if (lastPage != null && page > lastPage) {
          _pagingUpController?.appendPage([], page - 1);
          return;
        }

        if (page >= widget.firstPage) {
          debugPrint('up page fetching $T page: $page');

          List<T> list = await widget.fetch(page);
          if (list.isEmpty && widget.fetchFallback != null) {
            list = await widget.fetchFallback!(page);
          }

          page != widget.firstPage
              ? _pagingUpController?.appendPage(
                  list.reversed.toList(), page - 1)
              : _pagingUpController?.appendLastPage(list.reversed.toList());
        } else {
          _pagingUpController?.appendLastPage([]);
        }
      } catch (e) {
        debugPrint('up page获取$T列表失败：$e');
        if (rethrowError) {
          rethrow;
        } else {
          _pagingUpController?.error = e;
        }
      } finally {
        _isFetchingUp = false;
      }
    }
  }

  Future<void> _fetchDownPage(int page, [bool rethrowError = false]) async {
    if (!_isFetchingDown) {
      _isFetchingDown = true;
      _pagingDownError = null;

      try {
        final lastPage = widget.lastPage;
        if (lastPage != null && page > lastPage) {
          _pagingDownController?.appendLastPage([]);
          return;
        }

        if (page >= widget.firstPage) {
          debugPrint('down page fetching $T page: $page');

          List<T> list = await widget.fetch(page);

          if (_isLoadingMore.value && _pagingDownController?.itemList != null) {
            _pagingDownController?.itemList!.removeRange(
                _itemListLength, (_pagingDownController?.itemList)!.length);
          }

          if (list.isNotEmpty) {
            _lastPage = page;
            _itemListLength = _pagingDownController?.itemList?.length ?? 0;
          } else if (widget.getMaxPage != null &&
              widget.fetchFallback != null &&
              page <= widget.getMaxPage!()) {
            list = await widget.fetchFallback!(page);
            _lastPage = page;
            _itemListLength = _pagingDownController?.itemList?.length ?? 0;
          }

          list.isNotEmpty && (lastPage == null || page < lastPage)
              ? _pagingDownController?.appendPage(list, page + 1)
              : _pagingDownController?.appendLastPage(list);
        } else {
          _pagingDownController?.appendPage([], page + 1);
        }
      } catch (e) {
        debugPrint('down page获取$T列表失败：$e');
        if (rethrowError) {
          rethrow;
        } else {
          _pagingDownController?.error = e;
        }
      } finally {
        _isFetchingDown = false;
      }
    }
  }

  Future<void> _refresh() async {
    if (!_isRefreshing && !_isFetchingUp && !_isFetchingDown) {
      _isRefreshing = true;

      try {
        if (widget.onRefreshAndLoadMore != null) {
          widget.onRefreshAndLoadMore!();
        }

        if (_initialPage == widget.firstPage) {
          _pagingUpController?.refresh();
          _pagingDownController?.refresh();
        } else {
          _pagingUpController?.itemList?.clear();
          _pagingDownController?.itemList?.clear();

          await _fetchUpPage(widget.firstPage, true);
          await _fetchDownPage(widget.firstPage + 1, true);
        }
      } catch (e) {
        showToast('刷新出现错误：${exceptionMessage(e)}');
      } finally {
        _isRefreshing = false;
      }
    }
  }

  Future<void> _loadMore() async {
    if (!_isLoadingMore.value && !_isFetchingDown) {
      _isLoadingMore.value = true;

      try {
        if (widget.onRefreshAndLoadMore != null) {
          widget.onRefreshAndLoadMore!();
        }

        await _fetchDownPage(_lastPage, true);
      } catch (e) {
        showToast('加载出现错误：${exceptionMessage(e)}');
      } finally {
        _isLoadingMore.value = false;
        //_toRefresh.value = !_toRefresh.value;
      }
    }
  }

  Widget _errorWidgetBuilder(
      {required bool isPagingUp, bool isAtCenter = false}) {
    final user = UserService.to;
    final controller = isPagingUp ? _pagingUpController : _pagingDownController;
    final message = exceptionMessage(controller?.error ?? '未知错误');
    // 防止重复显示错误信息
    if (message != (isPagingUp ? _pagingUpError : _pagingDownError)) {
      showToast(message);
      if (isPagingUp) {
        _pagingUpError = message;
      } else {
        _pagingDownError = message;
      }
    }

    return InkWell(
      onTap: () {
        if (controller?.error != null) {
          if (!user.hasBrowseCookie && message.contains('饼干')) {
            AppRoutes.toUser();
          } else {
            controller?.retryLastFailedRequest();
          }
        }
      },
      child: _MinHeightIndicator(
        child: ListenableBuilder(
          listenable: user.browseCookieListenable,
          builder: (context, child) {
            final Widget text =
                (!user.hasBrowseCookie && message.contains('饼干'))
                    ? Text('没有饼干，点击管理饼干',
                        style: AppTheme.boldRedPostContentTextStyle,
                        strutStyle: AppTheme.boldRedPostContentStrutStyle)
                    : Text('点击重新尝试',
                        style: AppTheme.boldRedPostContentTextStyle,
                        strutStyle: AppTheme.boldRedPostContentStrutStyle);

            return Column(
              mainAxisAlignment: isAtCenter
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Text('错误：$message',
                    style: AppTheme.boldRedPostContentTextStyle,
                    strutStyle: AppTheme.boldRedPostContentStrutStyle),
                text,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _noMoreItems(BuildContext context) {
    final textStyle = AppTheme.postContentTextStyle.merge(TextStyle(
        color: AppTheme.specialTextColor, fontWeight: FontWeight.bold));

    if (widget.onNoMoreItems != null) {
      widget.onNoMoreItems!();
    }

    return widget.lastPage == null
        ? (widget.canLoadMoreAtBottom
            ? _MinHeightIndicator(
                child: Obx(
                  () => _isLoadingMore.value
                      ? const Quotation()
                      : TextButton(
                          style: TextButton.styleFrom(
                            alignment: Alignment.topCenter,
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: _loadMore,
                          child: Text(
                            '上拉或点击刷新',
                            style: textStyle,
                            strutStyle: StrutStyle.fromTextStyle(textStyle),
                          ),
                        ),
                ),
              )
            : const SizedBox.shrink())
        : _MinHeightIndicator(
            child: Align(
              alignment: Alignment.topCenter,
              child: Text(
                '已经抵达X岛的尽头',
                style: textStyle,
                strutStyle: StrutStyle.fromTextStyle(textStyle),
              ),
            ),
          );
  }

  void _checkBoundary() {
    if (_scrollController.hasClients) {
      final position = _scrollController.position;

      // 留1像素的空间
      if (position.pixels >= position.maxScrollExtent - 1.0 ||
          position.pixels <= position.minScrollExtent + 1.0) {
        _isOutOfBoundary.value = true;
      } else {
        _isOutOfBoundary.value = false;
      }
    }
  }

  Widget _itemBuilder(BuildContext context, T item, int index) {
    final itemWidget = widget.itemBuilder(context, item, index);

    return (widget.separator != null && itemWidget is! DumpItem)
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [itemWidget, widget.separator!],
          )
        : itemWidget;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _initialPage = widget.initialPage;

    _pagingUpController = PagingController(firstPageKey: _initialPage - 1);
    _pagingDownController = PagingController(firstPageKey: _initialPage);

    _pagingUpController!.addPageRequestListener(_fetchUpPage);
    _pagingDownController!.addPageRequestListener(_fetchDownPage);

    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_checkBoundary);

    if (widget.controller != null) {
      widget.controller!._loadMore = _loadMore;
      _isLoadingMoreSubscription = _isLoadingMore
          .listen((value) => widget.controller!._isLoadingMore = value);
    }
  }

  @override
  void didUpdateWidget(covariant BiListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.scrollController != oldWidget.scrollController) {
      final oldController = _scrollController;
      oldController.removeListener(_checkBoundary);
      if (oldWidget.scrollController == null) {
        oldController.dispose();
      }

      _scrollController = widget.scrollController ?? ScrollController();
      _scrollController.addListener(_checkBoundary);
    }

    if (widget.controller != oldWidget.controller) {
      _isLoadingMoreSubscription?.cancel();
      _isLoadingMoreSubscription = null;
      oldWidget.controller?._loadMore = null;

      if (widget.controller != null) {
        widget.controller!._loadMore = _loadMore;
        _isLoadingMoreSubscription = _isLoadingMore
            .listen((value) => widget.controller!._isLoadingMore = value);
      }
    }
  }

  @override
  void dispose() {
    _isLoadingMoreSubscription?.cancel();
    _isLoadingMoreSubscription = null;
    widget.controller?._loadMore = null;
    _pagingUpController?.removePageRequestListener(_fetchUpPage);
    _pagingUpController?.error = null;
    _pagingUpController?.itemList = null;
    _pagingUpController?.dispose();
    _pagingUpController = null;
    _pagingDownController?.removePageRequestListener(_fetchDownPage);
    _pagingDownController?.error = null;
    _pagingDownController?.itemList = null;
    _pagingDownController?.dispose();
    _pagingDownController = null;
    _refreshController?.dispose();
    _refreshController = null;
    _scrollController.removeListener(_checkBoundary);
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: EasyRefresh.builder(
        controller: _refreshController,
        header: _BiListViewRefreshHeader(
            postListController: widget.postListController, clamping: false),
        footer: widget.lastPage == null
            ? const MaterialFooter(clamping: false)
            : null,
        onRefresh: () async {
          if (!_isRefreshing) {
            await _refresh();
            _refreshController?.finishRefresh();
          }
        },
        onLoad: (widget.lastPage == null && widget.canLoadMoreAtBottom)
            ? () async {
                if (!_isLoading) {
                  _isLoading = true;

                  try {
                    await _loadMore();
                    _refreshController?.finishLoad();
                  } finally {
                    _isLoading = false;
                  }
                }
              }
            : null,
        noMoreRefresh: true,
        noMoreLoad: widget.lastPage == null ? true : false,
        childBuilder: (context, physics) => Obx(
          () {
            // 加载更多后需要刷新，否则某些Widget可能不会更新（不确定能否修复）
            //_toRefresh.value;

            return Scrollable(
              controller: _scrollController,
              physics: _isOutOfBoundary.value
                  ? physics
                  : const ClampingScrollPhysics(
                      parent: RangeMaintainingScrollPhysics()),
              viewportBuilder: (context, position) => Viewport(
                offset: position,
                center: _downKey,
                slivers: [
                  const SliverToBoxAdapter(child: _BiListViewHeader()),
                  if (_initialPage > 1)
                    PagedSliverList(
                      key: _upKey,
                      pagingController: _pagingUpController!,
                      builderDelegate: PagedChildBuilderDelegate<T>(
                        itemBuilder: _itemBuilder,
                        firstPageErrorIndicatorBuilder: (context) =>
                            _errorWidgetBuilder(
                                isPagingUp: true, isAtCenter: true),
                        newPageErrorIndicatorBuilder: (context) =>
                            _errorWidgetBuilder(isPagingUp: true),
                        firstPageProgressIndicatorBuilder: (context) =>
                            const QuotationLoadingIndicator(),
                        newPageProgressIndicatorBuilder: (context) =>
                            const _MinHeightIndicator(child: Quotation()),
                        noItemsFoundIndicatorBuilder: (context) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  PagedSliverList(
                    key: _downKey,
                    pagingController: _pagingDownController!,
                    builderDelegate: PagedChildBuilderDelegate<T>(
                      itemBuilder: _itemBuilder,
                      firstPageErrorIndicatorBuilder: (context) =>
                          _errorWidgetBuilder(
                              isPagingUp: false, isAtCenter: true),
                      newPageErrorIndicatorBuilder: (context) =>
                          _errorWidgetBuilder(isPagingUp: false),
                      firstPageProgressIndicatorBuilder: (context) =>
                          const QuotationLoadingIndicator(),
                      newPageProgressIndicatorBuilder: (context) =>
                          const _MinHeightIndicator(child: Quotation()),
                      noItemsFoundIndicatorBuilder: widget.noItemsFoundBuilder,
                      noMoreItemsIndicatorBuilder: _noMoreItems,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
