import 'dart:io';
import 'dart:math';

import 'package:align_positioned/align_positioned.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:html_to_text/html_to_text.dart';
import 'package:path/path.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import 'package:xdnmb_api/xdnmb_api.dart' as xdnmb_api;

import '../data/models/draft.dart';
import '../data/models/emoticon.dart';
import '../data/models/post.dart';
import '../data/models/reply.dart';
import '../data/services/drafts.dart';
import '../data/services/emoticons.dart';
import '../data/services/forum.dart';
import '../data/services/history.dart';
import '../data/services/persistent.dart';
import '../data/services/settings.dart';
import '../data/services/user.dart';
import '../data/services/xdnmb_client.dart';
import '../modules/edit_post.dart';
import '../modules/post_list.dart';
import '../routes/routes.dart';
import '../utils/exception.dart';
import '../utils/extensions.dart';
import '../utils/icons.dart';
import '../utils/theme.dart';
import '../utils/toast.dart';
import 'dialog.dart';
import 'loading.dart';
import 'scroll.dart';
import 'size.dart';

const double _defaultHeight = 200.0;

typedef _ForumIdCallback = void Function(int forumId);

class _SelectForum extends StatelessWidget {
  final _ForumIdCallback onForumId;

  const _SelectForum({super.key, required this.onForumId});

  @override
  Widget build(BuildContext context) => SimpleDialog(
        children: [
          for (final forum
              in ForumListService.to.forums.where((forum) => forum.isForum))
            SimpleDialogOption(
              onPressed: () {
                onForumId(forum.id);
                Get.back();
              },
              child: htmlToRichText(context, forum.forumName,
                  textStyle: Theme.of(context).textTheme.bodyText1),
            )
        ],
      );
}

class _ForumName extends StatelessWidget {
  final PostListType postListType;

  final int? forumId;

  final _ForumIdCallback onForumId;

  const _ForumName(
      {super.key,
      required this.postListType,
      required this.forumId,
      required this.onForumId});

  @override
  Widget build(BuildContext context) {
    String? forumName;
    if (forumId != null) {
      forumName = ForumListService.to.forumName(forumId!);
    }
    forumName ??= '选择板块';

    return postListType.isForumType()
        ? TextButton(
            onPressed: () {
              if (postListType.isForumType()) {
                Get.dialog(
                  _SelectForum(onForumId: onForumId),
                );
              }
            },
            child: htmlToRichText(
              context,
              forumName,
              textStyle: TextStyle(
                  color: Get.isDarkMode
                      ? Colors.white
                      : AppTheme.primaryColorLight),
            ),
          )
        : htmlToRichText(context, forumName);
  }
}

class _ReportReasonDialog extends StatelessWidget {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final String? text;

  _ReportReasonDialog({super.key, this.text});

