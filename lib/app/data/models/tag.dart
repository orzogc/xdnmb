import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

part 'tag.g.dart';

@HiveType(typeId: 11)
class TagData extends HiveObject {
  /// 从 0 开始
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2, defaultValue: null)
  final int? backgroundColorValue;

  @HiveField(3, defaultValue: null)
  final int? textColorValue;

  /// 新的在最前面
  @HiveField(4, defaultValue: <int>[])
  final List<int> pinnedPosts;

  bool get useDefaultColor =>
      backgroundColorValue == null && textColorValue == null;

  Color get backgroundColor => backgroundColorValue != null
      ? Color(backgroundColorValue!)
      : Get.theme.colorScheme.primary;

  Color get textColor => textColorValue != null
      ? Color(textColorValue!)
      : Get.theme.colorScheme.onPrimary;

  TagData(
      {required this.id,
      required this.name,
      this.backgroundColorValue,
      this.textColorValue,
      required this.pinnedPosts})
      : assert(name.isNotEmpty);

  TagData copyWith(
          {String? name,
          Color? backgroundColor,
          Color? textColor,
          List<int>? pinnedPosts}) =>
      TagData(
          id: id,
          name: name ?? this.name,
          backgroundColorValue: backgroundColor?.value ?? backgroundColorValue,
          textColorValue: textColor?.value ?? textColorValue,
          pinnedPosts: pinnedPosts ?? this.pinnedPosts);

  Future<void> pinPost(int postId, [bool toSave = true]) async {
    if (pinnedPosts.contains(postId)) {
      pinnedPosts
        ..removeWhere((element) => element == postId)
        ..insert(0, postId);
    } else {
      pinnedPosts.insert(0, postId);
    }

    if (toSave) {
      await save();
    }
  }

  Future<void> unpinPost(int postId, [bool toSave = true]) async {
    pinnedPosts.removeWhere((element) => element == postId);

    if (toSave) {
      await save();
    }
  }
}
