import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/models/controller.dart';
import '../data/services/persistent.dart';
import '../data/services/settings.dart';
import '../data/services/stack.dart';
import '../modules/post_list.dart';
import '../modules/settings.dart';
import '../routes/routes.dart';
import '../utils/extensions.dart';
import '../utils/notify.dart';
import '../utils/regex.dart';
import '../utils/theme.dart';
import '../utils/toast.dart';
import '../utils/url.dart';
import 'content.dart';
import 'dialog.dart';
import 'forum_name.dart';
import 'guide.dart';
import 'reference.dart';
import 'thread.dart';

class _SearchDialog extends StatelessWidget {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  _SearchDialog({super.key});

  @override
  Widget build(BuildContext context) {
    String? content;

    return InputDialog(
      title: const Text('搜索'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          autofocus: true,
          onSaved: (newValue) => content = newValue,
          validator: (value) =>
              (value == null || value.isEmpty) ? '请输入搜索内容' : null,
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();

              final postId = Regex.getPostId(content!);
              if (postId == null) {
                showToast('请输入串号');
                return;
              }

              Get.back<bool>(result: true);
              postListDialog(Center(child: ReferenceCard(postId: postId)));
            }
          },
          child: const Text('查询串号'),
        ),
        const ElevatedButton(
          onPressed: null,
          child: Text('搜索坏了', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;
    final data = PersistentDataService.to;
    final theme = Theme.of(context);

    final darkMode = Get.isDarkMode
        ? IconButton(
            onPressed: () => settings.isDarkMode = false,
            tooltip: '光来！',
            icon: const Icon(Icons.sunny, color: Colors.white),
          )
        : IconButton(
            onPressed: () => settings.isDarkMode = true,
            tooltip: '暗来！',
            icon: const Icon(Icons.brightness_3, color: Colors.black),
          );

    final search = IconButton(
      onPressed: () async {
        final result = await Get.dialog<bool>(_SearchDialog());
        if (result ?? false) {
          Get.back();
        }
      },
      tooltip: '搜索',
      icon: Icon(Icons.search, color: theme.colorScheme.onPrimary),
    );

    final setting = IconButton(
      onPressed: () => AppRoutes.toSettings(SettingsController(closeDrawer: () {
        final scaffold = Scaffold.of(context);
        scaffold.closeDrawer();
        scaffold.closeEndDrawer();
      })),
      tooltip: '设置',
      icon: Icon(Icons.settings, color: theme.colorScheme.onPrimary),
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
              '霞岛',
              style: (theme.appBarTheme.titleTextStyle ??
                      theme.textTheme.headline6)
                  ?.apply(
                color: theme.appBarTheme.foregroundColor ??
                    theme.colorScheme.onPrimary,
              ),
            ),
            const Spacer(),
            data.showGuide ? DarkModeGuide(darkMode) : darkMode,
            data.showGuide ? SearchGuide(search) : search,
            data.showGuide ? SettingsGuide(setting) : setting,
          ],
        ),
      ),
    );
  }
}

class _TabTitle extends StatelessWidget {
  final PostListController controller;

  const _TabTitle(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    late final Widget title;
    switch (controller.postListType) {
      case PostListType.thread:
      case PostListType.onlyPoThread:
        title = Obx(() {
          final postId = (controller as ThreadTypeController).id;
          final forumId = (controller as ThreadTypeController).post?.forumId;

          return DefaultTextStyle.merge(
            style: Theme.of(context)
                .textTheme
                .caption
                ?.apply(color: AppTheme.headerColor),
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
                maxLines: 1)
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

class _TabList extends StatelessWidget {
  const _TabList({super.key});

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
          itemCount: stacks.length,
          itemBuilder: (context, index) => NotifyBuilder(
            animation: stacks.getStackNotifier(index),
            builder: (context, child) {
              final controller = PostListController.get(index);

              final tab = ListTile(
                key: ValueKey<int>(stacks.getKeyId(index)),
                onTap: () {
                  PostListPage.pageKey.currentState!.jumpToPage(index);
                  Get.back();
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

              return (data.showGuide && index == 0) ? TabListGuide(tab) : tab;
            },
          ),
          separatorBuilder: (BuildContext context, int index) =>
              const Divider(height: 10, thickness: 1),
        ),
      ),
    );
  }
}

class _SponsorDialog extends StatelessWidget {
  const _SponsorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.subtitle1;

    return SimpleDialog(
      children: [
        SimpleDialogOption(
          onPressed: () => launchURL(Urls.authorSponsor),
          child: Text('赞助客户端作者', style: textStyle),
        ),
        SimpleDialogOption(
          onPressed: () => launchURL(Urls.xdnmbSponsor),
          child: Text('赞助X岛匿名版官方', style: textStyle),
        ),
      ],
    );
  }
}

class _DrawerBottom extends StatelessWidget {
  const _DrawerBottom({super.key});

  @override
  Widget build(BuildContext context) {
    final data = PersistentDataService.to;
    final theme = Theme.of(context);

    final history = IconButton(
      onPressed: () {
        AppRoutes.toHistory();
        Get.back();
      },
      icon: const Icon(Icons.history),
    );

    final feed = IconButton(
      onPressed: () {
        AppRoutes.toFeed();
        Get.back();
      },
      icon: const Icon(Icons.rss_feed),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          TextButton(
            onPressed: () => Get.dialog(const _SponsorDialog()),
            child: Text(
              '赞助',
              style: (theme.appBarTheme.titleTextStyle ??
                      theme.textTheme.headline6)
                  ?.merge(
                TextStyle(
                  color: AppTheme.highlightColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          data.showGuide ? HistoryGuide(history) : history,
          data.showGuide ? FeedGuide(feed) : feed,
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
