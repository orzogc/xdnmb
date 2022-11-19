import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';

import '../data/services/settings.dart';
import '../modules/advanced_settings.dart';
import '../modules/basic_settings.dart';
import '../modules/blacklist.dart';
import '../modules/cookie.dart';
import '../modules/drafts.dart';
import '../modules/edit_post.dart';
import '../modules/image.dart';
import '../modules/paint.dart';
import '../modules/post_list.dart';
import '../modules/reorder_forums.dart';
import '../modules/settings.dart';
import 'routes.dart';

/// 应用页面
abstract class AppPages {
  /// 根页面
  static final GetPage _home = GetPage(
      name: AppRoutes.home,
      page: () => const PostListView(),
      transition: Transition.rightToLeft,
      children: [
        _forum,
        _timeline,
        _thread,
        _onlyPoThread,
        _feed,
        _history,
        _image,
        _settings,
        _reorderForumList,
        _editPost,
        _postDrafts,
        _paint,
      ]);

  /// 版块页面
  static final GetPage _forum = GetPage(
      name: AppRoutes.forum,
      page: () => const PostListView(),
      binding: PostListBinding(),
      transition: Transition.rightToLeft);

  /// 时间线页面
  static final GetPage _timeline = GetPage(
      name: AppRoutes.timeline,
      page: () => const PostListView(),
      binding: PostListBinding(),
      transition: Transition.rightToLeft);

  /// 串（帖子）页面
  static final GetPage _thread = GetPage(
      name: AppRoutes.thread,
      page: () => const PostListView(),
      binding: PostListBinding(),
      transition: Transition.rightToLeft);

  /// 串（帖子）的只看Po的页面
  static final GetPage _onlyPoThread = GetPage(
      name: AppRoutes.onlyPoThread,
      page: () => const PostListView(),
      binding: PostListBinding(),
      transition: Transition.rightToLeft);

  /// 订阅页面
  static final GetPage _feed = GetPage(
      name: AppRoutes.feed,
      page: () => const PostListView(),
      binding: PostListBinding(),
      transition: Transition.rightToLeft);

  /// 历史记录页面
  static final GetPage _history = GetPage(
      name: AppRoutes.history,
      page: () => const PostListView(),
      binding: PostListBinding(),
      transition: Transition.rightToLeft);

  /// 图片浏览页面
  static final GetPage _image = GetPage(
      name: AppRoutes.image,
      page: () => ImageView(),
      binding: ImageBinding(),
      transition: Transition.fadeIn,
      opaque: false);

  /// 设置页面
  static final GetPage _settings = GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
      transition: Transition.rightToLeft,
      children: [_user, _blacklist, _basicSettings, _advancedSettings]);

  /// 用户（饼干管理）页面
  static final GetPage _user = GetPage(
      name: AppRoutes.user,
      page: () => const CookieView(),
      binding: CookieBinding(),
      transition: Transition.rightToLeft);

  /// 黑名单页面
  static final GetPage _blacklist = GetPage(
      name: AppRoutes.blacklist,
      page: () => const BlacklistView(),
      binding: BlacklistBinding(),
      transition: Transition.rightToLeft);

  /// 基本设置页面
  static final GetPage _basicSettings = GetPage(
      name: AppRoutes.basicSettings,
      page: () => const BasicSettingsView(),
      binding: BasicSettingsBinding(),
      transition: Transition.rightToLeft);

  /// 高级设置页面
  static final GetPage _advancedSettings = GetPage(
      name: AppRoutes.advancedSettings,
      page: () => const AdvancedSettingsView(),
      binding: AdvancedSettingsBinding(),
      transition: Transition.rightToLeft);

  /// 版块排序页面
  static final GetPage _reorderForumList = GetPage(
      name: AppRoutes.reorderForums,
      page: () => ReorderForumsView(),
      binding: ReorderForumsBinding(),
      transition: Transition.rightToLeft);

  /// 发串编辑页面
  static final GetPage _editPost = GetPage(
      name: AppRoutes.editPost,
      page: () => EditPostView(),
      binding: EditPostBinding(),
      transition: Transition.rightToLeft);

  /// 草稿箱页面
  static final GetPage _postDrafts = GetPage(
      name: AppRoutes.postDrafts,
      page: () => const PostDraftsView(),
      binding: PostDraftsBinding(),
      transition: Transition.rightToLeft);

  /// 涂鸦页面
  static final GetPage _paint = GetPage(
      name: AppRoutes.paint,
      page: () => const PaintView(),
      binding: PaintBinding(),
      transition: Transition.rightToLeft);
}

