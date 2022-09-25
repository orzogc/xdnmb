import 'package:hive/hive.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

part 'emoticon.g.dart';

@HiveType(typeId: 4)
class EmoticonData extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  String text;

  @HiveField(2, defaultValue: null)
  int? offset;

  EmoticonData({required this.name, required this.text, this.offset})
      : assert(name.isNotEmpty && text.isNotEmpty);

  EmoticonData.fromEmoticon(Emoticon emoticon)
      : this(name: emoticon.name, text: emoticon.text);

  void set({required String name, required String text}) {
    if (name.isNotEmpty) {
      this.name = name;
    }

    if (text.isNotEmpty) {
      this.text = text;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EmoticonData &&
          name == other.name &&
          text == other.text &&
          offset == other.offset);

  @override
  int get hashCode => Object.hash(name, text, offset);
}
