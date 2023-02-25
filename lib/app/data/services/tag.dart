import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:isar/isar.dart';

import '../models/hive.dart';
import '../models/tag.dart';

class TagService extends GetxService {
  static final TagService to = Get.find<TagService>();

  late final Box<TagData> _tagsBox;

  late int _nextTagId;

  late final HashMap<String, int> _tagsMap;

  final RxBool isReady = false.obs;

  bool hasTag(String tagName) => _tagsMap.containsKey(tagName);

  /// 返回标签ID
  Future<int> addNewTag(
      {required String tagName, int? backgroundColor, int? textColor}) async {
    assert(!hasTag(tagName));

    final id = _nextTagId;
    await _tagsBox.put(
        id,
        TagData(
            id: id,
            name: tagName,
            backgroundColorValue: backgroundColor,
            textColorValue: textColor));
    _tagsMap[tagName] = id;
    _nextTagId++;

    return id;
  }

  Future<void> editTag(
      {required int tagId,
      required String tagName,
      int? backgroundColor,
      int? textColor}) async {
    assert(_tagsBox.containsKey(tagId));

    await _tagsBox.put(
        tagId,
        TagData(
            id: tagId,
            name: tagName,
            backgroundColorValue: backgroundColor,
            textColorValue: textColor));
  }

  @override
  void onInit() async {
    super.onInit();

    _tagsBox = await Hive.openBox<TagData>(HiveBoxName.tags);
    _nextTagId = _tagsBox.isNotEmpty
        ? _tagsBox.keys.reduce((value, element) => max<int>(value, element)) + 1
        : 0;
    _tagsMap = HashMap.fromEntries(
        _tagsBox.values.map((tag) => MapEntry(tag.name, tag.id)));

    isReady.value = true;
    debugPrint('读取标签数据成功');
  }

  @override
  void onClose() {
    isReady.value = false;

    super.onClose();
  }
}
