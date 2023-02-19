import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

part 'tag.g.dart';

@HiveType(typeId: 11)
class TagData extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2, defaultValue: null)
  final int? backgroundColorValue;

  @HiveField(3, defaultValue: null)
  final int? textColorValue;

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
      this.textColorValue})
      : assert(name.isNotEmpty);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TagData &&
          id == other.id &&
          name == other.name &&
          backgroundColorValue == other.backgroundColorValue &&
          textColorValue == other.textColorValue);

  @override
  int get hashCode =>
      Object.hash(id, name, backgroundColorValue, textColorValue);
}
