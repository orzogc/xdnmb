import 'package:isar/isar.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

part 'post.g.dart';

/// 应官方要求，本地不再保存图片地址相关字段
@collection
class PostData {
  Id id = Isar.autoIncrement;

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

  bool hasImage;

  /// [image]是为了兼容旧版本，用来判断[hasImage]
  PostData(
      {this.postId,
      required this.forumId,
      String? image,
      required DateTime postTime,
      required this.userHash,
      String? name,
      String? title,
      required String content,
      this.isAdmin = false,
      bool hasImage = false})
      : image = null,
        imageExtension = null,
        postTime = postTime.toUtc(),
        name = ((name?.isNotEmpty ?? false) && name != '无名氏') ? name : null,
        title = ((title?.isNotEmpty ?? false) && title != '无标题') ? title : null,
        content = content.isNotEmpty ? content : '分享图片',
        hasImage = (image?.isNotEmpty ?? false) || hasImage;

  PostData.fromPost(Post post)
      : this(
            postId: post.id,
            forumId: post.forumId,
            postTime: post.postTime,
            userHash: post.userHash,
            name: post.name,
            title: post.title,
            content: post.content,
            isAdmin: post.isAdmin,
            hasImage: post.hasImage);

  Post toPost() => Post(
      id: postId ?? 0,
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

  void update(PostBase post) {
    if (post.forumId != null) {
      forumId = post.forumId!;
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PostData &&
          id == other.id &&
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
          hasImage == other.hasImage);

  @ignore
  @override
  int get hashCode => Object.hash(id, postId, forumId, image, imageExtension,
      postTime, userHash, name, title, content, isAdmin, hasImage);
}
