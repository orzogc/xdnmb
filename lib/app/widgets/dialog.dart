import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:html_to_text/html_to_text.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../data/services/forum.dart';
import '../data/services/persistent.dart';
import '../data/services/settings.dart';
import '../modules/post_list.dart';
import '../routes/routes.dart';
import '../utils/cache.dart';
import '../utils/extensions.dart';
import '../utils/navigation.dart';
import '../utils/toast.dart';
import '../utils/url.dart';
import 'content.dart';
import 'edit_post.dart';
import 'loading.dart';
import 'scroll.dart';

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

Future<T?> showNoticeDialog<T>({bool showCheckbox = false}) =>
    postListDialog<T>(NoticeDialog(showCheckbox: showCheckbox));

Future<T?> showForumRuleDialog<T>(PostListController controller) =>
    postListDialog<T>(ForumRuleDialog(controller));

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

  final String? content;

  final VoidCallback? onConfirm;

  final VoidCallback? onCancel;

  final String? confirmText;

  final String? cancelText;

  const ConfirmCancelDialog(
      {super.key,
      this.title,
      this.content,
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
      title: title != null ? Text(title!) : null,
      content: content != null
          ? SingleChildScrollViewWithScrollbar(child: Text(content!))
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

  const NoticeDialog({super.key, this.showCheckbox = false});

  @override
  Widget build(BuildContext context) {
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
        child: TextContent(
          text: PersistentDataService.to.notice,
          onLinkTap: (context, link) => parseUrl(url: link),
        ),
      ),
      actions: [
        if (showCheckbox)
          Row(
            mainAxisSize: MainAxisSize.min,
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
        TextButton(
          onPressed: () {
            if (showCheckbox) {
              settings.showNotice = !isCheck.value;
            }
            postListBack();
          },
          child: Text('确定', style: TextStyle(fontSize: textStyle?.fontSize)),
        )
      ],
    );
  }
}

class ForumRuleDialog extends StatelessWidget {
  final PostListController controller;

  const ForumRuleDialog(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.headline6;

    return Obx(
      () {
        final forum = ForumListService.to.forum(controller.id.value!);

        return AlertDialog(
          actionsPadding: const EdgeInsets.only(right: 20.0, bottom: 20.0),
          title: forum != null
              ? RichText(
                  text: TextSpan(
                    children: [
                      htmlToTextSpan(context, forum.forumName,
                          textStyle: textStyle),
                      const TextSpan(text: ' 版规'),
                    ],
                    style: textStyle,
                  ),
                )
              : const Text('版规'),
          content: SingleChildScrollViewWithScrollbar(
              child: TextContent(
            text: forum?.message ?? '',
            onLinkTap: (context, link) => parseUrl(url: link),
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
            )
          ],
        );
      },
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
          final controller = PostListController.fromPost(post: post);
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
          final controller = PostListController.fromPost(post: post);
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
  final PostBase post;

  final String? text;

  const CopyPostId(this.post, {super.key, this.text});

  @override
  Widget build(BuildContext context) => SimpleDialogOption(
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: '${post.id}'));
          showToast('已复制 ${post.id}');
          postListBack();
        },
        child:
            Text(text ?? '复制串号', style: Theme.of(context).textTheme.subtitle1),
      );
}

class CopyPostReference extends StatelessWidget {
  final PostBase post;

  final String? text;

  const CopyPostReference(this.post, {super.key, this.text});

  @override
  Widget build(BuildContext context) => SimpleDialogOption(
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: post.toPostReference()));
          showToast('已复制 ${post.toPostReference()}');
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
          await Clipboard.setData(ClipboardData(
              text: htmlToTextSpan(context, post.content).toPlainText()));
          showToast('已复制串 ${post.id.toPostNumber()} 的内容');
          postListBack();
        },
        child: Text('复制串的内容', style: Theme.of(context).textTheme.subtitle1),
      );
}

class Report extends StatelessWidget {
  final PostBase post;

  const Report(this.post, {super.key});

  @override
  Widget build(BuildContext context) => SimpleDialogOption(
        onPressed: () {
          postListBack();
          AppRoutes.toEditPost(
              postListType: PostListType.forum,
              id: EditPost.dutyRoomId,
              content: '${post.toPostReference()}\n',
              forumId: EditPost.dutyRoomId);
        },
        child: Text('举报', style: Theme.of(context).textTheme.subtitle1),
      );
}

class SaveImageDialog extends StatelessWidget {
  final VoidCallback onSave;

  final VoidCallback onNotSave;

  const SaveImageDialog(
      {super.key, required this.onSave, required this.onNotSave});

  @override
  Widget build(BuildContext context) => ConfirmCancelDialog(
        content: '保存图片？',
        onConfirm: onSave,
        onCancel: onNotSave,
        confirmText: '保存',
        cancelText: '不保存',
      );
}
