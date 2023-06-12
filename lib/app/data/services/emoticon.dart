import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../utils/backup.dart';
import '../models/emoticon.dart';
import '../models/hive.dart';

class EmoticonListService extends GetxService {
  static final EmoticonListService to = Get.find<EmoticonListService>();

  late final Box<EmoticonData> _emoticonBox;

  final RxBool isReady = false.obs;

  late final ValueListenable<Box<EmoticonData>> emoticonsListenable;

  Iterable<EmoticonData> get emoticons => _emoticonBox.values;

  Future<int> addEmoticon(EmoticonData emoticon) => _emoticonBox.add(emoticon);

  @override
  void onInit() async {
    super.onInit();

    _emoticonBox = await Hive.openBox<EmoticonData>(HiveBoxName.emoticon);

    emoticonsListenable = _emoticonBox.listenable();

    isReady.value = true;
    debugPrint('读取颜文字数据成功');
  }

  @override
  void onClose() async {
    await _emoticonBox.close();
    isReady.value = false;

    super.onClose();
  }
}

class EmoticonListBackupData extends BackupData {
  @override
  String get title => '自定义颜文字';

  EmoticonListBackupData();

  @override
  Future<void> backup(String dir) async {
    await EmoticonListService.to._emoticonBox.close();

    await copyHiveFileToBackupDir(dir, HiveBoxName.emoticon);
    progress = 1.0;
  }
}

class EmoticonListRestoreData extends RestoreData {
  @override
  String get title => '自定义颜文字';

  EmoticonListRestoreData();

  @override
  Future<bool> canRestore(String dir) =>
      hiveBackupFileInDir(dir, HiveBoxName.emoticon).exists();

  @override
  Future<void> restore(String dir) async {
    final emoticon = EmoticonListService.to;

    final file = await copyHiveBackupFile(dir, HiveBoxName.emoticon);
    final box =
        await Hive.openBox<EmoticonData>(hiveBackupName(HiveBoxName.emoticon));
    final set = HashSet.of(emoticon._emoticonBox.values);
    await emoticon._emoticonBox
        .addAll(box.values.where((e) => !set.contains(e)).map((e) => e.copy()));
    await box.close();
    await file.delete();
    await deleteHiveBackupLockFile(HiveBoxName.emoticon);

    progress = 1.0;
  }
}
