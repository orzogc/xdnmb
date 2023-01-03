import 'package:flutter/material.dart';
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

  /// 最后发串时间
  @HiveField(5, defaultValue: null)
  DateTime? lastPostTime;

  /// 饼干颜色
  @HiveField(6, defaultValue: 0xff2196f3)
  int colorValue;

  Color get color => Color(colorValue);

  CookieData(
      {required this.name,
      required this.userHash,
      this.id,
      this.isDeprecated = false,
      this.note,
      this.lastPostTime,
      this.colorValue = 0xff2196f3});

  CookieData.fromXdnmbCookie(
      {required XdnmbCookie cookie,
      this.isDeprecated = false,
      this.note,
      this.lastPostTime,
      this.colorValue = 0xff2196f3})
      : name = cookie.name!,
        userHash = cookie.userHash,
        id = cookie.id;

  /// 返回废弃饼干
  CookieData deprecate() => CookieData(
      name: name,
      userHash: userHash,
      id: id,
      isDeprecated: true,
      note: note,
      lastPostTime: lastPostTime,
      colorValue: colorValue);

  /// 修改备注
  Future<void> editNote(String? note) async {
    this.note = note;
    await save();
  }

  /// 设置最后发串时间
  Future<void> setLastPostTime(DateTime time) async {
    lastPostTime = time;
    await save();
  }

  /// 设置饼干颜色
  Future<void> setColor(Color color) async {
    colorValue = color.value;
    await save();
  }

  /// 返回删除的饼干，去掉敏感数据
  CookieData deleted() => CookieData(
      name: name,
      userHash: '',
      id: null,
      isDeprecated: isDeprecated,
      note: note,
      lastPostTime: lastPostTime,
      colorValue: colorValue);

  /// 复制饼干
  CookieData copy() => CookieData(
      name: name,
      userHash: userHash,
      id: id,
      isDeprecated: isDeprecated,
      note: note,
      lastPostTime: lastPostTime,
      colorValue: colorValue);

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
          note == other.note &&
          lastPostTime == other.lastPostTime &&
          colorValue == other.colorValue);

  @override
  int get hashCode => Object.hash(
      name, userHash, id, isDeprecated, note, lastPostTime, colorValue);
}
