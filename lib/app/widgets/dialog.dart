import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_expanded_tile/flutter_expanded_tile.dart';
import 'package:get/get.dart';
import 'package:html_to_text/html_to_text.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:xdnmb_api/xdnmb_api.dart' hide Image;

import '../data/models/controller.dart';
import '../data/models/cookie.dart';
import '../data/models/forum.dart';
import '../data/models/tag.dart';
import '../data/services/blacklist.dart';
import '../data/services/forum.dart';
import '../data/services/persistent.dart';
import '../data/services/settings.dart';
import '../data/services/tag.dart';
import '../data/services/user.dart';
import '../data/services/xdnmb_client.dart';
import '../modules/post_list.dart';
import '../routes/routes.dart';
import '../utils/exception.dart';
import '../utils/extensions.dart';
import '../utils/image.dart';
import '../utils/navigation.dart';
import '../utils/text.dart';
import '../utils/theme.dart';
import '../utils/time.dart';
import '../utils/toast.dart';
import '../utils/url.dart';
import 'checkbox.dart';
import 'color.dart';
import 'content.dart';
import 'edit_post.dart';
import 'forum_name.dart';
import 'listenable.dart';
import 'list_tile.dart';
import 'scroll.dart';
import 'tag.dart';
import 'tagged.dart';
import 'thread.dart';

Future<T?> postListDialog<T>(Widget widget, {int? index}) {
  final settings = SettingsService.to;
  final data = PersistentDataService.to;
  final controller = PostListController.get();

  return Get.dialog<T>(Obx(() {
    final isAutoHideAppBar = settings.autoHideAppBarRx;
    final isShowBottomBar = PostListBottomBar.isShownRx;

    return (isAutoHideAppBar || isShowBottomBar)
        ? Container(
            margin: EdgeInsets.only(
              top: isAutoHideAppBar ? controller.appBarHeight : 0.0,
              bottom: (!data.isKeyboardVisible && isShowBottomBar)
                  ? PostListBottomBar.height
                  : 0.0,
            ),
            child: widget)
        : widget;
  }), navigatorKey: postListkey(index));
}

Future<T?> showNoticeDialog<T>(
        {bool showCheckbox = false, bool isAutoUpdate = false}) =>
    postListDialog<T>(
        NoticeDialog(showCheckbox: showCheckbox, isAutoUpdate: isAutoUpdate));

Future<T?> showForumRuleDialog<T>(int forumId) =>
    postListDialog<T>(ForumRuleDialog(forumId));

class InputDialog extends StatelessWidget {
  final Widget? title;

  final Widget content;

  final List<Widget>? actions;

  const InputDialog(
      {super.key, this.title, required this.content, this.actions});

  @override
  Widget build(BuildContext context) => AlertDialog(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
        actionsPadding: const EdgeInsets.only(bottom: 10.0),
        actionsAlignment: MainAxisAlignment.spaceAround,
        title: title,
        content: SingleChildScrollViewWithScrollbar(child: content),
        actions: actions,
      );
}

class ConfirmCancelDialog extends StatelessWidget {
  final String? title;

  final Widget? titleWidget;

  final String? content;

  final Widget? contentWidget;

  final VoidCallback? onConfirm;

  final VoidCallback? onCancel;

  final String? confirmText;

  final String? cancelText;

  const ConfirmCancelDialog(
      {super.key,
      this.title,
      this.titleWidget,
      this.content,
      this.contentWidget,
      this.onConfirm,
      this.onCancel,
      this.confirmText,
      this.cancelText})
      : assert(titleWidget == null || title == null),
        assert(contentWidget == null || content == null);

  @override
  Widget build(BuildContext context) {
    final fontSize = Theme.of(context).textTheme.titleMedium?.fontSize;

    return AlertDialog(
      actionsPadding:
          const EdgeInsets.only(left: 10.0, right: 10.0, bottom: 10.0),
      title: titleWidget ?? (title != null ? Text(title!) : null),
      content: (content != null || contentWidget != null)
          ? SingleChildScrollViewWithScrollbar(
              child: contentWidget ?? Text(content!))
          : null,
      actions: (onConfirm != null || onCancel != null)
          ? [
              if (onCancel != null)
                TextButton(
                  onPressed: onCancel!,
                  child: Text(cancelText ?? '取消',
                      style: TextStyle(fontSize: fontSize)),
                ),
              if (onConfirm != null)
                TextButton(
                  onPressed: onConfirm!,
                  child: Text(confirmText ?? '确定',
                      style: TextStyle(fontSize: fontSize)),
                ),
            ]
          : null,
    );
  }
}

class NoticeDialog extends StatefulWidget {
  final bool showCheckbox;

  final bool isAutoUpdate;

  const NoticeDialog(
      {super.key, this.showCheckbox = false, this.isAutoUpdate = false})
      : assert(
            (showCheckbox && !isAutoUpdate) || (!showCheckbox && isAutoUpdate));

  @override
  State<NoticeDialog> createState() => _NoticeDialogState();
}

class _NoticeDialogState extends State<NoticeDialog> {
  Future<void>? _updateNotice;

  final RxBool isChecked = false.obs;

  void _setUpdateNotice() => _updateNotice =
      widget.isAutoUpdate ? PersistentDataService.to.updateNotice() : null;

  @override
  void initState() {
    super.initState();

    _setUpdateNotice();
  }

