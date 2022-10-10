import 'package:get/get.dart';
import 'package:xdnmb/app/modules/post_list.dart';

import '../modules/blacklist.dart';
import '../modules/cookie.dart';
import '../modules/drafts.dart';
import '../modules/edit_post.dart';
import '../modules/image.dart';
import '../modules/paint.dart';
import '../modules/reorder_forums.dart';
import '../modules/settings.dart';

import 'routes.dart';

abstract class AppPages {
  static final GetPage forum = GetPage(
      name: AppRoutes.forum,
      page: () => const PostListView(),
      binding: PostListBinding(),
      transition: Transition.rightToLeft);

  static final GetPage timeline = GetPage(
      name: AppRoutes.timeline,
      page: () => const PostListView(),
      binding: PostListBinding(),
      transition: Transition.rightToLeft);

  static final GetPage thread = GetPage(
      name: AppRoutes.thread,
      page: () => const PostListView(),
      binding: PostListBinding(),
      transition: Transition.rightToLeft);

  static final GetPage onlyPoThread = GetPage(
      name: AppRoutes.onlyPoThread,
      page: () => const PostListView(),
      binding: PostListBinding(),
      transition: Transition.rightToLeft);

  static final GetPage feed = GetPage(
      name: AppRoutes.feed,
      page: () => const PostListView(),
      binding: PostListBinding(),
      transition: Transition.rightToLeft);

  static final GetPage history = GetPage(
      name: AppRoutes.history,
      page: () => const PostListView(),
      binding: PostListBinding(),
      transition: Transition.rightToLeft);

  static final GetPage image = GetPage(
      name: AppRoutes.image,
      page: () => ImageView(),
      binding: ImageBinding(),
      transition: Transition.fadeIn);

  static final GetPage settings = GetPage(
      name: AppRoutes.settings,
      page: () => const SettingsView(),
      binding: SettingsBinding(),
      transition: Transition.rightToLeft,
      children: [
        GetPage(
            name: AppRoutes.user,
            page: () => const CookieView(),
            binding: CookieBinding(),
            transition: Transition.rightToLeft),
        GetPage(
            name: AppRoutes.blacklist,
            page: () => BlacklistView(),
            binding: BlacklistBinding(),
            transition: Transition.rightToLeft),
      ]);

  static final GetPage reorderForumList = GetPage(
      name: AppRoutes.reorderForums,
      page: () => ReorderForumsView(),
      binding: ReorderForumsBinding(),
      transition: Transition.leftToRight);

  static final GetPage editPost = GetPage(
      name: AppRoutes.editPost,
      page: () => EditPostView(),
      binding: EditPostBinding(),
      transition: Transition.rightToLeft);

  static final GetPage postDrafts = GetPage(
      name: AppRoutes.postDrafts,
      page: () => const PostDraftsView(),
      binding: PostDraftsBinding(),
      transition: Transition.rightToLeft);

  static final GetPage paint = GetPage(
      name: AppRoutes.paint,
      page: () => const PaintView(),
      binding: PaintBinding(),
      transition: Transition.rightToLeft);
}

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
