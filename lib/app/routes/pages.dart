import 'package:get/get.dart';
import 'package:xdnmb/app/modules/post_list.dart';

import '../modules/cookie.dart';
import '../modules/drafts.dart';
import '../modules/edit_post.dart';
import '../modules/image.dart';
import '../modules/reorder_forums.dart';
import '../modules/settings.dart';

import 'routes.dart';

abstract class AppPages {
  static final GetPage forum = GetPage(
      name: AppRoutes.forum,
      page: () => PostListView(),
      binding: PostListBinding(),
      transition: Transition.rightToLeft);

  static final GetPage timeline = GetPage(
      name: AppRoutes.timeline,
      page: () => PostListView(),
      binding: PostListBinding(),
      transition: Transition.rightToLeft);

  static final GetPage thread = GetPage(
      name: AppRoutes.thread,
      page: () => PostListView(),
      binding: PostListBinding(),
      transition: Transition.rightToLeft);

  static final GetPage onlyPoThread = GetPage(
      name: AppRoutes.onlyPoThread,
      page: () => PostListView(),
      binding: PostListBinding(),
      transition: Transition.rightToLeft);

  static final GetPage feed = GetPage(
      name: AppRoutes.feed,
      page: () => PostListView(),
      binding: PostListBinding(),
      transition: Transition.rightToLeft);

  static final GetPage history = GetPage(
      name: AppRoutes.history,
      page: () => PostListView(),
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
            transition: Transition.rightToLeft)
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
];
