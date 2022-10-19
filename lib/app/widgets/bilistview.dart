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

typedef FetchPage<T> = Future<List<T>> Function(int page);

typedef GetFunctionCallback = void Function(VoidCallback function);

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
      this.getLoadMore});

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

  bool _isLoading = false;

  bool _isRefreshing = false;

  int _lastPage = 0;

  int _itemListLength = 0;

  late final ScrollController _scrollController;

  final RxBool _isOutOfBoundary = true.obs;

  Future<void> _fetchUpPage(int page) async {
    final lastPage = widget.lastPage;
    if (lastPage != null && page > lastPage) {
      _pagingUpController?.appendPage([], page - 1);
      return;
    }

    if (page >= widget.firstPage) {
      try {
        debugPrint('up page fetching $T page: $page');

        final list = await widget.fetch(page);

        page != widget.firstPage
            ? _pagingUpController?.appendPage(list.reversed.toList(), page - 1)
            : _pagingUpController?.appendLastPage(list.reversed.toList());
      } catch (e) {
        debugPrint('up page获取$T列表失败：$e');
        _pagingUpController?.error = e;
      }
    } else {
      _pagingUpController?.appendLastPage([]);
    }
  }

  Future<void> _fetchDownPage(int page) async {
    final lastPage = widget.lastPage;
    if (lastPage != null && page > lastPage) {
      _pagingDownController?.appendLastPage([]);
      return;
    }

    if (page >= widget.firstPage) {
      try {
        debugPrint('down page fetching $T page: $page');

        final list = await widget.fetch(page);

        if (_isLoading && _pagingDownController?.itemList != null) {
          _pagingDownController?.itemList!.removeRange(
              _itemListLength, (_pagingDownController?.itemList)!.length);
        }

        if (list.isNotEmpty) {
          _lastPage = page;
          _itemListLength = _pagingDownController?.itemList?.length ?? 0;
        }

        list.isNotEmpty &&
                ((lastPage != null && page != lastPage) || lastPage == null)
            ? _pagingDownController?.appendPage(list, page + 1)
            : _pagingDownController?.appendLastPage(list);
      } catch (e) {
        debugPrint('down page获取$T列表失败：$e');
        _pagingDownController?.error = e;
      }
    } else {
      _pagingDownController?.appendPage([], page + 1);
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

          await _fetchUpPage(widget.firstPage);
          await _fetchDownPage(widget.firstPage + 1);
        }
      } finally {
        _isRefreshing = false;
      }
    }
  }

  Future<void> _loadMore() async {
    if (!_isLoading) {
      _isLoading = true;

      try {
        if (widget.onRefresh != null) {
          widget.onRefresh!();
        }

        await _fetchDownPage(_lastPage);
      } finally {
        _isLoading = false;
      }
    }
  }

  Widget _errorWidgetBuilder(PagingController<int, T> controller) {
    final user = UserService.to;
    final message = exceptionMessage(controller.error);
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
        child: Center(
          child: ValueListenableBuilder<Box>(
            valueListenable: user.browseCookieListenable,
            builder: (context, value, child) =>
                (!user.hasBrowseCookie && message.contains('饼干'))
                    ? const Text('出现错误，点击登陆X岛帐号')
                    : const Text('出现错误，点击重新尝试'),
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
    _pagingUpController?.dispose();
    _pagingUpController = null;
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

    final pagingUpDelegate = PagedChildBuilderDelegate<T>(
      itemBuilder: widget.itemBuilder,
      firstPageErrorIndicatorBuilder: (context) =>
          _errorWidgetBuilder(_pagingUpController!),
      newPageErrorIndicatorBuilder: (context) =>
          _errorWidgetBuilder(_pagingUpController!),
      firstPageProgressIndicatorBuilder: (context) =>
          const QuotationLoadingIndicator(),
      newPageProgressIndicatorBuilder: (context) => const Quotation(),
      noItemsFoundIndicatorBuilder: (context) => const SizedBox.shrink(),
    );

    final pagingDownDelegate = PagedChildBuilderDelegate<T>(
      itemBuilder: widget.itemBuilder,
      firstPageErrorIndicatorBuilder: (context) =>
          _errorWidgetBuilder(_pagingDownController!),
      newPageErrorIndicatorBuilder: (context) =>
          _errorWidgetBuilder(_pagingDownController!),
      firstPageProgressIndicatorBuilder: (context) =>
          const QuotationLoadingIndicator(),
      newPageProgressIndicatorBuilder: (context) => const Quotation(),
      noItemsFoundIndicatorBuilder: widget.noItemsFoundBuilder,
      noMoreItemsIndicatorBuilder: (context) {
        if (widget.onNoMoreItems != null) {
          widget.onNoMoreItems!();
        }

        return widget.lastPage == null
            ? (widget.canLoadMoreAtBottom
                ? GestureDetector(
                    onTap: _loadMore,
                    child: Center(
                      child: Text(
                        '上拉或点击刷新',
                        style: TextStyle(
                          color: specialTextColor(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink())
            : Center(
                child: Text(
                  '已经抵达X岛的尽头',
                  style: TextStyle(
                    color: specialTextColor(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
      },
    );

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
                  await _loadMore();
                  _refreshController?.finishLoad();
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
                  widget.separator != null
                      ? PagedSliverList.separated(
                          pagingController: _pagingUpController!,
                          separatorBuilder: (context, index) =>
                              widget.separator!,
                          builderDelegate: pagingUpDelegate)
                      : PagedSliverList(
                          pagingController: _pagingUpController!,
                          builderDelegate: pagingUpDelegate),
                if (widget.initialPage > 1)
                  SliverToBoxAdapter(child: widget.separator),
                widget.separator != null
                    ? PagedSliverList.separated(
                        key: _downKey,
                        pagingController: _pagingDownController!,
                        separatorBuilder: (context, index) => widget.separator!,
                        builderDelegate: pagingDownDelegate)
                    : PagedSliverList(
                        key: _downKey,
                        pagingController: _pagingDownController!,
                        builderDelegate: pagingDownDelegate),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
