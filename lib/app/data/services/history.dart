import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:isar/isar.dart';

import '../../utils/directory.dart';
import '../models/history.dart';

class PostHistoryService extends GetxService {
  static PostHistoryService get to => Get.find<PostHistoryService>();

  static const String _databaseName = 'history';

  late final Isar _isar;

  final RxBool isReady = false.obs;

  IsarCollection<BrowseHistory> get _browseHistorys => _isar.browseHistorys;

  Future<void> saveBrowseHistory(BrowseHistory history) =>
      _isar.writeTxn(() => _browseHistorys.put(history));

  Future<BrowseHistory?> getBrowseHistory(int postId) =>
      _browseHistorys.get(postId);

  @override
  void onInit() async {
    super.onInit();

    _isar = await Isar.open([BrowseHistorySchema],
        directory: databasePath, name: _databaseName, inspector: false);

    isReady.value = true;
    debugPrint('读取历史数据成功');
  }

  @override
  void onClose() async {
    await _isar.close();
    isReady.value = false;

    super.onClose();
  }
}
