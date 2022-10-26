import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../utils/directory.dart';
import '../../utils/toast.dart';

class ImageService extends GetxService {
  static ImageService get to => Get.find<ImageService>();

  String? savePath;

  bool hasStoragePermission = false;

  bool hasPhotoLibraryPermission = false;

  final RxBool isReady = false.obs;

  @override
  void onReady() async {
    super.onReady();

    if (GetPlatform.isAndroid || GetPlatform.isIOS) {
      PermissionStatus status = await Permission.storage.status;
      if (status.isDenied) {
        status = await Permission.storage.request();
      }
      if (status.isGranted) {
        hasStoragePermission = true;
      } else {
        showToast('读写图片需要存储权限');
      }
    } else {
      hasStoragePermission = true;
    }

    if (GetPlatform.isIOS) {
      PermissionStatus status = await Permission.photos.status;
      if (status.isDenied) {
        status = await Permission.photos.request();
      }
      if (status.isGranted) {
        hasPhotoLibraryPermission = true;
      } else {
        showToast('读写图库图片需要图库权限');
      }
    } else {
      hasPhotoLibraryPermission = true;
    }

    if (hasStoragePermission) {
      try {
        savePath = await getPicturesPath();
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
