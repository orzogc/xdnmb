import 'package:get/get.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../modules/image.dart';
import '../modules/post_list.dart';
import '../modules/stack_cache.dart';

abstract class AppRoutes {
  /// 参数：forumId和page
  static const String forum = '/${PathNames.forum}';

  /// 参数：timelineId和page
  static const String timeline = '/${PathNames.timeline}';

  /// 参数：mainPostId、page和jumpToId，arguments为主串Post
  static const String thread = '/${PathNames.thread}';

  /// 参数：mainPostId和page
  static const String onlyPoThread = '/${PathNames.onlyPoThread}';

  /// 参数：postId
  static const String reference = '/${PathNames.reference}';

  /// 参数：page
  static const String feed = '/${PathNames.feed}';

  /// 参数：index（0到2）和page
  static const String history = '/${PathNames.history}';

  static const String image = '/${PathNames.image}';

  static const String settings = '/${PathNames.settings}';

  static const String user = '/${PathNames.user}';

  static const String userPath = '$settings$user';

  static const String reorderForums = '/${PathNames.reorderForums}';

  /// 参数：postListType id title name content forumId imagePath isWatermark
  static const String editPost = '/${PathNames.editPost}';

  static const String postDrafts = '/${PathNames.postDrafts}';

  // TODO: 404
  static const String notFound = '/${PathNames.notFound}';

  static String forumUrl(int forumId, {int page = 1}) =>
      '$forum?forumId=$forumId&page=$page';

  static String timelineUrl(int timelineId, {int page = 1}) =>
      '$timeline?timelineId=$timelineId&page=$page';

  static String threadUrl(int mainPostId, {int page = 1, int? jumpToId}) =>
      jumpToId != null
          ? '$thread?mainPostId=$mainPostId&page=$page&jumpToId=$jumpToId'
          : '$thread?mainPostId=$mainPostId&page=$page';

  static String onlyPoThreadUrl(int mainPostId, {int page = 1}) =>
      '$onlyPoThread?mainPostId=$mainPostId&page=$page';

  static String referenceUrl(int postId) => '$reference?postId=$postId';

  static String feedUrl({int page = 1}) => '$feed?page=$page';

  static String historyUrl({int index = 0, int page = 1}) =>
      '$history?index=$index&page=$page';

  static Future<T?>? toForum<T>({required int forumId, int page = 1}) =>
      Get.toNamed(
        forum,
        id: StackCacheView.getKeyId(),
        parameters: {
          'forumId': '$forumId',
          'page': '$page',
        },
      );

  static Future<T?>? toTimeline<T>({required int timelineId, int page = 1}) =>
      Get.toNamed(
        timeline,
        id: StackCacheView.getKeyId(),
        parameters: {
          'timelineId': '$timelineId',
          'page': '$page',
        },
      );

  static Future<T?>? toThread<T>(
          {required int mainPostId,
          int page = 1,
          int? jumpToId,
          PostBase? mainPost}) =>
      Get.toNamed(
        thread,
        id: StackCacheView.getKeyId(),
        arguments: mainPost,
        parameters: {
          'mainPostId': '$mainPostId',
          'page': '$page',
          if (jumpToId != null) 'jumpToId': '$jumpToId',
        },
      );

  static Future<T?>? toOnlyPoThread<T>(
          {required int mainPostId, int page = 1, PostBase? mainPost}) =>
      Get.toNamed(
        onlyPoThread,
        id: StackCacheView.getKeyId(),
        arguments: mainPost,
        parameters: {
          'mainPostId': '$mainPostId',
          'page': '$page',
        },
      );

  static Future<T?>? toFeed<T>({int page = 1}) => Get.toNamed(
        feed,
        id: StackCacheView.getKeyId(),
        parameters: {'page': '$page'},
      );

  static Future<T?>? toHistory<T>({int index = 0, int page = 1}) => Get.toNamed(
        history,
        id: StackCacheView.getKeyId(),
        parameters: {
          'index': '$index',
          'page': '$page',
        },
      );

  static Future<T?>? toImage<T>(ImageController controller) =>
      Get.toNamed(image, arguments: controller);

  static Future<T?>? toSettings<T>() => Get.toNamed(settings);

  static Future<T?>? toUser<T>() => Get.toNamed(userPath);

  static Future<T?>? toReorderForums<T>() => Get.toNamed(reorderForums);

  static Future<T?>? toEditPost<T>(
          {required PostListType postListType,
          required int id,
          required String title,
          required String name,
          required String content,
          int? forumId,
          String? imagePath,
          required bool isWatermark}) =>
      Get.toNamed(
        editPost,
        parameters: {
          'postListType': '${postListType.index}',
          'id': '$id',
          if (title.isNotEmpty) 'title': title,
          if (name.isNotEmpty) 'name': name,
          if (content.isNotEmpty) 'content': content,
          if (forumId != null) 'forumId': '$forumId',
          if (imagePath != null) 'imagePath': imagePath,
          if (isWatermark) 'isWatermark': '',
        },
      );

  static Future<T?>? toPostDrafts<T>() => Get.toNamed(postDrafts);
}

abstract class PathNames {
  static const String forum = 'forum';

  static const String timeline = 'timeline';

  static const String thread = 'thread';

  static const String onlyPoThread = 'onlyPoThread';

  static const String reference = 'reference';

  static const String feed = 'feed';

  static const String history = 'history';

  static const String image = 'image';

  static const String settings = 'settings';

  static const String user = 'user';

  static const String reorderForums = 'reorderForums';

  static const String editPost = 'editPost';

  static const String postDrafts = 'postDrafts';

  static const String notFound = 'notFound';
}
