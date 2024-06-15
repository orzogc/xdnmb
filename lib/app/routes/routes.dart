import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

import '../data/models/controller.dart';
import '../data/services/settings.dart';
import '../data/services/stack.dart';
import '../modules/advanced_settings.dart';
import '../modules/backup.dart';
import '../modules/basic_settings.dart';
import '../modules/basic_ui_settings.dart';
import '../modules/blacklist.dart';
import '../modules/cookie.dart';
import '../modules/drafts.dart';
import '../modules/edit_post.dart';
import '../modules/image.dart';
import '../modules/network_settings.dart';
import '../modules/paint.dart';
import '../modules/post_settings.dart';
import '../modules/reorder_forums.dart';
import '../modules/settings.dart';
import '../modules/scanner.dart';
import '../modules/ui_settings.dart';
import '../widgets/feed.dart';
import '../widgets/forum.dart';
import '../widgets/history.dart';
import '../widgets/listenable.dart';
import '../widgets/tagged.dart';
import '../widgets/thread.dart';

abstract class AppRoutes {
  static const String home = '/';

  /// 参数：forumId 和 page
  static const String forum = '/${PathNames.forum}';

  /// 参数：timelineId 和 page
  static const String timeline = '/${PathNames.timeline}';

  /// 参数：mainPostId、page、cancelAutoJump 和 jumpToId，arguments 为主串 Post
  static const String thread = '/${PathNames.thread}';

  /// 参数：mainPostId、page、cancelAutoJump 和 jumpToId，arguments 为主串 Post
  static const String onlyPoThread = '/${PathNames.onlyPoThread}';

  /// 参数：postId
  static const String reference = '/${PathNames.reference}';

  /// 参数：index（0 到 1）和 page
  static const String feed = '/${PathNames.feed}';

  /// 参数：index（0 到 2）和 page
  static const String history = '/${PathNames.history}';

  /// 参数：tagId 和 page
  static const String taggedPostList = '/${PathNames.taggedPostList}';

  static const String image = '/${PathNames.image}';

  static const String settings = '/${PathNames.settings}';

  static const String user = '/${PathNames.user}';

  static const String userPath = '$settings$user';

  static const String qrCodeScanner = '/${PathNames.qrCodeScanner}';

  static const String qrCodeScannerPath = '$userPath$qrCodeScanner';

  static const String blacklist = '/${PathNames.blacklist}';

  static const String blacklistPath = '$settings$blacklist';

  static const String basicSettings = '/${PathNames.basicSettings}';

  static const String basicSettingsPath = '$settings$basicSettings';

  static const String advancedSettings = '/${PathNames.advancedSettings}';

  static const String advancedSettingsPath = '$settings$advancedSettings';

  static const String networkSettings = '/${PathNames.networkSettings}';

  static const String networkSettingsPath =
      '$advancedSettingsPath$networkSettings';

  static const String uiSettings = '/${PathNames.uiSettings}';

  static const String uiSettingsPath = '$settings$uiSettings';

  static const String basicUISettings = '/${PathNames.basicUISettings}';

  static const String basicUISettingsPath = '$uiSettingsPath$basicUISettings';

  static const String postUISettings = '/${PathNames.postUISettings}';

  static const String postUISettingsPath = '$uiSettingsPath$postUISettings';

  static const String backup = '/${PathNames.backup}';

  static const String backupPath = '$settings$backup';

  static const String reorderForums = '/${PathNames.reorderForums}';

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

  static String feedUrl({int? index, int page = 1}) =>
      index != null ? '$feed?index=$index&page=$page' : '$feed?page=$page';

  static String historyUrl({int? index, int page = 1}) => index != null
      ? '$history?index=$index&page=$page'
      : '$history?page=$page';

