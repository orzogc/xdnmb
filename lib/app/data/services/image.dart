import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../utils/directory.dart';
import '../../utils/toast.dart';
import 'settings.dart';

class ImageService extends GetxService {
  static ImageService get to => Get.find<ImageService>();

  static String? savePath;

  bool hasStoragePermission = false;

  bool hasPhotoLibraryPermission = false;

  final RxBool isReady = false.obs;

  @override
  void onReady() async {
    super.onReady();

    if (GetPlatform.isMobile) {
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
        await getDefaultSaveImagePath();
      } catch (e) {
        showToast('获取默认图片保存文件夹失败：$e');
      }
    }

    final settings = SettingsService.to;
    while (!settings.isReady.value) {
      debugPrint('正在等待读取设置数据');
      await Future.delayed(const Duration(milliseconds: 100));
    }
    settings.updateSaveImagePath();

    isReady.value = true;
    debugPrint('更新图片服务成功');
  }

  @override
  void onClose() {
    isReady.value = false;

    super.onClose();
  }
}
