import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/models/controller.dart';
import '../data/services/persistent.dart';
import '../data/services/settings.dart';
import '../data/services/stack.dart';
import '../modules/post_list.dart';
import '../utils/extensions.dart';
import '../utils/notify.dart';
import '../utils/theme.dart';
import 'backdrop.dart';
import 'content.dart';
import 'forum_name.dart';
import 'guide.dart';
import 'thread.dart';

class _TabTitle extends StatelessWidget {
  final PostListController controller;

  // ignore: unused_element
  const _TabTitle(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    late final Widget title;
    switch (controller.postListType) {
      case PostListType.thread:
      case PostListType.onlyPoThread:
        title = Obx(() {
          final postId = (controller as ThreadTypeController).id;
          final forumId = (controller as ThreadTypeController).post?.forumId;

          return DefaultTextStyle.merge(
            style: theme.textTheme.caption?.apply(color: AppTheme.headerColor),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (forumId != null)
                  Flexible(
                    child: ForumName(
                      forumId: forumId,
                      maxLines: 1,
                    ),
                  ),
                Flexible(child: Text(postId.toPostNumber())),
              ],
            ),
          );
        });

        break;
      case PostListType.forum:
      case PostListType.timeline:
        final forumId = controller.id;
        title = (forumId != null
            ? ForumName(
                forumId: forumId,
                isTimeline: controller.isTimeline,
                maxLines: 1,
                textStyle: theme.textTheme.bodyText1)
            : const SizedBox.shrink());

        break;
      case PostListType.feed:
        title = const Text('订阅');
        break;
      case PostListType.history:
        title = const Text('历史记录');
        break;
    }

    return title;
  }
}

class TabList extends StatelessWidget {
  final BackdropController? backdropController;

  const TabList({super.key, this.backdropController});

  @override
  Widget build(BuildContext context) {
    final data = PersistentDataService.to;
    final stacks = ControllerStacksService.to;
    final theme = Theme.of(context);
    final textStyle =
        theme.textTheme.bodyText2?.apply(color: AppTheme.textColor);

    return Center(
      child: Obx(
        () => ListView.separated(
          key: const PageStorageKey<String>('tabList'),
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: stacks.length,
          itemBuilder: (context, index) => NotifyBuilder(
            animation: stacks.notifier,
            builder: (context, child) {
              final controller = PostListController.get(index);

              final tab = ListTile(
                key: ValueKey<int>(stacks.getKeyId(index)),
                onTap: () {
                  PostListPage.pageKey.currentState!.jumpToPage(index);

                  if (SettingsService.isBackdropUI &&
                      backdropController != null) {
                    backdropController!.hideBackLayer();
                  } else {
                    Get.back();
                  }
                },
                tileColor: index == stacks.index ? theme.focusColor : null,
                title: _TabTitle(controller),
                subtitle: controller.isThreadType
                    ? Obx(() {
                        final post = (controller as ThreadTypeController).post;

                        return post != null
                            ? Content(
                                key: ValueKey<bool>(Get.isDarkMode),
                                post: post,
                                maxLines: 2,
                                displayImage: false,
                                textStyle: textStyle,
                              )
                            : const SizedBox.shrink();
                      })
                    : null,
                trailing: stacks.length > 1
                    ? IconButton(
                        onPressed: () {
                          stacks.removeStackAt(index);
                          PostListPage.pageKey.currentState!
                              .jumpToPage(stacks.index);
                        },
                        icon: const Icon(Icons.close))
                    : null,
              );

              return (data.shouldShowGuide && index == 0)
                  ? TabListGuide(tab)
                  : tab;
            },
          ),
          separatorBuilder: (BuildContext context, int index) =>
              const Divider(height: 10, thickness: 1),
        ),
      ),
    );
  }
}
