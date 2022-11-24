import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loader_overlay/loader_overlay.dart';

import '../data/models/forum.dart';
import '../data/services/forum.dart';
import '../data/services/xdnmb_client.dart';
import '../modules/post_list.dart';
import '../utils/exception.dart';
import '../utils/extensions.dart';
import '../utils/text.dart';
import '../utils/toast.dart';
import '../widgets/dialog.dart';
import '../widgets/forum_name.dart';

class _AddForum extends StatelessWidget {
  final GlobalKey<_ForumsState> forumListKey;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // ignore: unused_element
  _AddForum({super.key, required this.forumListKey});

  @override
  Widget build(BuildContext context) {
    final client = XdnmbClientService.to.client;
    final forums = ForumListService.to;
    String? id;

    return LoaderOverlay(
      child: InputDialog(
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: '版块ID'),
                autofocus: true,
                keyboardType: TextInputType.number,
                onSaved: (newValue) => id = newValue,
                validator: (value) => value.tryParseInt() == null
                    ? '请输入版块ID数字'
                    : (forums.forum(int.parse(value!)) != null
                        ? '已有该版块ID'
                        : null),
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
                  final forum = ForumData.fromHtmlForum(
                      await client.getHtmlForumInfo(forumId));
                  await forums.addForum(forum);
                  final state = forumListKey.currentState!;
                  state._refresh(() => state._hiddenForums.add(forum));

                  showToast(
                      '添加版块 ${htmlToPlainText(Get.context!, forum.name)} 成功');
                  Get.back();
                } catch (e) {
                  showToast('添加版块（id：$id）失败：${exceptionMessage(e)}');
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
    final forums = ForumListService.to;
    final theme = Theme.of(context);

    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      header: ListTile(
        title: Text('显示版块', style: theme.textTheme.titleLarge),
      ),
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text('隐藏版块', style: theme.textTheme.titleLarge),
          ),
          ...List.generate(
            _hiddenForums.length,
            (index) {
              final forum = _hiddenForums[index];

              return ListTile(
                key: ValueKey<PostList>(PostList.fromForumData(forum)),
                leading: IconButton(
                  onPressed: () {
                    if (mounted) {
                      setState(() {
                        final forum = _hiddenForums.removeAt(index);
                        _displayedForums.add(forum);
                        forums.displayForum(forum);
                      });
                      showToast(
                          '取消隐藏版块 ${htmlToPlainText(context, forum.forumDisplayName)}');
                    }
                  },
                  icon: const Icon(Icons.visibility_off),
                ),
                title: ForumName(
                  forumId: forum.id,
                  isTimeline: forum.isTimeline,
                  isDeprecated: forum.isDeprecated,
                  textStyle: theme.textTheme.titleMedium,
                  maxLines: 1,
                ),
                trailing: IconButton(
                  onPressed: () => Get.dialog(EditForumName(forum: forum)),
                  icon: const Icon(Icons.edit),
                ),
              );
            },
          )
        ],
      ),
      itemCount: _displayedForums.length,
      itemBuilder: (context, index) {
        final forum = _displayedForums[index];

        return ListTile(
          key: ValueKey<PostList>(PostList.fromForumData(forum)),
          leading: IconButton(
            onPressed: () {
              if (mounted) {
                setState(() {
                  final forum = _displayedForums.removeAt(index);
                  _hiddenForums.add(forum);
                  forums.hideForum(forum);
                });
                showToast(
                    '隐藏版块 ${htmlToPlainText(context, forum.forumDisplayName)}');
              }
            },
            icon: const Icon(Icons.visibility),
          ),
          title: ForumName(
            forumId: forum.id,
            isTimeline: forum.isTimeline,
            isDeprecated: forum.isDeprecated,
            textStyle: theme.textTheme.titleMedium,
            maxLines: 1,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => Get.dialog(EditForumName(forum: forum)),
                icon: const Icon(
                  Icons.edit,
                ),
              ),
              const SizedBox(width: 10.0),
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
    );
  }
}

class ReorderForumsView extends StatelessWidget {
  static final GlobalKey<_ForumsState> _forumListKey =
      GlobalKey<_ForumsState>();

  const ReorderForumsView({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
        left: false,
        top: false,
        right: false,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('版块排序'),
            actions: [
              IconButton(
                  onPressed: () =>
                      Get.dialog(_AddForum(forumListKey: _forumListKey)),
                  icon: const Icon(Icons.add)),
            ],
          ),
          body: _Forums(key: _forumListKey),
        ),
      );
}
