import 'package:hive/hive.dart';

import '../../modules/edit_post.dart';

part 'draft.g.dart';

@HiveType(typeId: 3)
class PostDraftData extends HiveObject {
  @HiveField(0, defaultValue: null)
  final String? title;

  @HiveField(1, defaultValue: null)
  final String? name;

  @HiveField(2, defaultValue: null)
  final String? content;

  PostDraftData({this.title, this.name, this.content})
      : assert(
            (title?.isNotEmpty ?? false) ||
                (name?.isNotEmpty ?? false) ||
                (content?.isNotEmpty ?? false),
            'text can\'t be all empty');

  PostDraftData.fromController(EditPostController controller)
      : assert(controller.hasText(), 'text can\'t be all empty'),
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
