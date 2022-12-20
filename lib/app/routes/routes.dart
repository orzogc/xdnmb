import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../data/models/controller.dart';
import '../data/services/settings.dart';
import '../data/services/stack.dart';
import '../modules/advanced_settings.dart';
import '../modules/basic_settings.dart';
import '../modules/basic_ui_settings.dart';
import '../modules/blacklist.dart';
import '../modules/cookie.dart';
import '../modules/drafts.dart';
import '../modules/edit_post.dart';
import '../modules/image.dart';
import '../modules/paint.dart';
import '../modules/post_settings.dart';
import '../modules/reorder_forums.dart';
import '../modules/settings.dart';
import '../modules/ui_settings.dart';
import '../widgets/feed.dart';
import '../widgets/forum.dart';
import '../widgets/history.dart';
import '../widgets/thread.dart';

abstract class AppRoutes {
  static const String home = '/';

  /// 参数：forumId和page
  static const String forum = '/${PathNames.forum}';

  /// 参数：timelineId和page
  static const String timeline = '/${PathNames.timeline}';

  /// 参数：mainPostId、page、cancelAutoJump和jumpToId，arguments为主串Post
  static const String thread = '/${PathNames.thread}';

  /// 参数：mainPostId、page、cancelAutoJump和jumpToId，arguments为主串Post
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

  static const String uiSettings = '/${PathNames.uiSettings}';

  static const String uiSettingsPath = '$settings$uiSettings';

  static const String basicUISettings = '/${PathNames.basicUISettings}';

  static const String basicUISettingsPath = '$uiSettingsPath$basicUISettings';

  static const String postUISettings = '/${PathNames.postUISettings}';

  static const String postUISettingsPath = '$uiSettingsPath$postUISettings';

  static const String reorderForums = '/${PathNames.reorderForums}';

  /// 参数：postListType id title name content forumId imagePath isWatermark
  /// reportReason isAttachDeviceInfo
  static const String editPost = '/${PathNames.editPost}';

  static const String postDrafts = '/${PathNames.postDrafts}';

  static const String paint = '/${PathNames.paint}';

  static const int feedbackId = 52940632;

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
          {int page = 1, bool cancelAutoJump = false, int? jumpToId}) =>
      jumpToId != null
          ? '$onlyPoThread?mainPostId=$mainPostId&page=$page&cancelAutoJump=$cancelAutoJump&jumpToId=$jumpToId'
          : '$onlyPoThread?mainPostId=$mainPostId&page=$page&cancelAutoJump=$cancelAutoJump';

  static String feedUrl({int page = 1}) => '$feed?page=$page';

  static String historyUrl({int index = 0, int page = 1}) =>
      '$history?index=$index&page=$page';

  static String referenceUrl(int postId) => '$reference?postId=$postId';

  static void toForum<T>({required int forumId, int page = 1}) =>
      ControllerStacksService.to
          .pushController(ForumController(id: forumId, page: page));

  static void toTimeline<T>({required int timelineId, int page = 1}) =>
      ControllerStacksService.to
          .pushController(TimelineController(id: timelineId, page: page));

  static void toThread<T>(
          {required int mainPostId,
          int page = 1,
          bool cancelAutoJump = false,
          int? jumpToId,
          PostBase? mainPost}) =>
      ControllerStacksService.to.pushController(ThreadController(
          id: mainPostId,
          page: page,
          post: mainPost,
          cancelAutoJump: cancelAutoJump,
          jumpToId: jumpToId));

  static void toOnlyPoThread<T>(
          {required int mainPostId,
          int page = 1,
          bool cancelAutoJump = false,
          int? jumpToId,
          PostBase? mainPost}) =>
      ControllerStacksService.to.pushController(OnlyPoThreadController(
          id: mainPostId,
          page: page,
          post: mainPost,
          cancelAutoJump: cancelAutoJump,
          jumpToId: jumpToId));

  static void toFeed<T>({int page = 1}) =>
      ControllerStacksService.to.pushController(FeedController(page));

  static void toHistory<T>(
          {int index = 0,
          int page = 1,
          List<DateTimeRange?>? dateRange,
          List<Search?>? search}) =>
      ControllerStacksService.to.pushController(HistoryController(
          page: page, pageIndex: index, dateRange: dateRange, search: search));

  static Future<T?>? toImage<T>(ImageController controller) =>
      Get.toNamed<T>(image, arguments: controller);

  static Future<T?>? toSettings<T>() => Get.toNamed<T>(settings);

  static Future<T?>? toUser<T>() => Get.toNamed<T>(userPath);

  static Future<T?>? toBlacklist<T>() => Get.toNamed<T>(blacklistPath);

  static Future<T?>? toBasicSettings<T>() => Get.toNamed<T>(basicSettingsPath);

  static Future<T?>? toAdvancedSettings<T>() =>
      Get.toNamed<T>(advancedSettingsPath);

  static Future<T?>? toUISettings<T>() => Get.toNamed<T>(uiSettingsPath);

  static Future<T?>? toBasicUISettings<T>() =>
      Get.toNamed<T>(basicUISettingsPath);

  static Future<T?>? toPostUISettings<T>() =>
      Get.toNamed<T>(postUISettingsPath);

  static Future<T?>? toReorderForums<T>() => Get.toNamed<T>(reorderForums);

  static Future<T?>? toEditPost<T>(
          {required PostListType postListType,
          required int id,
          int? forumId,
          String? title,
          String? name,
          String? content,
          String? imagePath,
          Uint8List? imageData,
          bool? isWatermark,
          String? reportReason,
          bool? isAttachDeviceInfo}) =>
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
          if (isAttachDeviceInfo != null)
            'isAttachDeviceInfo': '$isAttachDeviceInfo',
        },
        arguments: imageData,
      );

  static Future<T?>? toPostDrafts<T>() => Get.toNamed<T>(postDrafts);

  static Future<T?>? toPaint<T>([PaintController? controller]) =>
      Get.toNamed<T>(paint, arguments: controller);

  static void toFeedback<T>() => toThread(mainPostId: feedbackId);
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

  static const String uiSettings = 'uiSettings';

  static const String basicUISettings = 'basicUISettings';

  static const String postUISettings = 'postUISettings';

  static const String reorderForums = 'reorderForums';

  static const String editPost = 'editPost';

  static const String postDrafts = 'postDrafts';

  static const String paint = 'paint';
}

