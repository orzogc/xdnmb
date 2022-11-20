import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../data/services/settings.dart';
import '../utils/notify.dart';
import '../utils/theme.dart';
import '../utils/toast.dart';
import '../widgets/dialog.dart';

class _SaveImagePath extends StatelessWidget {
  // ignore: unused_element
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
  // ignore: unused_element
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
  // ignore: unused_element
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

class _RatioRangeDialog extends StatelessWidget {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final double initialValue;

  final double min;

  final double max;

  _RatioRangeDialog(
      // ignore: unused_element
      {super.key,
      required this.initialValue,
      required this.min,
      required this.max});

  @override
  Widget build(BuildContext context) {
    String? ratio;

    return InputDialog(
      content: Form(
        key: _formKey,
        child: TextFormField(
          decoration: InputDecoration(labelText: '比例（$min-$max）'),
          autofocus: true,
          initialValue: '$initialValue',
          onSaved: (newValue) => ratio = newValue,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final ratio = double.tryParse(value);
              if (ratio != null) {
                if (ratio >= min && ratio <= max) {
                  return null;
                } else {
                  return '比例必须在$min与$max之间';
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

              Get.back<double>(result: double.parse(ratio!));
            }
          },
          child: const Text('确定'),
        )
      ],
    );
  }
}

class _DrawerDragRatio extends StatelessWidget {
  // ignore: unused_element
  const _DrawerDragRatio({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ValueListenableBuilder<Box>(
      valueListenable: settings.drawerEdgeDragWidthRatioListenable,
      builder: (context, value, child) => ListTile(
        title: const Text('划开侧边栏的范围占屏幕宽度的比例'),
        trailing: Text('${settings.drawerEdgeDragWidthRatio}'),
        onTap: () async {
          final ratio = await Get.dialog<double>(_RatioRangeDialog(
              initialValue: settings.drawerEdgeDragWidthRatio,
              min: SettingsService.minDrawerEdgeDragWidthRatio,
              max: SettingsService.maxDrawerEdgeDragWidthRatio));

          if (ratio != null) {
            settings.drawerEdgeDragWidthRatio = ratio;
          }
        },
      ),
    );
  }
}

class _ImageDisposeDistanceDialog extends StatelessWidget {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // ignore: unused_element
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
  // ignore: unused_element
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

class _FixedImageDisposeRatio extends StatelessWidget {
  // ignore: unused_element
  const _FixedImageDisposeRatio({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ValueListenableBuilder<Box>(
      valueListenable: settings.fixedImageDisposeRatioListenable,
      builder: (context, value, child) => ListTile(
        title: const Text('适应模式下移动未缩放的大图导致返回的最小距离占屏幕高度/宽度的比例'),
        trailing: Text('${settings.fixedImageDisposeRatio}'),
        onTap: () async {
          final ratio = await Get.dialog<double>(_RatioRangeDialog(
              initialValue: settings.fixedImageDisposeRatio,
              min: 0.0,
              max: 1.0));

          if (ratio != null) {
            settings.fixedImageDisposeRatio = ratio;
          }
        },
      ),
    );
  }
}

class _FixMissingFont extends StatelessWidget {
  // ignore: unused_element
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

class _ShowGuide extends StatelessWidget {
  // ignore: unused_element
  const _ShowGuide({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ValueListenableBuilder<Box>(
      valueListenable: settings.showGuideListenable,
      builder: (context, value, child) => ListTile(
        title: const Text('显示用户指导'),
        subtitle: const Text('更改后需要重启应用'),
        trailing: Switch(
          value: settings.backdropUI
              ? settings.showBackdropGuide
              : settings.showGuide,
          onChanged: (value) {
            if (settings.backdropUI) {
              settings.showBackdropGuide = value;
            } else {
              settings.showGuide = value;
            }
          },
        ),
      ),
    );
  }
}

class _BackdropUI extends StatelessWidget {
  // ignore: unused_element
  const _BackdropUI({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ValueListenableBuilder<Box>(
      valueListenable: settings.backdropUIListenable,
      builder: (context, value, child) => ListTile(
        title: const Text('启用Backdrop UI'),
        subtitle: const Text('更改后需要重启应用'),
        trailing: Switch(
          value: settings.backdropUI,
          onChanged: (value) => settings.backdropUI = value,
        ),
      ),
    );
  }
}

class _CompactBackdrop extends StatelessWidget {
  // ignore: unused_element
  const _CompactBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return NotifyBuilder(
      animation: Listenable.merge(
          [settings.backdropUIListenable, settings.compactBackdropListenable]),
      builder: (context, child) => ListTile(
        title: Text(
          '同时显示标签页列表和版块列表',
          style: TextStyle(
            color: !settings.backdropUI ? AppTheme.inactiveSettingColor : null,
          ),
        ),
        trailing: Switch(
          value: settings.compactBackdrop,
          onChanged: settings.backdropUI
              ? (value) => settings.compactBackdrop = value
              : null,
        ),
      ),
    );
  }
}

class _PageDragWidthRatio extends StatelessWidget {
  // ignore: unused_element
  const _PageDragWidthRatio({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ValueListenableBuilder<Box>(
      valueListenable: settings.swipeablePageDragWidthRatioListenable,
      builder: (context, value, child) {
        final textStyle = TextStyle(
            color: !settings.backdropUI ? AppTheme.inactiveSettingColor : null);

        return ListTile(
          title: Text('返回上一页的手势范围占屏幕宽度的比例', style: textStyle),
          subtitle: Text('更改后需要重启应用', style: textStyle),
          trailing:
              Text('${settings.swipeablePageDragWidthRatio}', style: textStyle),
          onTap: settings.backdropUI
              ? () async {
                  final ratio = await Get.dialog<double>(_RatioRangeDialog(
                      initialValue: settings.swipeablePageDragWidthRatio,
                      min: 0.0,
                      max: 1.0));

                  if (ratio != null) {
                    settings.swipeablePageDragWidthRatio = ratio;
                  }
                }
              : null,
        );
      },
    );
  }
}

class _FrontLayerDragHeightRatio extends StatelessWidget {
  // ignore: unused_element
  const _FrontLayerDragHeightRatio({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return NotifyBuilder(
      animation: Listenable.merge([
        settings.backdropUIListenable,
        settings.frontLayerDragHeightRatioListenable
      ]),
      builder: (context, child) {
        final textStyle = TextStyle(
            color: !settings.backdropUI ? AppTheme.inactiveSettingColor : null);

        return ListTile(
          title: Text('下拉手势范围占屏幕高度的比例', style: textStyle),
          trailing:
              Text('${settings.frontLayerDragHeightRatio}', style: textStyle),
          onTap: settings.backdropUI
              ? () async {
                  final ratio = await Get.dialog<double>(_RatioRangeDialog(
                      initialValue: settings.frontLayerDragHeightRatio,
                      min: 0.0,
                      max: 1.0));

                  if (ratio != null) {
                    settings.frontLayerDragHeightRatio = ratio;
                  }
                }
              : null,
        );
      },
    );
  }
}

class _BackLayerDragHeightRatio extends StatelessWidget {
  // ignore: unused_element
  const _BackLayerDragHeightRatio({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return NotifyBuilder(
      animation: Listenable.merge([
        settings.backdropUIListenable,
        settings.backLayerDragHeightRatioListenable
      ]),
      builder: (context, child) {
        final textStyle = TextStyle(
            color: !settings.backdropUI ? AppTheme.inactiveSettingColor : null);

        return ListTile(
          title: Text('上拉手势范围占屏幕高度的比例', style: textStyle),
          trailing:
              Text('${settings.backLayerDragHeightRatio}', style: textStyle),
          onTap: settings.backdropUI
              ? () async {
                  final ratio = await Get.dialog<double>(_RatioRangeDialog(
                      initialValue: settings.backLayerDragHeightRatio,
                      min: 0.0,
                      max: 1.0));

                  if (ratio != null) {
                    settings.backLayerDragHeightRatio = ratio;
                  }
                }
              : null,
        );
      },
    );
  }
}

class AdvancedSettingsController extends GetxController {}

class AdvancedSettingsBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(AdvancedSettingsController());
  }
}

class AdvancedSettingsView extends GetView<AdvancedSettingsController> {
  const AdvancedSettingsView({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
        left: false,
        top: false,
        right: false,
        child: Scaffold(
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
              const _ShowGuide(),
              const Divider(height: 10.0, thickness: 1.0),
              ListTile(
                title: Text(
                  'Backdrop UI',
                  style: Theme.of(context).textTheme.headline6,
                ),
              ),
              if (!GetPlatform.isIOS) const _BackdropUI(),
              const _CompactBackdrop(),
              const _PageDragWidthRatio(),
              const _FrontLayerDragHeightRatio(),
              const _BackLayerDragHeightRatio(),
            ],
          ),
        ),
      );
}
