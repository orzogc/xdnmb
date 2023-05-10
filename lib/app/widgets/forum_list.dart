import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/models/forum.dart';
import '../data/services/forum.dart';
import '../data/services/settings.dart';
import '../data/services/stack.dart';
import '../data/services/xdnmb_client.dart';
import '../modules/post_list.dart';
import '../routes/routes.dart';
import '../utils/navigation.dart';
import '../utils/text.dart';
import '../utils/toast.dart';
import 'forum.dart';
import 'forum_name.dart';
import 'guide.dart';
import 'listenable.dart';

class _Dialog extends StatelessWidget {
  final ForumData forum;

  // ignore: unused_element
  const _Dialog({super.key, required this.forum});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleMedium;
    final client = XdnmbClientService.to;
    final forumName = htmlToPlainText(context, forum.forumDisplayName);

    return SimpleDialog(
      children: [
        if (client.isReady.value)
          SimpleDialogOption(
            onPressed: () async {
              Get.back(result: false);

              AppRoutes.toReorderForums();
            },
            child: Text('版块管理', style: textStyle),
          ),
        if (client.isReady.value)
          SimpleDialogOption(
            onPressed: () async {
              await ForumListService.to.hideForum(forum);

              showToast('隐藏版块 $forumName');
              Get.back(result: false);
            },
            child: ForumName(
              forumId: forum.id,
              isTimeline: forum.isTimeline,
              leading: '隐藏 ',
              trailing: ' 版块',
              textStyle: textStyle,
              maxLines: 1,
            ),
          ),
        if (client.isReady.value)
          SimpleDialogOption(
            onPressed: () async {
              if (await Get.dialog<bool>(EditForumName(forum: forum)) ??
                  false) {
                Get.back(result: false);
              }
            },
            child: ForumName(
              forumId: forum.id,
              isTimeline: forum.isTimeline,
              leading: '修改 ',
              trailing: ' 版块的名字',
              textStyle: textStyle,
              maxLines: 1,
            ),
          ),
        SimpleDialogOption(
          onPressed: () {
            final controller = ForumTypeController.fromForumData(forum: forum);
            openNewTab(controller);

            showToast('已在新标签页打开 $forumName');
            Get.back(result: true);
          },
          child: ForumName(
            forumId: forum.id,
            isTimeline: forum.isTimeline,
            leading: '在新标签页打开 ',
            textStyle: textStyle,
            maxLines: 1,
          ),
        ),
        SimpleDialogOption(
          onPressed: () {
            final controller = ForumTypeController.fromForumData(forum: forum);
            openNewTabBackground(controller);

            showToast('已在新标签页后台打开 $forumName');
            Get.back(result: false);
          },
          child: ForumName(
            forumId: forum.id,
            isTimeline: forum.isTimeline,
            leading: '在新标签页后台打开 ',
            textStyle: textStyle,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}

class ForumList extends StatelessWidget {
  final VoidCallback onTapEnd;

  const ForumList({super.key, required this.onTapEnd});

  @override
  Widget build(BuildContext context) {
    final forums = ForumListService.to;
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: ControllerStacksService.to.notifier,
      builder: (context, child) {
        final controller = PostListController.get();
        final forumId = controller.forumOrTimelineId;
        final isTimeline = controller.isTimeline;

        return ListenableBuilder(
          listenable: forums.displayedForumIndexNotifier,
          builder: (context, child) => ListView.builder(
            key: const PageStorageKey<String>('forumList'),
            padding: EdgeInsets.zero,
            itemCount: forums.displayedForumsCount,
            itemBuilder: (context, index) {
              final forum = forums.displayedForum(index);

              if (forum != null) {
                final Widget forumWidget = ListTile(
                  key: ValueKey<PostList>(PostList.fromForumData(forum)),
                  onTap: () {
                    if (!controller.isForumType || forumId != forum.id) {
                      if (forum.isTimeline) {
                        AppRoutes.toTimeline(timelineId: forum.id);
                      } else {
                        AppRoutes.toForum(forumId: forum.id);
                      }
                    }

                    onTapEnd();
                  },
                  onLongPress: () async {
                    if (await Get.dialog<bool>(_Dialog(forum: forum)) ??
                        false) {
                      onTapEnd();
                    }
                  },
                  tileColor:
                      (forumId == forum.id && isTimeline == forum.isTimeline)
                          ? theme.focusColor
                          : null,
                  title: ForumName(
                    forumId: forum.id,
                    isTimeline: forum.isTimeline,
                    isDeprecated: forum.isDeprecated,
                    maxLines: 1,
                    isBodyLargeStyle: true,
                  ),
                );

                return (index == 0 && SettingsService.shouldShowGuide)
                    ? ForumListGuide(forumWidget)
                    : forumWidget;
              } else {
                return const SizedBox.shrink();
              }
            },
          ),
        );
      },
    );
  }
}
