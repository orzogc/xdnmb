import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../data/models/controller.dart';
import '../data/models/tag.dart';
import '../data/models/tagged_post.dart';
import '../data/services/tag.dart';
import '../modules/post_list.dart';
import '../routes/routes.dart';
import '../utils/extensions.dart';
import '../utils/history.dart';
import '../utils/image.dart';
import '../utils/post.dart';
import '../utils/reference.dart';
import '../utils/regex.dart';
import '../utils/theme.dart';
import '../utils/toast.dart';
import 'bilistview.dart';
import 'dialog.dart';
import 'list_tile.dart';
import 'post.dart';
import 'post_list.dart';
import 'tag.dart';

class TaggedPostListController extends PostListController {
  @override
  PostListType get postListType => PostListType.taggedPostList;

  /// 标签ID
  @override
  final int id;

  final Rxn<Search> _search;

  final Rxn<TagData> _tag = Rxn(null);

  final RxnInt _postsCount = RxnInt(null);

  final RxDouble _headerHeight = 0.0.obs;

  final ValueListenable<Box<TagData>> _listenable;

  Search? get search => _search.value;

  TagData? get tag => _tag.value;

  bool get tagExists => TagService.to.tagIdExists(id);

  TaggedPostListController(
      {required this.id, required int page, Search? search})
      : _search = Rxn(search),
        _listenable = TagService.to.tagListenable([id]),
        super(page) {
    _updateTag();
    _listenable.addListener(_updateTag);
  }

  void _updateTag() {
    final tag = TagService.to.getTagData(id);
    if (tag != null) {
      _tag.value = tag;
    }
  }

  void _setSearch(Search? search) {
    _search.value = search;

    refreshPage();
  }

  int? _getPostsCount() => _postsCount.value.notNegative;

  void _setPostsCount(int? count) => _postsCount.value = count.notNegative;

  void _decreasePostCount() {
    final count = _getPostsCount();

    _setPostsCount(count != null ? count - 1 : null);
  }

  Future<void> _clear() async {
    await TagService.deleteTagInPosts(tagId: id, search: search);

    refreshPage();
  }

  @override
  void dispose() {
    _listenable.removeListener(_updateTag);

    super.dispose();
  }
}

TaggedPostListController taggedPostListController(
        Map<String, String?> parameters) =>
    TaggedPostListController(
        id: parameters['tagId'].tryParseInt() ?? 0,
        page: parameters['page'].tryParseInt() ?? 1);

class TaggedPostListAppBarTitle extends StatelessWidget {
  final TaggedPostListController controller;

  const TaggedPostListAppBarTitle(this.controller, {super.key});

  @override
  Widget build(BuildContext context) => Obx(() {
        final count = controller._getPostsCount();

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: PostTag(controller: controller)),
            if (count != null) Text('・$count')
          ],
        );
      });
}

class TaggedPostListAppBarPopupMenuButton extends StatelessWidget {
  final TaggedPostListController controller;

  const TaggedPostListAppBarPopupMenuButton(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final tagService = TagService.to;

    return PopupMenuButton(
      itemBuilder: (context) {
        final tag = tagService.getTagData(controller.id);
        final count = controller._getPostsCount();

        return [
          if (tag != null)
            PopupMenuItem(
              onTap: () => postListDialog(SearchDialog(
                search: controller.search,
                onSearch: (search) => controller._setSearch(search),
              )),
              child: const Text('搜索'),
            ),
          if (tag != null && count != null && count > 0)
            PopupMenuItem(
              onTap: () => postListDialog(ClearDialog(
                text: '标签 ${tag.name} ',
                textWidgetPrefix: '标签',
                textWidget: Tag.fromTagData(tag: tag),
                onClear: controller._clear,
              )),
              child: const Text('清空'),
            ),
        ];
      },
    );
  }
}

class _TaggedPostListHeader extends StatelessWidget {
  final TaggedPostListController controller;

  // ignore: unused_element
  const _TaggedPostListHeader(this.controller, {super.key});

  @override
  Widget build(BuildContext context) => Obx(() {
        final search = controller.search;

        return PostListHeader(
            key: ValueKey<Search?>(search),
            onSize: (value) => controller._headerHeight.value = value.height,
            child: search != null
                ? SearchListTile(
                    search: search, onCancel: () => controller._setSearch(null))
                : const SizedBox.shrink());
      });
}

class _TaggedPostListItem extends StatefulWidget {
  final TaggedPostListController controller;

  final Visible<TaggedPost> post;

  const _TaggedPostListItem(
      // ignore: unused_element
      {super.key,
      required this.controller,
      required this.post});

