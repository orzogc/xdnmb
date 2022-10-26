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
        name = name != null
            ? ((name.isNotEmpty && name != '无名氏') ? name : null)
            : null,
        title = title != null
            ? ((title.isNotEmpty && title != '无标题') ? title : null)
            : null,
        content = content.isNotEmpty ? content : '分享图片',
        hasImage = (image != null && image.isNotEmpty) || hasImage;

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
            hasImage: post.hasImage());

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

  void update(Post post) {
    postId = post.id;
    forumId = post.forumId;
    image = null;
    imageExtension = null;
    postTime = post.postTime.toUtc();
    userHash = post.userHash;
    name = (post.name.isNotEmpty && post.name != '无名氏') ? post.name : null;
    title = (post.title.isNotEmpty && post.title != '无标题') ? post.title : null;
    content = post.content.isNotEmpty ? post.content : '分享图片';
    isAdmin = post.isAdmin;
    hasImage = post.hasImage();
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
