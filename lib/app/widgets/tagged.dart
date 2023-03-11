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
  Widget build(BuildContext context) => PostTag(controller: controller);
}

class _TaggedPostListItem extends StatefulWidget {
  final Visible<TaggedPost> post;

  final int tagId;

  final Search? search;

  const _TaggedPostListItem(
      // ignore: unused_element
      {super.key,
      required this.post,
      required this.tagId,
      this.search});

  @override
  State<_TaggedPostListItem> createState() => _TaggedPostListItemState();
}

class _TaggedPostListItemState extends State<_TaggedPostListItem> {
  late Future<void> _getData;

  int? _mainPostId;

  int? _page;

  TaggedPost get _post => widget.post.item;

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
                  child: PostInkWell(
                    post: _post,
                    contentMaxLines: 8,
                    onText: !(widget.search?.useWildcard ?? true)
                        ? (context, text) => Regex.onSearchText(
                            text: text, search: widget.search!)
                        : null,
                    showFullTime: false,
                    showPostId: _post.isNormalPost,
                    showReplyCount: false,
                    onTagDeleted: (value) {
                      if (value == widget.tagId) {
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
                      onDeleted: () async {
                        await TagService.deletePostTag(post.id, widget.tagId);
                        showToast(post.isNormalPost
                            ? '删除标签列表里的串 ${post.toPostNumber()}'
                            : '删除标签列表里的串');
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
        controller: controller,
        postList: PostListScrollView(
          controller: controller,
          builder: (context, scrollController, refresh) {
            final search = controller.search;

            return BiListView<Visible<TaggedPost>>(
              scrollController: scrollController,
              postListController: controller,
              initialPage: 1,
              canLoadMoreAtBottom: false,
              fetch: (page) async => page == 1
                  ? (await TagService.taggedPostList(
                          tagId: controller.id, search: search))
                      .map((post) => Visible(post))
                      .toList()
                  : [],
              itemBuilder: (context, post, index) => _TaggedPostListItem(
                  post: post, tagId: controller.id, search: search),
              noItemsFoundBuilder: (context) => Center(
                child: Text(
                  '没有串',
                  style: AppTheme.boldRedPostContentTextStyle,
                  strutStyle: AppTheme.boldRedPostContentStrutStyle,
                ),
              ),
            );
          },
        ),
      );
}
