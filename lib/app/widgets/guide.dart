import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

import '../data/services/settings.dart';

abstract class Guide {
  static bool isShowForumGuides = false;

  static bool isShowDrawerGuides = false;

  static bool isShowEndDrawerGuides = false;

  static bool isShowBottomBarGuides = false;

  static bool isShowBackLayerTabListGuides = false;

  static bool isShowBackLayerForumListGuides = false;

  static final List<GlobalKey> forumGuides = [
    if (AppBarMenuGuide._key.currentState?.mounted ?? false)
      AppBarMenuGuide._key,
    if (AppBarTitleGuide._key.currentState?.mounted ?? false)
      AppBarTitleGuide._key,
    if (AppBarPageButtonGuide._key.currentState?.mounted ?? false)
      AppBarPageButtonGuide._key,
    if (AppBarPopupMenuGuide._key.currentState?.mounted ?? false)
      AppBarPopupMenuGuide._key,
    if (ThreadGuide._key.currentState?.mounted ?? false) ThreadGuide._key,
    if (!SettingsService.isShowBottomBar &&
        !SettingsService.to.hideFloatingButton &&
        (EditPostGuide._key.currentState?.mounted ?? false))
      EditPostGuide._key,
  ];

  static final List<GlobalKey> drawerGuides = [
    if (TabListGuide._key.currentState?.mounted ?? false) TabListGuide._key,
    if (DarkModeGuide._key.currentState?.mounted ?? false) DarkModeGuide._key,
    if (SearchGuide._key.currentState?.mounted ?? false) SearchGuide._key,
    if (SettingsGuide._key.currentState?.mounted ?? false) SettingsGuide._key,
    if (HistoryGuide._key.currentState?.mounted ?? false) HistoryGuide._key,
    if (FeedGuide._key.currentState?.mounted ?? false) FeedGuide._key,
  ];

  static final List<GlobalKey> endDrawerGuides = [
    if (ForumListGuide._key.currentState?.mounted ?? false) ForumListGuide._key,
    if (ReorderForumsGuide._key.currentState?.mounted ?? false)
      ReorderForumsGuide._key,
  ];

  static final List<GlobalKey> bottomBarGuides = [
    if (SearchGuide._key.currentState?.mounted ?? false) SearchGuide._key,
    if (SettingsGuide._key.currentState?.mounted ?? false) SettingsGuide._key,
    if (!SettingsService.isBackdropUI &&
        SettingsService.to.compactTabAndForumList &&
        (CompactListButtonGuide._key.currentState?.mounted ?? false))
      CompactListButtonGuide._key,
    if (!SettingsService.isBackdropUI &&
        !SettingsService.to.compactTabAndForumList &&
        (TabListButtonGuide._key.currentState?.mounted ?? false))
      TabListButtonGuide._key,
    if (!SettingsService.isBackdropUI &&
        !SettingsService.to.compactTabAndForumList &&
        (ForumListButtonGuide._key.currentState?.mounted ?? false))
      ForumListButtonGuide._key,
    if (FeedGuide._key.currentState?.mounted ?? false) FeedGuide._key,
    if (HistoryGuide._key.currentState?.mounted ?? false) HistoryGuide._key,
    if (EditPostGuide._key.currentState?.mounted ?? false) EditPostGuide._key,
  ];

  static final List<GlobalKey> backdropEndDrawerGuides = [
    if (DarkModeGuide._key.currentState?.mounted ?? false) DarkModeGuide._key,
    if (SearchGuide._key.currentState?.mounted ?? false) SearchGuide._key,
    if (HistoryGuide._key.currentState?.mounted ?? false) HistoryGuide._key,
    if (FeedGuide._key.currentState?.mounted ?? false) FeedGuide._key,
    if (SettingsGuide._key.currentState?.mounted ?? false) SettingsGuide._key,
  ];

  static final List<GlobalKey> backLayerTabListGuides = [
    if (TabListGuide._key.currentState?.mounted ?? false) TabListGuide._key,
  ];

  static final List<GlobalKey> backLayerForumListGuides = [
    if (ForumListGuide._key.currentState?.mounted ?? false) ForumListGuide._key,
  ];
}

class AppBarMenuGuide extends StatelessWidget {
  static final GlobalKey _key = GlobalKey();

  final Widget child;

  const AppBarMenuGuide(this.child, {super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return Showcase(
      key: _key,
      title: (settings.showGuide && !SettingsService.isShowBottomBar)
          ? '标签页菜单'
          : '标签页和版块列表菜单',
      description: (settings.showGuide && !SettingsService.isShowBottomBar)
          ? '点击打开标签页'
          : '点击打开标签页和版块列表',
      child: child,
    );
  }
}

class AppBarTitleGuide extends StatelessWidget {
  static final GlobalKey _key = GlobalKey();

  final Widget child;

  const AppBarTitleGuide(this.child, {super.key});

  @override
  Widget build(BuildContext context) => Showcase(
        key: _key,
        title: '标题栏',
        description:
            SettingsService.to.showGuide ? '点击刷新页面' : '点击刷新页面，双击或下拉显示标签页和版块列表',
        child: child,
      );
}

class AppBarPageButtonGuide extends StatelessWidget {
  static final GlobalKey _key = GlobalKey();

  final Widget child;

  const AppBarPageButtonGuide(this.child, {super.key});

