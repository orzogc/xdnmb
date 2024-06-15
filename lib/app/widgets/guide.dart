import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:showcaseview/showcaseview.dart';

import '../data/services/settings.dart';

abstract class Guide {
  static bool isShowForumGuides = false;

  static bool isShowDrawerGuides = false;

  static bool isShowEndDrawerHasOnlyOneListGuides = false;

  static bool isShowBottomBarGuides = false;

  static bool isShowTabListGuide = false;

  static bool isShowForumListGuide = false;

  static bool isShowEndDrawerBottomGuides = false;

  static List<GlobalKey> get forumGuides => [
        if (AppBarMenuGuide._key.currentState?.mounted ?? false)
          AppBarMenuGuide._key,
        if (AppBarTitleGuide._key.currentState?.mounted ?? false)
          AppBarTitleGuide._key,
        if (AppBarPageButtonGuide._key.currentState?.mounted ?? false)
          AppBarPageButtonGuide._key,
        if (AppBarPopupMenuGuide._key.currentState?.mounted ?? false)
          AppBarPopupMenuGuide._key,
        if (ThreadGuide._key.currentState?.mounted ?? false) ThreadGuide._key,
        if (FloatingButtonGuide._key.currentState?.mounted ?? false)
          FloatingButtonGuide._key,
      ];

  static List<GlobalKey> get drawerGuides => [
        if (TabListGuide._key.currentState?.mounted ?? false) TabListGuide._key,
        if (ForumListGuide._key.currentState?.mounted ?? false)
          ForumListGuide._key,
        if (DarkModeGuide._key.currentState?.mounted ?? false)
          DarkModeGuide._key,
        if (SearchGuide._key.currentState?.mounted ?? false) SearchGuide._key,
        if (SettingsGuide._key.currentState?.mounted ?? false)
          SettingsGuide._key,
        if (HistoryGuide._key.currentState?.mounted ?? false) HistoryGuide._key,
        if (FeedGuide._key.currentState?.mounted ?? false) FeedGuide._key,
      ];

  static List<GlobalKey> get endDrawerHasOnlyOneListGuides => [
        if (ForumListGuide._key.currentState?.mounted ?? false)
          ForumListGuide._key,
        if (TabListGuide._key.currentState?.mounted ?? false) TabListGuide._key,
        if (ReorderForumsGuide._key.currentState?.mounted ?? false)
          ReorderForumsGuide._key,
      ];

  static List<GlobalKey> get bottomBarGuides => [
        if (SearchGuide._key.currentState?.mounted ?? false) SearchGuide._key,
        if (SettingsGuide._key.currentState?.mounted ?? false)
          SettingsGuide._key,
        if (CompactListButtonGuide._key.currentState?.mounted ?? false)
          CompactListButtonGuide._key,
        if (TabListButtonGuide._key.currentState?.mounted ?? false)
          TabListButtonGuide._key,
        if (ForumListButtonGuide._key.currentState?.mounted ?? false)
          ForumListButtonGuide._key,
        if (FeedGuide._key.currentState?.mounted ?? false) FeedGuide._key,
        if (HistoryGuide._key.currentState?.mounted ?? false) HistoryGuide._key,
        if (EditPostGuide._key.currentState?.mounted ?? false)
          EditPostGuide._key,
      ];

  static List<GlobalKey> get tabListGuide => [
        if (TabListGuide._key.currentState?.mounted ?? false) TabListGuide._key,
      ];

  static List<GlobalKey> get forumListGuide => [
        if (ForumListGuide._key.currentState?.mounted ?? false)
          ForumListGuide._key,
      ];

  static List<GlobalKey> get endDrawerBottomGuides => [
        if (HistoryGuide._key.currentState?.mounted ?? false) HistoryGuide._key,
        if (FeedGuide._key.currentState?.mounted ?? false) FeedGuide._key,
        if (SettingsGuide._key.currentState?.mounted ?? false)
          SettingsGuide._key,
        if (SearchGuide._key.currentState?.mounted ?? false) SearchGuide._key,
      ];
}

class AppBarMenuGuide extends StatelessWidget {
  static final GlobalKey _key = GlobalKey();

  final Widget child;

