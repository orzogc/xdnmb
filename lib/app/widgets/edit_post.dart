import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:align_positioned/align_positioned.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:responsive_grid_list/responsive_grid_list.dart';
import 'package:xdnmb_api/xdnmb_api.dart' as xdnmb_api;

import '../data/models/controller.dart';
import '../data/models/draft.dart';
import '../data/models/emoticon.dart';
import '../data/models/post.dart';
import '../data/models/reply.dart';
import '../data/services/draft.dart';
import '../data/services/emoticon.dart';
import '../data/services/forum.dart';
import '../data/services/history.dart';
import '../data/services/image.dart';
import '../data/services/persistent.dart';
import '../data/services/settings.dart';
import '../data/services/user.dart';
import '../data/services/xdnmb_client.dart';
import '../modules/edit_post.dart';
import '../modules/image.dart';
import '../modules/paint.dart';
import '../modules/post_list.dart';
import '../routes/routes.dart';
import '../utils/emoticons.dart';
import '../utils/exception.dart';
import '../utils/extensions.dart';
import '../utils/image.dart';
import '../utils/icons.dart';
import '../utils/padding.dart';
import '../utils/text.dart';
import '../utils/theme.dart';
import '../utils/toast.dart';
import 'checkbox.dart';
import 'dialog.dart';
import 'forum_name.dart';
import 'image.dart';
import 'listenable.dart';
import 'scroll.dart';
import 'size.dart';
import 'thread.dart';
import 'tooltip.dart';

class _ForumName extends StatelessWidget {
  final PostListType postListType;

  final int? forumId;

  final ForumCallback onForum;

  const _ForumName(
      // ignore: unused_element
      {super.key,
      required this.postListType,
      required this.forumId,
      required this.onForum});

  @override
  Widget build(BuildContext context) {
    final forums = ForumListService.to;

    return ListenableBuilder(
      listenable: forums.updateForumNameNotifier,
      builder: (context, child) {
        String? forumName;
        if (forumId != null) {
          forumName = forums.forumName(forumId!);
        }
        forumName ??= '选择版块';

        return postListType.isTimeline
            ? TextButton(
                onPressed: () {
                  if (postListType.isTimeline) {
                    Get.dialog(
                      SelectForum(
                        isOnlyForum: true,
                        onSelect: (forum) {
                          onForum(forum);
                          Get.back();
                        },
                      ),
                    );
                  }
                },
                child: ForumNameText(
                  forumName: forumName,
                  textStyle: TextStyle(color: AppTheme.highlightColor),
                  maxLines: 2,
                ),
              )
            : ForumNameText(forumName: forumName, maxLines: 2);
      },
    );
  }
}

class _ReportReasonDialog extends StatelessWidget {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final String? text;

  // ignore: unused_element
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

  final RxnString _value;

  final RxnString _userDefined;

  // ignore: unused_element
  _ReportReason({super.key, this.reportReason, required this.onReportReason})
      : _value = RxnString(reportReason),
        _userDefined = RxnString(xdnmb_api.ReportReason.list
                .any((reason) => reason.reason == reportReason)
            ? null
            : reportReason);

  @override
  Widget build(BuildContext context) {
    final RxDouble width = 0.0.obs;

    return LayoutBuilder(
      builder: (context, constraints) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ChildSizeNotifier(builder: (context, size, child) {
            WidgetsBinding.instance
                .addPostFrameCallback((timeStamp) => width.value = size.width);

            return const Text('举报理由：');
          }),
          Obx(
            () => DropdownButton<String>(
              value: _value.value,
              style: Theme.of(context).textTheme.bodyMedium,
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
                    WidgetsBinding.instance
                        .addPostFrameCallback((timeStamp) async {
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
      // ignore: unused_element
      {super.key,
      required bool isWatermark,
      required this.onWatermark})
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
                fontSize: Theme.of(context).textTheme.titleMedium?.fontSize),
          ),
        ),
      ],
    );
  }
}

class _Image extends StatelessWidget {
  final double maxWidth;

  final double maxHeight;

  final String? imagePath;

  final Uint8List? imageData;

  final bool isWatermark;

  final VoidCallback onCancel;

  final _WatermarkCallback onWatermark;

  final ImageDataCallback onImageFileLoaded;

  final ImageDataCallback onImagePainted;

  final UniqueKey _tag = UniqueKey();

  final Future<Uint8List>? _readImageFile;

  _Image(
      // ignore: unused_element
      {super.key,
      required this.maxWidth,
      required this.maxHeight,
      this.imagePath,
      this.imageData,
      required this.isWatermark,
      required this.onCancel,
      required this.onWatermark,
      required this.onImageFileLoaded,
      required this.onImagePainted})
      : assert(imagePath != null || imageData != null),
        _readImageFile =
            imageData == null ? File(imagePath!).readAsBytes() : null;

  Widget _memoryImage(Uint8List imageData) => Image.memory(
        imageData,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            loadingImageErrorBuilder(context, imagePath, error),
      );

