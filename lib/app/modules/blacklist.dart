import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:html_to_text/html_to_text.dart';

import '../data/models/forum.dart';
import '../data/services/blacklist.dart';
import '../data/services/forum.dart';
import '../utils/extensions.dart';
import '../utils/navigation.dart';
import '../utils/text.dart';
import '../utils/theme.dart';
import '../utils/toast.dart';
import '../widgets/dialog.dart';
import '../widgets/forum_name.dart';

class _AppBarTitle extends StatelessWidget {
  final int index;

  const _AppBarTitle({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    late final String text;
    switch (index) {
      case BlacklistView._forumIndex:
        text = '板块黑名单';
        break;
      case BlacklistView._postIndex:
        text = '串号黑名单';
        break;
      case BlacklistView._userIndex:
        text = '饼干黑名单';
        break;
      default:
        text = '黑名单';
    }

    return Text(text);
  }
}

class _AppBarPopupMenuButton extends StatelessWidget {
  final int index;

  final VoidCallback refresh;

  const _AppBarPopupMenuButton(
      {super.key, required this.index, required this.refresh});

  @override
  Widget build(BuildContext context) {
    final blacklist = BlacklistService.to;

    return PopupMenuButton(
      itemBuilder: (context) => [
        PopupMenuItem(
          onTap: () => WidgetsBinding.instance.addPostFrameCallback(
            (timeStamp) {
              switch (index) {
                case BlacklistView._forumIndex:
                  if (blacklist.forumBlacklistLength > 0) {
                    Get.dialog(ConfirmCancelDialog(
                      content: '确定清空板块黑名单？',
                      onConfirm: () async {
                        await blacklist.clearForumBlacklist();
                        refresh();
                        Get.back();
                      },
                      onCancel: () => Get.back(),
                    ));
                  }

                  break;
                case BlacklistView._postIndex:
                  if (blacklist.postBlacklistLength > 0) {
                    Get.dialog(ConfirmCancelDialog(
                      content: '确定清空串号黑名单？',
                      onConfirm: () async {
                        await blacklist.clearPostBlacklist();
                        refresh();
                        Get.back();
                      },
                      onCancel: () => Get.back(),
                    ));
                  }

                  break;
                case BlacklistView._userIndex:
                  if (blacklist.userBlacklistLength > 0) {
                    Get.dialog(ConfirmCancelDialog(
                      content: '确定清空饼干黑名单？',
                      onConfirm: () async {
                        await blacklist.clearUserBlacklist();
                        refresh();
                        Get.back();
                      },
                      onCancel: () => Get.back(),
                    ));
                  }

                  break;
                default:
                  debugPrint('未知bottomBarIndex：$index');
              }
            },
          ),
          child: const Text('清空'),
        ),
      ],
    );
  }
}

typedef _IndexCallback<T> = T Function(int index);

typedef _WidgetBuilder<T> = Widget Function(T item);

typedef _ItemCallback<T> = void Function(T item);

typedef _GetText<T> = String Function(T item);

class _List<T> extends StatelessWidget {
  final int itemCount;

  final _IndexCallback<T?> getItem;

  final _WidgetBuilder<T> titleBuilder;

  final _WidgetBuilder<T>? subtitleBuilder;

  final _ItemCallback<T> onDelete;

  final _WidgetBuilder<T> deleteDialogContent;

  final _GetText<T> deleteToastContent;

  const _List(
      {super.key,
      required this.itemCount,
      required this.getItem,
      required this.titleBuilder,
      this.subtitleBuilder,
      required this.onDelete,
      required this.deleteDialogContent,
      required this.deleteToastContent});

  @override
  Widget build(BuildContext context) => itemCount > 0
      ? ListView.builder(
          itemCount: itemCount,
          itemBuilder: (context, index) {
            final item = getItem(index);
            final RxBool isVisible = true.obs;

            return Obx(
              () => (item != null && isVisible.value)
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: titleBuilder(item),
                          subtitle: subtitleBuilder != null
                              ? subtitleBuilder!(item)
                              : null,
                          trailing: IconButton(
                            onPressed: () => Get.dialog(
                              ConfirmCancelDialog(
                                contentWidget: deleteDialogContent(item),
                                onConfirm: () {
                                  onDelete(item);
                                  isVisible.value = false;
                                  showToast(deleteToastContent(item));
                                  Get.back();
                                },
                                onCancel: () => Get.back(),
                              ),
                            ),
                            icon: const Icon(Icons.close),
                          ),
                        ),
                        if (index != itemCount - 1)
                          const Divider(height: 10.0, thickness: 1.0),
                      ],
                    )
                  : const SizedBox.shrink(),
            );
          },
        )
      : const Center(child: Text('没有黑名单', style: AppTheme.boldRed));
}

class _Body extends StatefulWidget {
  final int index;

  const _Body({super.key, required this.index});

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final List<BlockForumData> _deletedForumList = [];

  final List<int> _deletedPostIdList = [];

  final List<String> _deletedUserHashList = [];