class AppSwipeablePageRoute<T> extends SwipeablePageRoute<T> {
  bool _maintainState;

  double _backGestureDetectionWidth = Get.mediaQuery.size.width *
      SettingsService.to.swipeablePageDragWidthRatio;

  @override
  bool get maintainState => _maintainState;

  @override
  double get backGestureDetectionWidth => _backGestureDetectionWidth;

  @override
  WidgetBuilder get builder => (context) {
        _active();

        return super.builder(context);
      };

  AppSwipeablePageRoute(
      {RouteSettings? settings,
      bool maintainState = true,
      required WidgetBuilder builder})
      : _maintainState = maintainState,
        super(
            settings: settings,
            canSwipe: SettingsService.isSwipeablePage,
            canOnlySwipeFromEdge: true,
            builder: builder) {
    SettingsService.to.swipeablePageDragWidthRatioListenable
        .addListener(_dragWidth);
  }

  void _active() {
    if (isActive && !_maintainState) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        if (isActive && !_maintainState) {
          _maintainState = true;
          changedInternalState();
        }
      });
    }
  }

  void _dragWidth() =>
      setState(() => _backGestureDetectionWidth = Get.mediaQuery.size.width *
          SettingsService.to.swipeablePageDragWidthRatio);

  @override
  void dispose() {
    SettingsService.to.swipeablePageDragWidthRatioListenable
        .removeListener(_dragWidth);

    super.dispose();
  }
}

class AppPageTransitionsBuilder extends SwipeablePageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
      PageRoute<T> route,
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    final settings = SettingsService.to;

    return ValueListenableBuilder(
      valueListenable: settings.swipeablePageDragWidthRatioListenable,
      builder: (context, value, child_) =>
          SwipeablePageRoute.buildPageTransitions<T>(
        route,
        context,
        animation,
        secondaryAnimation,
        child,
        canSwipe: () => SettingsService.isSwipeablePage,
        canOnlySwipeFromEdge: true,
        backGestureDetectionWidth:
            Get.mediaQuery.size.width * settings.swipeablePageDragWidthRatio,
        transitionBuilder: transitionBuilder,
      ),
    );
  }
}

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
            transition: Transition.fadeIn,
            opaque: false);
      case AppRoutes.settings:
        return AppSwipeablePageRoute(
            settings: settings, builder: (context) => const SettingsView());
      case AppRoutes.userPath:
        return AppSwipeablePageRoute(
            settings: settings, builder: (context) => const CookieView());
      case AppRoutes.blacklistPath:
        return AppSwipeablePageRoute(
            settings: settings, builder: (context) => const BlacklistView());
      case AppRoutes.basicSettingsPath:
        return AppSwipeablePageRoute(
            settings: settings,
            builder: (context) => const BasicSettingsView());
      case AppRoutes.advancedSettingsPath:
        return AppSwipeablePageRoute(
            settings: settings,
            builder: (context) => const AdvancedSettingsView());
      case AppRoutes.uiSettingsPath:
        return AppSwipeablePageRoute(
            settings: settings, builder: (context) => const UISettingsView());
      case AppRoutes.basicUISettingsPath:
        return AppSwipeablePageRoute(
            settings: settings,
            builder: (context) => const BasicUISettingsView());
      case AppRoutes.postUISettingsPath:
        return GetPageRoute(
            settings: settings,
            routeName: AppRoutes.postUISettingsPath,
            binding: PostFontSettingsBinding(),
            page: () => const PostFontSettingsView(),
            transition: Transition.rightToLeft);
      case AppRoutes.reorderForums:
        return AppSwipeablePageRoute(
            settings: settings,
            builder: (context) => const ReorderForumsView());
      case AppRoutes.editPost:
        return GetPageRoute(
            settings: settings,
            routeName: AppRoutes.editPost,
            binding: EditPostBinding(),
            page: () => const EditPostView(),
            transition: Transition.rightToLeft);
      case AppRoutes.postDrafts:
        return AppSwipeablePageRoute(
            settings: settings, builder: (context) => const PostDraftsView());
      case AppRoutes.paint:
        return GetPageRoute(
            settings: settings,
            routeName: AppRoutes.paint,
            binding: PaintBinding(),
            page: () => const PaintView(),
            transition: Transition.rightToLeft);
      default:
        throw '未知URI: $uri';
    }
  } else {
    throw '未知RouteSettings: $RouteSettings';
  }
}
