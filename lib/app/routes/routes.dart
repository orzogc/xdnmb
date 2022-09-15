abstract class AppRoutes {
  /// 参数：forumId和page
  static const String forum = '/${PathNames.forum}';

  /// 参数：timelineId和page
  static const String timeline = '/${PathNames.timeline}';

  /// 参数：mainPostId和page
  static const String thread = '/${PathNames.thread}';

  /// 参数：mainPostId和page
  static const String onlyPoThread = '/${PathNames.onlyPoThread}';

  /// 参数：postId
  static const String reference = '/${PathNames.reference}';

  /// 参数：page
  static const String feed = '/${PathNames.feed}';

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

  static String threadUrl(int mainPostId, {int page = 1}) =>
      '$thread?mainPostId=$mainPostId&page=$page';

  static String onlyPoThreadUrl(int mainPostId, {int page = 1}) =>
      '$onlyPoThread?mainPostId=$mainPostId&page=$page';

  static String referenceUrl(int postId) => '$reference?postId=$postId';

  static String feedUrl({int page = 1}) => '$feed?page=$page';
}

abstract class PathNames {
  static const String forum = 'forum';

  static const String timeline = 'timeline';

  static const String thread = 'thread';

  static const String onlyPoThread = 'onlyPoThread';

  static const String reference = 'reference';

  static const String feed = 'feed';

  static const String image = 'image';

  static const String settings = 'settings';

  static const String user = 'user';

  static const String reorderForums = 'reorderForums';

  static const String editPost = 'editPost';

  static const String postDrafts = 'postDrafts';

  static const String notFound = 'notFound';
}
