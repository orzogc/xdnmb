import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/draft.dart';
import '../models/hive.dart';

class PostDraftListService extends GetxService {
  static PostDraftListService get to => Get.find<PostDraftListService>();

  late final Box<PostDraftData> _draftBox;

  final RxBool isReady = false.obs;

  int get length => _draftBox.length;

  PostDraftData? draft(int index) => _draftBox.getAt(index);

  int? draftKey(int index) => _draftBox.keyAt(index);

  Future<int> addDraft(PostDraftData draft) => _draftBox.add(draft);

  @override
  void onInit() async {
    super.onInit();

    _draftBox = await Hive.openBox<PostDraftData>(HiveBoxName.draft);

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