  @override
  void didUpdateWidget(covariant NoticeDialog oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isAutoUpdate != oldWidget.isAutoUpdate) {
      _setUpdateNotice();
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = PersistentDataService.to;
    final settings = SettingsService.to;
    final textStyle = Theme.of(context).textTheme.titleMedium;

    return AlertDialog(
      actionsPadding:
          const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
      actionsAlignment: widget.showCheckbox
          ? MainAxisAlignment.spaceBetween
          : MainAxisAlignment.end,
      contentPadding: const EdgeInsets.fromLTRB(24.0, 10.0, 24.0, 5.0),
      title: ListenBuilder(
          listenable: data.noticeDateListenable,
          builder: (context, child) => data.noticeDate != null
              ? Text('公告 ${formatDay(data.noticeDate!)}')
              : const Text('公告')),
      content: SingleChildScrollViewWithScrollbar(
        child: (widget.isAutoUpdate && _updateNotice != null)
            ? FutureBuilder<void>(
                future: _updateNotice!,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.hasError) {
                    showToast(exceptionMessage(snapshot.error!));

                    return const Center(
                      child: Text('加载失败', style: AppTheme.boldRed),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.done) {
                    return TextContent(
                      text: data.notice ?? '',
                      onTapLink: (context, link, text) => parseUrl(url: link),
                    );
                  }

                  return const Center(child: CircularProgressIndicator());
                },
              )
            : TextContent(
                text: data.notice ?? '',
                onTapLink: (context, link, text) => parseUrl(url: link),
              ),
      ),
      actions: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showCheckbox)
              Row(
                children: [
                  Obx(
                    () => AppCheckbox(
                      value: isChecked.value,
                      onChanged: (value) {
                        if (value != null) {
                          isChecked.value = value;
                        }
                      },
                    ),
                  ),
                  Flexible(child: Text('不再提示此条公告', style: textStyle)),
                ],
              ),
            Row(
              children: [
                const Spacer(),
                TextButton(
                  onPressed: () {
                    if (widget.showCheckbox) {
                      settings.showNotice = !isChecked.value;
                    }
                    postListBack();
                  },
                  child: Text(
                    '确定',
                    style: TextStyle(fontSize: textStyle?.fontSize),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class NewVersionDialog extends StatefulWidget {
  final String url;

  final String? latestVersion;

  final String? updateMessage;

  const NewVersionDialog(
      {super.key, required this.url, this.latestVersion, this.updateMessage});

  @override
  State<NewVersionDialog> createState() => _NewVersionDialogState();
}

class _NewVersionDialogState extends State<NewVersionDialog> {
  HtmlText? _text;

  @override
  void dispose() {
    _text?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _text?.dispose();

    _text = HtmlText(
        context, widget.updateMessage ?? '新版本 ${widget.latestVersion}',
        onTapLink: (context, link, text) => launchURL(link),
        textStyle: Theme.of(context).textTheme.titleMedium);

    return ConfirmCancelDialog(
      title: '发现新版本 ${widget.latestVersion}',
      contentWidget: _text!.toRichText(),
      onConfirm: () {
        showToast('正在打开下载链接');
        launchURL(widget.url);
      },
      confirmText: '下载',
    );
  }
}

class ForumRuleDialog extends StatefulWidget {
  final int forumId;

  const ForumRuleDialog(this.forumId, {super.key});

  @override
  State<ForumRuleDialog> createState() => _ForumRuleDialogState();
}

class _ForumRuleDialogState extends State<ForumRuleDialog> {
  late Future<void> _getForumRule;

  void _setGetForumRule() => _getForumRule = Future(() async {
        final forums = ForumListService.to;

        final entry = forums.forums.toList().asMap().entries.singleWhere(
            (entry) => entry.value.isForum && entry.value.id == widget.forumId);

        if (entry.value.isDeprecated) {
          final htmlForum = await XdnmbClientService.to.client
              .getHtmlForumInfo(widget.forumId);
          final forum = ForumData.fromHtmlForum(htmlForum);
          forum.userDefinedName = entry.value.userDefinedName;
          forum.isHidden = entry.value.isHidden;
          await forums.updateForum(entry.key, forum);

          debugPrint('更新废弃版块成功');
        }
      });

  @override
  void initState() {
    super.initState();

    _setGetForumRule();
  }

  @override
  void didUpdateWidget(covariant ForumRuleDialog oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.forumId != oldWidget.forumId) {
      _setGetForumRule();
    }
  }

  @override
  Widget build(BuildContext context) {
    final forums = ForumListService.to;

    return FutureBuilder<void>(
      future: _getForumRule,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasError) {
          showToast('更新版规出现错误：${exceptionMessage(snapshot.error!)}');
        }

        final forum = forums.forum(widget.forumId);

        return AlertDialog(
          actionsPadding: const EdgeInsets.only(right: 20.0, bottom: 20.0),
          title: forum != null
              ? ForumName(
                  forumId: forum.id,
                  trailing: ' 版规',
                  textStyle: Theme.of(context).textTheme.titleLarge,
                  maxLines: 1)
              : const Text('版规'),
          content: SingleChildScrollViewWithScrollbar(
            child: TextContent(
              text: forum?.message ?? '',
              onTapLink: (context, link, text) => parseUrl(url: link),
              onImage: SettingsService.to.showImage
                  ? ((context, image, element) => image != null
                      ? TextSpan(
                          children: [
                            WidgetSpan(
                              child: CachedNetworkImage(
                                imageUrl: image,
                                cacheKey: hashImage(image, imageHashLength),
                                cacheManager: XdnmbImageCacheManager(),
                                progressIndicatorBuilder:
                                    loadingThumbImageIndicatorBuilder,
                                errorWidget: loadingImageErrorBuilder,
                              ),
                            ),
                            const TextSpan(text: '\n'),
                          ],
                        )
                      : const TextSpan())
                  : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => postListBack(),
              child: Text(
                '确定',
                style: TextStyle(
                  fontSize: Theme.of(context).textTheme.titleMedium?.fontSize,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// TODO: SimpleDialog 自动显示 scrollbar
class NewTab extends StatelessWidget {
  final int mainPostId;

  final int page;

  final PostBase? mainPost;

  final int? jumpToId;

  final String? text;

  const NewTab(
      {super.key,
      required this.mainPostId,
      this.page = 1,
      this.mainPost,
      this.jumpToId,
      this.text});

  @override
  Widget build(BuildContext context) => SimpleDialogOption(
        onPressed: () {
          final controller = ThreadController(
              id: mainPostId,
              page: page,
              mainPost: mainPost,
              jumpToId: jumpToId);
          postListBack();
          openNewTab(controller);
          showToast('已在新标签页打开 ${mainPostId.toPostNumber()}');
        },
        child: Text(
          text ?? '在新标签页打开',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
}

class NewTabBackground extends StatelessWidget {
  final int mainPostId;

  final int page;

  final PostBase? mainPost;

  final int? jumpToId;

  final String? text;

  const NewTabBackground(
      {super.key,
      required this.mainPostId,
      this.page = 1,
      this.mainPost,
      this.jumpToId,
      this.text});

  @override
  Widget build(BuildContext context) => SimpleDialogOption(
        onPressed: () {
          final controller = ThreadController(
              id: mainPostId,
              page: page,
              mainPost: mainPost,
              jumpToId: jumpToId);
          openNewTabBackground(controller);
          showToast('已在新标签页后台打开 ${mainPostId.toPostNumber()}');
          postListBack();
        },
        child: Text(
          text ?? '在新标签页后台打开',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
}

class CopyPostReference extends StatelessWidget {
  final int postId;

  final String? text;

  const CopyPostReference(this.postId, {super.key, this.text});

  @override
  Widget build(BuildContext context) => SimpleDialogOption(
        onPressed: () async {
          await Clipboard.setData(
              ClipboardData(text: postId.toPostReference()));
          showToast('已复制 ${postId.toPostReference()}');
          postListBack();
        },
        child: Text(
          text ?? '复制串号引用',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
}

class CopyPostContent extends StatelessWidget {
  final PostBase post;

  const CopyPostContent(this.post, {super.key});

  @override
  Widget build(BuildContext context) => SimpleDialogOption(
        onPressed: () async {
          await Clipboard.setData(
              ClipboardData(text: htmlToPlainText(context, post.content)));
          showToast(post.isNormalPost
              ? '已复制串 ${post.toPostNumber()} 的内容'
              : '已复制串的内容');
          postListBack();
        },
        child: Text('复制串的内容', style: Theme.of(context).textTheme.titleMedium),
      );
}

class Report extends StatelessWidget {
  final int postId;

  const Report(this.postId, {super.key});

  @override
  Widget build(BuildContext context) => SimpleDialogOption(
        onPressed: () {
          postListBack();
          AppRoutes.toEditPost(
            postListType: PostListType.forum,
            id: EditPost.dutyRoomId,
            forumId: EditPost.dutyRoomId,
            content: '${postId.toPostReference()}\n',
          );
        },
        child: Text('举报', style: Theme.of(context).textTheme.titleMedium),
      );
}

class BlockPost extends StatelessWidget {
  final int postId;

  final VoidCallback? onBlock;

  const BlockPost({super.key, required this.postId, this.onBlock});

  @override
  Widget build(BuildContext context) => SimpleDialogOption(
        onPressed: () async {
          final result = await postListDialog<bool>(ConfirmCancelDialog(
            content: '确定屏蔽串号 ${postId.toPostNumber()} ？',
            onConfirm: () => postListBack<bool>(result: true),
            onCancel: () => postListBack<bool>(result: false),
          ));

          if (result ?? false) {
            await BlacklistService.to.blockPost(postId);
            onBlock?.call();

            showToast('屏蔽串号 ${postId.toPostNumber()}');
            postListBack();
          }
        },
        child: Text('屏蔽串号', style: Theme.of(context).textTheme.titleMedium),
      );
}

class BlockUser extends StatelessWidget {
  final String userHash;

  final VoidCallback? onBlock;

  const BlockUser({super.key, required this.userHash, this.onBlock});

  @override
  Widget build(BuildContext context) => SimpleDialogOption(
        onPressed: () async {
          final result = await postListDialog<bool>(ConfirmCancelDialog(
            // autocorrect: false
            content: '确定屏蔽饼干 $userHash ？',
            // autocorrect: true
            onConfirm: () => postListBack<bool>(result: true),
            onCancel: () => postListBack<bool>(result: false),
          ));

          if (result ?? false) {
            await BlacklistService.to.blockUser(userHash);
            onBlock?.call();

            showToast('屏蔽饼干 $userHash');
            postListBack();
          }
        },
        child: Text('屏蔽饼干', style: Theme.of(context).textTheme.titleMedium),
      );
}

class SharePost extends StatelessWidget {
  final int mainPostId;

  final bool isOnlyPo;

  final int? page;

  final int? postId;

  const SharePost(
      {super.key,
      required this.mainPostId,
      this.isOnlyPo = false,
      this.page,
      this.postId});

  @override
  Widget build(BuildContext context) => SimpleDialogOption(
        onPressed: () async {
          await Clipboard.setData(ClipboardData(
              text: Urls.threadUrl(
                  mainPostId: mainPostId,
                  isOnlyPo: isOnlyPo,
                  // page 不等于 1 时才显示在链接里
                  page: page != 1 ? page : null,
                  postId: postId)));

          showToast('已复制串 ${mainPostId.toPostNumber()} 链接');
          postListBack();
        },
        child: Text('分享', style: Theme.of(context).textTheme.titleMedium),
      );
}

class AddOrEditTag extends StatelessWidget {
  final TagData? editedTag;

  final VoidCallback? onAdded;

  const AddOrEditTag({super.key, this.editedTag, this.onAdded});

  @override
  Widget build(BuildContext context) => SimpleDialogOption(
        onPressed: () async {
          final result = await postListDialog<bool>(
              _AddOrEditTagDialog(editedTag: editedTag, onAdded: onAdded));

          if (result ?? false) {
            postListBack();
          }
        },
        child: Text('${editedTag == null ? '添加' : '修改'}标签',
            style: Theme.of(context).textTheme.titleMedium),
      );
}

class DeleteTag extends StatelessWidget {
  final TagData tag;

  const DeleteTag(this.tag, {super.key});

  @override
  Widget build(BuildContext context) => SimpleDialogOption(
        onPressed: () async {
          final result = await postListDialog<bool>(ConfirmCancelDialog(
            contentWidget: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('确定删除标签'),
                Flexible(child: Tag.fromTagData(tag: tag)),
                const Text('？'),
              ].withSpaceBetween(width: 5.0),
            ),
            onConfirm: () async {
              await TagService.to.deleteTag(tag.id);

              showToast('删除标签 ${tag.name} 成功');
              postListBack<bool>(result: true);
            },
            onCancel: () => postListBack<bool>(result: false),
          ));

          if (result ?? false) {
            postListBack();
          }
        },
        child: Text('删除标签', style: Theme.of(context).textTheme.titleMedium),
      );
}

class AddOrReplacePostTag extends StatelessWidget {
  final PostBase post;

  final TagData? replacedTag;

  final ValueSetter<int>? onDeleteTag;

  const AddOrReplacePostTag(
      {super.key, required this.post, this.replacedTag, this.onDeleteTag});

  @override
  Widget build(BuildContext context) => SimpleDialogOption(
        onPressed: () async {
          final result = await postListDialog<bool>(AddOrReplacePostTagDialog(
              post: post, repacedTag: replacedTag, onDeleteTag: onDeleteTag));

          if (result ?? false) {
            postListBack();
          }
        },
        child: Text(
          '${replacedTag == null ? '添加' : '替换'}标签',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
}

class DeletePostTag extends StatelessWidget {
  final int postId;

  final TagData tag;

  final ValueSetter<int>? onDelete;

  const DeletePostTag(
      {super.key, required this.postId, required this.tag, this.onDelete});

  @override
  Widget build(BuildContext context) => SimpleDialogOption(
        onPressed: () async {
          final result = await postListDialog<bool>(ConfirmCancelDialog(
            contentWidget: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('确定删除串的标签'),
                Flexible(child: Tag.fromTagData(tag: tag)),
                const Text('？'),
              ].withSpaceBetween(width: 5.0),
            ),
            onConfirm: () async {
              await TagService.to.deletePostTag(postId: postId, tagId: tag.id);
              onDelete?.call(tag.id);

              showToast(postId.isNormalPost
                  ? '删除串 ${postId.toPostNumber()} 的标签 ${tag.name}'
                  : '删除串的标签 ${tag.name}');
              postListBack<bool>(result: true);
            },
            onCancel: () => postListBack<bool>(result: false),
          ));

          if (result ?? false) {
            postListBack();
          }
        },
        child: Text('删除标签', style: Theme.of(context).textTheme.titleMedium),
      );
}

class ToTaggedPostList extends StatelessWidget {
  final int tagId;

  const ToTaggedPostList(this.tagId, {super.key});

  @override
  Widget build(BuildContext context) => SimpleDialogOption(
        onPressed: () => AppRoutes.toTaggedPostList(tagId: tagId),
        child: Text('查询标签', style: Theme.of(context).textTheme.titleMedium),
      );
}

class NewTabToTaggedPostList extends StatelessWidget {
  final TagData tag;

  const NewTabToTaggedPostList(this.tag, {super.key});

  @override
  Widget build(BuildContext context) => SimpleDialogOption(
        onPressed: () {
          final controller = TaggedPostListController(id: tag.id, page: 1);
          postListBack();
          openNewTab(controller);
          showToast('已在新标签页查询标签 ${tag.name}');
        },
        child:
            Text('在新标签页查询标签', style: Theme.of(context).textTheme.titleMedium),
      );
}

class NewTabBackgroundToTaggedPostList extends StatelessWidget {
  final TagData tag;

  const NewTabBackgroundToTaggedPostList(this.tag, {super.key});

  @override
  Widget build(BuildContext context) => SimpleDialogOption(
        onPressed: () {
          final controller = TaggedPostListController(id: tag.id, page: 1);
          openNewTabBackground(controller);
          showToast('已在新标签页后台查询标签 ${tag.name}');
          postListBack();
        },
        child: Text(
          '在新标签页后台查询标签',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      );
}

class ApplyImageDialog extends StatelessWidget {
  final VoidCallback? onApply;

  final VoidCallback? onSave;

  final VoidCallback onCancel;

  final VoidCallback onNotSave;

  const ApplyImageDialog(
      {super.key,
      this.onApply,
      this.onSave,
      required this.onCancel,
      required this.onNotSave})
      : assert((onApply != null && onSave == null) ||
            (onApply == null && onSave != null));

  @override
  Widget build(BuildContext context) => AlertDialog(
        actionsPadding:
            const EdgeInsets.only(left: 10.0, right: 10.0, bottom: 10.0),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        content: onApply != null ? const Text('应用图片？') : const Text('保存图片？'),
        actions: [
          TextButton(onPressed: onCancel, child: const Text('取消')),
          TextButton(
              onPressed: onNotSave,
              child: onApply != null ? const Text('不应用') : const Text('不保存')),
          if (onSave != null)
            TextButton(onPressed: onSave, child: const Text('保存')),
          if (onApply != null)
            TextButton(onPressed: onApply, child: const Text('应用')),
        ],
      );
}

class NumRangeDialog<T extends num> extends StatelessWidget {
  final GlobalKey<FormFieldState<String>> _formKey =
      GlobalKey<FormFieldState<String>>();

  final String text;

  final T initialValue;

  final T min;

  final T? max;

  NumRangeDialog(
      {super.key,
      required this.text,
      required this.initialValue,
      required this.min,
      this.max});

  @override
  Widget build(BuildContext context) {
    String? number;

    // autocorrect: false
    return InputDialog(
      content: TextFormField(
        key: _formKey,
        decoration: InputDecoration(
            labelText:
                max != null ? '$text（ $min - $max ）' : '$text（ >= $min ）'),
        autofocus: true,
        keyboardType:
            const TextInputType.numberWithOptions(signed: true, decimal: true),
        initialValue: '$initialValue',
        onSaved: (newValue) => number = newValue,
        validator: (value) {
          if (value != null && value.isNotEmpty) {
            try {
              final num? n = T == double
                  ? double.tryParse(value)
                  : (T == int ? int.tryParse(value) : num.tryParse(value));

              if (n != null) {
                if (max != null) {
                  if (n >= min && n <= max!) {
                    return null;
                  } else {
                    return '$text必须在$min与$max之间';
                  }
                } else {
                  if (n >= min) {
                    return null;
                  } else {
                    return '$text必须大于等于$min';
                  }
                }
              } else {
                return '请输入$text数字';
              }
            } catch (e) {
              return '请输入$text数字';
            }
          } else {
            return '请输入$text数字';
          }
        },
      ),
      actions: [
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();

              Get.back<T>(
                  result: (T == double
                      ? double.parse(number!)
                      : (T == int
                          ? int.parse(number!)
                          : num.parse(number!))) as T);
            }
          },
          child: const Text('确定'),
        )
      ],
    );
    // autocorrect: true
  }
}

class RewardQRCode extends StatelessWidget {
  const RewardQRCode({super.key});

  @override
  Widget build(BuildContext context) => AlertDialog(
        actionsPadding: const EdgeInsets.only(right: 20.0, bottom: 20.0),
        title: const Text('微信赞赏码'),
        content:
            const Image(image: AssetImage('assets/image/reward_qrcode.png')),
        actions: [
          TextButton(
            onPressed: () async {
              final data = await DefaultAssetBundle.of(context)
                  .load('assets/image/reward_qrcode.png');
              await saveImageData(
                  data.buffer.asUint8List(), 'reward_qrcode.png');

              Get.back();
            },
            child: const Text('保存'),
          ),
        ],
      );
}

class EditCookieDialog extends StatelessWidget {
  final CookieData cookie;

  final bool setColor;

  const EditCookieDialog(
      {super.key, required this.cookie, this.setColor = false});

  @override
  Widget build(BuildContext context) {
    final user = UserService.to;
    String? note = cookie.note;
    final Rx<Color> color = Rx(cookie.color);

    return InputDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            decoration: const InputDecoration(labelText: '备注'),
            autofocus: !setColor,
            initialValue: cookie.note,
            onChanged: (value) => note = value,
          ),
          if (setColor) const SizedBox(height: 15.0),
          if (setColor)
            Obx(
              () => ColorListTile(
                title: const Text('颜色'),
                color: color.value,
                onColorChanged: (value) => color.value = value,
              ),
            ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () async {
            await user.setCookieNote(
                cookie, (note?.isNotEmpty ?? false) ? note : null);
            if (setColor) {
              await user.setCookieColor(cookie, color.value);
            }

            Get.back(result: true);
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}

class EditCookieNote extends StatelessWidget {
  final CookieData cookie;

  const EditCookieNote(this.cookie, {super.key});

  @override
  Widget build(BuildContext context) => SimpleDialogOption(
        onPressed: () async {
          if (await Get.dialog<bool>(EditCookieDialog(cookie: cookie)) ??
              false) {
            Get.back();
          }
        },
        child: Text('编辑饼干备注', style: Theme.of(context).textTheme.titleMedium),
      );
}

class SetCookieColor extends StatelessWidget {
  final CookieData cookie;

  const SetCookieColor(this.cookie, {super.key});

  @override
  Widget build(BuildContext context) => SimpleDialogOption(
        onPressed: () async {
          Color? color;
          final result = await Get.dialog<bool>(ConfirmCancelDialog(
            contentWidget: MaterialPicker(
              pickerColor: cookie.color,
              onColorChanged: (value) => color = value,
              enableLabel: true,
            ),
            onConfirm: () {
              if (color != null) {
                UserService.to.setCookieColor(cookie, color!);
                Get.back(result: true);
              } else {
                Get.back(result: false);
              }
            },
            onCancel: () => Get.back(result: false),
          ));

          if (result ?? false) {
            Get.back();
          }
        },
        child: Text('设置饼干颜色', style: Theme.of(context).textTheme.titleMedium),
      );
}

class _SetTagColor extends StatefulWidget {
  final List<Widget> children;

  // ignore: unused_element
  const _SetTagColor({super.key, required this.children});

  @override
  State<_SetTagColor> createState() => _SetTagColorState();
}

class _SetTagColorState extends State<_SetTagColor> {
  final ExpandedTileController _controller = ExpandedTileController();

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ExpandedTile(
      controller: _controller,
      contentseparator: 0.0,
      theme: ExpandedTileThemeData(
        headerColor: theme.cardColor,
        headerSplashColor: theme.cardColor,
        headerPadding: const EdgeInsets.symmetric(vertical: 5.0),
        headerBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero),
        titlePadding: EdgeInsets.zero,
        contentBackgroundColor: theme.cardColor,
        contentPadding: EdgeInsets.zero,
        contentBorder:
            const OutlineInputBorder(borderRadius: BorderRadius.zero),
      ),
      title: Text('设置标签颜色', style: theme.textTheme.titleMedium),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: widget.children,
      ),
    );
  }
}

class _AddOrEditTagDialog extends StatelessWidget {
  final GlobalKey<FormFieldState<String>> _formKey =
      GlobalKey<FormFieldState<String>>();

  final TagData? editedTag;

  final VoidCallback? onAdded;

  final RxnString _tagName;

  final RxBool _useDefaultColor;

  final Rxn<Color> _userBackgroundColor;

  final Rxn<Color> _userTextColor;

  Color? get _backgroundColor => !_useDefaultColor.value
      ? (_userBackgroundColor.value ?? Get.theme.primaryColor)
      : null;

  Color? get _textColor => !_useDefaultColor.value
      ? (_userTextColor.value ?? Get.theme.colorScheme.onPrimary)
      : null;

  String get _text => editedTag == null ? '添加' : '修改';

  String? get _name => editedTag?.name ?? _tagName.value;

  // ignore: unused_element
  _AddOrEditTagDialog({super.key, this.editedTag, this.onAdded})
      : _tagName = RxnString(editedTag?.name),
        _useDefaultColor = (editedTag?.useDefaultColor ?? true).obs,
        _userBackgroundColor = Rxn(editedTag?.backgroundColor),
        _userTextColor = Rxn(editedTag?.textColor);

  @override
  Widget build(BuildContext context) {
    final tagService = TagService.to;
    final theme = Theme.of(context);

    return InputDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() => (_tagName.value?.isNotEmpty ?? false)
              ? Tag(
                  text: _tagName.value!,
                  textStyle: AppTheme.postContentTextStyle,
                  strutStyle: AppTheme.postContentStrutStyle,
                  backgroundColor: _backgroundColor,
                  textColor: _textColor)
              : const SizedBox.shrink()),
          TextFormField(
            key: _formKey,
            decoration: const InputDecoration(labelText: '标签'),
            initialValue: _tagName.value,
            onChanged: (value) => _tagName.value = value,
            onSaved: (newValue) => _tagName.value = newValue,
            validator: (value) => (value == null || value.isEmpty)
                ? '请输入标签名字'
                : (((editedTag == null && tagService.tagNameExists(value)) ||
                        (editedTag != null &&
                            value != editedTag!.name &&
                            tagService.tagNameExists(value)))
                    ? '已存在该标签名字'
                    : null),
          ),
          const SizedBox(height: 5.0),
          _SetTagColor(children: [
            Obx(
              () => TightCheckboxListTile(
                title: const Text('配色跟随应用主题'),
                value: _useDefaultColor.value,
                onChanged: (value) {
                  if (value != null) {
                    _useDefaultColor.value = value;
                  }
                },
              ),
            ),
            Obx(
              () => ColorListTile(
                enabled: !_useDefaultColor.value,
                title: const Text('文字颜色'),
                color: _textColor ?? theme.colorScheme.onPrimary,
                onColorChanged: (value) => _userTextColor.value = value,
              ),
            ),
            Obx(
              () => ColorListTile(
                enabled: !_useDefaultColor.value,
                title: const Text('背景颜色'),
                color: _backgroundColor ?? theme.primaryColor,
                onColorChanged: (value) => _userBackgroundColor.value = value,
              ),
            )
          ]),
        ],
      ),
      actions: [
        // autocorrect: false
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();

              if (_tagName.value != null) {
                try {
                  if (editedTag == null) {
                    await tagService.getTagIdOrAddNewTag(
                        tagName: _tagName.value!,
                        backgroundColor: _backgroundColor,
                        textColor: _textColor);

                    onAdded?.call();
                  } else {
                    if (!await tagService.editTag(editedTag!.copyWith(
                        name: _tagName.value,
                        backgroundColor: _backgroundColor,
                        textColor: _textColor))) {
                      showToast('修改标签 ${editedTag?.name} 失败');

                      return;
                    }
                  }

                  showToast('$_text标签 $_name 成功');
                  postListBack<bool>(result: true);
                } catch (e) {
                  showToast('$_text标签 $_name 失败：$e');
                }
              }
            }
          },
          child: Text(_text),
        ),
        // autocorrect: true
      ],
    );
  }
}

class AddOrReplacePostTagDialog extends StatefulWidget {
  final PostBase post;

  final TagData? repacedTag;

  final ValueSetter<int>? onDeleteTag;

  const AddOrReplacePostTagDialog(
      {super.key, required this.post, this.repacedTag, this.onDeleteTag});

  @override
  State<AddOrReplacePostTagDialog> createState() =>
      _AddOrReplacePostTagDialogState();
}

class _AddOrReplacePostTagDialogState extends State<AddOrReplacePostTagDialog> {
  final GlobalKey<FormFieldState<String>> _formKey =
      GlobalKey<FormFieldState<String>>();

  late final TextEditingController _controller;

  late final RxString _tagName;

  late final Rxn<TagData> _existingTag;

  final RxBool _userUseDefaultColor = true.obs;

  final Rxn<Color> _userBackgroundColor = Rxn(null);

  final Rxn<Color> _userTextColor = Rxn(null);

  PostBase get _post => widget.post;

  TagData? get _replacedTag => widget.repacedTag;

  bool get _tagExists => _existingTag.value != null;

  bool get _useDefaultColor =>
      _existingTag.value?.useDefaultColor ?? _userUseDefaultColor.value;

  Color? get _backgroundColor => !_useDefaultColor
      ? (_existingTag.value?.backgroundColor ??
          _userBackgroundColor.value ??
          Get.theme.primaryColor)
      : null;

  Color? get _textColor => !_useDefaultColor
      ? (_existingTag.value?.textColor ??
          _userTextColor.value ??
          Get.theme.colorScheme.onPrimary)
      : null;

  String get _text => _replacedTag == null
      ? '添加标签 ${_controller.text} '
      : '替换标签 ${_replacedTag?.name} 为 ${_controller.text} ';

  void _onTextChanged({String? text, TagData? tag}) {
    assert((text != null && tag == null) || (text == null && tag != null));

    if (text != null) {
      tag = TagService.to.getTagDataFromName(text);
    }

    if (tag != null) {
      _tagName.value = tag.name;
      if (text == null) {
        _controller.text = tag.name;
      }
      _existingTag.value = tag;
    } else {
      _tagName.value = text!;
      _existingTag.value = null;
    }
  }

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: _replacedTag?.name);
    _tagName = (_replacedTag?.name ?? '').obs;
    _existingTag = Rxn(_replacedTag);
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tagService = TagService.to;
    final data = PersistentDataService.to;
    final theme = Theme.of(context);

    return InputDialog(
      title: _post.isNormalPost ? Text(_post.toPostNumber()) : null,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() => _tagName.value.isNotEmpty
              ? Tag(
                  text: _tagName.value,
                  textStyle: AppTheme.postContentTextStyle,
                  strutStyle: AppTheme.postContentStrutStyle,
                  backgroundColor: _backgroundColor,
                  textColor: _textColor)
              : const SizedBox.shrink()),
          TextFormField(
            key: _formKey,
            controller: _controller,
            decoration: const InputDecoration(labelText: '标签'),
            onChanged: (value) => _onTextChanged(text: value),
            validator: (value) => (value == null || value.isEmpty)
                ? '请输入标签名字'
                : ((_replacedTag != null &&
                        _replacedTag!.name == _controller.text)
                    ? '同一个标签'
                    : null),
          ),
          const SizedBox(height: 5.0),
          _SetTagColor(children: [
            Obx(
              () => TightCheckboxListTile(
                enabled: !_tagExists,
                title: const Text('配色跟随应用主题'),
                value: _useDefaultColor,
                onChanged: (value) {
                  if (value != null) {
                    _userUseDefaultColor.value = value;
                  }
                },
              ),
            ),
            Obx(
              () => ColorListTile(
                enabled: !(_tagExists || _useDefaultColor),
                title: const Text('文字颜色'),
                color: _textColor ?? theme.colorScheme.onPrimary,
                onColorChanged: (value) => _userTextColor.value = value,
              ),
            ),
            Obx(
              () => ColorListTile(
                enabled: !(_tagExists || _useDefaultColor),
                title: const Text('背景颜色'),
                color: _backgroundColor ?? theme.primaryColor,
                onColorChanged: (value) => _userBackgroundColor.value = value,
              ),
            )
          ]),
          if (data.recentTags.isNotEmpty) const SizedBox(height: 5.0),
          if (data.recentTags.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('最近使用'),
                const SizedBox(width: 10.0),
                Flexible(
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 10.0,
                    runSpacing: 5.0,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      for (final tag in tagService.getTagsData(data.recentTags))
                        Tag.fromTagData(
                          tag: tag,
                          textStyle: AppTheme.postContentTextStyle,
                          strutStyle: AppTheme.postContentStrutStyle,
                          onTap: () => _onTextChanged(tag: tag),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          if (data.recentTags.isNotEmpty) const SizedBox(height: 5.0),
        ],
      ),
      actions: [
        // autocorrect: false
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              try {
                final tagId = await tagService.getTagIdOrAddNewTag(
                    tagName: _controller.text,
                    backgroundColor: _backgroundColor,
                    textColor: _textColor);

                if (_replacedTag == null) {
                  await tagService.addPostTag(_post, tagId);
                } else if (_replacedTag!.id != tagId) {
                  await tagService.replacePostTag(
                      postId: _post.id,
                      oldTagId: _replacedTag!.id,
                      newTagId: tagId);
                  widget.onDeleteTag?.call(_replacedTag!.id);
                }

                showToast(_post.isNormalPost
                    ? '给串 ${_post.toPostNumber()} $_text成功'
                    : '给串$_text成功');
                postListBack<bool>(result: true);
              } catch (e) {
                showToast(_post.isNormalPost
                    ? '给串 ${_post.toPostNumber()} $_text失败：$e'
                    : '给串$_text失败：$e');
              }
            }
          },
          child: Text(_replacedTag == null ? '添加' : '替换'),
        ),
        // autocorrect: true
      ],
    );
  }
}

