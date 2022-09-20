import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../data/models/history.dart';
import '../data/services/history.dart';
import '../modules/post_list.dart';
import '../routes/routes.dart';
import '../utils/extensions.dart';
import '../utils/hidden_text.dart';
import '../utils/navigation.dart';
import '../utils/time.dart';
import '../utils/toast.dart';
import 'bilistview.dart';
import 'dialog.dart';
import 'post.dart';

PostListController historyController(Map<String, String?> parameters) =>
    PostListController(
        postListType: PostListType.history,
        bottomBarIndex: int.tryParse(parameters['index'] ?? '0') ?? 0);

class HistoryAppBarTitle extends StatelessWidget {
  const HistoryAppBarTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('历史记录');
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
        onTap: (value) => index.value = value,
        items: const [
          BottomNavigationBarItem(icon: SizedBox.shrink(), label: '浏览'),
          BottomNavigationBarItem(icon: SizedBox.shrink(), label: '发串'),
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

  late final StreamSubscription<int?> _listener;

  @override
  void initState() {
    super.initState();

    _controller = PageController(
        initialPage: widget.controller.bottomBarIndex.value ?? 0);
    _listener = widget.controller.bottomBarIndex.listen((index) {
      if (index != null) {
        _controller.jumpToPage(index);
      }
    });
  }

  @override
  void dispose() {
    _listener.cancel();
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageView.builder(
        controller: _controller,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        itemBuilder: (context, index) {
          switch (index) {
            case 0:
              return const _BrowseHistoryBody();
            default:
              return const SizedBox.shrink();
          }
        },
      );
}

class _BrowseHistoryDialog extends StatelessWidget {
  final PostBase post;

  final VoidCallback onDelete;

  const _BrowseHistoryDialog(
      {super.key, required this.post, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text(post.toPostNumber()),
      children: [
        SimpleDialogOption(
          onPressed: () async {
            postListBack();
            await PostHistoryService.to.deleteBrowseHistory(post.id);
            showToast('删除 ${post.id.toPostNumber()} 的浏览记录');
            onDelete();
          },
          child: Text(
            '删除',
            style: TextStyle(
                fontSize: Theme.of(context).textTheme.subtitle1?.fontSize),
          ),
        ),
        AddFeed(post),
        CopyPostId(post),
        CopyPostNumber(post),
        CopyPostContent(post),
        NewTab(post),
        NewTabBackground(post),
      ],
    );
  }
}

class _BrowseHistoryBody extends StatelessWidget {
  static const int _historyEachPage = 20;

  const _BrowseHistoryBody({super.key});

  @override
  Widget build(BuildContext context) {
    final history = PostHistoryService.to;

    return BiListView<BrowseHistory>(
      initialPage: 1,
      fetch: (page) => history.browseHistory(
          (page - 1) * _historyEachPage, page * _historyEachPage),
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
                      _BrowseHistoryDialog(
                        post: browse,
                        onDelete: () => isVisible.value = false,
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('最后浏览时间：${formatTime(browse.browseTime)}'),
                                if (browsePage != null && browsePostId != null)
                                  Text(
                                      '浏览到：第$browsePage页 ${browsePostId.toPostNumber()}'),
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
                                  textStyle: textStyle),
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        );
      },
      separator: const SizedBox.shrink(),
      noItemsFoundBuilder: (context) => const Center(
        child: Text(
          '这里没有浏览记录',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
      ),
      canRefreshAtBottom: false,
    );
  }
}
