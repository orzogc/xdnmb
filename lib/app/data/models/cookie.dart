import 'package:hive/hive.dart';
import 'package:xdnmb_api/xdnmb_api.dart';

part 'cookie.g.dart';

/// 饼干数据
@HiveType(typeId: 2)
class CookieData extends HiveObject {
  /// 饼干显示的名字
  @HiveField(0)
  final String name;

  /// 饼干的userhash
  @HiveField(1)
  final String userHash;

  /// 饼干的ID
  @HiveField(2, defaultValue: null)
  final int? id;

  /// 饼干是否废弃（是否登陆帐号所拥有）
  @HiveField(3, defaultValue: false)
  final bool isDeprecated;

  /// 饼干备注
  @HiveField(4, defaultValue: null)
  String? note;

  CookieData(
      {required this.name,
      required this.userHash,
      this.id,
      this.isDeprecated = false,
      this.note});

  CookieData.fromXdnmbCookie(
      {required XdnmbCookie cookie, this.isDeprecated = false, this.note})
      : name = cookie.name!,
        userHash = cookie.userHash,
        id = cookie.id;

  /// 返回废弃饼干
  CookieData deprecate() => CookieData(
      name: name, userHash: userHash, id: id, isDeprecated: true, note: note);

  /// 修改备注
  Future<void> editNote(String? note) async {
    this.note = note;
    await save();
  }

  /// 复制饼干
  CookieData copy() => CookieData(
      name: name,
      userHash: userHash,
      id: id,
      isDeprecated: isDeprecated,
      note: note);

  /// 返回饼干的cookie
  String cookie() => 'userhash=$userHash';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CookieData &&
          name == other.name &&
          userHash == other.userHash &&
          id == other.id &&
          isDeprecated == other.isDeprecated &&
          note == other.note);

  @override
  int get hashCode => Object.hash(name, userHash, id, isDeprecated, note);
}
