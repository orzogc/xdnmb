import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/models/controller.dart';
import '../data/services/settings.dart';
import '../data/services/stack.dart';
import '../modules/post_list.dart';
import '../utils/extensions.dart';
import '../utils/theme.dart';
import 'content.dart';
import 'feed.dart';
import 'forum_name.dart';
import 'guide.dart';
import 'history.dart';
import 'listenable.dart';
import 'tag.dart';
import 'tagged.dart';
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
          final forumId =
              (controller as ThreadTypeController).mainPost?.forumId;

          return Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 5.0,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (forumId != null)
                ForumName(
                  forumId: forumId,
                  maxLines: 1,
                  forumNameCache: ForumNameStyle.bodySmallWithHeaderColor,
                ),
              Text(
                postId.toPostNumber(),
                style: theme.textTheme.bodySmall?.apply(
                  color: AppTheme.headerColor,
                ),
              ),
            ],
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
                forumNameCache: ForumNameStyle.bodyLarge)
            : const SizedBox.shrink());

        break;
      case PostListType.feed:
        final text = (controller as FeedController).text();
        title = Text(text, style: theme.textTheme.bodyLarge);
        break;
      case PostListType.history:
        title = Text((controller as HistoryController).text(),
            style: theme.textTheme.bodyLarge);
        break;
      case PostListType.taggedPostList:
        title = Align(
          alignment: Alignment.centerLeft,
          child: PostTag(
            controller: controller as TaggedPostListController,
            textStyle: theme.textTheme.bodyLarge,
          ),
        );
        break;
    }

    return title;
  }
}

class TabList extends StatelessWidget {
  final double? bottomPadding;

  final VoidCallback onTapEnd;

  const TabList({super.key, this.bottomPadding, required this.onTapEnd})
      : assert(bottomPadding == null || bottomPadding >= 0.0);

  void _closeTab(int index) {
    final stacks = ControllerStacksService.to;

    stacks.removeStackAt(index);
    PostListPage.pageKey.currentState!.jumpToPage(stacks.index);
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;
    final stacks = ControllerStacksService.to;
    final theme = Theme.of(context);
    final textStyle =
        theme.textTheme.bodyMedium?.apply(color: AppTheme.textColor);

    return Center(
      child: Obx(
        () {
          final count = stacks.length;

          return ListView.separated(
            key: const PageStorageKey<String>('tabList'),
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: bottomPadding != null ? count + 1 : count,
            itemBuilder: (context, index) => ListenBuilder(
              listenable: Listenable.merge(
                  [stacks.notifier, settings.dismissibleTabListenable]),
              builder: (context, child) {
                if (bottomPadding != null &&
                    bottomPadding! > 0.0 &&
                    index == count) {
                  return SizedBox(height: bottomPadding);
                }

                final controller = PostListController.get(index);

                Widget tab = ListTile(
                  key: !(settings.dismissibleTab && count > 1)
                      ? ValueKey<int>(stacks.getKeyId(index))
                      : null,
                  onTap: () {
                    PostListPage.pageKey.currentState!.jumpToPage(index);

                    onTapEnd();
                  },
                  tileColor: index == stacks.index ? theme.focusColor : null,
                  title: _TabTitle(controller),
                  subtitle: controller.isThreadType
                      ? Obx(() {
                          final post =
                              (controller as ThreadTypeController).mainPost;

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
                  trailing: (!settings.dismissibleTab && count > 1)
                      ? IconButton(
                          onPressed: () => _closeTab(index),
                          icon: const Icon(Icons.close))
                      : null,
                );

                if (settings.dismissibleTab && count > 1) {
                  final isIconOnLeft = true.obs;

                  tab = Dismissible(
                    key: ValueKey<int>(stacks.getKeyId(index)),
                    background: ColoredBox(
                      color: theme.primaryColor,
                      child: Obx(() => isIconOnLeft.value
                          ? Padding(
                              padding: const EdgeInsets.only(left: 20.0),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Icon(
                                  Icons.delete_outline,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.only(right: 20.0),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Icon(
                                  Icons.delete_outline,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                            )),
                    ),
                    onUpdate: (details) {
                      if (details.direction == DismissDirection.startToEnd) {
                        isIconOnLeft.value = true;
                      } else if (details.direction ==
                          DismissDirection.endToStart) {
                        isIconOnLeft.value = false;
                      }
                    },
                    onDismissed: (direction) => _closeTab(index),
                    child: tab,
                  );
                }

                return (SettingsService.shouldShowGuide && index == 0)
                    ? TabListGuide(tab)
                    : tab;
              },
            ),
            separatorBuilder: (BuildContext context, int index) {
              if (bottomPadding != null &&
                  bottomPadding! > 0.0 &&
                  index == count - 1) {
                return const SizedBox.shrink();
              }

              return const Divider(height: 10.0, thickness: 1.0);
            },
          );
        },
      ),
    );
  }
}
