import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:html_to_text/html_to_text.dart';
import 'package:loader_overlay/loader_overlay.dart';

import '../data/models/forum.dart';
import '../data/services/forum.dart';
import '../data/services/xdnmb_client.dart';
import '../modules/post_list.dart';
import '../utils/exception.dart';
import '../utils/extensions.dart';
import '../utils/toast.dart';
import '../widgets/dialog.dart';
import '../widgets/forum_name.dart';

class _AddForum extends StatelessWidget {
  final GlobalKey<_ForumsState> forumListKey;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  _AddForum({super.key, required this.forumListKey});

  @override
  Widget build(BuildContext context) {
    final client = XdnmbClientService.to.client;
    final forms = ForumListService.to;
    String? id;
    String? name;

    return LoaderOverlay(
      child: InputDialog(
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: '板块ID'),
                autofocus: true,
                keyboardType: TextInputType.number,
                onSaved: (newValue) => id = newValue,
                validator: (value) => value.tryParseInt() == null
                    ? '请输入板块ID数字'
                    : (forms.forum(int.parse(value!)) != null
                        ? '已有该板块ID'
                        : null),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: '板块名字'),
                onSaved: (newValue) => name = newValue,
                validator: (value) =>
                    (value == null || value.isEmpty) ? '请输入板块名字' : null,
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();

                final overlay = context.loaderOverlay;
                try {
                  overlay.show();
                  final forumId = int.parse(id!);
                  final message = await client.getHtmlForumMessage(forumId);
                  final forum = ForumData(
                      id: forumId,
                      name: name!,
                      message: message,
                      maxPage: 100,
                      isDeprecated: true);
                  await forms.addForum(forum);
                  final state = forumListKey.currentState!;
                  state._refresh(() => state._displayedForums.add(forum));

                  showToast('添加板块 $name 成功');
                  Get.back();
                } catch (e) {
                  showToast('添加板块 $name 失败：${exceptionMessage(e)}');
                } finally {
                  if (overlay.visible) {
                    overlay.hide();
                  }
                }
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}

class _DeprecatedButton extends StatelessWidget {
  final VoidCallback onDelete;

  const _DeprecatedButton({super.key, required this.onDelete});

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: () => Get.dialog(
          ConfirmCancelDialog(
            content: '确定删除该板块？',
            onConfirm: () {
              onDelete();
              Get.back();
            },
            onCancel: () => Get.back(),
          ),
        ),
        child: const Text(
          '废弃',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
      );
}

class _Forums extends StatefulWidget {
  const _Forums({super.key});

  @override
  State<_Forums> createState() => _ForumsState();
}

class _ForumsState extends State<_Forums> {
  late final List<ForumData> _displayedForums;

  late final List<ForumData> _hiddenForums;

  void _refresh(VoidCallback fn) {
    if (mounted) {
      setState(() => fn());
    }
  }

  @override
  void initState() {
    super.initState();

    final forums = ForumListService.to;
    _displayedForums = forums.displayedForums.toList();
    _hiddenForums = forums.hiddenForums.toList();
  }

  @override
  void dispose() {
    ForumListService.to.saveForums(
        displayedForums: _displayedForums, hiddenForums: _hiddenForums);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      children: [
        ListTile(
          title: Text('显示板块', style: theme.textTheme.headline6),
        ),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: _displayedForums.length,
          itemBuilder: (context, index) {
            final forum = _displayedForums[index];
            final span = htmlToTextSpan(context, forum.forumName,
                textStyle: theme.textTheme.subtitle1);
            final forumName = span.toPlainText();

            return ListTile(
              key: ValueKey<PostList>(PostList.fromForumData(forum)),
              leading: IconButton(
                onPressed: () {
                  if (mounted) {
                    setState(() {
                      final forum = _displayedForums.removeAt(index);
                      _hiddenForums.add(forum);
                    });
                    showToast('已隐藏板块 $forumName');
                  }
                },
                icon: const Icon(Icons.visibility),
              ),
              title: RichText(text: span),
              trailing: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (forum.isDeprecated)
                    _DeprecatedButton(
                      onDelete: () async {
                        await forum.delete();
                        if (mounted) {
                          setState(() {
                            _displayedForums.removeAt(index);
                          });
                        }
                        showToast('删除板块 $forumName 成功');
                      },
                    ),
                  IconButton(
                    onPressed: () async {
                      await Get.dialog(EditForumName(forum: forum));
                      if (mounted) {
                        setState(() {});
                      }
                    },
                    icon: const Icon(
                      Icons.edit,
                    ),
                  ),
                  ReorderableDragStartListener(
                    index: index,
                    child: const Icon(Icons.drag_handle),
                  ),
                ],
              ),
            );
          },
          onReorder: (oldIndex, newIndex) {
            if (mounted) {
              setState(() {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final forum = _displayedForums.removeAt(oldIndex);
                _displayedForums.insert(newIndex, forum);
              });
            }
          },
        ),
        ListTile(
          title: Text('隐藏板块', style: theme.textTheme.headline6),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            _hiddenForums.length,
            (index) {
              final forum = _hiddenForums[index];
              final span = htmlToTextSpan(context, forum.forumName,
                  textStyle: theme.textTheme.subtitle1);
              final forumName = span.toPlainText();

              return ListTile(
                key: ValueKey<PostList>(PostList.fromForumData(forum)),
                leading: IconButton(
                  onPressed: () {
                    if (mounted) {
                      setState(() {
                        final forum = _hiddenForums.removeAt(index);
                        _displayedForums.add(forum);
                      });
                      showToast('取消隐藏板块 $forumName');
                    }
                  },
                  icon: const Icon(Icons.visibility_off),
                ),
                title: RichText(text: span),
                trailing: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (forum.isDeprecated)
                      _DeprecatedButton(
                        onDelete: () async {
                          await forum.delete();
                          if (mounted) {
                            setState(() {
                              _hiddenForums.removeAt(index);
                            });
                          }
                          showToast('删除板块 $forumName 成功');
                        },
                      ),
                    IconButton(
                      onPressed: () async {
                        await Get.dialog(EditForumName(forum: forum));
                        if (mounted) {
                          setState(() {});
                        }
                      },
                      icon: const Icon(Icons.edit),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ReorderForumsController extends GetxController {}

class ReorderForumsBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(ReorderForumsController());
  }
}

// TODO: 显示版规？
class ReorderForumsView extends GetView<ReorderForumsController> {
  final GlobalKey<_ForumsState> _forumListKey = GlobalKey();

  ReorderForumsView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text('板块排序'),
          actions: [
            IconButton(
                onPressed: () =>
                    Get.dialog(_AddForum(forumListKey: _forumListKey)),
                icon: const Icon(Icons.add)),
          ],
        ),
        body: _Forums(key: _forumListKey),
      );
}