  @override
  Widget build(BuildContext context) {
    String? reason;

    return InputDialog(
      content: Form(
        key: _formKey,
        child: TextFormField(
          decoration: const InputDecoration(labelText: '举报理由'),
          initialValue: text,
          autofocus: true,
          onSaved: (newValue) => reason = newValue,
          validator: (value) => (value == null || value.isEmpty)
              ? '请输入举报理由'
              : (xdnmb_api.ReportReason.list
                      .any((reason) => reason.reason == value)
                  ? '举报理由不能与已有的重复'
                  : null),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();

              Get.back<String>(result: reason);
            }
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}

typedef _ReportReasonCallback = void Function(String? text);

class _ReportReason extends StatelessWidget {
  final String? reportReason;

  final _ReportReasonCallback onReportReason;

  late final RxnString _value = RxnString(reportReason);

  late final RxnString _userDefined = RxnString(
      xdnmb_api.ReportReason.list.any((reason) => reason.reason == reportReason)
          ? null
          : reportReason);

  _ReportReason({super.key, this.reportReason, required this.onReportReason});

  @override
  Widget build(BuildContext context) {
    final RxDouble width = 0.0.obs;

    return LayoutBuilder(
      builder: (context, constraints) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ChildSizeNotifier(
              builder: (context, size, child) {
                Future.delayed(const Duration(milliseconds: 100),
                    () => width.value = size.width);

                return child!;
              },
              child: const Text('举报理由：')),
          Obx(
            () => DropdownButton<String>(
              value: _value.value,
              style: Theme.of(context).textTheme.bodyText2,
              onChanged: (value) {
                if (value != null && value.isNotEmpty) {
                  _value.value = value;
                  onReportReason(value);
                }
              },
              items: [
                for (final reason in xdnmb_api.ReportReason.list)
                  DropdownMenuItem<String>(
                    value: reason.text,
                    child: Text(reason.reason),
                  ),
                DropdownMenuItem(
                  value: _userDefined.value ?? '',
                  onTap: () {
                    Future.delayed(const Duration(milliseconds: 100), () async {
                      final reason = await Get.dialog<String>(
                          _ReportReasonDialog(text: _userDefined.value));
                      if (reason != null && reason.isNotEmpty) {
                        _value.value = reason;
                        _userDefined.value = reason;
                        onReportReason(reason);
                      }
                    });
                  },
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      // TODO: 这里应该更加精确
                      maxWidth: max(
                        width.value > 0
                            ? constraints.maxWidth - width.value - 50
                            : constraints.maxWidth - 120,
                        0.0,
                      ),
                    ),
                    child: Text(
                      _userDefined.value ?? '自定义',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

typedef _WatermarkCallback = void Function(bool isWatermark);

class _WatermarkDialog extends StatelessWidget {
  final RxBool isWatermark;

  final _WatermarkCallback onWatermark;

  _WatermarkDialog(
      {super.key, required bool isWatermark, required this.onWatermark})
      : isWatermark = isWatermark.obs;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      actionsPadding: const EdgeInsets.only(right: 10.0, bottom: 10.0),
      content: SingleChildScrollViewWithScrollbar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('水印'),
              trailing: Obx(
                () => Radio<bool>(
                  value: true,
                  groupValue: isWatermark.value,
                  onChanged: (isWatermark) {
                    if (isWatermark != null) {
                      this.isWatermark.value = isWatermark;
                    }
                  },
                ),
              ),
            ),
            ListTile(
              title: const Text('没水印'),
              trailing: Obx(
                () => Radio<bool>(
                  value: false,
                  groupValue: isWatermark.value,
                  onChanged: (isWatermark) {
                    if (isWatermark != null) {
                      this.isWatermark.value = isWatermark;
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            onWatermark(isWatermark.value);
            Get.back();
          },
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

class _Image extends StatelessWidget {
  final double maxHeight;

  final String path;

  final bool isWatermark;

  final VoidCallback onCancel;

  final _WatermarkCallback onWatermark;

  const _Image(
      {super.key,
      required this.maxHeight,
      required this.path,
      required this.isWatermark,
      required this.onCancel,
      required this.onWatermark});

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width / 3.0,
            maxHeight: maxHeight),
        child: AlignPositioned.relative(
          alignment: Alignment.topRight,
          container: GestureDetector(
            onLongPress: () => Get.dialog(_WatermarkDialog(
                isWatermark: isWatermark, onWatermark: onWatermark)),
            child: Image.file(
              File(path),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  loadingImageErrorBuilder(context, path, error),
            ),
          ),
          child: ElevatedButton(
            onPressed: onCancel,
            style: ElevatedButton.styleFrom(shape: const CircleBorder()),
            child: const Icon(Icons.close),
          ),
        ),
      );
}

class _ShowEmoticon extends StatelessWidget {
  final RxBool showEmoticon;

  const _ShowEmoticon(this.showEmoticon, {super.key});

  @override
  Widget build(BuildContext context) {
    final data = PersistentDataService.to;

    return IconButton(
      onPressed: () {
        if (data.isKeyboardVisible.value) {
          FocusManager.instance.primaryFocus?.unfocus();
          showEmoticon.trigger(true);
        } else {
          showEmoticon.value = !showEmoticon.value;
        }
      },
      icon: const Icon(Icons.insert_emoticon),
    );
  }
}

typedef _PickImageCallback = void Function(String path);

class _PickImage extends StatelessWidget {
  final _PickImageCallback onPickImage;

  const _PickImage({super.key, required this.onPickImage});

  @override
  Widget build(BuildContext context) {
    final data = PersistentDataService.to;

    return IconButton(
      onPressed: () async {
        try {
          final result = await FilePicker.platform.pickFiles(
            dialogTitle: 'xdnmb',
            initialDirectory:
                (GetPlatform.isDesktop) ? data.pictureDirectory : null,
            type: FileType.custom,
            allowedExtensions: ['jif', 'jpeg', 'jpg', 'png'],
            lockParentWindow: true,
          );

          if (result != null) {
            final path = result.files.single.path;
            if (path != null) {
              if (GetPlatform.isDesktop) {
                data.pictureDirectory = dirname(path);
              }
              onPickImage(path);
            } else {
              showToast('无法获取图片具体路径');
            }
          }
        } catch (e) {
          showToast('选择图片失败：$e');
        }
      },
      icon: const Icon(Icons.image),
    );
  }
}

typedef _InsertTextCallback = void Function(String text, [int? offset]);

class _Dice extends StatelessWidget {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final _InsertTextCallback onDice;

  _Dice({super.key, required this.onDice});

  @override
  Widget build(BuildContext context) {
    final data = PersistentDataService.to;
    String? lower;
    String? upper;

    return IconButton(
      onPressed: () => Get.dialog(
        InputDialog(
          title: const Text('骰子范围'),
          content: Form(
            key: _formKey,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    decoration: const InputDecoration(hintText: '下限'),
                    initialValue: '${data.diceLower}',
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    onSaved: (newValue) => lower = newValue,
                    validator: (value) =>
                        value.tryParseInt() == null ? '请输入下限' : null,
                  ),
                ),
                const Text('—'),
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    decoration: const InputDecoration(hintText: '上限'),
                    initialValue: '${data.diceUpper}',
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    onSaved: (newValue) => upper = newValue,
                    validator: (value) =>
                        value.tryParseInt() == null ? '请输入上限' : null,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();

                  data.diceLower = int.parse(lower!);
                  data.diceUpper = int.parse(upper!);

                  onDice('[$lower,$upper]');
                  Get.back();
                }
              },
              child: const Text('确定'),
            ),
          ],
        ),
      ),
      icon: const Icon(AppIcons.dice, size: 18.0),
    );
  }
}

typedef _GetText = String Function();

class _SaveDraft extends StatelessWidget {
  final _GetText getTitle;

  final _GetText getName;

  final _GetText getContent;

  const _SaveDraft(
      {super.key,
      required this.getTitle,
      required this.getName,
      required this.getContent});

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: () {
          final title = getTitle();
          final name = getTitle();
          final content = getContent();

          if (title.isNotEmpty || name.isNotEmpty || content.isNotEmpty) {
            PostDraftsService.to.addDraft(PostDraftData(
                title: title.isNotEmpty ? title : null,
                name: name.isNotEmpty ? name : null,
                content: content.isNotEmpty ? content : null));

            showToast('已保存为草稿');
          }
        },
        icon: const Icon(Icons.save),
      );
}

class _Cookie extends StatelessWidget {
  const _Cookie({super.key});

  @override
  Widget build(BuildContext context) {
    final user = UserService.to;

    return user.hasPostCookie
        ? ValueListenableBuilder<Box>(
            valueListenable: user.postCookieListenable,
            builder: (context, value, child) => TextButton(
              onPressed: () => Get.dialog(
                SimpleDialog(
                  children: [
                    for (final cookie in user.xdnmbCookies)
                      ListTile(
                        onTap: () {
                          user.postCookie = cookie.copy();
                          Get.back();
                        },
                        title: Text(cookie.name),
                        subtitle: (cookie.note?.isNotEmpty ?? false)
                            ? Text(cookie.note!)
                            : null,
                        trailing:
                            (user.isUserCookieValid && cookie.isDeprecated)
                                ? const Text('非登陆帐号饼干',
                                    style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold))
                                : null,
                      ),
                  ],
                ),
              ),
              child: Text(user.postCookie!.name),
            ),
          )
        : const Text('没有饼干',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold));
  }
}

class _Post extends StatelessWidget {
  static const Duration _difference = Duration(seconds: 60);

  final PostList postList;

  final int? forumId;

  final bool? isWatermark;

  final String? imagePath;

  final String? reportReason;

  final _GetText getTitle;

  final _GetText getName;

  final _GetText getContent;

  final VoidCallback onPost;

  const _Post(
      {super.key,
      required this.postList,
      this.forumId,
      this.isWatermark,
      this.imagePath,
      this.reportReason,
      required this.getTitle,
      required this.getName,
      required this.getContent,
      required this.onPost});

  Future<void> savePost(PostData post) async {
    final history = PostHistoryService.to;
    final client = XdnmbClientService.to.client;

    try {
      final id = await history.savePostData(post);
      final forum = await client.getForum(post.forumId);

      final threads = forum.where((thread) =>
          thread.mainPost.userHash == post.userHash &&
          thread.mainPost.postTime.difference(post.postTime).abs() <
              _difference);
      if (threads.isNotEmpty) {
        final postData = await history.getPostData(id);
        if (postData != null) {
          postData.update(threads.first.mainPost);
          await history.savePostData(postData);
        }
      }
    } catch (e) {
      showToast('获取发布的新串数据出现错误：${exceptionMessage(e)}');
    }
  }

  Future<bool> getPostId(
      {required int id, required ReplyData reply, required int page}) async {
    final history = PostHistoryService.to;
    final client = XdnmbClientService.to.client;

    final thread = await client.getThread(reply.mainPostId, page: page);
    final posts = thread.replies.where((post) =>
        post.userHash == reply.userHash &&
        (post.postTime.difference(reply.postTime).abs() < _difference));
    if (posts.isNotEmpty) {
      final replyData = await history.getReplyData(id);
      if (replyData != null) {
        replyData.update(post: posts.last, page: page);
        await history.saveReplyData(replyData);
        return true;
      }
    }

    return false;
  }

  Future<void> saveReply(ReplyData reply) async {
    final history = PostHistoryService.to;
    final client = XdnmbClientService.to.client;

    try {
      final id = await history.saveReplyData(reply);
      final thread = await client.getThread(reply.mainPostId);

      final page = thread.mainPost.replyCount != 0
          ? (thread.mainPost.replyCount / 19).ceil()
          : 1;
      if (!await getPostId(id: id, reply: reply, page: page) && page > 1) {
        await getPostId(id: id, reply: reply, page: page - 1);
      }
    } catch (e) {
      showToast('获取回串数据出现错误：${exceptionMessage(e)}');
    }
  }

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: () {
          final user = UserService.to;

          if (user.hasPostCookie) {
            if (forumId != null) {
              final postListType = postList.postListType;

              if (postListType.isForumType() &&
                  forumId == EditPost.dutyRoomId &&
                  (reportReason == null || reportReason!.isEmpty)) {
                showToast('请选择举报理由');
                return;
              }

              var content = getContent();

              if (content.isNotEmpty || imagePath != null) {
                final client = XdnmbClientService.to.client;

                final title = getTitle();
                final name = getName();
                final cookie = user.postCookie!;

                Future(() async {
                  xdnmb_api.Image? image;
                  if (imagePath != null) {
                    image = await xdnmb_api.Image.fromFile(imagePath!);
                  }

                  if (postListType.isForumType()) {
                    if (forumId == EditPost.dutyRoomId) {
                      content = '举报理由：$reportReason\n$content';
                    }

                    await client.postNewThread(
                      forumId: forumId!,
                      content: content,
                      name: name.isNotEmpty ? name : null,
                      title: title.isNotEmpty ? title : null,
                      watermark: isWatermark,
                      image: image,
                      cookie: cookie.cookie(),
                    );
                  } else {
                    await client.replyThread(
                      mainPostId: postList.id!,
                      content: content,
                      name: name.isNotEmpty ? name : null,
                      title: title.isNotEmpty ? title : null,
                      watermark: isWatermark,
                      image: image,
                      cookie: cookie.cookie(),
                    );
                  }
                }).then(
                  (value) {
                    if (postListType.isForumType()) {
                      showToast('发表新串成功');
                      final post = PostData(
                          forumId: forumId!,
                          postTime: DateTime.now(),
                          userHash: cookie.name,
                          name: name,
                          title: title,
                          content: content);
                      savePost(post);
                    } else {
                      showToast('回串成功');
                      final reply = ReplyData(
                          mainPostId: postList.id!,
                          forumId: forumId!,
                          postTime: DateTime.now(),
                          userHash: cookie.name,
                          name: name,
                          title: title,
                          content: content);
                      saveReply(reply);
                    }
                  },
                  onError: (e) {
                    if (title.isNotEmpty ||
                        name.isNotEmpty ||
                        content.isNotEmpty) {
                      PostDraftsService.to.addDraft(PostDraftData(
                          title: title.isNotEmpty ? title : null,
                          name: name.isNotEmpty ? name : null,
                          content: content.isNotEmpty ? content : null));
                      showToast('发串失败，内容已保存为草稿：${exceptionMessage(e)}');
                    } else {
                      showToast('发串失败：${exceptionMessage(e)}');
                    }
                  },
                );

                onPost();
                Get.back<bool>(result: true);
              } else {
                showToast('不发图时串的内容不能为空');
              }
            } else {
              showToast('请选择板块');
            }
          } else {
            showToast('发串需要饼干，请在设置里领取饼干');
          }
        },
        icon: const Icon(Icons.send),
      );
}

class _EditEmoticon extends StatefulWidget {
  final EmoticonData? emoticon;

  const _EditEmoticon({super.key, this.emoticon});

  @override
  State<_EditEmoticon> createState() => _EditEmoticonState();
}

class _EditEmoticonState extends State<_EditEmoticon> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.emoticon?.text);
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Get.isDarkMode
        ? AppTheme.editPostFilledColorDark
        : AppTheme.editPostFilledColorLight;

    final border = OutlineInputBorder(
      borderSide: BorderSide(color: color),
      borderRadius: BorderRadius.circular(10.0),
    );

    String? name;
    String? text;

    return InputDialog(
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(hintText: '名称'),
              autofocus: widget.emoticon == null,
              initialValue: widget.emoticon?.name,
              onSaved: (newValue) => name = newValue,
              validator: (value) =>
                  (value == null || value.isEmpty) ? '请输入颜文字名称' : null,
            ),
            const SizedBox(height: 10.0),
            TextFormField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: '颜文字',
                filled: true,
                fillColor: color,
                enabledBorder: border,
                focusedBorder: border,
              ),
              autofocus: widget.emoticon != null,
              maxLines: null,
              minLines: 8,
              textAlignVertical: TextAlignVertical.top,
              onSaved: (newValue) => text = newValue,
              validator: (value) =>
                  (value == null || value.isEmpty) ? '请输入颜文字' : null,
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => _controller.insertText('　'),
          child: const Text('全角空格'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();

              if (widget.emoticon != null) {
                widget.emoticon!.set(name: name!, text: text!);
                await widget.emoticon!.save();

                showToast('修改颜文字 $name 成功');
              } else {
                await EmoticonsService.to
                    .addEmoticon(EmoticonData(name: name!, text: text!));

                showToast('添加颜文字 $name 成功');
              }

              Get.back();
            }
          },
          child: widget.emoticon != null ? const Text('修改') : const Text('添加'),
        ),
      ],
    );
  }
}

