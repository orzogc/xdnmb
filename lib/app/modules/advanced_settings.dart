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

    final Widget widget = ValueListenableBuilder<Box>(
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

class _AddBlueIslandEmoticons extends StatelessWidget {
  const _AddBlueIslandEmoticons({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ValueListenableBuilder<Box>(
      valueListenable: settings.addBlueIslandEmoticonsListenable,
      builder: (context, value, child) => ListTile(
        title: const Text('添加蓝岛颜文字'),
        trailing: Switch(
          value: settings.addBlueIslandEmoticons,
          onChanged: (value) => settings.addBlueIslandEmoticons = value,
        ),
      ),
    );
  }
}

class _RestoreForumPage extends StatelessWidget {
  const _RestoreForumPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ValueListenableBuilder<Box>(
      valueListenable: settings.restoreForumPageListenable,
      builder: (context, value, child) => ListTile(
        title: const Text('恢复标签页时恢复时间线/版块的页数'),
        trailing: Switch(
          value: settings.restoreForumPage,
          onChanged: (value) => settings.restoreForumPage = value,
        ),
      ),
    );
  }
}

class _DrawerDragRatioDialog extends StatelessWidget {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  _DrawerDragRatioDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;
    String? ratio;

    return InputDialog(
      content: Form(
        key: _formKey,
        child: TextFormField(
          decoration: const InputDecoration(labelText: '比例（0.1-0.5）'),
          autofocus: true,
          initialValue: '${settings.drawerEdgeDragWidthRatio}',
          onSaved: (newValue) => ratio = newValue,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final ratio = double.tryParse(value);
              if (ratio != null) {
                if (ratio >= SettingsService.minDrawerEdgeDragWidthRatio &&
                    ratio <= SettingsService.maxDrawerEdgeDragWidthRatio) {
                  return null;
                } else {
                  return '比例必须在${SettingsService.minDrawerEdgeDragWidthRatio}'
                      '与${SettingsService.maxDrawerEdgeDragWidthRatio}之间';
                }
              } else {
                return '请输入比例数字';
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

              settings.drawerEdgeDragWidthRatio = double.parse(ratio!);

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
        trailing: Text('${settings.drawerEdgeDragWidthRatio}'),
        onTap: () => Get.dialog(_DrawerDragRatioDialog()),
      ),
    );
  }
}

class _ImageDisposeDistanceDialog extends StatelessWidget {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  _ImageDisposeDistanceDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;
    String? distance;

    return InputDialog(
      content: Form(
        key: _formKey,
        child: TextFormField(
          decoration: const InputDecoration(labelText: '距离'),
          autofocus: true,
          initialValue: '${settings.imageDisposeDistance}',
          onSaved: (newValue) => distance = newValue,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final distance = int.tryParse(value);
              if (distance != null) {
                if (distance >= 0) {
                  return null;
                } else {
                  return '距离必须大于等于0';
                }
              } else {
                return '请输入距离数字（整数）';
              }
            } else {
              return '请输入距离';
            }
          },
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();

              settings.imageDisposeDistance = int.parse(distance!);

              Get.back();
            }
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}

class _ImageDisposeDistance extends StatelessWidget {
  const _ImageDisposeDistance({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ValueListenableBuilder<Box>(
      valueListenable: settings.imageDisposeDistanceListenable,
      builder: (context, value, child) => ListTile(
        title: const Text('非适应模式下移动未放大的图片导致返回的最小距离'),
        trailing: Text('${settings.imageDisposeDistance}'),
        onTap: () => Get.dialog(_ImageDisposeDistanceDialog()),
      ),
    );
  }
}

class _FixedImageDisposeRatioDialog extends StatelessWidget {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  _FixedImageDisposeRatioDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;
    String? ratio;

    return InputDialog(
      content: Form(
        key: _formKey,
        child: TextFormField(
          decoration: const InputDecoration(labelText: '比例（0.0-1.0）'),
          autofocus: true,
          initialValue: '${settings.fixedImageDisposeRatio}',
          onSaved: (newValue) => ratio = newValue,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final ratio = double.tryParse(value);
              if (ratio != null) {
                if (ratio >= 0.0 && ratio <= 1.0) {
                  return null;
                } else {
                  return '比例必须在0与1之间';
                }
              } else {
                return '请输入比例数字';
              }
            } else {
              return '请输入比例';
            }
          },
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();

              settings.fixedImageDisposeRatio = double.parse(ratio!);

              Get.back();
            }
          },
          child: const Text('确定'),
        )
      ],
    );
  }
}

class _FixedImageDisposeRatio extends StatelessWidget {
  const _FixedImageDisposeRatio({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ValueListenableBuilder(
      valueListenable: settings.fixedImageDisposeRatioListenable,
      builder: (context, value, child) => ListTile(
        title: const Text('适应模式下移动未缩放的大图导致返回的最小距离占屏幕高度/宽度的比例'),
        trailing: Text('${settings.fixedImageDisposeRatio}'),
        onTap: () => Get.dialog(_FixedImageDisposeRatioDialog()),
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
            const _AddBlueIslandEmoticons(),
            const _RestoreForumPage(),
            if (GetPlatform.isMobile) const _DrawerDragRatio(),
            const _ImageDisposeDistance(),
            const _FixedImageDisposeRatio(),
            const _FixMissingFont(),
          ],
        ),
      );
}
