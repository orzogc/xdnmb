import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/models/forum.dart';
import '../data/services/forum.dart';
import '../data/services/persistent.dart';
import '../data/services/settings.dart';
import '../data/services/xdnmb_client.dart';
import '../modules/post_list.dart';
import '../routes/routes.dart';
import '../utils/navigation.dart';
import '../utils/text.dart';
import '../utils/toast.dart';
import 'forum.dart';
import 'forum_name.dart';
import 'guide.dart';

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final client = XdnmbClientService.to;

    final reorderForums = IconButton(
      onPressed: AppRoutes.toReorderForums,
      icon: Icon(Icons.swap_vert, color: theme.colorScheme.onPrimary),
    );

    return SizedBox(
      height: (theme.appBarTheme.toolbarHeight ?? kToolbarHeight) +
          MediaQuery.of(context).padding.top,
      child: DrawerHeader(
        decoration: BoxDecoration(
          color: theme.appBarTheme.backgroundColor ?? theme.colorScheme.primary,
        ),
        margin: null,
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Row(
          children: [
            Text(
              '板块',
              style: (theme.appBarTheme.titleTextStyle ??
                      theme.textTheme.headline6)
                  ?.apply(
                color: theme.appBarTheme.foregroundColor ??
                    theme.colorScheme.onPrimary,
              ),
            ),
            const Spacer(),
            PersistentDataService.to.showGuide
                ? ReorderForumsGuide(reorderForums)
                : Obx(
                    () => client.isReady.value
                        ? reorderForums
                        : const SizedBox.shrink(),
                  ),
          ],
        ),
      ),
    );
  }
}

class _Dialog extends StatelessWidget {
  final ForumData forum;

  const _Dialog({super.key, required this.forum});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.subtitle1;
    final client = XdnmbClientService.to;
    final forumName = htmlToPlainText(context, forum.forumName);

    return SimpleDialog(
      children: [
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
            Get.back(result: true);
          },
          child: ForumName(
            forumId: forum.id,
            isTimeline: forum.isTimeline,
            leading: '在新标签页后台打开 ',
            textStyle: textStyle,
            maxLines: 1,
          ),
        ),
        if (client.isReady.value)
          SimpleDialogOption(
            onPressed: () async {
              await ForumListService.to.hideForum(forum);

              showToast('隐藏板块 $forumName');
              Get.back(result: false);
            },
            child: ForumName(
              forumId: forum.id,
              isTimeline: forum.isTimeline,
              leading: '隐藏 ',
              trailing: ' 板块',
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
              trailing: ' 板块的名字',
              textStyle: textStyle,
              maxLines: 1,
            ),
          ),
      ],
    );
  }
}

class _ForumList extends StatelessWidget {
  const _ForumList({super.key});

  @override
  Widget build(BuildContext context) {
    final forums = ForumListService.to;
    final theme = Theme.of(context);

    return PersistentDataService.to.showGuide
        ? ListView(
            padding: EdgeInsets.zero,
            children: [
              ForumListGuide(
                ListTile(
                  tileColor: theme.focusColor,
                  title: Text(defaultForum.forumName),
                ),
              ),
            ],
          )
        : ValueListenableBuilder<HashMap<int, int>>(
            valueListenable: forums.displayedForumIndexNotifier,
            builder: (context, box, child) => ListView.builder(
              key: const PageStorageKey<String>('forumList'),
              padding: EdgeInsets.zero,
              itemCount: forums.displayedForumsCount,
              itemBuilder: (context, index) {
                final forum = forums.displayedForum(index);
                final controller = PostListController.get();
                final forumId = controller.forumOrTimelineId;
                final isTimeline = controller.isTimeline;

                return forum != null
                    ? ListTile(
                        key: ValueKey<PostList>(PostList.fromForumData(forum)),
                        onTap: () {
                          if (forumId != forum.id) {
                            if (forum.isTimeline) {
                              AppRoutes.toTimeline(timelineId: forum.id);
                            } else {
                              AppRoutes.toForum(forumId: forum.id);
                            }
                          }
                          Get.back();
                        },
                        onLongPress: () async {
                          if (await Get.dialog<bool>(_Dialog(forum: forum)) ??
                              false) {
                            Get.back();
                          }
                        },
                        tileColor: (forumId == forum.id &&
                                isTimeline == forum.isTimeline)
                            ? theme.focusColor
                            : null,
                        title: ForumName(
                          forumId: forum.id,
                          isTimeline: forum.isTimeline,
                          isDeprecated: forum.isDeprecated,
                          textStyle: theme.textTheme.bodyText1,
                          maxLines: 1,
                        ),
                      )
                    : const SizedBox.shrink();
              },
            ),
          );
  }
}

class AppEndDrawer extends StatelessWidget {
  const AppEndDrawer({super.key});

  @override
  Widget build(BuildContext context) => Drawer(
        width: min(MediaQuery.of(context).size.width / 2.0, 304),
        child: Column(
          children: const [
            _DrawerHeader(),
            Expanded(child: _ForumList()),
          ],
        ),
      );
}
