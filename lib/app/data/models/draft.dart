import 'package:hive/hive.dart';

import '../../modules/edit_post.dart';

part 'draft.g.dart';

/// 草稿数据
@HiveType(typeId: 3)
class PostDraftData extends HiveObject {
  /// 草稿标题
  @HiveField(0, defaultValue: null)
  final String? title;

  /// 草稿名字
  @HiveField(1, defaultValue: null)
  final String? name;

  /// 草稿内容
  @HiveField(2, defaultValue: null)
  final String? content;

  PostDraftData({this.title, this.name, this.content})
      : assert((title?.isNotEmpty ?? false) ||
            (name?.isNotEmpty ?? false) ||
            (content?.isNotEmpty ?? false));

  PostDraftData.fromController(EditPostController controller)
      : assert(controller.hasText),
        title = controller.title,
        name = controller.name,
        content = controller.content;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PostDraftData &&
          title == other.title &&
          name == other.name &&
          content == other.content);

  @override
  int get hashCode => Object.hash(title, name, content);
}