  Widget _fileImage() => FutureBuilder<Uint8List>(
        future: _readImageFile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasError) {
            showToast('读取图片出错：${snapshot.error!}');
          }

          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            WidgetsBinding.instance.addPostFrameCallback(
                (timeStamp) => onImageFileLoaded(snapshot.data!));

            return _memoryImage(snapshot.data!);
          }

          return const SizedBox.shrink();
        },
      );

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: AlignPositioned.relative(
          alignment: Alignment.topRight,
          container: GestureDetector(
            onTap: imageData != null
                ? () async {
                    final result = await AppRoutes.toImage(ImageController(
                        tag: _tag,
                        imageData: imageData,
                        canReturnImageData: true));
                    if (result is Uint8List) {
                      onImagePainted(result);
                    }
                  }
                : null,
            onLongPress: () => Get.dialog(_WatermarkDialog(
                isWatermark: isWatermark, onWatermark: onWatermark)),
            child: Hero(
              tag: _tag,
              child:
                  imageData != null ? _memoryImage(imageData!) : _fileImage(),
            ),
          ),
          child: ElevatedButton(
            onPressed: onCancel,
            style: ElevatedButton.styleFrom(shape: const CircleBorder()),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Icon(Icons.close,
                    size: min(constraints.maxHeight, 24.0));
              },
            ),
          ),
        ),
      );
}

typedef _OnCheckCallback = void Function(bool isCheck);

class _AttachDeviceInfo extends StatelessWidget {
  final bool isChecked;

  final _OnCheckCallback onCheck;

  const _AttachDeviceInfo(
      // ignore: unused_element
      {super.key,
      required this.isChecked,
      required this.onCheck});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          AppCheckbox(
            value: isChecked,
            onChanged: (value) {
              if (value != null) {
                onCheck(value);
              }
            },
          ),
          const Flexible(child: Text('附加应用和设备信息')),
          const SizedBox(width: 5),
          const QuestionTooltip(message: '提供这些信息以便开发者更好地解决问题'),
        ],
      );
}

class _ShowEmoticon extends StatelessWidget {
  final RxBool showEmoticon;

  // ignore: unused_element
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

typedef _InsertTextCallback = void Function(String text, [int? offset]);

class _DiceDialog extends StatefulWidget {
  final _InsertTextCallback onDice;

  // ignore: unused_element
  const _DiceDialog({super.key, required this.onDice});

  @override
  State<_DiceDialog> createState() => _DiceDialogState();
}

class _DiceDialogState extends State<_DiceDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _lowerController;

  late final TextEditingController _upperController;

  @override
  void initState() {
    super.initState();

    final data = PersistentDataService.to;
    _lowerController = TextEditingController(text: '${data.diceLower}');
    _upperController = TextEditingController(text: '${data.diceUpper}');
  }

  @override
  void dispose() {
    _lowerController.dispose();
    _upperController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => InputDialog(
        title: const Text('骰子范围'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Flexible(
                    child: IconButton(
                      onPressed: () {
                        final number = _lowerController.text.tryParseInt();
                        if (number != null) {
                          _lowerController.text = '${number - 1}';
                        }
                      },
                      icon: const Icon(Icons.chevron_left),
                    ),
                  ),
                  Flexible(
                    child: SizedBox(
                      width: 80,
                      child: TextFormField(
                        controller: _lowerController,
                        decoration: const InputDecoration(hintText: '下限'),
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value.tryParseInt() == null ? '请输入数字' : null,
                      ),
                    ),
                  ),
                  Flexible(
                    child: IconButton(
                      onPressed: () {
                        final number = _lowerController.text.tryParseInt();
                        if (number != null) {
                          _lowerController.text = '${number + 1}';
                        }
                      },
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10.0),
              const Text('|'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Flexible(
                    child: IconButton(
                      onPressed: () {
                        final number = _upperController.text.tryParseInt();
                        if (number != null) {
                          _upperController.text = '${number - 1}';
                        }
                      },
                      icon: const Icon(Icons.chevron_left),
                    ),
                  ),
                  Flexible(
                    child: SizedBox(
                      width: 80,
                      child: TextFormField(
                        controller: _upperController,
                        decoration: const InputDecoration(hintText: '上限'),
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value.tryParseInt() == null ? '请输入数字' : null,
                      ),
                    ),
                  ),
                  Flexible(
                    child: IconButton(
                      onPressed: () {
                        final number = _upperController.text.tryParseInt();
                        if (number != null) {
                          _upperController.text = '${number + 1}';
                        }
                      },
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                final data = PersistentDataService.to;
                data.diceLower = int.parse(_lowerController.text);
                data.diceUpper = int.parse(_upperController.text);

                widget.onDice(
                    '[${_lowerController.text},${_upperController.text}]');
                Get.back();
              }
            },
            child: const Text('确定'),
          ),
        ],
      );
}

class _Dice extends StatelessWidget {
  final _InsertTextCallback onDice;

  // ignore: unused_element
  const _Dice({super.key, required this.onDice});

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: () => Get.dialog(_DiceDialog(onDice: onDice)),
        icon: const Icon(AppIcons.dice, size: 18.0),
      );
}

class _Paint extends StatelessWidget {
  final Uint8List? imageData;

