import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/models/forum.dart';
import '../data/services/forum.dart';
import '../data/services/persistent.dart';
import '../data/services/settings.dart';
import '../data/services/stack.dart';
import '../data/services/xdnmb_client.dart';
import '../modules/post_list.dart';
import '../routes/routes.dart';
import '../utils/navigation.dart';
import '../utils/notify.dart';
import '../utils/text.dart';
import '../utils/toast.dart';
import 'backdrop.dart';
import 'forum.dart';
import 'forum_name.dart';
import 'guide.dart';

class _Dialog extends StatelessWidget {
  final ForumData forum;

  // ignore: unused_element
  const _Dialog({super.key, required this.forum});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.subtitle1;
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
            child: Text('版块排序', style: textStyle),
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
  final BackdropController? backdropController;

  const ForumList({super.key, this.backdropController});

  void _back() {
    if (SettingsService.isBackdropUI && backdropController != null) {
      backdropController!.hideBackLayer();
    } else {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = PersistentDataService.to;
    final forums = ForumListService.to;
    final theme = Theme.of(context);

    return NotifyBuilder(
      animation: ControllerStacksService.to.notifier,
      builder: (context, child) {
        final controller = PostListController.get();
        final forumId = controller.forumOrTimelineId;
        final isTimeline = controller.isTimeline;

        return ValueListenableBuilder<HashMap<int, int>>(
          valueListenable: forums.displayedForumIndexNotifier,
          builder: (context, box, child) => ListView.builder(
            key: const PageStorageKey<String>('forumList'),
            padding: EdgeInsets.zero,
            shrinkWrap: true,
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
                    _back();
                  },
                  onLongPress: () async {
                    if (await Get.dialog<bool>(_Dialog(forum: forum)) ??
                        false) {
                      _back();
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
                    textStyle: theme.textTheme.bodyText1,
                    maxLines: 1,
                  ),
                );

                return (index == 0 && data.shouldShowGuide)
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
