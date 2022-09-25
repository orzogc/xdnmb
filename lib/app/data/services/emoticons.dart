import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/emoticon.dart';
import '../models/hive.dart';

class EmoticonsService extends GetxService {
  static EmoticonsService get to => Get.find<EmoticonsService>();

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
