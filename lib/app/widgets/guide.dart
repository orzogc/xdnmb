import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

abstract class Guide {
  static bool isShowForumGuides = false;

  static bool isShowDrawerGuides = false;

  static bool isShowEndDrawerGuides = false;

  static final List<GlobalKey> forumGuides = [
    AppBarTitleGuide._key,
    AppBarPageButtonGuide._key,
    AppBarMenuGuide._key,
    ThreadGuide._key,
    FloatingButtonGuide._key,
  ];

  static final List<GlobalKey> drawerGuides = [
    TabListGuide._key,
    DarkModeGuide._key,
    SearchGuide._key,
    SettingsGuide._key,
    HistoryGuide._key,
    FeedGuide._key,
  ];

  static final List<GlobalKey> endDrawerGuides = [
    ForumListGuide._key,
    ReorderForumsGuide._key,
  ];
}

class AppBarTitleGuide extends StatelessWidget {
  static final GlobalKey _key = GlobalKey();

  final Widget child;

  const AppBarTitleGuide(this.child, {super.key});

  @override
  Widget build(BuildContext context) => Showcase(
        key: _key,
        title: '标题栏',
        description: '点击刷新页面',
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

class AppBarMenuGuide extends StatelessWidget {
  static final GlobalKey _key = GlobalKey();

  final Widget child;

  const AppBarMenuGuide(this.child, {super.key});

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

class FloatingButtonGuide extends StatelessWidget {
  static final GlobalKey _key = GlobalKey();

  final Widget child;

  const FloatingButtonGuide(this.child, {super.key});

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
        description: '从左向右划可以打开标签页列表',
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
  Widget build(BuildContext context) => Showcase.withWidget(
        key: _key,
        container: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(8.0)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('订阅', style: Theme.of(context).textTheme.headline6),
              Text('点击查看订阅', style: Theme.of(context).textTheme.subtitle2),
            ],
          ),
        ),
        height: null,
        width: 150,
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
        title: '板块列表',
        description: '从右向左划可以打开板块列表，点击进入板块，长按打开功能菜单',
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
        title: '板块排序',
        description: '点击可以设置板块顺序和显示/隐藏板块',
        child: child,
      );
}
