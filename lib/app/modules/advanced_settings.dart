import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../data/services/settings.dart';
import '../utils/toast.dart';
import '../widgets/dialog.dart';

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

class _DrawerDragRatioDialog extends StatelessWidget {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  _DrawerDragRatioDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;
    String? ratioString;

    return InputDialog(
      content: Form(
        key: _formKey,
        child: TextFormField(
          decoration: const InputDecoration(labelText: '比例（0.1-0.5）'),
          autofocus: true,
          initialValue: '${settings.drawerEdgeDragWidthRatio}',
          onSaved: (newValue) => ratioString = newValue,
          validator: (value) {
            if (value != null) {
              if (value.isNotEmpty) {
                final ratio = double.tryParse(value);
                if (ratio != null) {
                  if (ratio >= SettingsService.minDrawerEdgeDragWidthRatio &&
                      ratio <= SettingsService.maxDrawerEdgeDragWidthRatio) {
                    return null;
                  } else {
                    return '比例需要在${SettingsService.minDrawerEdgeDragWidthRatio}'
                        '与${SettingsService.maxDrawerEdgeDragWidthRatio}之间';
                  }
                } else {
                  return '请输入比例数字';
                }
              } else {
                return '请输入比例';
              }
            } else {
              return '请输入比例';
            }
          },
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();

              final ratio = double.parse(ratioString!);
              settings.drawerEdgeDragWidthRatio = ratio;

              Get.back();
            }
          },
          child: const Text('确定'),
        )
      ],
    );
  }
}

class _DrawerDragRatio extends StatelessWidget {
  const _DrawerDragRatio({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ValueListenableBuilder<Box>(
      valueListenable: settings.drawerEdgeDragWidthRatioListenable,
      builder: (context, value, child) => ListTile(
        title: const Text('划开侧边栏的范围占屏幕宽度的比例'),
        trailing: Text('${settings.drawerEdgeDragWidthRatio * 100.0}%'),
        onTap: () => Get.dialog(_DrawerDragRatioDialog()),
      ),
    );
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
        subtitle: const Text('字体显示不正常可以尝试开启此项，更改后需要重启应用'),
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
            if (GetPlatform.isAndroid || GetPlatform.isIOS)
              const _DrawerDragRatio(),
            const _FixMissingFont(),
          ],
        ),
      );
}