  @override
  State<_TaggedPostListItem> createState() => _TaggedPostListItemState();
}

class _TaggedPostListItemState extends State<_TaggedPostListItem> {
  late Future<void> _getData;

  int? _mainPostId;

  int? _page;

  TaggedPostListController get _controller => widget.controller;

  TaggedPost get _post => widget.post.item;

  int get _tagId => _controller.id;

  Search? get _search => _controller.search;

  bool get _isMainPost => _post.isNormalPost ? _post.id == _mainPostId : false;

  void _setGetData() => _getData = Future(() async {
        if (_post.isNormalPost) {
          final data = await ReferenceDatabase.getReference(_post.id);
          if (data != null) {
            _mainPostId = data.mainPostId;
            _page = data.page;
          }
        } else if (_post.isReplyHistory) {
          final data = await ReplyHistory.getReplyData(_post.historyId!);
          if (data != null) {
            _mainPostId = data.mainPostId;
            _page = data.page;
          }
        }

        if (_post.isNormalPost && _post.hasImage) {
          final image = await ReferenceImageCache.getImage(_post.id, _post.id);
          if (image != null) {
            _post.image = image.image;
            _post.imageExtension = image.imageExtension;
          }
        }
      });

  @override
  void initState() {
    super.initState();

    _setGetData();
  }

  @override
  void didUpdateWidget(covariant _TaggedPostListItem oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.post != oldWidget.post) {
      _setGetData();
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
        future: _getData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasError) {
            debugPrint('获取串 ${_post.toPostNumber()} 的数据出错：${snapshot.error}');
          }

          return Obx(() => widget.post.isVisible
              ? PostCard(
                  key: ValueKey<int>(_post.id),
                  child: PostInkWell(
                    post: _post,
                    contentMaxLines: 8,
                    onText: !(_search?.useWildcard ?? true)
                        ? (context, text) =>
                            Regex.onSearchText(text: text, search: _search!)
                        : null,
                    showFullTime: false,
                    showPostId: _post.isNormalPost,
                    showReplyCount: false,
                    onDeleteTag: (value) {
                      if (value == _tagId) {
                        _controller._decreasePostCount();
                        widget.post.isVisible = false;
                      }
                    },
                    onTap: !_post.isPostHistory
                        ? (post) async {
                            if (_mainPostId != null) {
                              AppRoutes.toThread(
                                  mainPostId: _mainPostId!,
                                  page: _page ?? 1,
                                  jumpToId: (_post.isNormalPost &&
                                          !_isMainPost &&
                                          _page != null)
                                      ? _post.id
                                      : null);
                            }
                          }
                        : null,
                    onLongPress: (post) => postListDialog(SavedPostDialog(
                      post: post,
                      mainPostId: _mainPostId,
                      page: _page,
                      onDelete: () async {
                        await TagService.deletePostTag(post.id, _tagId);
                        _controller._decreasePostCount();
                        showToast(post.isNormalPost
                            ? '删除串 ${post.toPostNumber()}'
                            : '删除串');
                        widget.post.isVisible = false;
                      },
                    )),
                  ),
                )
              : const SizedBox.shrink());
        },
      );
}

class TaggedPostListBody extends StatelessWidget {
  final TaggedPostListController controller;

  const TaggedPostListBody(this.controller, {super.key});

  @override
  Widget build(BuildContext context) => PostListWithTabBarOrHeader(
        headerHeight: () => controller._headerHeight.value,
        header: _TaggedPostListHeader(controller),
        controller: controller,
        postList: PostListScrollView(
          controller: controller,
          builder: (context, scrollController, refresh) =>
              BiListView<Visible<TaggedPost>>(
            key: ValueKey<int>(refresh),
            scrollController: scrollController,
            postListController: controller,
            initialPage: 1,
            canLoadMoreAtBottom: false,
            fetch: (page) async {
              if (page == 1) {
                final list = (await TagService.taggedPostList(
                        tagId: controller.id, search: controller.search))
                    .map((post) => Visible(post))
                    .toList();
                controller._setPostsCount(list.length);

                return list;
              }

              return <Visible<TaggedPost>>[];
            },
            itemBuilder: (context, post, index) =>
                _TaggedPostListItem(controller: controller, post: post),
            noItemsFoundBuilder: (context) => Center(
              child: Text(
                '没有串',
                style: AppTheme.boldRedPostContentTextStyle,
                strutStyle: AppTheme.boldRedPostContentStrutStyle,
              ),
            ),
          ),
        ),
      );
}
