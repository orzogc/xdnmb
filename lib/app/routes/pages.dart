import 'package:get/get.dart';

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
  /// 版块页面
  static final GetPage forum = GetPage(
      name: AppRoutes.forum,
      page: () => const PostListView(),
      binding: PostListBinding(),
      transition: Transition.rightToLeft);

  /// 时间线页面
  static final GetPage timeline = GetPage(
      name: AppRoutes.timeline,
      page: () => const PostListView(),
      binding: PostListBinding(),
      transition: Transition.rightToLeft);

  /// 串（帖子）页面
  static final GetPage thread = GetPage(
      name: AppRoutes.thread,
      page: () => const PostListView(),
      binding: PostListBinding(),
      transition: Transition.rightToLeft);

  /// 串（帖子）的只看Po的页面
  static final GetPage onlyPoThread = GetPage(
      name: AppRoutes.onlyPoThread,
      page: () => const PostListView(),
      binding: PostListBinding(),
      transition: Transition.rightToLeft);

  /// 订阅页面
  static final GetPage feed = GetPage(
      name: AppRoutes.feed,
      page: () => const PostListView(),
      binding: PostListBinding(),
      transition: Transition.rightToLeft);

  /// 历史记录页面
  static final GetPage history = GetPage(
      name: AppRoutes.history,
      page: () => const PostListView(),
      binding: PostListBinding(),
      transition: Transition.rightToLeft);

  /// 图片浏览页面
  static final GetPage image = GetPage(
      name: AppRoutes.image,
      page: () => ImageView(),
      binding: ImageBinding(),
      transition: Transition.fadeIn,
      opaque: false);

  /// 设置页面
  static final GetPage settings = GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
      transition: Transition.rightToLeft,
      children: [
        // 用户（饼干管理）页面
        GetPage(
            name: AppRoutes.user,
            page: () => const CookieView(),
            binding: CookieBinding(),
            transition: Transition.rightToLeft),
        // 黑名单页面
        GetPage(
            name: AppRoutes.blacklist,
            page: () => const BlacklistView(),
            binding: BlacklistBinding(),
            transition: Transition.rightToLeft),
        // 基本设置页面
        GetPage(
            name: AppRoutes.basicSettings,
            page: () => const BasicSettingsView(),
            binding: BasicSettingsBinding(),
            transition: Transition.rightToLeft),
        // 高级设置页面
        GetPage(
            name: AppRoutes.advancedSettings,
            page: () => const AdvancedSettingsView(),
            binding: AdvancedSettingsBinding(),
            transition: Transition.rightToLeft)
      ]);

  /// 版块排序页面
  static final GetPage reorderForumList = GetPage(
      name: AppRoutes.reorderForums,
      page: () => ReorderForumsView(),
      binding: ReorderForumsBinding(),
      transition: Transition.rightToLeft);

  /// 发串编辑页面
  static final GetPage editPost = GetPage(
      name: AppRoutes.editPost,
      page: () => EditPostView(),
      binding: EditPostBinding(),
      transition: Transition.rightToLeft);

  /// 草稿箱页面
  static final GetPage postDrafts = GetPage(
      name: AppRoutes.postDrafts,
      page: () => const PostDraftsView(),
      binding: PostDraftsBinding(),
      transition: Transition.rightToLeft);

  /// 涂鸦页面
  static final GetPage paint = GetPage(
      name: AppRoutes.paint,
      page: () => const PaintView(),
      binding: PaintBinding(),
      transition: Transition.rightToLeft);
}

/// [GetPage]列表
List<GetPage> getPages = [
  AppPages.forum,
  AppPages.timeline,
  AppPages.thread,
  AppPages.onlyPoThread,
  AppPages.feed,
  AppPages.history,
  AppPages.image,
  AppPages.settings,
  AppPages.reorderForumList,
  AppPages.editPost,
  AppPages.postDrafts,
  AppPages.paint,
];
