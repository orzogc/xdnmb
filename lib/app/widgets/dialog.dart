import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';
import 'package:xdnmb_api/xdnmb_api.dart' hide Image;

import '../data/models/controller.dart';
import '../data/models/cookie.dart';
import '../data/models/forum.dart';
import '../data/services/blacklist.dart';
import '../data/services/forum.dart';
import '../data/services/persistent.dart';
import '../data/services/settings.dart';
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
import 'content.dart';
import 'edit_post.dart';
import 'forum_name.dart';
import 'listenable.dart';
import 'scroll.dart';
import 'thread.dart';

Future<T?> postListDialog<T>(Widget widget, {int? index}) {
  final settings = SettingsService.to;
  final data = PersistentDataService.to;
  final controller = PostListController.get();

  return Get.dialog<T>(Obx(() {
    final isAutoHideAppBar = settings.isAutoHideAppBar;
    final isShowBottomBar = PostListBottomBar.isShowed;

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
                  child: Text(cancelText ?? '??????',
                      style: TextStyle(fontSize: fontSize)),
                ),
              if (onConfirm != null)
                TextButton(
                  onPressed: onConfirm!,
                  child: Text(confirmText ?? '??????',
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

  final Future<void> _updateNotice = PersistentDataService.to.updateNotice();

  NoticeDialog(
      {super.key, this.showCheckbox = false, this.isAutoUpdate = false})
      : assert(
            (showCheckbox && !isAutoUpdate) || (!showCheckbox && isAutoUpdate));

  @override
  Widget build(BuildContext context) {
    final data = PersistentDataService.to;
    final settings = SettingsService.to;
    final textStyle = Theme.of(context).textTheme.titleMedium;
    final isChecked = false.obs;

    return AlertDialog(
      actionsPadding:
          const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
      actionsAlignment:
          showCheckbox ? MainAxisAlignment.spaceBetween : MainAxisAlignment.end,
      contentPadding: const EdgeInsets.fromLTRB(24.0, 10.0, 24.0, 5.0),
      title: ListenableBuilder(
          listenable: data.noticeDateListenable,
          builder: (context, child) => data.noticeDate != null
              ? Text('?????? ${formatDay(data.noticeDate!)}')
              : const Text('??????')),
      content: SingleChildScrollViewWithScrollbar(
        child: isAutoUpdate
            ? FutureBuilder<void>(
                future: _updateNotice,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.hasError) {
                    showToast(exceptionMessage(snapshot.error!));

                    return const Center(
                      child: Text('????????????', style: AppTheme.boldRed),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.done) {
                    return TextContent(
                      text: data.notice ?? '',
                      onLinkTap: (context, link, text) => parseUrl(url: link),
                    );
                  }

                  return const Center(child: CircularProgressIndicator());
                },
              )
            : TextContent(
                text: data.notice ?? '',
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
                  Flexible(child: Text('????????????????????????', style: textStyle)),
                ],
              ),
            Row(
              children: [
                const Spacer(),
                TextButton(
                  onPressed: () {
                    if (showCheckbox) {
                      settings.showNotice = !isChecked.value;
                    }
                    postListBack();
                  },
                  child: Text(
                    '??????',
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

class ForumRuleDialog extends StatelessWidget {
  final int forumId;

  final Future<void> _getForumRule;

  ForumRuleDialog(this.forumId, {super.key})
      : _getForumRule = Future(() async {
          final forums = ForumListService.to;

          final entry = forums.forums.toList().asMap().entries.singleWhere(
              (entry) => entry.value.isForum && entry.value.id == forumId);

          if (entry.value.isDeprecated) {
            final htmlForum =
                await XdnmbClientService.to.client.getHtmlForumInfo(forumId);
            final forum = ForumData.fromHtmlForum(htmlForum);
            forum.userDefinedName = entry.value.userDefinedName;
            forum.isHidden = entry.value.isHidden;
            await forums.updateForum(entry.key, forum);

            debugPrint('????????????????????????');
          }
        });

  @override
  Widget build(BuildContext context) {
    final forums = ForumListService.to;

    return FutureBuilder<void>(
      future: _getForumRule,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasError) {
          showToast('???????????????????????????${exceptionMessage(snapshot.error!)}');
        }

        final forum = forums.forum(forumId);

        return AlertDialog(
          actionsPadding: const EdgeInsets.only(right: 20.0, bottom: 20.0),
          title: forum != null
              ? ForumName(
                  forumId: forum.id,
                  trailing: ' ??????',
                  textStyle: Theme.of(context).textTheme.titleLarge,
                  maxLines: 1)
              : const Text('??????'),
          content: SingleChildScrollViewWithScrollbar(
            child: TextContent(
              text: forum?.message ?? '',
              onLinkTap: (context, link, text) => parseUrl(url: link),
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
                '??????',
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

// TODO: SimpleDialog????????????scrollbar
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
          showToast('???????????????????????? ${post.toPostNumber()}');
        },
        child: Text(
          text ?? '?????????????????????',
          style: Theme.of(context).textTheme.titleMedium,
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
          showToast('?????????????????????????????? ${post.toPostNumber()}');
          postListBack();
        },
        child: Text(
          text ?? '???????????????????????????',
          style: Theme.of(context).textTheme.titleMedium,
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
          showToast('????????? $postId');
          postListBack();
        },
        child: Text(text ?? '????????????',
            style: Theme.of(context).textTheme.titleMedium),
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
          showToast('????????? ${postId.toPostReference()}');
          postListBack();
        },
        child: Text(
          text ?? '??????????????????',
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
          showToast('???????????? ${post.toPostNumber()} ?????????');
          postListBack();
        },
        child: Text('??????????????????', style: Theme.of(context).textTheme.titleMedium),
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
        child: Text('??????', style: Theme.of(context).textTheme.titleMedium),
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
            content: '?????????????????? ${postId.toPostNumber()} ???',
            onConfirm: () => postListBack<bool>(result: true),
            onCancel: () => postListBack<bool>(result: false),
          ));

          if (result ?? false) {
            await BlacklistService.to.blockPost(postId);
            if (onBlock != null) {
              onBlock!();
            }

            showToast('???????????? ${postId.toPostNumber()}');
            postListBack();
          }
        },
        child: Text('????????????', style: Theme.of(context).textTheme.titleMedium),
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
            content: '?????????????????? $userHash ???',
            onConfirm: () => postListBack<bool>(result: true),
            onCancel: () => postListBack<bool>(result: false),
          ));

          if (result ?? false) {
            await BlacklistService.to.blockUser(userHash);
            if (onBlock != null) {
              onBlock!();
            }

            showToast('???????????? $userHash');
            postListBack();
          }
        },
        child: Text('????????????', style: Theme.of(context).textTheme.titleMedium),
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
                  page: page,
                  postId: postId)));

          showToast('???????????? ${mainPostId.toPostNumber()} ??????');
          postListBack();
        },
        child: Text('??????', style: Theme.of(context).textTheme.titleMedium),
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
        content: onApply != null ? const Text('???????????????') : const Text('???????????????'),
        actions: [
          TextButton(
              onPressed: onNotSave,
              child: onApply != null ? const Text('?????????') : const Text('?????????')),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(onPressed: onCancel, child: const Text('??????')),
              if (onSave != null)
                TextButton(onPressed: onSave, child: const Text('??????')),
              if (onApply != null)
                TextButton(onPressed: onApply, child: const Text('??????')),
            ],
          ),
        ],
      );
}

