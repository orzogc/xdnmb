import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../modules/image.dart';
import '../modules/paint.dart';
import '../modules/post_list.dart';
import '../utils/stack.dart';

abstract class AppRoutes {
  /// 参数：forumId和page
  static const String forum = '/${PathNames.forum}';

  /// 参数：timelineId和page
  static const String timeline = '/${PathNames.timeline}';

  /// 参数：mainPostId、page、cancelAutoJump和jumpToId，arguments为主串Post
  static const String thread = '/${PathNames.thread}';

  /// 参数：mainPostId、page和cancelAutoJump，arguments为主串Post
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

  static const String blacklist = '/${PathNames.blacklist}';

  static const String blacklistPath = '$settings$blacklist';

  static const String basicSettings = '/${PathNames.basicSettings}';

  static const String basicSettingsPath = '$settings$basicSettings';

  static const String advancedSettings = '/${PathNames.advancedSettings}';

  static const String advancedSettingsPath = '$settings$advancedSettings';

  static const String reorderForums = '/${PathNames.reorderForums}';

  /// 参数：postListType id title name content forumId imagePath isWatermark reportReason
  static const String editPost = '/${PathNames.editPost}';

  static const String postDrafts = '/${PathNames.postDrafts}';

  static const String paint = '/${PathNames.paint}';

  // TODO: 404
  static const String notFound = '/${PathNames.notFound}';

  static String forumUrl(int forumId, {int page = 1}) =>
      '$forum?forumId=$forumId&page=$page';

  static String timelineUrl(int timelineId, {int page = 1}) =>
      '$timeline?timelineId=$timelineId&page=$page';

  static String threadUrl(int mainPostId,
          {int page = 1, bool cancelAutoJump = false, int? jumpToId}) =>
      jumpToId != null
          ? '$thread?mainPostId=$mainPostId&page=$page&cancelAutoJump=$cancelAutoJump&jumpToId=$jumpToId'
          : '$thread?mainPostId=$mainPostId&page=$page&cancelAutoJump=$cancelAutoJump';

  static String onlyPoThreadUrl(int mainPostId,
          {int page = 1, bool cancelAutoJump = false}) =>
      '$onlyPoThread?mainPostId=$mainPostId&page=$page&cancelAutoJump=$cancelAutoJump';

  static String feedUrl({int page = 1}) => '$feed?page=$page';

  static String historyUrl({int index = 0, int page = 1}) =>
      '$history?index=$index&page=$page';

  static String referenceUrl(int postId) => '$reference?postId=$postId';

  static Future<T?>? toForum<T>({required int forumId, int page = 1}) =>
      Get.toNamed<T>(
        forum,
        id: ControllerStack.getKeyId(),
        parameters: {'forumId': '$forumId', 'page': '$page'},
      );

  static Future<T?>? toTimeline<T>({required int timelineId, int page = 1}) =>
      Get.toNamed<T>(
        timeline,
        id: ControllerStack.getKeyId(),
        parameters: {'timelineId': '$timelineId', 'page': '$page'},
      );

  static Future<T?>? toThread<T>(
          {required int mainPostId,
          int page = 1,
          bool cancelAutoJump = false,
          int? jumpToId,
          PostBase? mainPost}) =>
      Get.toNamed<T>(
        thread,
        id: ControllerStack.getKeyId(),
        arguments: mainPost,
        parameters: {
          'mainPostId': '$mainPostId',
          'page': '$page',
          'cancelAutoJump': '$cancelAutoJump',
          if (jumpToId != null) 'jumpToId': '$jumpToId',
        },
      );

  static Future<T?>? toOnlyPoThread<T>(
          {required int mainPostId,
          int page = 1,
          bool cancelAutoJump = false,
          PostBase? mainPost}) =>
      Get.toNamed<T>(
        onlyPoThread,
        id: ControllerStack.getKeyId(),
        arguments: mainPost,
        parameters: {
          'mainPostId': '$mainPostId',
          'page': '$page',
          'cancelAutoJump': '$cancelAutoJump',
        },
      );

  static Future<T?>? toFeed<T>({int page = 1}) => Get.toNamed<T>(
        feed,
        id: ControllerStack.getKeyId(),
        parameters: {'page': '$page'},
      );

  static Future<T?>? toHistory<T>({int index = 0, int page = 1}) =>
      Get.toNamed<T>(
        history,
        id: ControllerStack.getKeyId(),
        parameters: {'index': '$index', 'page': '$page'},
      );

  static Future<T?>? toImage<T>(ImageController controller) =>
      Get.toNamed<T>(image, arguments: controller);

  static Future<T?>? toSettings<T>() => Get.toNamed<T>(settings);

  static Future<T?>? toUser<T>() => Get.toNamed<T>(userPath);

  static Future<T?>? toBlacklist<T>() => Get.toNamed<T>(blacklistPath);

  static Future<T?>? toBasicSettings<T>() => Get.toNamed<T>(basicSettingsPath);

  static Future<T?>? toAdvancedSettings<T>() =>
      Get.toNamed<T>(advancedSettingsPath);

  static Future<T?>? toReorderForums<T>() => Get.toNamed<T>(reorderForums);

  static Future<T?>? toEditPost<T>(
          {required PostListType postListType,
          required int id,
          String? title,
          String? name,
          String? content,
          int? forumId,
          String? imagePath,
          Uint8List? imageData,
          bool? isWatermark,
          String? reportReason}) =>
      Get.toNamed<T>(
        editPost,
        parameters: {
          'postListType': '${postListType.index}',
          'id': '$id',
          if (title != null && title.isNotEmpty) 'title': title,
          if (name != null && name.isNotEmpty) 'name': name,
          if (content != null && content.isNotEmpty) 'content': content,
          if (forumId != null) 'forumId': '$forumId',
          if (imagePath != null) 'imagePath': imagePath,
          if (isWatermark != null) 'isWatermark': '$isWatermark',
          if (reportReason != null && reportReason.isNotEmpty)
            'reportReason': reportReason,
        },
        arguments: imageData,
      );

  static Future<T?>? toPostDrafts<T>() => Get.toNamed<T>(postDrafts);

  static Future<T?>? toPaint<T>([PaintController? controller]) =>
      Get.toNamed<T>(paint, arguments: controller);
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

  static const String blacklist = 'blacklist';

  static const String basicSettings = 'basicSettings';

  static const String advancedSettings = 'advancedSettings';

  static const String reorderForums = 'reorderForums';

  static const String editPost = 'editPost';

  static const String postDrafts = 'postDrafts';

  static const String notFound = 'notFound';

  static const String paint = 'paint';
}