  @override
  void dispose() {
    final blacklist = BlacklistService.to;

    for (final forum in _deletedForumList) {
      blacklist.unblockForum(forum);
    }
    for (final postId in _deletedPostIdList) {
      blacklist.unblockPost(postId);
    }
    for (final userHash in _deletedUserHashList) {
      blacklist.unblockUser(userHash);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blacklist = BlacklistService.to;
    final forums = ForumListService.to;
    final textStyle = Theme.of(context).textTheme.subtitle1;

    switch (widget.index) {
      case BlacklistView._forumIndex:
        return _List<BlockForumData>(
          itemCount: blacklist.forumBlacklistLength,
          getItem: (index) => blacklist.blockedForum(index),
          titleBuilder: (forum) =>
              ForumName(forumId: forum.forumId, maxLines: 1),
          subtitleBuilder: (forum) => ForumName(
              forumId: forum.timelineId, isTimeline: true, maxLines: 1),
          onDelete: (forum) => _deletedForumList.add(forum),
          deleteDialogContent: (forum) {
            final forumName = forums.forumName(forum.forumId);
            final timelineName =
                forums.forumName(forum.timelineId, isTimeline: true);

            return RichText(
              text: (forumName != null && timelineName != null)
                  ? TextSpan(
                      text: '确定在 ',
                      children: [
                        htmlToTextSpan(context, timelineName,
                            textStyle: textStyle),
                        TextSpan(
                          text: ' 取消屏蔽板块 ',
                          children: [
                            htmlToTextSpan(context, forumName,
                                textStyle: textStyle),
                            const TextSpan(text: ' ？'),
                          ],
                        ),
                      ],
                      style: textStyle,
                    )
                  : (forumName != null
                      ? TextSpan(
                          text: '确定取消屏蔽板块 ',
                          children: [
                            htmlToTextSpan(context, forumName,
                                textStyle: textStyle),
                            const TextSpan(text: ' ？'),
                          ],
                          style: textStyle,
                        )
                      : TextSpan(text: '确定取消屏蔽板块？', style: textStyle)),
            );
          },
          deleteToastContent: (forum) {
            final forumName =
                htmlToPlainText(context, forums.forumName(forum.forumId) ?? '');
            final timelineName = htmlToPlainText(context,
                forums.forumName(forum.timelineId, isTimeline: true) ?? '');

            return (forumName.isNotEmpty && timelineName.isNotEmpty)
                ? '在 $timelineName 取消屏蔽板块 $forumName'
                : (forumName.isNotEmpty ? '取消屏蔽板块 $forumName' : '取消屏蔽板块');
          },
        );
      case BlacklistView._postIndex:
        return _List<int>(
          itemCount: blacklist.postBlacklistLength,
          getItem: (index) => blacklist.blockedPost(index),
          titleBuilder: (postId) => Text('$postId'),
          onDelete: (postId) => _deletedPostIdList.add(postId),
          deleteDialogContent: (postId) =>
              Text('确定取消屏蔽 ${postId.toPostNumber()} ？'),
          deleteToastContent: (postId) => '取消屏蔽 ${postId.toPostNumber()}',
        );
      case BlacklistView._userIndex:
        return _List<String>(
          itemCount: blacklist.userBlacklistLength,
          getItem: (index) => blacklist.blockedUser(index),
          titleBuilder: (userHash) => Text(userHash),
          onDelete: (userHash) => _deletedUserHashList.add(userHash),
          deleteDialogContent: (userHash) => Text('确定取消屏蔽饼干 $userHash ？'),
          deleteToastContent: (userHash) => '取消屏蔽饼干 $userHash',
        );
      default:
        return const Center(child: Text('未知黑名单列表', style: AppTheme.boldRed));
    }
  }
}

class _BottomBar extends StatelessWidget {
  final int index;

  final _IndexCallback<void> onIndex;

  const _BottomBar({super.key, required this.index, required this.onIndex});

  @override
  Widget build(BuildContext context) => BottomNavigationBar(
        currentIndex: index,
        onTap: (value) {
          if (index != value) {
            popAllPopup();
            onIndex(value);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: SizedBox.shrink(), label: '板块'),
          BottomNavigationBarItem(icon: SizedBox.shrink(), label: '串号'),
          BottomNavigationBarItem(icon: SizedBox.shrink(), label: '饼干'),
        ],
      );
}

class BlacklistController extends GetxController {}

class BlacklistBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(BlacklistController());
  }
}

class BlacklistView extends GetView<BlacklistController> {
  static const int _forumIndex = 0;

  static const int _postIndex = 1;

  static const int _userIndex = 2;

  final RxInt _index = 0.obs;

  BlacklistView({super.key});

  void _refresh() => _index.refresh();

  @override
  Widget build(BuildContext context) => Obx(
        () => Scaffold(
          appBar: AppBar(
            title: _AppBarTitle(index: _index.value),
            actions: [
              _AppBarPopupMenuButton(index: _index.value, refresh: _refresh),
            ],
          ),
          body: _Body(index: _index.value),
          bottomNavigationBar: _BottomBar(
            index: _index.value,
            onIndex: (index) => _index.value = index,
          ),
        ),
      );
}
