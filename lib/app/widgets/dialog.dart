import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../data/services/blacklist.dart';
import '../data/services/forum.dart';
import '../data/services/persistent.dart';
import '../data/services/settings.dart';
import '../modules/post_list.dart';
import '../routes/routes.dart';
import '../utils/cache.dart';
import '../utils/exception.dart';
import '../utils/extensions.dart';
import '../utils/navigation.dart';
import '../utils/text.dart';
import '../utils/theme.dart';
import '../utils/toast.dart';
import '../utils/url.dart';
import 'content.dart';
import 'edit_post.dart';
import 'forum_name.dart';
import 'loading.dart';
import 'scroll.dart';
import 'thread.dart';

Future<T?> postListDialog<T>(
  Widget widget, {
  int? index,
  bool barrierDismissible = true,
  Color? barrierColor,
  bool useSafeArea = true,
  Object? arguments,
  Duration? transitionDuration,
  Curve? transitionCurve,
  String? name,
  RouteSettings? routeSettings,
}) =>
    Get.dialog<T>(
      widget,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      useSafeArea: useSafeArea,
      navigatorKey: postListkey(index),
      arguments: arguments,
      transitionDuration: transitionDuration,
      transitionCurve: transitionCurve,
      name: name,
      routeSettings: routeSettings,
    );

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
      this.cancelText});

  @override
  Widget build(BuildContext context) {
    final fontSize = Theme.of(context).textTheme.subtitle1?.fontSize;

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

class NoticeDialog extends StatelessWidget {
  final bool showCheckbox;

  final bool isAutoUpdate;

  const NoticeDialog(
      {super.key, this.showCheckbox = false, this.isAutoUpdate = false});

  @override
  Widget build(BuildContext context) {
    final data = PersistentDataService.to;
    final settings = SettingsService.to;
    final textStyle = Theme.of(context).textTheme.subtitle1;
    final isCheck = false.obs;

    return AlertDialog(
      actionsPadding:
          const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
      actionsAlignment:
          showCheckbox ? MainAxisAlignment.spaceBetween : MainAxisAlignment.end,
      contentPadding: const EdgeInsets.fromLTRB(24.0, 10.0, 24.0, 5.0),
      title: const Text('公告'),
      content: SingleChildScrollViewWithScrollbar(
        child: isAutoUpdate
            ? FutureBuilder<void>(
                future: data.updateNotice(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.hasError) {
                    showToast(exceptionMessage(snapshot.error!));

                    return const Text('加载失败', style: AppTheme.boldRed);
                  }

                  if (snapshot.connectionState == ConnectionState.done) {
                    return TextContent(
                      text: data.notice,
                      onLinkTap: (context, link, text) => parseUrl(url: link),
                    );
                  }

                  return const Center(child: CircularProgressIndicator());
                },
              )
            : TextContent(
                text: data.notice,
                onLinkTap: (context, link, text) => parseUrl(url: link),
              ),
      ),
      actions: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showCheckbox)
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: Obx(
                      () => Checkbox(
                        value: isCheck.value,
                        onChanged: (value) {
                          if (value != null) {
                            isCheck.value = value;
                          }
                        },
                      ),
                    ),
                  ),
                  Text('不再提示此条公告', style: textStyle),
                ],
              ),
            Row(
              children: [
                const Spacer(),
                TextButton(
                  onPressed: () {
                    if (showCheckbox) {
                      settings.showNotice = !isCheck.value;
                    }
                    postListBack();
                  },
                  child: Text('确定',
                      style: TextStyle(fontSize: textStyle?.fontSize)),
                ),
              ],
            ),
          ],
        )
      ],
    );
  }
}

// TODO: 废弃板块自动更新最新版规
class ForumRuleDialog extends StatelessWidget {
  final int forumId;

  const ForumRuleDialog(this.forumId, {super.key});

