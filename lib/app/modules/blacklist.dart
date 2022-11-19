import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:html_to_text/html_to_text.dart';

import '../data/models/forum.dart';
import '../data/services/blacklist.dart';
import '../data/services/forum.dart';
import '../utils/extensions.dart';
import '../utils/text.dart';
import '../utils/theme.dart';
import '../utils/toast.dart';
import '../widgets/dialog.dart';
import '../widgets/forum_name.dart';
import '../widgets/page_view.dart';

class _AppBarTitle extends StatelessWidget {
  final int index;

  // ignore: unused_element
  const _AppBarTitle({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    late final String text;
    switch (index) {
      case BlacklistView._forumIndex:
        text = '版块黑名单';
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
      // ignore: unused_element
      {super.key,
      required this.index,
      required this.refresh});

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
                      content: '确定清空版块黑名单？',
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
      ? ListView.separated(
          itemCount: itemCount,
          itemBuilder: (context, index) {
            final item = getItem(index);

            return item != null
                ? ListTile(
                    key: ValueKey<T>(item),
                    title: titleBuilder(item),
                    subtitle:
                        subtitleBuilder != null ? subtitleBuilder!(item) : null,
                    trailing: IconButton(
                      onPressed: () => Get.dialog(
                        ConfirmCancelDialog(
                          contentWidget: deleteDialogContent(item),
                          onConfirm: () {
                            onDelete(item);
                            showToast(deleteToastContent(item));
                            Get.back();
                          },
                          onCancel: () => Get.back(),
                        ),
                      ),
                      icon: const Icon(Icons.close),
                    ),
                  )
                : const SizedBox.shrink();
          },
          separatorBuilder: (context, index) =>
              const Divider(height: 10.0, thickness: 1.0),
        )
      : const Center(child: Text('没有黑名单', style: AppTheme.boldRed));
}

class _Body extends StatelessWidget {
  final int index;

  final VoidCallback refresh;

  // ignore: unused_element
  const _Body({super.key, required this.index, required this.refresh});

  @override
  Widget build(BuildContext context) {
    final blacklist = BlacklistService.to;
    final forums = ForumListService.to;
    final textStyle = Theme.of(context).textTheme.subtitle1;

    switch (index) {
      case BlacklistView._forumIndex:
        return _List<BlockForumData>(
          key: const PageStorageKey('blockedForums'),
          itemCount: blacklist.forumBlacklistLength,
          getItem: (index) => blacklist.blockedForum(index),
          titleBuilder: (forum) =>
              ForumName(forumId: forum.forumId, maxLines: 1),
          subtitleBuilder: (forum) => ForumName(
              forumId: forum.timelineId, isTimeline: true, maxLines: 1),
          onDelete: (forum) async {
            await blacklist.unblockForum(forum);
            refresh();
          },
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
                          text: ' 取消屏蔽版块 ',
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
                          text: '确定取消屏蔽版块 ',
                          children: [
                            htmlToTextSpan(context, forumName,
                                textStyle: textStyle),
                            const TextSpan(text: ' ？'),
                          ],
                          style: textStyle,
                        )
                      : TextSpan(text: '确定取消屏蔽版块？', style: textStyle)),
            );
          },
          deleteToastContent: (forum) {
            final forumName =
                htmlToPlainText(context, forums.forumName(forum.forumId) ?? '');
            final timelineName = htmlToPlainText(context,
                forums.forumName(forum.timelineId, isTimeline: true) ?? '');

            return (forumName.isNotEmpty && timelineName.isNotEmpty)
                ? '在 $timelineName 取消屏蔽版块 $forumName'
                : (forumName.isNotEmpty ? '取消屏蔽版块 $forumName' : '取消屏蔽版块');
          },
        );
      case BlacklistView._postIndex:
        return _List<int>(
          key: const PageStorageKey('blockedPostIds'),
          itemCount: blacklist.postBlacklistLength,
          getItem: (index) => blacklist.blockedPost(index),
          titleBuilder: (postId) => Text('$postId'),
          onDelete: (postId) async {
            await blacklist.unblockPost(postId);
            refresh();
          },
          deleteDialogContent: (postId) =>
              Text('确定取消屏蔽 ${postId.toPostNumber()} ？'),
          deleteToastContent: (postId) => '取消屏蔽 ${postId.toPostNumber()}',
        );
      case BlacklistView._userIndex:
        return _List<String>(
          key: const PageStorageKey('blockedUsers'),
          itemCount: blacklist.userBlacklistLength,
          getItem: (index) => blacklist.blockedUser(index),
          titleBuilder: (userHash) => Text(userHash),
          onDelete: (userHash) async {
            await blacklist.unblockUser(userHash);
            refresh();
          },
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

  // ignore: unused_element
  const _BottomBar({super.key, required this.index, required this.onIndex});

  @override
  Widget build(BuildContext context) => BottomNavigationBar(
        currentIndex: index,
        onTap: (value) {
          if (index != value) {
            onIndex(value);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: SizedBox.shrink(), label: '版块'),
          BottomNavigationBarItem(icon: SizedBox.shrink(), label: '串号'),
          BottomNavigationBarItem(icon: SizedBox.shrink(), label: '饼干'),
        ],
      );
}

class BlacklistController extends GetxController {
  final PageController _controller = PageController();

  final RxInt _index = 0.obs;

  void _updateIndex() {
    final page = _controller.page;
    if (page != null) {
      _index.value = page.round();
    }
  }

  @override
  void onInit() {
    super.onInit();

    _controller.addListener(_updateIndex);
  }

  @override
  void onClose() {
    _controller.removeListener(_updateIndex);
    _controller.dispose();

    super.onClose();
  }
}

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

  const BlacklistView({super.key});

  void _refresh() => controller._index.refresh();

  @override
  Widget build(BuildContext context) => SafeArea(
        left: false,
        top: false,
        right: false,
        child: Obx(
          () => Scaffold(
            appBar: AppBar(
              title: _AppBarTitle(index: controller._index.value),
              actions: [
                _AppBarPopupMenuButton(
                    index: controller._index.value, refresh: _refresh),
              ],
            ),
            body: SwipeablePageView(
              controller: controller._controller,
              itemCount: 3,
              itemBuilder: (context, index) =>
                  _Body(index: index, refresh: _refresh),
            ),
            bottomNavigationBar: _BottomBar(
              index: controller._index.value,
              onIndex: (index) => controller._controller.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeIn,
              ),
            ),
          ),
        ),
      );
}