  final ImageDataCallback onImage;

  // ignore: unused_element
  const _Paint({super.key, this.imageData, required this.onImage});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () async {
        final data = await AppRoutes.toPaint(
            imageData != null ? PaintController(imageData) : null);
        if (data is Uint8List) {
          onImage(data);
        }
      },
      icon: const Icon(Icons.brush),
    );
  }
}

typedef _GetText = String Function();

class _SaveDraft extends StatelessWidget {
  final _GetText getTitle;

  final _GetText getName;

  final _GetText getContent;

  const _SaveDraft(
      // ignore: unused_element
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
            PostDraftListService.to.addDraft(PostDraftData(
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
  // ignore: unused_element
  const _Cookie({super.key});

  @override
  Widget build(BuildContext context) {
    final user = UserService.to;
    final size =
        getTextSize(context, '啊啊啊啊啊啊啊', Theme.of(context).textTheme.bodyMedium);

    return user.hasPostCookie
        ? ListenableBuilder(
            listenable: user.postCookieListenable,
            builder: (context, child) => TextButton(
              onPressed: () => Get.dialog(
                SimpleDialog(
                  children: [
                    for (final cookie in user.xdnmbCookies)
                      ListTile(
                        onTap: () {
                          user.postCookie = cookie.copy();
                          Get.back();
                        },
                        title: Text(cookie.name,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: (cookie.note?.isNotEmpty ?? false)
                            ? Text(cookie.note!,
                                maxLines: 1, overflow: TextOverflow.ellipsis)
                            : null,
                        trailing:
                            (user.isUserCookieValid && cookie.isDeprecated)
                                ? const Text('非登陆帐号饼干', style: AppTheme.boldRed)
                                : null,
                      ),
                  ],
                ),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: size.width),
                child: Text(
                  user.postCookie!.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          )
        : TextButton(
            onPressed: () => AppRoutes.toUser(),
            child: const Text(
              '没有饼干',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.boldRed,
            ),
          );
  }
}

class _Post extends StatelessWidget {
  static const Duration _difference = Duration(seconds: 60);

  final PostList postList;

  final int? forumId;

  final bool isWatermark;

  final Uint8List? imageData;

  final String? reportReason;

  final bool isPainted;

  final bool isAttachDeviceInfo;

  final _GetText getTitle;

  final _GetText getName;

  final _GetText getContent;

  final VoidCallback onPost;

  const _Post(
      // ignore: unused_element
      {super.key,
      required this.postList,
      this.forumId,
      this.isWatermark = false,
      this.imageData,
      this.reportReason,
      required this.isPainted,
      required this.isAttachDeviceInfo,
      required this.getTitle,
      required this.getName,
      required this.getContent,
      required this.onPost});

  Future<xdnmb_api.LastPost?> _getLastPost(String cookie) async {
    try {
      return await XdnmbClientService.to.client.getLastPost(cookie: cookie);
    } catch (e) {
      debugPrint('获取发布的新串数据出错：$e');
      return null;
    }
  }

  Future<void> _savePost(PostData post, String cookie) async {
    debugPrint('开始获取发布的新串数据');
    final history = PostHistoryService.to;

    try {
      final id = await history.savePostData(post);

      final lastPost = await _getLastPost(cookie);
      if (lastPost != null &&
          lastPost.mainPostId == null &&
          lastPost.userHash == post.userHash) {
        await history.updatePostData(id, lastPost);
      } else {
        final forum = await XdnmbClientService.to.client
            .getForum(post.forumId, cookie: cookie);
        final threads = forum.where((thread) =>
            thread.mainPost.userHash == post.userHash &&
            thread.mainPost.postTime.difference(post.postTime).abs() <
                _difference);
        if (threads.isNotEmpty) {
          await history.updatePostData(id, threads.first.mainPost);
        } else {
          showToast('获取发布的新串数据失败');
        }
      }

      debugPrint('获取发布的新串数据成功');
    } catch (e) {
      showToast('获取发布的新串数据出错：${exceptionMessage(e)}');
    }
  }

  Future<bool> _getPost(
      {required int id,
      required ReplyData reply,
      required int page,
      required String cookie}) async {
    final thread = await XdnmbClientService.to.client
        .getThread(reply.mainPostId, page: page, cookie: cookie);
    final posts = thread.replies.where((post) =>
        post.userHash == reply.userHash &&
        (post.postTime.difference(reply.postTime).abs() < _difference));
    if (posts.isNotEmpty) {
      return await PostHistoryService.to
          .updateReplyData(id: id, post: posts.last, page: page);
    }

    return false;
  }

  Future<bool> _getPostPage(
      {required int id,
      required xdnmb_api.LastPost lastPost,
      required int page,
      required String cookie}) async {
    final thread = await XdnmbClientService.to.client
        .getThread(lastPost.mainPostId!, page: page, cookie: cookie);
    final posts = thread.replies.where((post) => post.id == lastPost.id);
    if (posts.isNotEmpty) {
      if (posts.length > 1) {
        debugPrint('postId出现重复');
      }

      return await PostHistoryService.to
          .updateReplyData(id: id, post: posts.last, page: page);
    }

    return false;
  }

  Future<void> _saveReply(ReplyData reply, String cookie) async {
    debugPrint('开始获取回串数据');
    final history = PostHistoryService.to;
    final client = XdnmbClientService.to.client;

    try {
      final id = await history.saveReplyData(reply);

      final lastPost = await _getLastPost(cookie);
      if (lastPost != null &&
          lastPost.mainPostId == reply.mainPostId &&
          lastPost.userHash == reply.userHash) {
        await history.updateReplyData(id: id, post: lastPost);
        final thread = await client.getThread(reply.mainPostId, cookie: cookie);
        final maxPage = thread.maxPage;

        if (!await _getPostPage(
            id: id, lastPost: lastPost, page: maxPage, cookie: cookie)) {
          if (maxPage > 1) {
            if (!await _getPostPage(
                id: id,
                lastPost: lastPost,
                page: maxPage - 1,
                cookie: cookie)) {
              showToast('获取回串数据失败');
            }
          } else {
            showToast('获取回串数据失败');
          }
        }
      } else {
        final thread = await client.getThread(reply.mainPostId, cookie: cookie);
        final maxPage = thread.maxPage;

        if (!await _getPost(
            id: id, reply: reply, page: maxPage, cookie: cookie)) {
          if (maxPage > 1) {
            if (!await _getPost(
                id: id, reply: reply, page: maxPage - 1, cookie: cookie)) {
              showToast('获取回串数据失败');
            }
          } else {
            showToast('获取回串数据失败');
          }
        }
      }

      debugPrint('获取回串数据成功');
    } catch (e) {
      showToast('获取回串数据出错：${exceptionMessage(e)}');
    }
  }

  @override
  Widget build(BuildContext context) => IconButton(
        onPressed: () {
          final user = UserService.to;
          final controller = PostListController.get();

          if (user.hasPostCookie) {
            if (forumId != null) {
              final postListType = postList.postListType;

              if (postListType.isForum &&
                  forumId == EditPost.dutyRoomId &&
                  (reportReason == null || reportReason!.isEmpty)) {
                showToast('请选择举报理由');
                return;
              }

              final content = getContent();

              if (content.isNotEmpty || imageData != null) {
                final client = XdnmbClientService.to.client;

                final title = getTitle();
                final name = getName();
                final cookie = user.postCookie!;
                String postContent = content;

                Future(() async {
                  xdnmb_api.Image? image;
                  if (imageData != null) {
                    image = getImage(imageData!);
                    if (image == null) {
                      throw '无效的图片格式';
                    }
                  }

                  if (postListType.isForumType) {
                    if (postListType.isForum &&
                        forumId == EditPost.dutyRoomId) {
                      postContent = '举报理由：$reportReason\n$postContent';
                    }

                    await client.postNewThread(
                      forumId: forumId!,
                      content: postContent,
                      name: name.isNotEmpty ? name : null,
                      title: title.isNotEmpty ? title : null,
                      watermark: isWatermark,
                      image: image,
                      cookie: cookie.cookie(),
                    );
                  } else if (postListType.isThreadType) {
                    if (postList.id == AppRoutes.feedbackId &&
                        isAttachDeviceInfo) {
                      final buffer = StringBuffer('霞岛版本：');
                      final packageInfo = await PackageInfo.fromPlatform();
                      buffer.writeln(packageInfo.version);

                      final deviceInfo = await _getDeviceInfo();
                      if (deviceInfo != null) {
                        buffer.writeln('设备信息：$deviceInfo');
                      }

                      postContent = '$postContent\n\n${buffer.toString()}';
                    }

                    await client.replyThread(
                      mainPostId: postList.id!,
                      content: postContent,
                      name: name.isNotEmpty ? name : null,
                      title: title.isNotEmpty ? title : null,
                      watermark: isWatermark,
                      image: image,
                      cookie: cookie.cookie(),
                    );
                  } else {
                    showToast('该页面无法发串');
                  }
                }).then(
                  (value) {
                    if (postListType.isForumType) {
                      showToast('发表新串成功');
                      final post = PostData(
                          forumId: forumId!,
                          postTime: DateTime.now(),
                          userHash: cookie.name,
                          name: name,
                          title: title,
                          content: postContent);
                      _savePost(post, cookie.cookie());
                    } else {
                      showToast('回串成功');
                      final reply = ReplyData(
                          mainPostId: postList.id!,
                          forumId: forumId!,
                          postTime: DateTime.now(),
                          userHash: cookie.name,
                          name: name,
                          title: title,
                          content: postContent);
                      _saveReply(reply, cookie.cookie());
                    }

                    if (controller.postListType == postListType &&
                        (controller.isTimeline ||
                            (controller.isForum && controller.id == forumId) ||
                            (controller.isThreadType &&
                                controller.id == postList.id))) {
                      try {
                        if (controller.isForumType &&
                            SettingsService.to.isAfterPostRefresh) {
                          controller.refreshPage();
                        } else if (controller.isThread) {
                          final controller_ = controller as ThreadController;
                          if (controller_.loadMore != null) {
                            controller_.loadMore!();
                          }
                        }
                      } catch (e) {
                        debugPrint('发串后刷新数据出现错误：$e');
                      }
                    } else {
                      debugPrint('PostListController跟发串的数据对不上');
                    }
                  },
                  onError: (e) async {
                    final message = GetPlatform.isIOS
                        ? '图片保存在相册'
                        : '图片保存在 ${ImageService.savePath} ';
                    if (title.isNotEmpty ||
                        name.isNotEmpty ||
                        content.isNotEmpty) {
                      await PostDraftListService.to.addDraft(PostDraftData(
                          title: title.isNotEmpty ? title : null,
                          name: name.isNotEmpty ? name : null,
                          content: content.isNotEmpty ? content : null));

                      if (isPainted &&
                          imageData != null &&
                          await saveImageData(imageData!)) {
                        showToast(
                            '发串失败，内容已保存为草稿，$message：${exceptionMessage(e)}');
                      } else {
                        showToast('发串失败，内容已保存为草稿：${exceptionMessage(e)}');
                      }
                    } else {
                      if (isPainted &&
                          imageData != null &&
                          await saveImageData(imageData!)) {
                        showToast('发串失败，$message：${exceptionMessage(e)}');
                      } else {
                        showToast('发串失败：${exceptionMessage(e)}');
                      }
                    }
                  },
                );

                onPost();
                Get.back<bool>(result: true);
              } else {
                showToast('不发图时串的内容不能为空');
              }
            } else {
              showToast('请选择版块');
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

  // ignore: unused_element
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
                await EmoticonListService.to
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

  // ignore: unused_element
  const _EmoticonDialog(this.emoticon, {super.key});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleMedium;

    return SimpleDialog(
      children: [
        SimpleDialogOption(
          onPressed: () {
            Get.back();
            Get.dialog(_EditEmoticon(emoticon: emoticon));
          },
          child: Text('修改 ${emoticon.name}', style: textStyle),
        ),
        SimpleDialogOption(
          onPressed: () async {
            await Get.dialog(ConfirmCancelDialog(
              content: '确定删除颜文字 ${emoticon.name}？',
              onConfirm: () async {
                await emoticon.delete();
                Get.back();
                showToast('删除颜文字 ${emoticon.name} 成功');
              },
              onCancel: () => Get.back(),
            ));
            Get.back();
          },
          child: Text('删除 ${emoticon.name}', style: textStyle),
        ),
      ],
    );
  }
}

class _Emoticon extends StatefulWidget {
  final _InsertTextCallback onTap;

  // ignore: unused_element
  const _Emoticon({super.key, required this.onTap});

  @override
  State<_Emoticon> createState() => _EmoticonState();
}

class _EmoticonState extends State<_Emoticon> {
  static const double _defaultHeight = 200.0;

  static final Iterable<EmoticonData> _emoticonList = xdnmb_api.Emoticon.list
      .getRange(0, xdnmb_api.Emoticon.list.length - 3)
      .map((emoticon) => EmoticonData(name: emoticon.name, text: emoticon.text))
      .followedBy([
    EmoticonData(name: '防剧透', text: '[h][/h]', offset: 3),
    EmoticonData(name: '全角空格', text: '　'),
  ]);

  static final Iterable<EmoticonData> _emoticonList2 = xdnmb_api.Emoticon.list
      .getRange(0, xdnmb_api.Emoticon.list.length - 3)
      .map((emoticon) => EmoticonData(name: emoticon.name, text: emoticon.text))
      .followedBy(blueIslandEmoticons)
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
    final emoticons = EmoticonListService.to;
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    final buttonStyle = TextButton.styleFrom(
      padding: EdgeInsets.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    return ValueListenableBuilder(
      valueListenable: data.bottomHeight,
      builder: (context, value, child) => Obx(
        () {
          final height = max(
              (data.keyboardHeight != null && data.keyboardHeight! > 0)
                  ? data.keyboardHeight! - value
                  : _defaultHeight - value,
              0.0);

          return !data.isKeyboardVisible.value
              ? SizedBox(
                  height: height,
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 20.0, right: 20.0, bottom: 10.0),
                    child: Scrollbar(
                      controller: _controller,
                      thumbVisibility: true,
                      child: ListenableBuilder(
                        listenable: emoticons.emoticonsListenable,
                        // 这里可能有性能问题
                        builder: (context, child) => ResponsiveGridList(
                          key: const PageStorageKey<String>('emoticons'),
                          minItemWidth: 80.0,
                          horizontalGridSpacing: 10.0,
                          verticalGridSpacing: 10.0,
                          listViewBuilderOptions: ListViewBuilderOptions(
                            controller: _controller,
                            shrinkWrap: true,
                          ),
                          children: [
                            for (final emoticon
                                in SettingsService.to.addBlueIslandEmoticons
                                    ? _emoticonList2
                                    : _emoticonList)
                              TextButton(
                                style: buttonStyle,
                                onPressed: () => widget.onTap(
                                    emoticon.text, emoticon.offset),
                                child: Text(emoticon.name, style: textStyle),
                              ),
                            for (final emoticon in emoticons.emoticons)
                              TextButton(
                                style: buttonStyle,
                                onPressed: () => widget.onTap(
                                    emoticon.text, emoticon.offset),
                                onLongPress: () =>
                                    Get.dialog(_EmoticonDialog(emoticon)),
                                child: Text(emoticon.name, style: textStyle),
                              ),
                            child!,
                          ],
                        ),
                        child: TextButton(
                          style: buttonStyle,
                          onPressed: () => Get.dialog(const _EditEmoticon()),
                          child: Text('自定义', style: textStyle),
                        ),
                      ),
                    ),
                  ),
                )
              : SizedBox(height: height);
        },
      ),
    );
  }
}

typedef IsPostedCallback = bool Function();

typedef ToContorllerCallback = EditPostController Function();

typedef InsertTextCallback = void Function(String text, [int? offset]);

typedef InsertImageCallback = void Function(Uint8List imageData);

typedef SetPostListCallback = void Function(PostList postList, int? forumId);

class EditPostCallback {
  static EditPostCallback? bottomSheet;

  static EditPostCallback? page;

  final IsPostedCallback _isPosted;

  final ToContorllerCallback _toController;

  final InsertTextCallback _insertText;

  final InsertImageCallback _insertImage;

  final SetPostListCallback _setPostList;

  EditPostCallback._internal(
      {required IsPostedCallback isPosted,
      required ToContorllerCallback toController,
      required InsertTextCallback insertText,
      required InsertImageCallback insertImage,
      required SetPostListCallback setPostList})
      : _isPosted = isPosted,
        _toController = toController,
        _insertText = insertText,
        _insertImage = insertImage,
        _setPostList = setPostList;

  bool isPosted() => _isPosted();

  EditPostController toController() => _toController();

  void insertText(String text, [int? offset]) => _insertText(text, offset);

  void insertImage(Uint8List imageData) => _insertImage(imageData);

  void setPostList(PostList postList, int? forumId) =>
      _setPostList(postList, forumId);
}

class EditPost extends StatefulWidget {
  static const int dutyRoomId = 18;

  final PostList postList;

  final double? height;

  final int? forumId;

  final String? title;

  final String? name;

  final String? content;

  final String? imagePath;

  final Uint8List? imageData;

  final bool? isWatermark;

  final String? reportReason;

  final bool? isAttachDeviceInfo;

  const EditPost(
      {super.key,
      required this.postList,
      this.height,
      this.forumId,
      this.title,
      this.name,
      this.content,
      this.imagePath,
      this.imageData,
      this.isWatermark,
      this.reportReason,
      this.isAttachDeviceInfo});

  EditPost.fromController(
      {Key? key, required EditPostController controller, double? height})
      : this(
            key: key,
            postList: PostList(
                postListType: controller.postListType, id: controller.id),
            height: height,
            forumId: controller.forumId,
            title: controller.title,
            name: controller.name,
            content: controller.content,
            imagePath: controller.imagePath,
            imageData: controller.imageData,
            isWatermark: controller.isWatermark,
            reportReason: controller.reportReason,
            isAttachDeviceInfo: controller.isAttachDeviceInfo);

  @override
  State<EditPost> createState() => _EditPostState();
}

class _EditPostState extends State<EditPost> {
  late final Rx<PostList> _postList;

  late final RxnInt _forumId;

  late final TextEditingController _titleController;

  late final TextEditingController _nameController;

  late final TextEditingController _contentController;

  late final RxnString _imagePath;

  late final Rxn<Uint8List> _imageData;

  late final RxBool _isWatermark;

  late final RxnString _reportReason;

  late final RxBool _isAttachDeviceInfo;

  late final RxBool _isExpanded;

  final RxBool _showEmoticon = false.obs;

  bool _isPosted = false;

  bool get _isAtBottom => widget.height != null;

  bool get _canAttachDeviceInfo {
    final postList = _postList.value;

    return postList.postListType.isThreadType &&
        postList.id == AppRoutes.feedbackId;
  }

  EditPostController _toController() => EditPostController(
      postListType: _postList.value.postListType,
      id: _postList.value.id!,
      forumId: _forumId.value,
      title: _titleController.text,
      name: _nameController.text,
      content: _contentController.text,
      imagePath: _imagePath.value,
      imageData: _imageData.value,
      isWatermark: _isWatermark.value,
      reportReason: _reportReason.value,
      isAttachDeviceInfo: _isAttachDeviceInfo.value);

  void _insertText(String text, [int? offset]) =>
      _contentController.insertText(text, offset);

  void _insertImage(Uint8List imageData) {
    _imagePath.value = null;
    _imageData.value = imageData;
  }

  void _setPostList(PostList postList, int? forumId) {
    _postList.value = postList;
    _forumId.value =
        forumId ?? (postList.postListType.isForum ? postList.id : null);
  }

  Widget _inputArea(BuildContext context, double height) {
    assert(height > 0.0);

    final textStyle = Theme.of(context).textTheme.bodyMedium;

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
            Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: IconButton(
                      onPressed: () => _isExpanded.value = !_isExpanded.value,
                      icon: const Icon(Icons.more_horiz, size: 20.0),
                    ),
                  ),
                  Flexible(
                    child: _ForumName(
                      postListType: _postList.value.postListType,
                      forumId: _forumId.value,
                      onForum: (forum) => _forumId.value = forum.id,
                    ),
                  ),
                  if (_postList.value.postListType.isThreadType)
                    Text(_postList.value.id!.toPostNumber()),
                  Flexible(
                    child: IconButton(
                      onPressed: () async {
                        final result = await AppRoutes.toPostDrafts();

                        if (result is PostDraftData) {
                          _titleController.text = result.title ?? '';
                          _nameController.text = result.name ?? '';
                          _contentController.text = result.content ?? '';
                          _isExpanded.value =
                              _titleController.text.isNotEmpty ||
                                  _nameController.text.isNotEmpty;
                        } else if (result is Uint8List) {
                          _imagePath.value = null;
                          _imageData.value = result;
                        }
                      },
                      icon: const Icon(Icons.edit_note),
                    ),
                  ),
                  if (_isAtBottom)
                    Flexible(
                      child: IconButton(
                        onPressed: () async {
                          final result = await AppRoutes.toEditPost(
                              postListType: _postList.value.postListType,
                              id: _postList.value.id!,
                              forumId: _forumId.value,
                              title: _titleController.text,
                              name: _nameController.text,
                              content: _contentController.text,
                              imagePath: _imagePath.value,
                              imageData: _imageData.value,
                              isWatermark: _isWatermark.value,
                              reportReason: _reportReason.value,
                              isAttachDeviceInfo: _isAttachDeviceInfo.value);

                          if (result is EditPostController && mounted) {
                            _forumId.value = result.forumId;
                            _titleController.text = result.title ?? '';
                            _nameController.text = result.name ?? '';
                            _contentController.text = result.content ?? '';
                            _imagePath.value = result.imagePath;
                            _imageData.value = result.imageData;
                            _isWatermark.value = result.isWatermark ??
                                SettingsService.to.isWatermark;
                            _reportReason.value = result.reportReason;
                            _isAttachDeviceInfo.value =
                                result.isAttachDeviceInfo ?? true;
                            _isExpanded.value =
                                _titleController.text.isNotEmpty ||
                                    _nameController.text.isNotEmpty;
                          } else if (result is bool && result) {
                            _isPosted = true;
                            Get.back();
                          }
                        },
                        icon: const Icon(Icons.open_in_new, size: 20.0),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final height = getLineHeight(context, 'A啊', textStyle);
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
                            if (_postList.value.postListType.isForum &&
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
                                if (_imagePath.value != null ||
                                    _imageData.value != null)
                                  _Image(
                                    maxWidth: constraints.maxWidth / 3.0,
                                    maxHeight: constraints.maxHeight,
                                    imagePath: _imagePath.value,
                                    imageData: _imageData.value,
                                    isWatermark: _isWatermark.value,
                                    onCancel: () {
                                      _imagePath.value = null;
                                      _imageData.value = null;
                                    },
                                    onWatermark: (isWatermark) =>
                                        _isWatermark.value = isWatermark,
                                    onImageFileLoaded: (imageData) =>
                                        _imageData.value = imageData,
                                    onImagePainted: (imageData) {
                                      _imagePath.value = null;
                                      _imageData.value = imageData;
                                    },
                                  ),
                                if (_imagePath.value != null)
                                  const SizedBox(width: 10.0),
                                Expanded(
                                  child: TextField(
                                    controller: _contentController,
                                    style: textStyle,
                                    maxLines: null,
                                    minLines: max(
                                        (constraints.maxHeight - 24.0) ~/
                                            height,
                                        1),
                                    textAlignVertical: TextAlignVertical.top,
                                    decoration: InputDecoration(
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.all(12.0),
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
            Obx(
              () => _canAttachDeviceInfo
                  ? _AttachDeviceInfo(
                      isChecked: _isAttachDeviceInfo.value,
                      onCheck: (isCheck) => _isAttachDeviceInfo.value = isCheck)
                  : const SizedBox.shrink(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: _ShowEmoticon(_showEmoticon)),
                Flexible(child: PickImage(onPickImage: (path) {
                  debugPrint('image path: $path');
                  _imagePath.value = path;
                  _imageData.value = null;
                })),
                Flexible(child: _Dice(onDice: _insertText)),
                Flexible(
                  child: Obx(
                    () => _Paint(
                      imageData: _imageData.value,
                      onImage: (imageData) {
                        _imagePath.value = null;
                        _imageData.value = imageData;
                      },
                    ),
                  ),
                ),
                Flexible(
                  child: _SaveDraft(
                    getTitle: () => _titleController.text,
                    getName: () => _nameController.text,
                    getContent: () => _contentController.text,
                  ),
                ),
                const Spacer(),
                const _Cookie(),
                Flexible(
                  child: Obx(
                    () => _Post(
                      postList: _postList.value,
                      forumId: _forumId.value,
                      isWatermark: _isWatermark.value,
                      imageData: _imageData.value,
                      isPainted:
                          _imagePath.value == null && _imageData.value != null,
                      isAttachDeviceInfo:
                          _canAttachDeviceInfo && _isAttachDeviceInfo.value,
                      reportReason: (_postList.value.postListType.isForum &&
                              _forumId.value == EditPost.dutyRoomId)
                          ? _reportReason.value
                          : null,
                      getTitle: () => _titleController.text,
                      getName: () => _nameController.text,
                      getContent: () => _contentController.text,
                      onPost: () => _isPosted = true,
                    ),
                  ),
                ),
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

    _postList = Rx(widget.postList);
    _forumId = RxnInt(widget.forumId ??
        (widget.postList.postListType.isForum ? widget.postList.id : null));

    _titleController = _initController(widget.title);
    _nameController = _initController(widget.name);
    _contentController = _initController(widget.content);

    if ((widget.title?.isNotEmpty ?? false) ||
        (widget.name?.isNotEmpty ?? false)) {
      _isExpanded = true.obs;
    } else {
      _isExpanded = false.obs;
    }

    _imagePath = RxnString(widget.imagePath);
    _imageData = Rxn(widget.imageData);
    _isWatermark = (widget.isWatermark ?? SettingsService.to.isWatermark).obs;
    _reportReason = RxnString(widget.reportReason);
    _isAttachDeviceInfo = (widget.isAttachDeviceInfo ?? true).obs;

    if (widget.height != null) {
      EditPostCallback.bottomSheet = EditPostCallback._internal(
          isPosted: () => _isPosted,
          toController: _toController,
          insertText: _insertText,
          insertImage: _insertImage,
          setPostList: _setPostList);
    } else {
      EditPostCallback.page = EditPostCallback._internal(
          isPosted: () => _isPosted,
          toController: _toController,
          insertText: _insertText,
          insertImage: _insertImage,
          setPostList: _setPostList);
    }
  }

  @override
  void dispose() {
    if (widget.height != null) {
      EditPostCallback.bottomSheet = null;
    } else {
      EditPostCallback.page = null;
    }

    _titleController.dispose();
    _nameController.dispose();
    _contentController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('build edit');

    final data = PersistentDataService.to;
    final media = MediaQuery.of(context);
    final padding = getViewPadding();
    final fullHeight = media.size.height -
        padding.top -
        PostListAppBar.height -
        padding.bottom;

    return ValueListenableBuilder<double>(
      valueListenable: data.bottomHeight,
      builder: (context, value, child) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isAtBottom)
            _inputArea(
                context, max(min(widget.height!, fullHeight - value), 0.0))
          else
            Obx(
              () {
                final dynamicHeight = fullHeight - value;
                final lessHeight = fullHeight - (data.keyboardHeight ?? value);

                return (data.isKeyboardVisible.value || _showEmoticon.value)
                    ? _inputArea(context, max(lessHeight, 0.0))
                    : _inputArea(context, max(dynamicHeight, 0.0));
              },
            ),
          Obx(
            () => _showEmoticon.value
                ? _Emoticon(onTap: _insertText)
                : const SizedBox.shrink(),
          ),
        ],
      ),
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

Future<String?> _getDeviceInfo() async {
  final deviceInfo = DeviceInfoPlugin();

  if (GetPlatform.isAndroid) {
    final info = await deviceInfo.androidInfo;
    final version = info.version;

    return 'Android ${info.brand} ${info.device} ${info.display} ${version.release} ${version.sdkInt}';
  } else if (GetPlatform.isIOS) {
    final info = await deviceInfo.iosInfo;
    //final utsname = info.utsname;

    // TODO: 需要确认需要哪些信息
    return 'iOS ${info.data}';
    //return 'iOS: ${info.localizedModel} ${info.model} ${info.name} ${info.systemName} ${info.systemVersion} ${utsname.machine} ${utsname.sysname} ${utsname.version}';
  } else if (GetPlatform.isLinux) {
    final info = await deviceInfo.linuxInfo;
    final message = StringBuffer('Linux ${info.prettyName}');
    if (info.variant != null) {
      message.write(' ${info.variant}');
    }

    return message.toString();
  } else if (GetPlatform.isMacOS) {
    final info = await deviceInfo.macOsInfo;

    return 'macOS ${info.model} ${info.arch} ${info.osRelease}';
  } else if (GetPlatform.isWindows) {
    final info = await deviceInfo.windowsInfo;

    return 'Windows ${info.productName}';
  }

  return null;
}