  @override
  Widget build(BuildContext context) {
    final forum = ForumListService.to.forum(forumId);

    return AlertDialog(
      actionsPadding: const EdgeInsets.only(right: 20.0, bottom: 20.0),
      title: forum != null
          ? ForumName(
              forumId: forum.id,
              trailing: ' 版规',
              textStyle: Theme.of(context).textTheme.headline6,
              maxLines: 1)
          : const Text('版规'),
      content: SingleChildScrollViewWithScrollbar(
          child: TextContent(
        text: forum?.message ?? '',
        onLinkTap: (context, link, text) => parseUrl(url: link),
        onImage: (context, image, element) => image != null
            ? TextSpan(
                children: [
                  WidgetSpan(
                    child: CachedNetworkImage(
                      imageUrl: image,
                      cacheManager: XdnmbImageCacheManager(),
                      progressIndicatorBuilder:
                          loadingThumbImageIndicatorBuilder,
                      errorWidget: loadingImageErrorBuilder,
                    ),
                  ),
                  const TextSpan(text: '\n'),
                ],
              )
            : const TextSpan(),
      )),
      actions: [
        TextButton(
          onPressed: () => postListBack(),
          child: Text(
            '确定',
            style: TextStyle(
              fontSize: Theme.of(context).textTheme.subtitle1?.fontSize,
            ),
          ),
        ),
      ],
    );
  }
}

class NewTab extends StatelessWidget {
  final PostBase post;

  final String? text;

  const NewTab(this.post, {super.key, this.text});

  @override
  Widget build(BuildContext context) => SimpleDialogOption(
        onPressed: () {
          final controller = ThreadTypeController.fromPost(post: post);
          postListBack();
          openNewTab(controller);
          showToast('已在新标签页打开 ${post.toPostNumber()}');
        },
        child: Text(
          text ?? '在新标签页打开',
          style: Theme.of(context).textTheme.subtitle1,
        ),
      );
}

class NewTabBackground extends StatelessWidget {
  final PostBase post;

  final String? text;

  const NewTabBackground(this.post, {super.key, this.text});

  @override
  Widget build(BuildContext context) => SimpleDialogOption(
        onPressed: () {
          final controller = ThreadTypeController.fromPost(post: post);
          openNewTabBackground(controller);
          showToast('已在新标签页后台打开 ${post.toPostNumber()}');
          postListBack();
        },
        child: Text(
          text ?? '在新标签页后台打开',
          style: Theme.of(context).textTheme.subtitle1,
        ),
      );
}

class CopyPostId extends StatelessWidget {
  final int postId;

  final String? text;

  const CopyPostId(this.postId, {super.key, this.text});

  @override
  Widget build(BuildContext context) => SimpleDialogOption(
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: '$postId'));
          showToast('已复制 $postId');
          postListBack();
        },
        child:
            Text(text ?? '复制串号', style: Theme.of(context).textTheme.subtitle1),
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
          style: Theme.of(context).textTheme.subtitle1,
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
          showToast('已复制串 ${post.toPostNumber()} 的内容');
          postListBack();
        },
        child: Text('复制串的内容', style: Theme.of(context).textTheme.subtitle1),
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
              content: '${postId.toPostReference()}\n',
              forumId: EditPost.dutyRoomId);
        },
        child: Text('举报', style: Theme.of(context).textTheme.subtitle1),
      );
}

class BlockPost extends StatelessWidget {
  final int postId;

  final VoidCallback onBlock;

  const BlockPost({super.key, required this.postId, required this.onBlock});

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
            onBlock();
            showToast('屏蔽串号 ${postId.toPostNumber()}');
            postListBack();
          }
        },
        child: Text('屏蔽串号', style: Theme.of(context).textTheme.subtitle1),
      );
}

class BlockUser extends StatelessWidget {
  final String userHash;

  final VoidCallback onBlock;

  const BlockUser({super.key, required this.userHash, required this.onBlock});

  @override
  Widget build(BuildContext context) {
    return SimpleDialogOption(
      onPressed: () async {
        final result = await postListDialog<bool>(ConfirmCancelDialog(
          content: '确定屏蔽饼干 $userHash ？',
          onConfirm: () => postListBack<bool>(result: true),
          onCancel: () => postListBack<bool>(result: false),
        ));

        if (result ?? false) {
          await BlacklistService.to.blockUser(userHash);
          onBlock();
          showToast('屏蔽饼干 $userHash');
          postListBack();
        }
      },
      child: Text('屏蔽饼干', style: Theme.of(context).textTheme.subtitle1),
    );
  }
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
          TextButton(
              onPressed: onNotSave,
              child: onApply != null ? const Text('不应用') : const Text('不保存')),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(onPressed: onCancel, child: const Text('取消')),
              if (onSave != null)
                TextButton(onPressed: onSave, child: const Text('保存')),
              if (onApply != null)
                TextButton(onPressed: onApply, child: const Text('应用')),
            ],
          ),
        ],
      );
}
