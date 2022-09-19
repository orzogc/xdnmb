import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:html_to_text/html_to_text.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../data/services/forum.dart';
import '../data/services/persistent.dart';
import '../data/services/settings.dart';
import '../data/services/xdnmb_client.dart';
import '../modules/post_list.dart';
import '../utils/cache.dart';
import '../utils/extensions.dart';
import '../utils/navigation.dart';
import '../utils/toast.dart';
import '../utils/url.dart';
import 'content.dart';
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

  const ConfirmCancelDialog(
      {super.key, this.title, this.content, this.onConfirm, this.onCancel});

  @override
  Widget build(BuildContext context) {
    final fontSize = Theme.of(context).textTheme.subtitle1?.fontSize;

    return AlertDialog(
      actionsPadding: const EdgeInsets.only(right: 10.0, bottom: 10.0),
      title: title != null ? Text(title!) : null,
      content: content != null
          ? SingleChildScrollViewWithScrollbar(child: Text(content!))
          : null,
      actions: (onConfirm != null || onCancel != null)
          ? [
              if (onCancel != null)
                TextButton(
                  onPressed: onCancel!,
                  child: Text('取消', style: TextStyle(fontSize: fontSize)),
                ),
              if (onConfirm != null)
                TextButton(
                  onPressed: onConfirm!,
                  child: Text('确定', style: TextStyle(fontSize: fontSize)),
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
    final fontSize = Theme.of(context).textTheme.subtitle1?.fontSize;
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
              Text('不再提示此条公告', style: TextStyle(fontSize: fontSize)),
            ],
          ),
        TextButton(
          onPressed: () {
            if (showCheckbox) {
              settings.showNotice = !isCheck.value;
            }
            postListBack();
          },
          child: Text(
            '确定',
            style: TextStyle(fontSize: fontSize),
          ),
        )
      ],
    );
  }
}

// TODO: 显示图片
class ForumRuleDialog extends StatelessWidget {
  final PostListController controller;

  const ForumRuleDialog(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.headline6;

    return Obx(() {
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
                  fontSize: Theme.of(context).textTheme.subtitle1?.fontSize),
            ),
          )
        ],
      );
    });
  }
}

class NewTab extends StatelessWidget {
  final PostBase post;

  const NewTab(this.post, {super.key});

  @override
  Widget build(BuildContext context) => SimpleDialogOption(
        onPressed: () {
          final controller = PostListController.fromPost(post: post);
          postListBack();
          openNewTab(controller);
          showToast('已在新标签页打开 ${post.toPostNumber()}');
        },
        child: Text(
          '在新标签页打开',
          style: TextStyle(
              fontSize: Theme.of(context).textTheme.subtitle1?.fontSize),
        ),
      );
}

class NewTabBackground extends StatelessWidget {
  final PostBase post;

  const NewTabBackground(this.post, {super.key});

  @override
  Widget build(BuildContext context) => SimpleDialogOption(
        onPressed: () {
          final controller = PostListController.fromPost(post: post);
          openNewTabBackground(controller);
          showToast('已在新标签页后台打开 ${post.toPostNumber()}');
          postListBack();
        },
        child: Text(
          '在新标签页后台打开',
          style: TextStyle(
              fontSize: Theme.of(context).textTheme.subtitle1?.fontSize),
        ),
      );
}

class CopyPostId extends StatelessWidget {
  final PostBase post;

  const CopyPostId(this.post, {super.key});

  @override
  Widget build(BuildContext context) => SimpleDialogOption(
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: '${post.id}'));
          showToast('已复制 ${post.id}');
          postListBack();
        },
        child: Text(
          '复制串号',
          style: TextStyle(
              fontSize: Theme.of(context).textTheme.subtitle1?.fontSize),
        ),
      );
}

class CopyPostNumber extends StatelessWidget {
  final PostBase post;

  const CopyPostNumber(this.post, {super.key});

  @override
  Widget build(BuildContext context) => SimpleDialogOption(
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: post.toPostReference()));
          showToast('已复制 ${post.toPostReference()}');
          postListBack();
        },
        child: Text(
          '复制串号引用',
          style: TextStyle(
              fontSize: Theme.of(context).textTheme.subtitle1?.fontSize),
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
          showToast('已复制串 ${post.id.toPostNumber()} 内容');
          postListBack();
        },
        child: Text(
          '复制串的内容',
          style: TextStyle(
              fontSize: Theme.of(context).textTheme.subtitle1?.fontSize),
        ),
      );
}

class AddFeed extends StatelessWidget {
  final PostBase post;

  const AddFeed(this.post, {super.key});

  @override
  Widget build(BuildContext context) => SimpleDialogOption(
        onPressed: () async {
          postListBack();
          try {
            await XdnmbClientService.to.client
                .addFeed(SettingsService.to.feedUuid, post.id);
            showToast('订阅 ${post.id.toPostNumber()} 成功');
          } catch (e) {
            showToast('订阅 ${post.id.toPostNumber()} 失败：$e');
          }
        },
        child: Text(
          '订阅',
          style: TextStyle(
              fontSize: Theme.of(context).textTheme.subtitle1?.fontSize),
        ),
      );
}

class JumpPageDialog extends StatelessWidget {
  final int currentPage;

  final int? maxPage;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  JumpPageDialog({super.key, required this.currentPage, this.maxPage});

  @override
  Widget build(BuildContext context) {
    String? page;

    return InputDialog(
      title: const Text('跳页'),
      content: Form(
        key: _formKey,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            SizedBox(
              width: 80,
              child: TextFormField(
                initialValue: '$currentPage',
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                onSaved: (newValue) => page = newValue,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入页数';
                  }

                  final num = int.tryParse(value);
                  if (num == null || (maxPage != null && num > maxPage!)) {
                    return '请输入页数';
                  }

                  return null;
                },
              ),
            ),
            if (maxPage != null) const Text('/'),
            if (maxPage != null) Text('$maxPage'),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();

              postListBack<int>(result: int.tryParse(page!));
            }
          },
          child: const Text('确定'),
        )
      ],
    );
  }
}