class _EmoticonDialog extends StatelessWidget {
  final EmoticonData emoticon;

  const _EmoticonDialog(this.emoticon, {super.key});

  @override
  Widget build(BuildContext context) {
    final fontSize = Theme.of(context).textTheme.subtitle1?.fontSize;

    return SimpleDialog(
      children: [
        SimpleDialogOption(
          onPressed: () {
            Get.back();
            Get.dialog(_EditEmoticon(emoticon: emoticon));
          },
          child:
              Text('修改 ${emoticon.name}', style: TextStyle(fontSize: fontSize)),
        ),
        SimpleDialogOption(
          onPressed: () async {
            await emoticon.delete();
            Get.back();
            showToast('删除颜文字 ${emoticon.name} 成功');
          },
          child:
              Text('删除 ${emoticon.name}', style: TextStyle(fontSize: fontSize)),
        ),
      ],
    );
  }
}

class _Emoticon extends StatefulWidget {
  final _InsertTextCallback onTap;

  const _Emoticon({super.key, required this.onTap});

  @override
  State<_Emoticon> createState() => _EmoticonState();
}

class _EmoticonState extends State<_Emoticon> {
  static final Iterable<EmoticonData> _list = xdnmb_api.Emoticon.list
      .getRange(0, xdnmb_api.Emoticon.list.length - 3)
      .map((emoticon) => EmoticonData(name: emoticon.name, text: emoticon.text))
      .followedBy([
    EmoticonData(name: '防剧透', text: '[h][/h]', offset: 3),
    EmoticonData(name: '全角空格', text: '　'),
  ]);