/// [GetPage]列表
List<GetPage> getPages = [AppPages._home];

/// Backdrop UI下生成[Route]
Route? backdropOnGenerateRoute(RouteSettings settings) {
  if (settings.name != null) {
    final uri = Uri.parse(settings.name!);
    Get.parameters = uri.queryParameters;

    switch (uri.path) {
      case AppRoutes.image:
        return GetPageRoute(
            settings: settings,
            routeName: AppRoutes.image,
            page: () => ImageView(),
            binding: ImageBinding(),
            transition: Transition.fadeIn,
            opaque: false);
      case AppRoutes.settings:
        return SwipeablePageRoute(
            settings: settings,
            canOnlySwipeFromEdge: true,
            backGestureDetectionWidth: Get.mediaQuery.size.width *
                SettingsService.to.swipeablePageDragWidthRatio,
            builder: (context) {
              SettingsBinding().dependencies();

              return const SettingsView();
            });
      case AppRoutes.userPath:
        return SwipeablePageRoute(
            settings: settings,
            canOnlySwipeFromEdge: true,
            backGestureDetectionWidth: Get.mediaQuery.size.width *
                SettingsService.to.swipeablePageDragWidthRatio,
            builder: (context) {
              CookieBinding().dependencies();

              return const CookieView();
            });
      case AppRoutes.blacklistPath:
        return SwipeablePageRoute(
            settings: settings,
            canOnlySwipeFromEdge: true,
            backGestureDetectionWidth: Get.mediaQuery.size.width *
                SettingsService.to.swipeablePageDragWidthRatio,
            builder: (context) {
              BlacklistBinding().dependencies();

              return const BlacklistView();
            });
      case AppRoutes.basicSettingsPath:
        return SwipeablePageRoute(
            settings: settings,
            canOnlySwipeFromEdge: true,
            backGestureDetectionWidth: Get.mediaQuery.size.width *
                SettingsService.to.swipeablePageDragWidthRatio,
            builder: (context) {
              BasicSettingsBinding().dependencies();

              return const BasicSettingsView();
            });
      case AppRoutes.advancedSettingsPath:
        return SwipeablePageRoute(
            settings: settings,
            canOnlySwipeFromEdge: true,
            backGestureDetectionWidth: Get.mediaQuery.size.width *
                SettingsService.to.swipeablePageDragWidthRatio,
            builder: (context) {
              AdvancedSettingsBinding().dependencies();

              return const AdvancedSettingsView();
            });
      case AppRoutes.reorderForums:
        return SwipeablePageRoute(
            settings: settings,
            canOnlySwipeFromEdge: true,
            backGestureDetectionWidth: Get.mediaQuery.size.width *
                SettingsService.to.swipeablePageDragWidthRatio,
            builder: (context) {
              ReorderForumsBinding().dependencies();

              return ReorderForumsView();
            });
      case AppRoutes.editPost:
        return GetPageRoute(
            settings: settings,
            routeName: AppRoutes.editPost,
            page: () => EditPostView(),
            binding: EditPostBinding(),
            transition: Transition.rightToLeft);
      case AppRoutes.postDrafts:
        return SwipeablePageRoute(
            settings: settings,
            canOnlySwipeFromEdge: true,
            backGestureDetectionWidth: Get.mediaQuery.size.width *
                SettingsService.to.swipeablePageDragWidthRatio,
            builder: (context) {
              PostDraftsBinding().dependencies();

              return const PostDraftsView();
            });
      case AppRoutes.paint:
        return GetPageRoute(
            settings: settings,
            routeName: AppRoutes.paint,
            page: () => const PaintView(),
            binding: PaintBinding(),
            transition: Transition.rightToLeft);
      default:
        throw '未知URI: $uri';
    }
  } else {
    throw '未知RouteSettings: $RouteSettings';
  }
}
