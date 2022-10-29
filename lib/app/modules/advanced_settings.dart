import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../data/services/settings.dart';
import '../utils/toast.dart';

class _SaveImagePath extends StatelessWidget {
  const _SaveImagePath({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    final Widget widget = ValueListenableBuilder(
      valueListenable: settings.saveImagePathListenable,
      builder: (context, value, child) => ListTile(
        title: const Text('图片保存位置'),
        subtitle: settings.saveImagePath != null
            ? Text(settings.saveImagePath!)
            : null,
        onTap: () async {
          try {
            final path = await FilePicker.platform.getDirectoryPath(
              dialogTitle: 'X岛',
              initialDirectory: settings.saveImagePath,
            );
            if (path != null) {
              if (GetPlatform.isAndroid && path == '/') {
                showToast('获取图片保存文件夹失败');
              } else {
                settings.saveImagePath = path;
              }
            } else {
              debugPrint('用户放弃或者获取图片保存文件夹失败');
            }
          } catch (e) {
            showToast('获取图片保存文件夹失败：$e');
          }
        },
      ),
    );

    return GetPlatform.isAndroid
        ? FutureBuilder<AndroidDeviceInfo>(
            future: DeviceInfoPlugin().androidInfo,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasError) {
                showToast('获取Android设备信息失败：${snapshot.error}');
              }

              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData) {
                if (snapshot.data!.version.sdkInt >= 21) {
                  return widget;
                }
              }

              return const SizedBox.shrink();
            },
          )
        : widget;
  }
}

class _FixMissingFont extends StatelessWidget {
  const _FixMissingFont({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ValueListenableBuilder<Box>(
      valueListenable: settings.fixMissingFontListenable,
      builder: (context, value, child) => ListTile(
        title: const Text('修复字体显示'),
        subtitle: const Text('字体显示不正常可以尝试开启此项，需要重启应用'),
        trailing: Switch(
          value: settings.fixMissingFont,
          onChanged: (value) => settings.fixMissingFont = value,
        ),
      ),
    );
  }
}

class AdvancedSettingsController extends GetxController {}

class AdvancedSettingsBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(AdvancedSettingsBinding());
  }
}

class AdvancedSettingsView extends GetView<AdvancedSettingsController> {
  const AdvancedSettingsView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('高级设置'),
        ),
        body: ListView(
          children: [
            if (!GetPlatform.isIOS) const _SaveImagePath(),
            const _FixMissingFont(),
          ],
        ),
      );
}
