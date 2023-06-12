import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../utils/directory.dart';
import '../../utils/toast.dart';
import 'settings.dart';

class ImageService extends GetxService {
  static final ImageService to = Get.find<ImageService>();

  /// 保存图片的文件夹，iOS下为图片临时保存文件夹
  static String? savePath;

  bool hasStoragePermission = false;

  bool hasPhotoLibraryPermission = false;

  final RxBool isReady = false.obs;

  Future<void> _getPermission() async {
    // Android SDK版本大于等于33不需要存储权限，但是需要图库权限
    if (GetPlatform.isAndroid &&
        (await DeviceInfoPlugin().androidInfo).version.sdkInt < 33) {
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

    if ((GetPlatform.isAndroid &&
            (await DeviceInfoPlugin().androidInfo).version.sdkInt >= 33) ||
        GetPlatform.isIOS) {
      PermissionStatus status = await Permission.photos.status;
      if (status.isDenied) {
        status = await Permission.photos.request();
      }
      if (status.isGranted) {
        hasPhotoLibraryPermission = true;
      } else {
        if (GetPlatform.isIOS) {
          showToast('读写图库图片需要图库权限');
        } else if (GetPlatform.isAndroid) {
          showToast('读取图片需要相应权限');
        }
      }
    } else {
      hasPhotoLibraryPermission = true;
    }
  }

  @override
  void onReady() async {
    super.onReady();

    await _getPermission();

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
