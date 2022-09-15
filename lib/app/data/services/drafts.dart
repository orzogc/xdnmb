import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/draft.dart';
import '../models/hive.dart';

class PostDraftsService extends GetxService {
  static PostDraftsService get to => Get.find<PostDraftsService>();

  late final Box<PostDraftData> _draftBox;

  final RxBool isReady = false.obs;

  int get length => _draftBox.length;

  Iterable<PostDraftData> get drafts => _draftBox.values;

  late final ValueListenable<Box<PostDraftData>> draftListenable;

  Future<void> addDraft(PostDraftData draft) => _draftBox.add(draft);

  @override
  void onInit() async {
    super.onInit();

    _draftBox = await Hive.openBox<PostDraftData>(HiveBoxName.draft);

    draftListenable = _draftBox.listenable();

    isReady.value = true;
    debugPrint('读取草稿列表成功');
  }

  @override
  void onClose() async {
    await _draftBox.close();
    isReady.value = false;

    super.onClose();
  }
}
