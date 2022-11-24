import 'package:get/get.dart';

import '../modules/advanced_settings.dart';
import '../modules/backdrop_settings.dart';
import '../modules/basic_settings.dart';
import '../modules/blacklist.dart';
import '../modules/cookie.dart';
import '../modules/drafts.dart';
import '../modules/edit_post.dart';
import '../modules/image.dart';
import '../modules/paint.dart';
import '../modules/post_list.dart';
import '../modules/post_settings.dart';
import '../modules/reorder_forums.dart';
import '../modules/settings.dart';
import '../modules/ui_settings.dart';
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
      binding: PostListBinding(),
      page: () => const PostListView(),
      transition: Transition.rightToLeft);

  /// 时间线页面
  static final GetPage _timeline = GetPage(
      name: AppRoutes.timeline,
      binding: PostListBinding(),
      page: () => const PostListView(),
      transition: Transition.rightToLeft);

  /// 串（帖子）页面
  static final GetPage _thread = GetPage(
      name: AppRoutes.thread,
      binding: PostListBinding(),
      page: () => const PostListView(),
      transition: Transition.rightToLeft);

  /// 串（帖子）的只看Po的页面
  static final GetPage _onlyPoThread = GetPage(
      name: AppRoutes.onlyPoThread,
      binding: PostListBinding(),
      page: () => const PostListView(),
      transition: Transition.rightToLeft);

  /// 订阅页面
  static final GetPage _feed = GetPage(
      name: AppRoutes.feed,
      binding: PostListBinding(),
      page: () => const PostListView(),
      transition: Transition.rightToLeft);

  /// 历史记录页面
  static final GetPage _history = GetPage(
      name: AppRoutes.history,
      binding: PostListBinding(),
      page: () => const PostListView(),
      transition: Transition.rightToLeft);

  /// 图片浏览页面
  static final GetPage _image = GetPage(
      name: AppRoutes.image,
      binding: ImageBinding(),
      page: () => ImageView(),
      transition: Transition.fadeIn,
      opaque: false);

  /// 设置页面
  static final GetPage _settings = GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsView(),
      transition: Transition.rightToLeft,
      children: [
        _user,
        _blacklist,
        _basicSettings,
        _advancedSettings,
        _uiSettings,
      ]);

  /// 用户（饼干管理）页面
  static final GetPage _user = GetPage(
      name: AppRoutes.user,
      page: () => const CookieView(),
      transition: Transition.rightToLeft);

  /// 黑名单页面
  static final GetPage _blacklist = GetPage(
      name: AppRoutes.blacklist,
      binding: BlacklistBinding(),
      page: () => const BlacklistView(),
      transition: Transition.rightToLeft);

  /// 基本设置页面
  static final GetPage _basicSettings = GetPage(
      name: AppRoutes.basicSettings,
      page: () => const BasicSettingsView(),
      transition: Transition.rightToLeft);

  /// 高级设置页面
  static final GetPage _advancedSettings = GetPage(
      name: AppRoutes.advancedSettings,
      page: () => const AdvancedSettingsView(),
      transition: Transition.rightToLeft);

  static final GetPage _uiSettings = GetPage(
      name: AppRoutes.uiSettings,
      page: () => const UISettingsView(),
      transition: Transition.rightToLeft,
      children: [_backdropUISettings, _postUISettings]);

  static final GetPage _backdropUISettings = GetPage(
      name: AppRoutes.backdropUISettings,
      page: () => const BackdropUISettingsView(),
      transition: Transition.rightToLeft);

  static final GetPage _postUISettings = GetPage(
      name: AppRoutes.postUISettings,
      binding: PostUISettingsBinding(),
      page: () => const PostUISettingsView(),
      transition: Transition.rightToLeft);

  /// 版块排序页面
  static final GetPage _reorderForumList = GetPage(
      name: AppRoutes.reorderForums,
      page: () => const ReorderForumsView(),
      transition: Transition.rightToLeft);

  /// 发串编辑页面
  static final GetPage _editPost = GetPage(
      name: AppRoutes.editPost,
      binding: EditPostBinding(),
      page: () => EditPostView(),
      transition: Transition.rightToLeft);

  /// 草稿箱页面
  static final GetPage _postDrafts = GetPage(
      name: AppRoutes.postDrafts,
      page: () => const PostDraftsView(),
      transition: Transition.rightToLeft);

  /// 涂鸦页面
  static final GetPage _paint = GetPage(
      name: AppRoutes.paint,
      binding: PaintBinding(),
      page: () => const PaintView(),
      transition: Transition.rightToLeft);
}

/// [GetPage]列表
List<GetPage> getPages = [AppPages._home];
