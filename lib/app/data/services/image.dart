import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../utils/directory.dart';
import '../../utils/toast.dart';

class ImageService extends GetxService {
  static ImageService get to => Get.find<ImageService>();

  String? savePath;

  final RxBool isReady = false.obs;

  @override
  void onReady() async {
    super.onReady();

    bool isGranted = true;
    if (GetPlatform.isAndroid || GetPlatform.isIOS) {
      PermissionStatus status = await Permission.storage.status;
      if (status.isDenied) {
        status = await Permission.storage.request();
      }
      if (!status.isGranted) {
        isGranted = false;
        showToast('读取和保存图片需要存储权限');
      }
    }

    if (GetPlatform.isIOS) {
      PermissionStatus status = await Permission.photos.status;
      if (status.isDenied) {
        status = await Permission.photos.request();
      }
      if (!status.isGranted) {
        showToast('读取图库图片需要图库权限');
      }
    }

    if (isGranted) {
      try {
        savePath = await picturesPath();
      } catch (e) {
        showToast('获取图片保存文件夹失败：$e');
      }
    }

    isReady.value = true;

    debugPrint('更新图片服务成功');
  }

  @override
  void onClose() {
    isReady.value = false;

    super.onClose();
  }
}
