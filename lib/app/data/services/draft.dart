import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../utils/backup.dart';
import '../models/draft.dart';
import '../models/hive.dart';

class PostDraftListService extends GetxService {
  static final PostDraftListService to = Get.find<PostDraftListService>();

  late final Box<PostDraftData> _draftBox;

  final RxBool isReady = false.obs;

  late final ValueListenable<Box<PostDraftData>> draftListListenable;

  int get length => _draftBox.length;

  PostDraftData? draft(int index) => _draftBox.getAt(index);

  int? draftKey(int index) => _draftBox.keyAt(index);

  Future<int> addDraft(PostDraftData draft) => _draftBox.add(draft);

  Future<int> clear() => _draftBox.clear();

  @override
  void onInit() async {
    super.onInit();

    _draftBox = await Hive.openBox<PostDraftData>(HiveBoxName.draft);

    draftListListenable = _draftBox.listenable();

    isReady.value = true;
    debugPrint('读取草稿数据成功');
  }

  @override
  void onClose() async {
    await _draftBox.close();
    isReady.value = false;

    super.onClose();
  }
}

class PostDraftListBackupData extends BackupData {
  @override
  String get title => '草稿';

  PostDraftListBackupData();

  @override
  Future<void> backup(String dir) async {
    await PostDraftListService.to._draftBox.close();

    await copyHiveFileToBackupDir(dir, HiveBoxName.draft);
    progress = 1.0;
  }
}

class PostDraftListRestoreData extends RestoreData {
  @override
  String get title => '草稿';

  @override
  String get subTitle => '不会覆盖或合并现有草稿';

  PostDraftListRestoreData();

  @override
  Future<bool> canRestore(String dir) =>
      hiveBackupFileInDir(dir, HiveBoxName.draft).exists();

  @override
  Future<void> restore(String dir) async {
    final file = await copyHiveBackupFile(dir, HiveBoxName.draft);
    final box =
        await Hive.openBox<PostDraftData>(hiveBackupName(HiveBoxName.draft));
    await PostDraftListService.to._draftBox
        .addAll(box.values.map((draft) => draft.copy()));
    await box.close();
    await file.delete();
    await deleteHiveBackupLockFile(HiveBoxName.draft);

    progress = 1.0;
  }
}