  static double _offset = 0.0;

  final ScrollController _controller =
      ScrollController(initialScrollOffset: _offset);

  void _setOffset() => _offset = _controller.offset;

  @override
  void initState() {
    super.initState();

    _controller.addListener(_setOffset);
  }

  @override
  void dispose() {
    _controller.removeListener(_setOffset);
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = PersistentDataService.to;
    final emoticons = EmoticonsService.to;
    final textStyle = Theme.of(context).textTheme.bodyText2;
    final buttonStyle = TextButton.styleFrom(
      padding: EdgeInsets.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    return Obx(
      () => !data.isKeyboardVisible.value
          ? SizedBox(
              height: (data.keyboardHeight != null && data.keyboardHeight! > 0)
                  ? data.keyboardHeight!
                  : _defaultHeight,
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 20.0, right: 20.0, bottom: 10.0),
                child: Scrollbar(
                  controller: _controller,
                  thumbVisibility: true,
                  child: ValueListenableBuilder(
                    valueListenable: emoticons.emoticonsListenable,
                    // 这里可能有性能问题
                    builder: (context, value, child) => ResponsiveGridList(
                      minItemWidth: 80.0,
                      horizontalGridSpacing: 10.0,
                      verticalGridSpacing: 10.0,
                      listViewBuilderOptions: ListViewBuilderOptions(
                        controller: _controller,
                        shrinkWrap: true,
                      ),
                      children: [
                        for (final emoticon in _list)
                          TextButton(
                            style: buttonStyle,
                            onPressed: () =>
                                widget.onTap(emoticon.text, emoticon.offset),
                            child: Text(emoticon.name, style: textStyle),
                          ),
                        for (final emoticon in emoticons.emoticons)
                          TextButton(
                            style: buttonStyle,
                            onPressed: () =>
                                widget.onTap(emoticon.text, emoticon.offset),
                            onLongPress: () =>
                                Get.dialog(_EmoticonDialog(emoticon)),
                            child: Text(emoticon.name, style: textStyle),
                          ),
                        TextButton(
                          style: buttonStyle,
                          onPressed: () => Get.dialog(_EditEmoticon()),
                          child: Text('自定义', style: textStyle),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

class EditPost extends StatefulWidget {
  static const int dutyRoomId = 18;

  static final GlobalKey<EditPostState> bottomSheetkey =
      GlobalKey<EditPostState>();

  final PostList postList;

  final double? height;

  final int? forumId;

  final String? title;

  final String? name;

  final String? content;

  final String? imagePath;

  final bool? isWatermark;

  final String? reportReason;

  const EditPost(
      {super.key,
      required this.postList,
      this.height,
      this.forumId,
      this.title,
      this.name,
      this.content,
      this.imagePath,
      this.isWatermark,
      this.reportReason});

  EditPost.fromController(
      {super.key, required EditPostController controller, this.height})
      : postList =
            PostList(postListType: controller.postListType, id: controller.id),
        forumId = controller.forumId,
        title = controller.title,
        name = controller.name,
        content = controller.content,
        imagePath = controller.imagePath,
        isWatermark = controller.isWatermark,
        reportReason = controller.reportReason;

  @override
  State<EditPost> createState() => EditPostState();
}

class EditPostState extends State<EditPost> {
  late final RxnInt _forumId;

  late final TextEditingController _titleController;

  late final TextEditingController _nameController;

  late final TextEditingController _contentController;

  late final RxnString _imagePath;

  late final RxBool _isWatermark;

  late final RxnString _reportReason;

  late final RxBool _isExpanded;

  final RxBool _showEmoticon = false.obs;

  bool isPosted = false;

  EditPostController toController() => EditPostController(
      postListType: widget.postList.postListType,
      id: widget.postList.id!,
      forumId: _forumId.value,
      title: _titleController.text,
      name: _nameController.text,
      content: _contentController.text,
      imagePath: _imagePath.value,
      isWatermark: _isWatermark.value,
      reportReason: _reportReason.value);

  void insertText(String text, [int? offset]) =>
      _contentController.insertText(text, offset);

  Widget _inputArea(BuildContext context, double height) {
    final textStyle = Theme.of(context).textTheme.bodyText2;
    final postListType = widget.postList.postListType;
    final id = widget.postList.id!;

    final color = Get.isDarkMode
        ? AppTheme.editPostFilledColorDark
        : AppTheme.editPostFilledColorLight;
    final border = OutlineInputBorder(
      borderSide: BorderSide(color: color),
      borderRadius: BorderRadius.circular(10.0),
    );

    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: IconButton(
                    onPressed: () => _isExpanded.value = !_isExpanded.value,
                    icon: const Icon(Icons.more_horiz, size: 20.0),
                  ),
                ),
                Flexible(
                  child: Obx(
                    () => _ForumName(
                        postListType: postListType,
                        forumId: _forumId.value,
                        onForumId: (forumId) => _forumId.value = forumId),
                  ),
                ),
                if (postListType.isThreadType()) Text(id.toPostNumber()),
                Flexible(
                  child: IconButton(
                    onPressed: () async {
                      final draft = await AppRoutes.toPostDrafts();

                      if (draft is PostDraftData) {
                        _titleController.text = draft.title ?? '';
                        _nameController.text = draft.name ?? '';
                        _contentController.text = draft.content ?? '';
                      }
                    },
                    icon: const Icon(Icons.edit_note),
                  ),
                ),
                if (widget.height != null)
                  Flexible(
                    child: IconButton(
                      onPressed: () async {
                        final result = await AppRoutes.toEditPost(
                            postListType: postListType,
                            id: id,
                            title: _titleController.text,
                            name: _nameController.text,
                            content: _contentController.text,
                            forumId: _forumId.value,
                            imagePath: _imagePath.value,
                            isWatermark: _isWatermark.value,
                            reportReason: _reportReason.value);

                        if (result is EditPostController && mounted) {
                          _forumId.value = result.forumId;
                          _imagePath.value = result.imagePath;
                          _isWatermark.value = result.isWatermark ??
                              SettingsService.to.isWatermark;
                          setState(() {
                            _titleController.text = result.title ?? '';
                            _nameController.text = result.name ?? '';
                            _contentController.text = result.content ?? '';
                            _reportReason.value = result.reportReason;
                          });
                        } else if (result is bool && result) {
                          isPosted = true;
                          Get.back();
                        }
                      },
                      icon: const Icon(Icons.open_in_new, size: 20.0),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final textSize = _textSize(context, 'a啊', textStyle);
                    final reportReason = _reportReason.value;

                    return SingleChildScrollViewWithScrollbar(
                      child: Obx(
                        () => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_isExpanded.value)
                              TextField(
                                controller: _titleController,
                                style: textStyle,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  hintText: '标题',
                                ),
                              ),
                            if (_isExpanded.value)
                              TextField(
                                controller: _nameController,
                                style: textStyle,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  hintText: '名称',
                                ),
                              ),
                            if (_isExpanded.value) const SizedBox(height: 10.0),
                            if (postListType.isForumType() &&
                                _forumId.value == EditPost.dutyRoomId)
                              _ReportReason(
                                reportReason: reportReason,
                                onReportReason: (text) {
                                  if (text != null && text.isNotEmpty) {
                                    _reportReason.value = text;
                                  }
                                },
                              ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_imagePath.value != null)
                                  _Image(
                                      maxHeight: constraints.maxHeight,
                                      path: _imagePath.value!,
                                      isWatermark: _isWatermark.value,
                                      onCancel: () => _imagePath.value = null,
                                      onWatermark: (isWatermark) =>
                                          _isWatermark.value = isWatermark),
                                if (_imagePath.value != null)
                                  const SizedBox(width: 10.0),
                                Expanded(
                                  child: TextField(
                                    controller: _contentController,
                                    style: textStyle,
                                    maxLines: null,
                                    minLines: constraints.maxHeight ~/
                                        textSize.height,
                                    //expands: widget.height != null ? false : true,
                                    textAlignVertical: TextAlignVertical.top,
                                    //autofocus: true,
                                    decoration: InputDecoration(
                                      hintText: '正文',
                                      filled: true,
                                      fillColor: color,
                                      enabledBorder: border,
                                      focusedBorder: border,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Row(
              children: [
                _ShowEmoticon(_showEmoticon),
                _PickImage(onPickImage: (path) {
                  debugPrint('image path: $path');
                  _imagePath.value = path;
                }),
                _Dice(onDice: insertText),
                _SaveDraft(
                  getTitle: () => _titleController.text,
                  getName: () => _nameController.text,
                  getContent: () => _contentController.text,
                ),
                const Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _Cookie(),
                  ),
                ),
                Obx(
                  () => _Post(
                    postList: widget.postList,
                    forumId: _forumId.value,
                    isWatermark: _isWatermark.value,
                    imagePath: _imagePath.value,
                    reportReason: _reportReason.value,
                    getTitle: () => _titleController.text,
                    getName: () => _nameController.text,
                    getContent: () => _contentController.text,
                    onPost: () => isPosted = true,
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _titleController = _initController(widget.title);
    _nameController = _initController(widget.name);
    _contentController = _initController(widget.content);

    if ((widget.title?.isNotEmpty ?? false) ||
        (widget.name?.isNotEmpty ?? false)) {
      _isExpanded = true.obs;
    } else {
      _isExpanded = false.obs;
    }

    _forumId = RxnInt(widget.forumId);

    _imagePath = RxnString(widget.imagePath);

    if (widget.isWatermark != null) {
      _isWatermark = widget.isWatermark!.obs;
    } else {
      _isWatermark = SettingsService.to.isWatermark.obs;
    }

    _reportReason = RxnString(widget.reportReason);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _nameController.dispose();
    _contentController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = PersistentDataService.to;
    debugPrint('build edit');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        widget.height != null
            ? _inputArea(context, widget.height!)
            : Obx(
                () {
                  final fullHeight = MediaQuery.of(context).size.height -
                      Scaffold.of(context).appBarMaxHeight!;
                  final lessHeight =
                      fullHeight - (data.keyboardHeight ?? _defaultHeight);

                  return (_showEmoticon.value || data.isKeyboardVisible.value)
                      ? _inputArea(
                          context, lessHeight > 0 ? lessHeight : _defaultHeight)
                      : _inputArea(context,
                          fullHeight > 0 ? fullHeight : _defaultHeight);
                },
              ),
        Obx(
          () => _showEmoticon.value
              ? _Emoticon(onTap: insertText)
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

TextEditingController _initController(String? text) {
  final controller = TextEditingController(text: text);
  if (text != null) {
    controller.selection = TextSelection.collapsed(offset: text.length);
  }

  return controller;
}

Size _textSize(BuildContext context, String text, TextStyle? style) {
  final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textScaleFactor: MediaQuery.of(context).textScaleFactor,
      textDirection: TextDirection.ltr)
    ..layout();

  return textPainter.size;
}
