import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../data/services/user.dart';
import '../routes/routes.dart';
import '../utils/exception.dart';
import '../utils/theme.dart';
import '../utils/toast.dart';
import 'loading.dart';

class _MinHeightIndicator extends StatelessWidget {
  static const double _minHeight = 90.0;

  final Widget child;

  const _MinHeightIndicator({super.key, required this.child});

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _minHeight),
        child: child,
      );
}

class DumpItem extends StatelessWidget {
  const DumpItem({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

typedef FetchPage<T> = Future<List<T>> Function(int page);

typedef GetFunctionCallback = void Function(VoidCallback function);

typedef GetPageCallback = int Function();

class BiListView<T> extends StatefulWidget {
  final ScrollController? controller;

  final int initialPage;

  final int firstPage;

  final int? lastPage;

  final bool canLoadMoreAtBottom;

  final FetchPage<T> fetch;

  final ItemWidgetBuilder<T> itemBuilder;

  final Widget? separator;

  final WidgetBuilder? noItemsFoundBuilder;

  final VoidCallback? onNoMoreItems;

  final VoidCallback? onRefresh;

  final GetFunctionCallback? getLoadMore;

  final FetchPage<T>? fetchFallback;

  final GetPageCallback? getMaxPage;

  const BiListView(
      {super.key,
      this.controller,
      required this.initialPage,
      this.firstPage = 1,
      this.lastPage,
      this.canLoadMoreAtBottom = true,
      required this.fetch,
      required this.itemBuilder,
      this.separator,
      this.noItemsFoundBuilder,
      this.onNoMoreItems,
      this.onRefresh,
      this.getLoadMore,
      this.fetchFallback,
      this.getMaxPage})
      : assert(
            getMaxPage == null || (lastPage == null && fetchFallback != null));

  @override
  State<BiListView<T>> createState() => _BiListViewState<T>();
}

class _BiListViewState<T> extends State<BiListView<T>>
    with AutomaticKeepAliveClientMixin<BiListView<T>> {
  PagingController<int, T>? _pagingUpController;

  PagingController<int, T>? _pagingDownController;

  final Key _downKey = UniqueKey();

  EasyRefreshController? _refreshController = EasyRefreshController(
    controlFinishRefresh: true,
    controlFinishLoad: true,
  );

  final RxBool _isLoadingMore = false.obs;

  bool _isLoading = false;

  bool _isRefreshing = false;

  int _lastPage = 0;

  int _itemListLength = 0;

  late final ScrollController _scrollController;

  final RxBool _isOutOfBoundary = true.obs;

  bool _isFetchingUp = false;

  bool _isFetchingDown = false;

  Future<void> _fetchUpPage(int page, [bool rethrowError = false]) async {
    if (!_isFetchingUp) {
      _isFetchingUp = true;

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
    if (!_isRefreshing) {
      _isRefreshing = true;

      try {
        if (widget.onRefresh != null) {
          widget.onRefresh!();
        }

        if (widget.initialPage == widget.firstPage) {
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
    if (!_isLoadingMore.value) {
      _isLoadingMore.value = true;

      try {
        if (widget.onRefresh != null) {
          widget.onRefresh!();
        }

        await _fetchDownPage(_lastPage, true);
      } catch (e) {
        showToast('加载出现错误：${exceptionMessage(e)}');
      } finally {
        _isLoadingMore.value = false;
      }
    }
  }

  Widget _errorWidgetBuilder(PagingController<int, T> controller,
      [bool isAtCenter = false]) {
    final user = UserService.to;
    final message = exceptionMessage(controller.error ?? '未知错误');
    showToast(message);

    return InkWell(
      onTap: () {
        if (controller.error != null) {
          if (!user.hasBrowseCookie && message.contains('饼干')) {
            AppRoutes.toUser();
          } else {
            controller.retryLastFailedRequest();
          }
        }
      },
      child: DefaultTextStyle.merge(
        style: AppTheme.boldRed,
        child: _MinHeightIndicator(
          child: ValueListenableBuilder<Box>(
            valueListenable: user.browseCookieListenable,
            builder: (context, value, child) {
              final Widget text =
                  (!user.hasBrowseCookie && message.contains('饼干'))
                      ? const Text('没有饼干，点击管理饼干')
                      : const Text('点击重新尝试');

              return Column(
                mainAxisAlignment: isAtCenter
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('错误：$message'),
                  text,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _noMoreItems(BuildContext context) {
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
                            style: TextStyle(
                              color: specialTextColor(),
                              fontWeight: FontWeight.bold,
                            ),
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
                style: TextStyle(
                  color: specialTextColor(),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
  }

  void _checkBoundary() {
    final position = _scrollController.position;

    if (position.pixels >= position.maxScrollExtent ||
        position.pixels <= position.minScrollExtent) {
      _isOutOfBoundary.value = true;
    } else {
      _isOutOfBoundary.value = false;
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

    _pagingUpController =
        PagingController(firstPageKey: widget.initialPage - 1);
    _pagingDownController = PagingController(firstPageKey: widget.initialPage);

    _pagingUpController!.addPageRequestListener(_fetchUpPage);
    _pagingDownController!.addPageRequestListener(_fetchDownPage);

    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_checkBoundary);

    if (widget.getLoadMore != null) {
      widget.getLoadMore!(_loadMore);
    }
  }

  @override
  void dispose() {
    _pagingUpController?.removePageRequestListener(_fetchUpPage);
    _pagingUpController?.dispose();
    _pagingUpController = null;
    _pagingDownController?.removePageRequestListener(_fetchDownPage);
    _pagingDownController?.dispose();
    _pagingDownController = null;
    _refreshController?.dispose();
    _refreshController = null;
    _scrollController.removeListener(_checkBoundary);
    if (widget.controller == null) {
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
        header: const MaterialHeader(clamping: false),
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
          () => Scrollable(
            controller: _scrollController,
            physics: _isOutOfBoundary.value
                ? physics
                : const ClampingScrollPhysics(
                    parent: RangeMaintainingScrollPhysics()),
            viewportBuilder: (context, position) => Viewport(
              offset: position,
              center: _downKey,
              slivers: [
                if (widget.initialPage > 1)
                  PagedSliverList(
                    pagingController: _pagingUpController!,
                    builderDelegate: PagedChildBuilderDelegate<T>(
                      itemBuilder: _itemBuilder,
                      firstPageErrorIndicatorBuilder: (context) =>
                          _errorWidgetBuilder(_pagingUpController!, true),
                      newPageErrorIndicatorBuilder: (context) =>
                          _errorWidgetBuilder(_pagingUpController!),
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
                        _errorWidgetBuilder(_pagingDownController!, true),
                    newPageErrorIndicatorBuilder: (context) =>
                        _errorWidgetBuilder(_pagingDownController!),
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
          ),
        ),
      ),
    );
  }
}