  @override
  Widget build(BuildContext context) => Showcase(
        key: _key,
        title: '页数',
        description: '点击可以跳转页数',
        child: child,
      );
}

class AppBarPopupMenuGuide extends StatelessWidget {
  static final GlobalKey _key = GlobalKey();

  final Widget child;

  const AppBarPopupMenuGuide(this.child, {super.key});

  @override
  Widget build(BuildContext context) => Showcase(
        key: _key,
        title: '菜单',
        description: '点击打开功能菜单',
        child: child,
      );
}

class ThreadGuide extends StatelessWidget {
  static final GlobalKey _key = GlobalKey();

  static bool exist() => _key.currentState?.mounted ?? false;

  final Widget child;

  const ThreadGuide(this.child, {super.key});

  @override
  Widget build(BuildContext context) => Showcase(
        key: _key,
        title: '主串',
        description: '点击进入主串，长按打开功能菜单',
        child: child,
      );
}

class EditPostGuide extends StatelessWidget {
  static final GlobalKey _key = GlobalKey();

  final Widget child;

  const EditPostGuide(this.child, {super.key});

  @override
  Widget build(BuildContext context) => Showcase(
        key: _key,
        title: '发串',
        description: '点击发串或回串',
        child: child,
      );
}

class TabListGuide extends StatelessWidget {
  static final GlobalKey _key = GlobalKey();

  final Widget child;

  const TabListGuide(this.child, {super.key});

  @override
  Widget build(BuildContext context) => Showcase(
        key: _key,
        title: '标签页列表',
        description:
            SettingsService.to.showGuide ? '从左向右划可以打开标签页列表，点击切换标签页' : '点击切换标签页',
        child: child,
      );
}

class DarkModeGuide extends StatelessWidget {
  static final GlobalKey _key = GlobalKey();

  final Widget child;

  const DarkModeGuide(this.child, {super.key});

  @override
  Widget build(BuildContext context) => Showcase(
        key: _key,
        title: '黑夜模式',
        description: '点击切换白天/黑夜模式',
        child: child,
      );
}

class SearchGuide extends StatelessWidget {
  static final GlobalKey _key = GlobalKey();

  final Widget child;

  const SearchGuide(this.child, {super.key});

  @override
  Widget build(BuildContext context) => Showcase(
        key: _key,
        title: '搜索',
        description: '现在搜索坏了，只有查询串号的功能',
        child: child,
      );
}

class SettingsGuide extends StatelessWidget {
  static final GlobalKey _key = GlobalKey();

  final Widget child;

  const SettingsGuide(this.child, {super.key});

  @override
  Widget build(BuildContext context) => Showcase(
        key: _key,
        title: '设置',
        description: '点击打开设置页面，里面可以管理饼干',
        child: child,
      );
}

class HistoryGuide extends StatelessWidget {
  static final GlobalKey _key = GlobalKey();

  final Widget child;

  const HistoryGuide(this.child, {super.key});

  @override
  Widget build(BuildContext context) => Showcase(
        key: _key,
        title: '历史记录',
        description: '点击查看浏览、发串和回复记录',
        child: child,
      );
}

class FeedGuide extends StatelessWidget {
  static final GlobalKey _key = GlobalKey();

  final Widget child;

  const FeedGuide(this.child, {super.key});

  @override
  Widget build(BuildContext context) => Showcase(
        key: _key,
        title: '订阅',
        description: '点击查看订阅',
        child: child,
      );
}

class CompactListButtonGuide extends StatelessWidget {
  static final GlobalKey _key = GlobalKey();

  final Widget child;

  const CompactListButtonGuide(this.child, {super.key});

  @override
  Widget build(BuildContext context) => Showcase(
        key: _key,
        title: '标签页和版块列表',
        description: '点击打开标签页和版块列表',
        child: child,
      );
}

class TabListButtonGuide extends StatelessWidget {
  static final GlobalKey _key = GlobalKey();

  final Widget child;

  const TabListButtonGuide(this.child, {super.key});

  @override
  Widget build(BuildContext context) => Showcase(
        key: _key,
        title: '标签页列表',
        description: '点击打开标签页列表',
        child: child,
      );
}

class ForumListButtonGuide extends StatelessWidget {
  static final GlobalKey _key = GlobalKey();

  final Widget child;

  const ForumListButtonGuide(this.child, {super.key});

  @override
  Widget build(BuildContext context) => Showcase(
        key: _key,
        title: '版块列表',
        description: '点击打开版块列表',
        child: child,
      );
}

class ForumListGuide extends StatelessWidget {
  static final GlobalKey _key = GlobalKey();

  final Widget child;

  const ForumListGuide(this.child, {super.key});

  @override
  Widget build(BuildContext context) => Showcase(
        key: _key,
        title: '版块列表',
        description: SettingsService.to.showGuide
            ? '从右向左划可以打开版块列表，点击进入版块，长按打开功能菜单'
            : '点击进入版块，长按打开功能菜单',
        child: child,
      );
}

class ReorderForumsGuide extends StatelessWidget {
  static final GlobalKey _key = GlobalKey();

  final Widget child;

  const ReorderForumsGuide(this.child, {super.key});

  @override
  Widget build(BuildContext context) => Showcase(
        key: _key,
        title: '版块排序',
        description: '点击可以设置版块顺序和显示/隐藏版块',
        child: child,
      );
}
