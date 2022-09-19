import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/services/settings.dart';
import '../modules/post_list.dart';
import '../modules/stack_cache.dart';
import '../routes/routes.dart';
import '../utils/extensions.dart';
import 'content.dart';
import 'forum_name.dart';

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = SettingsService.to;

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
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                'X岛匿名版',
                style: (theme.appBarTheme.titleTextStyle ??
                        theme.textTheme.headline6)
                    ?.apply(
                  color: theme.appBarTheme.foregroundColor ??
                      theme.colorScheme.onPrimary,
                ),
              ),
            ),
            Get.isDarkMode
                ? IconButton(
                    onPressed: () => settings.isDarkMode = false,
                    tooltip: '光来！',
                    icon: const Icon(Icons.sunny, color: Colors.white),
                  )
                : IconButton(
                    onPressed: () => settings.isDarkMode = true,
                    tooltip: '暗来！',
                    icon: const Icon(Icons.brightness_3, color: Colors.black),
                  ),
            IconButton(
              onPressed: () {},
              tooltip: '搜索',
              icon: Icon(Icons.search, color: theme.colorScheme.onPrimary),
            ),
            IconButton(
              onPressed: AppRoutes.toSettings,
              tooltip: '设置',
              icon: Icon(Icons.settings, color: theme.colorScheme.onPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabTitle extends StatelessWidget {
  final int index;

  const _TabTitle(this.index, {super.key});

  @override
  Widget build(BuildContext context) {
    final controller =
        StackCacheView.getController(index) as PostListController;

    return Obx(() {
      final postListType = controller.postListType.value;
      final forumId = controller.forumOrTimelineId;
      final postId = controller.post.value?.id;

      late final Widget title;
      switch (postListType) {
        case PostListType.thread:
        case PostListType.onlyPoThread:
          title = Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (forumId != null) Flexible(child: ForumName(forumId: forumId)),
              if (postId != null) Flexible(child: Text(postId.toPostNumber())),
            ],
          );
          break;
        case PostListType.forum:
        case PostListType.timeline:
          title = (forumId != null
              ? ForumName(
                  forumId: forumId, isTimeline: postListType.isTimeline())
              : const SizedBox.shrink());
          break;
        case PostListType.feed:
          title = const Text('订阅');
          break;
      }

      return title;
    });
  }
}

class _TabList extends StatelessWidget {
  const _TabList({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Obx(
        () => ListView.separated(
          key: const PageStorageKey<String>('tabList'),
          shrinkWrap: true,
          itemCount: StackCacheView.length.value,
          itemBuilder: (context, index) {
            final controller =
                StackCacheView.getController(index) as PostListController;
            final post = controller.post;

            return Obx(
              () => ListTile(
                key: ValueKey<int>(StackCacheView.getKeyId(index)),
                onTap: () {
                  PostListPage.pageKey.currentState!.jumpToPage(index);
                  Get.back();
                },
                tileColor:
                    index == StackCacheView.index ? theme.focusColor : null,
                title: _TabTitle(index),
                subtitle: post.value != null
                    ? Content(
                        post: post.value!, maxLines: 2, displayImage: false)
                    : null,
                trailing: StackCacheView.length.value > 1
                    ? IconButton(
                        onPressed: () {
                          StackCacheView.removeControllerAt(index);
                          PostListPage.pageKey.currentState!
                              .jumpToPage(StackCacheView.index);
                        },
                        icon: const Icon(Icons.close))
                    : null,
              ),
            );
          },
          separatorBuilder: (BuildContext context, int index) =>
              const Divider(height: 10, thickness: 1),
        ),
      ),
    );
  }
}

class _DrawerBottom extends StatelessWidget {
  const _DrawerBottom({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          TextButton(
            //style: style,
            onPressed: () {},
            child: Text(
              '赞助',
              style: (theme.appBarTheme.titleTextStyle ??
                      theme.textTheme.headline6)
                  ?.merge(TextStyle(
                      color: theme.primaryColor, fontWeight: FontWeight.bold)),
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.event_note)),
          IconButton(
            onPressed: () {
              AppRoutes.toFeed();
              Get.back();
            },
            icon: const Icon(Icons.feed),
          )
        ],
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) => Drawer(
        child: Column(
          children: const [
            _DrawerHeader(),
            Expanded(child: _TabList()),
            Divider(height: 10.0, thickness: 1.0),
            _DrawerBottom(),
          ],
        ),
      );
}