class SavedPostDialog extends StatelessWidget {
  final PostBase post;

  final int? mainPostId;

  final int? page;

  final bool confirmDelete;

  final VoidCallback? onDelete;

  final List<Widget>? children;

  const SavedPostDialog(
      {super.key,
      required this.post,
      this.mainPostId,
      this.page,
      this.confirmDelete = true,
      this.onDelete,
      this.children});

  bool get _hasPostId => post.isNormalPost;

  bool get _hasMainPostId => mainPostId != null;

  bool get _isMainPost => _hasPostId ? post.id == mainPostId : false;

  bool get _hasNonMainPostId => !_isMainPost && _hasPostId;

  @override
  Widget build(BuildContext context) => SimpleDialog(
        title: _hasPostId ? Text(post.toPostNumber()) : null,
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
                  onDelete?.call();
                  postListBack();
                }
              } else {
                onDelete?.call();
                postListBack();
              }
            },
            child: Text('删除', style: Theme.of(context).textTheme.titleMedium),
          ),
          if (_hasMainPostId)
            SharePost(
              mainPostId: mainPostId!,
              page: page,
              postId: _hasNonMainPostId ? post.id : null,
            ),
          if (children != null) ...children!,
          AddOrReplacePostTag(post: post),
          if (_hasPostId) CopyPostReference(post.id),
          CopyPostContent(post),
          if (!_isMainPost && _hasMainPostId)
            CopyPostReference(mainPostId!, text: '复制主串串号引用'),
          if (_hasMainPostId)
            NewTab(
                mainPostId: mainPostId!,
                page: page ?? 1,
                mainPost: _isMainPost ? post : null,
                jumpToId: (_hasNonMainPostId && page != null) ? post.id : null,
                text: !_isMainPost ? '在新标签页打开主串' : null),
          if (_hasMainPostId)
            NewTabBackground(
                mainPostId: mainPostId!,
                page: page ?? 1,
                mainPost: _isMainPost ? post : null,
                jumpToId: (_hasNonMainPostId && page != null) ? post.id : null,
                text: !_isMainPost ? '在新标签页后台打开主串' : null),
        ],
      );
}

