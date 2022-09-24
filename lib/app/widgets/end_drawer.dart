import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:html_to_text/html_to_text.dart';

import '../data/models/forum.dart';
import '../data/services/forum.dart';
import '../data/services/xdnmb_client.dart';
import '../modules/post_list.dart';
import '../routes/routes.dart';
import '../utils/navigation.dart';
import '../utils/toast.dart';
import 'forum_name.dart';

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final client = XdnmbClientService.to;

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
            Expanded(
              child: Text(
                '板块',
                style: (theme.appBarTheme.titleTextStyle ??
                        theme.textTheme.headline6)
                    ?.apply(
                  color: theme.appBarTheme.foregroundColor ??
                      theme.colorScheme.onPrimary,
                ),
              ),
            ),
            Obx(
              () => client.isReady.value
                  ? IconButton(
                      onPressed: AppRoutes.toReorderForums,
                      icon: Icon(Icons.swap_vert,
                          color: theme.colorScheme.onPrimary),
                    )
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
    final forums = ForumListService.to;
    final span = htmlToTextSpan(context, forum.forumName, textStyle: textStyle);
    final forumName = span.toPlainText();

    return SimpleDialog(
      children: [
        SimpleDialogOption(
          onPressed: () {
            final controller = PostListController.fromForumData(forum: forum);
            openNewTab(controller);

            showToast('已在新标签页打开 $forumName');
            Get.back(result: true);
          },
          child: RichText(
            text:
                TextSpan(text: '在新标签页打开 ', children: [span], style: textStyle),
          ),
        ),
        SimpleDialogOption(
          onPressed: () {
            final controller = PostListController.fromForumData(forum: forum);
            openNewTabBackground(controller);

            showToast('已在新标签页后台打开 $forumName');
            Get.back(result: true);
          },
          child: RichText(
            text: TextSpan(
                text: '在新标签页后台打开 ', children: [span], style: textStyle),
          ),
        ),
        if (client.isReady.value)
          SimpleDialogOption(
            onPressed: () async {
              await forums.hideForum(forum);

              showToast('已隐藏板块 $forumName');
              Get.back(result: false);
            },
            child: RichText(
              text: TextSpan(
                text: '隐藏 ',
                children: [span, const TextSpan(text: ' 板块')],
                style: textStyle,
              ),
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
            child: RichText(
              text: TextSpan(
                text: '修改 ',
                children: [span, const TextSpan(text: ' 板块的名字')],
                style: textStyle,
              ),
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

    return ValueListenableBuilder<Box<ForumData>>(
      valueListenable: forums.displayedForumListenable,
      builder: (context, box, child) => ListView.builder(
        key: const PageStorageKey<String>('forumList'),
        padding: EdgeInsets.zero,
        itemCount: forums.displayedLength,
        itemBuilder: (context, index) {
          final forum = forums.displayedForum(index);
          final controller = PostListController.get();
          final forumId = controller.forumOrTimelineId;
          final isTimeline = controller.postListType.value.isTimeline();

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
                  tileColor:
                      (forumId == forum.id && isTimeline == forum.isTimeline)
                          ? theme.focusColor
                          : null,
                  title: htmlToRichText(context, forum.forumName,
                      textStyle: theme.textTheme.bodyText1),
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