class NumRangeDialog<T extends num> extends StatelessWidget {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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

    return InputDialog(
      content: Form(
        key: _formKey,
        child: TextFormField(
          decoration: InputDecoration(
              labelText:
                  max != null ? '$text??? $min - $max ???' : '$text??? >= $min ???'),
          autofocus: true,
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
                      return '$text?????????$min???$max??????';
                    }
                  } else {
                    if (n >= min) {
                      return null;
                    } else {
                      return '$text??????????????????$min';
                    }
                  }
                } else {
                  return '?????????$text??????';
                }
              } catch (e) {
                return '?????????$text??????';
              }
            } else {
              return '?????????$text??????';
            }
          },
        ),
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
          child: const Text('??????'),
        )
      ],
    );
  }
}

class RewardQRCode extends StatelessWidget {
  const RewardQRCode({super.key});

  @override
  Widget build(BuildContext context) => AlertDialog(
        actionsPadding: const EdgeInsets.only(right: 20.0, bottom: 20.0),
        title: const Text('???????????????'),
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
            child: const Text('??????'),
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
    String? note;
    final Rx<Color> color = Rx(cookie.color);

    return InputDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            decoration: const InputDecoration(labelText: '??????'),
            autofocus: true,
            initialValue: cookie.note,
            onChanged: (value) => note = value,
          ),
          if (setColor) const SizedBox(height: 15.0),
          if (setColor)
            GestureDetector(
              onTap: () {
                Color? color_;
                Get.dialog(
                  ConfirmCancelDialog(
                    contentWidget: MaterialPicker(
                      pickerColor: cookie.color,
                      onColorChanged: (value) => color_ = value,
                      enableLabel: true,
                    ),
                    onConfirm: () {
                      if (color_ != null) {
                        color.value = color_!;
                      }
                      Get.back();
                    },
                    onCancel: Get.back,
                  ),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('??????'),
                  Obx(
                    () => ColorIndicator(
                      HSVColor.fromColor(color.value),
                      key: ValueKey<Color>(color.value),
                      width: 25.0,
                      height: 25.0,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () async {
            await cookie.editNote((note?.isNotEmpty ?? false) ? note : null);
            if (setColor) {
              await UserService.to.setCookieColor(cookie, color.value);
            }

            Get.back(result: true);
          },
          child: const Text('??????'),
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
        child: Text('??????????????????', style: Theme.of(context).textTheme.titleMedium),
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
        child: Text('??????????????????', style: Theme.of(context).textTheme.titleMedium),
      );
}