  const AppBarMenuGuide(this.child, {super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return SettingsService.shouldShowGuide
        ? Obx(
            () {
              late final String text;
              switch (settings.endDrawerSettingRx) {
                case 0:
                  text = '标签页和版块列表';
                  break;
                case 1:
                  text = '标签页列表';
                  break;
                case 2:
                  text = '版块列表';
                  break;
                case 3:
                  text = '标签页和版块列表';
                  break;
                default:
                  text = '未知列表';
              }

              // autocorrect: false
              return Showcase(
                key: _key,
                title: '$text菜单',
                description: '点击打开$text',
                child: child,
              );
              // autocorrect: true
            },
          )
        : child;
  }
}

class AppBarTitleGuide extends StatelessWidget {
  static final GlobalKey _key = GlobalKey();

  final Widget child;

  const AppBarTitleGuide(this.child, {super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return SettingsService.shouldShowGuide
        ? Obx(
            () {
              late final String text;
              switch (settings.endDrawerSettingRx) {
                case 0:
                  text = '标签页和版块列表';
                  break;
                case 1:
                  text = '标签页列表';
                  break;
                case 2:
                  text = '版块列表';
                  break;
                case 3:
                  text = '未知列表';
                  break;
                default:
                  text = '未知列表';
              }

              return Showcase(
                key: _key,
                title: '标题栏',
                description: (settings.useDrawerAndEndDrawerRx ||
                        settings.endDrawerSettingRx == 3)
                    ? '点击刷新页面'
                    : '点击刷新页面，双击显示$text',
                child: child,
              );
            },
          )
        : child;
  }
}

class AppBarPageButtonGuide extends StatelessWidget {
  static final GlobalKey _key = GlobalKey();

  final Widget child;

  const AppBarPageButtonGuide(this.child, {super.key});

  @override
  Widget build(BuildContext context) => SettingsService.shouldShowGuide
      ? Showcase(key: _key, title: '页数', description: '点击可以跳转页数', child: child)
      : child;
}

class AppBarPopupMenuGuide extends StatelessWidget {
  static final GlobalKey _key = GlobalKey();

  final Widget child;

  const AppBarPopupMenuGuide(this.child, {super.key});

  @override
  Widget build(BuildContext context) => SettingsService.shouldShowGuide
      ? Showcase(key: _key, title: '菜单', description: '点击打开功能菜单', child: child)
      : child;
}

class ThreadGuide extends StatelessWidget {
  static final GlobalKey _key = GlobalKey();

  static bool get exist => _key.currentState?.mounted ?? false;

  final Widget child;

  const ThreadGuide(this.child, {super.key});

  @override
  Widget build(BuildContext context) => Showcase(
      key: _key, title: '主串', description: '点击查看串的内容，长按打开功能菜单', child: child);
}

class FloatingButtonGuide extends StatelessWidget {
  static final GlobalKey _key = GlobalKey();

  final Widget child;

  const FloatingButtonGuide(this.child, {super.key});

  @override
  Widget build(BuildContext context) => SettingsService.isShowGuide
      ? Showcase(key: _key, title: '发串', description: '点击发串或回串', child: child)
      : child;
}

class EditPostGuide extends StatelessWidget {
  static final GlobalKey _key = GlobalKey();

  final Widget child;

  const EditPostGuide(this.child, {super.key});

  @override
  Widget build(BuildContext context) => SettingsService.shouldShowGuide
      ? Showcase(key: _key, title: '发串', description: '点击发串或回串', child: child)
      : child;
}

class TabListGuide extends StatelessWidget {
  static final GlobalKey _key = GlobalKey();

  static final GlobalKey _key2 = GlobalKey();

  final Widget child;

  const TabListGuide(this.child, {super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return Obx(() {
      late final String text;
      switch (settings.endDrawerSettingRx) {
        case 0:
          text = '';
          break;
        case 1:
          if (settings.useDrawerAndEndDrawerRx) {
            text = '从左向右划可以打开标签页列表，';
          } else {
            text = '';
          }

          break;
        case 2:
          text = '从右向左划可以打开标签页列表，';
          break;
        case 3:
          text = '从右向左划可以打开标签页列表和版块列表，';
          break;
        default:
          text = '';
      }

      // autocorrect: false
      return Showcase(
        key: _key.currentState == null ? _key : _key2,
        title: '标签页列表',
        description: '$text点击切换标签页',
        child: child,
      );
      // autocorrect: true
    });
  }
}

class DarkModeGuide extends StatelessWidget {
  static final GlobalKey _key = GlobalKey();

