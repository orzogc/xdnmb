import 'package:hive/hive.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

part 'emoticon.g.dart';

/// 颜文字数据
@HiveType(typeId: 4)
class EmoticonData extends HiveObject {
  /// 颜文字名称
  @HiveField(0)
  String name;

  /// 颜文字内容
  @HiveField(1)
  String text;

  /// 插入颜文字后光标位置的移动，为`null`时光标移动[text]的长度
  @HiveField(2, defaultValue: null)
  int? offset;

  EmoticonData({required this.name, required this.text, this.offset})
      : assert(name.isNotEmpty && text.isNotEmpty);

  EmoticonData.fromEmoticon(Emoticon emoticon)
      : this(name: emoticon.name, text: emoticon.text);

  /// 设置[name]和[text]
  void set({required String name, required String text}) {
    if (name.isNotEmpty) {
      this.name = name;
    }

    if (text.isNotEmpty) {
      this.text = text;
    }
  }

  EmoticonData copy() => EmoticonData(name: name, text: text, offset: offset);

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
