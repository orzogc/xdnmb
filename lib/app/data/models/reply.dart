import 'package:isar/isar.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

part 'reply.g.dart';

/// 应官方要求，本地不再保存图片地址相关字段
@Collection(ignore: {'hashCode'})
class ReplyData {
  static const int taggedPostIdPrefix = 2;

  static int getTaggedPostId(int id) => (taggedPostIdPrefix << 32) | id;

  Id id = Isar.autoIncrement;

  int mainPostId;

  int? postId;

  int forumId;

  String? image;

  String? imageExtension;

  // UTC
  @Index()
  DateTime postTime;

  String userHash;

  String? name;

  String? title;

  String content;

  bool isAdmin;

  int? page;

  bool hasImage;

  @ignore
  bool get hasPostId => postId != null;

  @ignore
  bool get isComplete => hasPostId && page != null;

  @ignore
  int get taggedPostId => getTaggedPostId(id);

  /// [image] 是为了兼容旧版本，用来判断 [hasImage]
  ReplyData(
      {required this.mainPostId,
      this.postId,
      required this.forumId,
      String? image,
      required DateTime postTime,
      required this.userHash,
      String? name,
      String? title,
      required String content,
      this.isAdmin = false,
      this.page,
      bool hasImage = false})
      : image = null,
        imageExtension = null,
        postTime = postTime.toUtc(),
        name = ((name?.isNotEmpty ?? false) && name != '无名氏') ? name : null,
        title = ((title?.isNotEmpty ?? false) && title != '无标题') ? title : null,
        content = content.isNotEmpty ? content : '分享图片',
        hasImage = (image?.isNotEmpty ?? false) || hasImage;

  ReplyData.fromPost({required Post post, required int mainPostId, int? page})
      : this(
            mainPostId: mainPostId,
            postId: post.id,
            forumId: post.forumId,
            postTime: post.postTime,
            userHash: post.userHash,
            name: post.name,
            title: post.title,
            content: post.content,
            isAdmin: post.isAdmin,
            page: page,
            hasImage: post.hasImage);

  /// 返回的 postId 可能是 [taggedPostId]
  Post toPost() => Post(
      id: postId ?? taggedPostId,
      forumId: forumId,
      replyCount: 0,
      image: image ?? '',
      imageExtension: imageExtension ?? '',
      postTime: postTime,
      userHash: userHash,
      name: name ?? '',
      title: title ?? '',
      content: content,
      isAdmin: isAdmin);

  void update({required PostBase post, int? mainPostId, int? page}) {
    if (mainPostId != null) {
      this.mainPostId = mainPostId;
    }
    if (post.forumId != null) {
      forumId = post.forumId!;
    }
    if (page != null) {
      this.page = page;
    }

    postId = post.id;
    image = null;
    imageExtension = null;
    postTime = post.postTime.toUtc();
    userHash = post.userHash;
    name = (post.name.isNotEmpty && post.name != '无名氏') ? post.name : null;
    title = (post.title.isNotEmpty && post.title != '无标题') ? post.title : null;
    content = post.content.isNotEmpty ? post.content : '分享图片';
    isAdmin = post.isAdmin;
    hasImage = post.hasImage;
  }

  /// 不复制 [image] 和 [imageExtension]
  ReplyData copy() => ReplyData(
      mainPostId: mainPostId,
      postId: postId,
      forumId: forumId,
      postTime: postTime,
      userHash: userHash,
      name: name,
      title: title,
      content: content,
      isAdmin: isAdmin,
      page: page,
      hasImage: hasImage);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReplyData &&
          id == other.id &&
          mainPostId == other.mainPostId &&
          postId == other.postId &&
          forumId == other.forumId &&
          image == other.image &&
          imageExtension == other.imageExtension &&
          postTime == other.postTime &&
          userHash == other.userHash &&
          name == other.name &&
          title == other.title &&
          content == other.content &&
          isAdmin == other.isAdmin &&
          page == other.page &&
          hasImage == other.hasImage);

  @ignore
  @override
  int get hashCode => Object.hash(
      id,
      mainPostId,
      postId,
      forumId,
      image,
      imageExtension,
      postTime,
      userHash,
      name,
      title,
      content,
      isAdmin,
      page,
      hasImage);
}