  final Widget child;

  const DarkModeGuide(this.child, {super.key});

  @override
  Widget build(BuildContext context) => SettingsService.shouldShowGuide
      ? Showcase(
          key: _key, title: '黑夜模式', description: '点击切换白天/黑夜模式', child: child)
      : child;
}

class SearchGuide extends StatelessWidget {
  static final GlobalKey _key = GlobalKey();

  final Widget child;

  const SearchGuide(this.child, {super.key});

  @override
  Widget build(BuildContext context) => SettingsService.shouldShowGuide
      ? Showcase(
          key: _key,
          title: '查询',
          description: '现在搜索坏了，只有查询串号和标签的功能',
          child: child)
      : child;
}

class SettingsGuide extends StatelessWidget {
  static final GlobalKey _key = GlobalKey();

  final Widget child;

  const SettingsGuide(this.child, {super.key});

  @override
  Widget build(BuildContext context) => SettingsService.shouldShowGuide
      ? Showcase(
          key: _key,
          title: '设置',
          description: '点击打开设置页面，里面可以管理饼干',
          child: child)
      : child;
}

class HistoryGuide extends StatelessWidget {
  static final GlobalKey _key = GlobalKey();

  final Widget child;

  const HistoryGuide(this.child, {super.key});

  @override
  Widget build(BuildContext context) => SettingsService.shouldShowGuide
      ? Showcase(
          key: _key, title: '历史记录', description: '点击查看浏览、发串和回复记录', child: child)
      : child;
}

class FeedGuide extends StatelessWidget {
  static final GlobalKey _key = GlobalKey();

  final Widget child;

  const FeedGuide(this.child, {super.key});

  @override
  Widget build(BuildContext context) => SettingsService.shouldShowGuide
      ? Showcase(
          key: _key, title: '订阅/标签', description: '点击查看订阅和标签', child: child)
      : child;
}

class CompactListButtonGuide extends StatelessWidget {
  static final GlobalKey _key = GlobalKey();

  final Widget child;

  const CompactListButtonGuide(this.child, {super.key});

  @override
  Widget build(BuildContext context) => SettingsService.shouldShowGuide
      ? Showcase(
          key: _key,
          title: '标签页和版块列表',
          description: '点击打开标签页和版块列表',
          child: child)
      : child;
}

class TabListButtonGuide extends StatelessWidget {
  static final GlobalKey _key = GlobalKey();

  final Widget child;

  const TabListButtonGuide(this.child, {super.key});

  @override
  Widget build(BuildContext context) => SettingsService.shouldShowGuide
      ? Showcase(
          key: _key, title: '标签页列表', description: '点击打开标签页列表', child: child)
      : child;
}

class ForumListButtonGuide extends StatelessWidget {
  static final GlobalKey _key = GlobalKey();

  final Widget child;

  const ForumListButtonGuide(this.child, {super.key});

  @override
  Widget build(BuildContext context) => SettingsService.shouldShowGuide
      ? Showcase(
          key: _key, title: '版块列表', description: '点击打开版块列表', child: child)
      : child;
}

class ForumListGuide extends StatelessWidget {
  static final GlobalKey _key = GlobalKey();

  final Widget child;

  const ForumListGuide(this.child, {super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return Obx(() {
      late final String text;
      switch (settings.endDrawerSettingRx) {
        case 0:
          text = '';
          break;
        case 1:
          text = '从右向左划可以打开版块列表，';
          break;
        case 2:
          if (settings.useDrawerAndEndDrawerRx) {
            text = '从左向右划可以打开版块列表，';
          } else {
            text = '';
          }

          break;
        case 3:
          text = '从右向左划可以切换标签页列表和版块列表，';
          break;
        default:
          text = '';
      }

      // autocorrect: false
      return Showcase(
        key: _key,
        title: '版块列表',
        description: '$text点击进入版块，长按打开功能菜单',
        child: child,
      );
      // autocorrect: true
    });
  }
}

class ReorderForumsGuide extends StatelessWidget {
  static final GlobalKey _key = GlobalKey();

  final Widget child;

  const ReorderForumsGuide(this.child, {super.key});

  @override
  Widget build(BuildContext context) => SettingsService.shouldShowGuide
      ? Showcase(
          key: _key,
          title: '版块管理',
          description: '点击可以设置版块顺序和显示/隐藏版块',
          child: child)
      : child;
}