class SearchDialog extends StatelessWidget {
  final GlobalKey<FormFieldState<String>> _formKey =
      GlobalKey<FormFieldState<String>>();

  final Search? search;

  final ValueSetter<Search>? onSearch;

  final RxBool caseSensitive;

  final RxBool useWildcard;

  SearchDialog({super.key, this.search, this.onSearch})
      : caseSensitive = (search?.caseSensitive ?? false).obs,
        useWildcard = (search?.useWildcard ?? false).obs;

  @override
  Widget build(BuildContext context) {
    String? searchText;

    return InputDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            key: _formKey,
            decoration: const InputDecoration(labelText: '搜索内容'),
            autofocus: true,
            initialValue: search?.text,
            onSaved: (newValue) => searchText = newValue,
            validator: (value) =>
                (value == null || value.isEmpty) ? '请输入搜索内容' : null,
          ),
          Obx(
            () => TightCheckboxListTile(
              title: const Text('英文字母区分大小写'),
              value: caseSensitive.value,
              onChanged: (value) {
                if (value != null) {
                  caseSensitive.value = value;
                }
              },
            ),
          ),
          Obx(
            () => TightCheckboxListTile(
              title: const Text('使用通配符'),
              value: useWildcard.value,
              onChanged: (value) {
                if (value != null) {
                  useWildcard.value = value;
                }
              },
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            postListDialog(const ConfirmCancelDialog(
              // autocorrect: false
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
              // autocorrect: true
              onConfirm: postListBack,
            ));
          },
          child: const Text('搜索说明'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();

              onSearch?.call(Search(
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

class ClearDialog extends StatelessWidget {
  final String text;

  final String? textWidgetPrefix;

  final Widget? textWidget;

  final AsyncCallback? onClear;

  const ClearDialog(
      {super.key,
      this.text = '',
      this.textWidgetPrefix = '',
      this.textWidget,
      this.onClear});

  @override
  Widget build(BuildContext context) => LoaderOverlay(
        child: ConfirmCancelDialog(
          content: textWidget == null ? '确定清空$text？' : null,
          contentWidget: textWidget != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('确定清空$textWidgetPrefix'),
                    Flexible(child: textWidget!),
                    const Text('？'),
                  ].withSpaceBetween(width: 5.0),
                )
              : null,
          onConfirm: () async {
            final overlay = context.loaderOverlay;
            try {
              overlay.show();

              await onClear?.call();
              showToast('清空$text');
            } catch (e) {
              // autocorrect: false
              showToast('清空$text失败：$e');
              // autocorrect: true
            } finally {
              if (overlay.visible) {
                overlay.hide();
              }
            }

            WidgetsBinding.instance
                .addPostFrameCallback((timeStamp) => postListBack());
          },
          onCancel: postListBack,
        ),
      );
}