  static String taggedPostListUrl(int tagId, {int page = 1}) =>
      '$taggedPostList?tagId=$tagId&page=$page';

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
          mainPost: mainPost,
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
          mainPost: mainPost,
          cancelAutoJump: cancelAutoJump,
          jumpToId: jumpToId));

  static void toFeed<T>({int? index, int page = 1}) =>
      ControllerStacksService.to
          .pushController(FeedController(page: page, pageIndex: index));

  static void toHistory<T>(
          {int? index,
          int page = 1,
          List<DateTimeRange?>? dateRange,
          List<Search?>? search}) =>
      ControllerStacksService.to.pushController(HistoryController(
          page: page, pageIndex: index, dateRange: dateRange, search: search));

  static void toTaggedPostList<T>(
          {required int tagId, int page = 1, Search? search}) =>
      ControllerStacksService.to.pushController(
          TaggedPostListController(id: tagId, page: page, search: search));

  static Future<T?>? toImage<T>(ImageController controller) =>
      Get.toNamed<T>(image, arguments: controller);

  static Future<T?>? toSettings<T>() => Get.toNamed<T>(settings);

  static Future<T?>? toUser<T>() => Get.toNamed<T>(userPath);

  static Future<T?>? toQRCodeScanner<T>() => Get.toNamed<T>(qrCodeScannerPath);

  static Future<T?>? toBlacklist<T>() => Get.toNamed<T>(blacklistPath);

  static Future<T?>? toBasicSettings<T>() => Get.toNamed<T>(basicSettingsPath);

  static Future<T?>? toAdvancedSettings<T>() =>
      Get.toNamed<T>(advancedSettingsPath);

  static Future<T?>? toNetworkSettings<T>() =>
      Get.toNamed<T>(networkSettingsPath);

  static Future<T?>? toUISettings<T>() => Get.toNamed<T>(uiSettingsPath);

  static Future<T?>? toBasicUISettings<T>() =>
      Get.toNamed<T>(basicUISettingsPath);

  static Future<T?>? toPostUISettings<T>() =>
      Get.toNamed<T>(postUISettingsPath);

  static Future<T?>? toBackup<T>() => Get.toNamed<T>(backupPath);

  static Future<T?>? toReorderForums<T>() => Get.toNamed<T>(reorderForums);

  static Future<T?>? toEditPost<T>(
          {required PostListType postListType,
          required int id,
          int? forumId,
          String? poUserHash,
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
        arguments: EditPostController(
            postListType: postListType,
            id: id,
            forumId: forumId,
            poUserHash: poUserHash,
            title: title,
            name: name,
            content: content,
            imagePath: imagePath,
            imageData: imageData,
            isWatermark: isWatermark,
            reportReason: reportReason,
            isAttachDeviceInfo: isAttachDeviceInfo),
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

  static const String taggedPostList = 'taggedPostList';

  static const String image = 'image';

  static const String settings = 'settings';

  static const String user = 'user';

  static const String qrCodeScanner = 'qrCodeScanner';

  static const String blacklist = 'blacklist';

  static const String basicSettings = 'basicSettings';

  static const String advancedSettings = 'advancedSettings';

  static const String networkSettings = 'networkSettings';

  static const String uiSettings = 'uiSettings';

  static const String basicUISettings = 'basicUISettings';

  static const String postUISettings = 'postUISettings';

  static const String backup = 'backup';

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
  bool get canSwipe => SettingsService.to.isSwipeablePageRx;

  @override
  double get backGestureDetectionWidth => _backGestureDetectionWidth;

  @override
  WidgetBuilder get builder => (context) {
        _active();

        return super.builder(context);
      };

  AppSwipeablePageRoute(
      {super.settings, bool maintainState = true, required super.builder})
      : _maintainState = maintainState,
        super(canOnlySwipeFromEdge: true) {
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

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    final settings = SettingsService.to;

    return SwipeablePageRoute.buildPageTransitions(
      this,
      context,
      animation,
      secondaryAnimation,
      child,
      canSwipe: () => settings.isSwipeablePageRx,
      canOnlySwipeFromEdge: () => canOnlySwipeFromEdge,
      backGestureDetectionWidth: () => backGestureDetectionWidth,
      backGestureDetectionStartOffset: () => backGestureDetectionStartOffset,
      transitionBuilder: transitionBuilder,
    );
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

    return ListenBuilder(
      listenable: settings.swipeablePageDragWidthRatioListenable,
      builder: (context, child_) => SwipeablePageRoute.buildPageTransitions<T>(
        route,
        context,
        animation,
        secondaryAnimation,
        child,
        canSwipe: () => settings.isSwipeablePageRx,
        canOnlySwipeFromEdge: () => true,
        backGestureDetectionWidth: () =>
            MediaQuery.sizeOf(context).width *
            settings.swipeablePageDragWidthRatio,
        transitionBuilder: transitionBuilder,
      ),
    );
  }
}

/// 生成 [Route]
Route? onGenerateRoute(RouteSettings settings) {
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
      case AppRoutes.qrCodeScannerPath:
        return AppSwipeablePageRoute(
            settings: settings,
            builder: (context) => const QRCodeScannerView());
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
      case AppRoutes.networkSettingsPath:
        return AppSwipeablePageRoute(
            settings: settings,
            builder: (context) => const NetworkSettingsView());
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
      case AppRoutes.backupPath:
        return AppSwipeablePageRoute(
            settings: settings, builder: (context) => const BackupView());
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
        throw '未知 URI: $uri';
    }
  } else {
    throw '未知 RouteSettings: $RouteSettings';
  }
}
