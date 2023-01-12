import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';

import '../data/services/image.dart';
import '../data/services/settings.dart';
import '../utils/toast.dart';
import '../widgets/dialog.dart';
import '../widgets/listenable.dart';
import '../widgets/safe_area.dart';

class _SaveImagePath extends StatelessWidget {
  final Future<AndroidDeviceInfo>? _androidInfo =
      GetPlatform.isAndroid ? DeviceInfoPlugin().androidInfo : null;

  // ignore: unused_element
  _SaveImagePath({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    final Widget widget = ListenableBuilder(
      listenable: settings.saveImagePathListenable,
      builder: (context, child) => ListTile(
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

    return (GetPlatform.isAndroid && _androidInfo != null)
        ? FutureBuilder<AndroidDeviceInfo>(
            future: _androidInfo!,
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

class _CacheImageCount extends StatelessWidget {
  // ignore: unused_element
  const _CacheImageCount({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ListenableBuilder(
      listenable: settings.cacheImageCountListenable,
      builder: (context, child) => ListTile(
        title: const Text('缓存图片存储数量'),
        subtitle: const Text('更改后需要重启应用'),
        trailing: Text('${settings.cacheImageCount}'),
        onTap: () async {
          final n = await Get.dialog<int>(NumRangeDialog<int>(
            text: '缓存',
            initialValue: settings.cacheImageCount,
            min: 0,
          ));

          if (n != null) {
            settings.cacheImageCount = n;
          }
        },
      ),
    );
  }
}

class _AddBlueIslandEmoticons extends StatelessWidget {
  // ignore: unused_element
  const _AddBlueIslandEmoticons({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ListenableBuilder(
      listenable: settings.addBlueIslandEmoticonsListenable,
      builder: (context, child) => SwitchListTile(
        title: const Text('添加蓝岛颜文字'),
        value: settings.addBlueIslandEmoticons,
        onChanged: (value) => settings.addBlueIslandEmoticons = value,
      ),
    );
  }
}

class _ShowPoCookieTag extends StatelessWidget {
  // ignore: unused_element
  const _ShowPoCookieTag({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ListenableBuilder(
      listenable: settings.showPoCookieTagListenable,
      builder: (context, child) => SwitchListTile(
        title: const Text('串内Po饼干左边显示Po标签'),
        value: settings.showPoCookieTag,
        onChanged: (value) => settings.showPoCookieTag = value,
      ),
    );
  }
}

class _PoCookieColor extends StatelessWidget {
  // ignore: unused_element
  const _PoCookieColor({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ListenableBuilder(
      listenable: settings.poCookieColorListenable,
      builder: (context, child) => ListTile(
        title: const Text('Po饼干颜色'),
        trailing: ColorIndicator(
          HSVColor.fromColor(settings.poCookieColor),
          key: ValueKey<Color>(settings.poCookieColor),
          width: 25.0,
          height: 25.0,
        ),
        onTap: () {
          Color? color;
          Get.dialog(ConfirmCancelDialog(
            contentWidget: MaterialPicker(
              pickerColor: settings.poCookieColor,
              onColorChanged: (value) => color = value,
              enableLabel: true,
            ),
            onConfirm: () {
              if (color != null) {
                settings.poCookieColor = color!;
              }

              Get.back();
            },
            onCancel: Get.back,
          ));
        },
      ),
    );
  }
}

class _ShowUserCookieNote extends StatelessWidget {
  // ignore: unused_element
  const _ShowUserCookieNote({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ListenableBuilder(
      listenable: settings.showUserCookieNoteListenable,
      builder: (context, child) => SwitchListTile(
        title: const Text('串饼干下方显示用户饼干的备注'),
        value: settings.showUserCookieNote,
        onChanged: (value) => settings.showUserCookieNote = value,
      ),
    );
  }
}

class _ShowUserCookieColor extends StatelessWidget {
  // ignore: unused_element
  const _ShowUserCookieColor({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ListenableBuilder(
      listenable: settings.showUserCookieColorListenable,
      builder: (context, child) => SwitchListTile(
        title: const Text('串饼干使用用户饼干的自定义颜色显示'),
        value: settings.showUserCookieColor,
        onChanged: (value) => settings.showUserCookieColor = value,
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

    return ListenableBuilder(
      listenable: settings.restoreForumPageListenable,
      builder: (context, child) => SwitchListTile(
        title: const Text('恢复标签页时恢复时间线/版块的页数'),
        value: settings.restoreForumPage,
        onChanged: (value) => settings.restoreForumPage = value,
      ),
    );
  }
}

class _ImageDisposeDistance extends StatelessWidget {
  // ignore: unused_element
  const _ImageDisposeDistance({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ListenableBuilder(
      listenable: settings.imageDisposeDistanceListenable,
      builder: (context, child) => ListTile(
        title: const Text('非适应模式下移动未放大的图片导致返回的最小距离'),
        trailing: Text('${settings.imageDisposeDistance}'),
        onTap: () async {
          final n = await Get.dialog<int>(NumRangeDialog<int>(
            text: '距离',
            initialValue: settings.imageDisposeDistance,
            min: 0,
          ));

          if (n != null) {
            settings.imageDisposeDistance = n;
          }
        },
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

    return ListenableBuilder(
      listenable: settings.fixedImageDisposeRatioListenable,
      builder: (context, child) => ListTile(
        title: const Text('适应模式下移动未缩放的大图导致返回的最小距离占屏幕高度/宽度的比例'),
        trailing: Text('${settings.fixedImageDisposeRatio}'),
        onTap: () async {
          final ratio = await Get.dialog<double>(NumRangeDialog<double>(
              text: '比例',
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

    return ListenableBuilder(
      listenable: settings.fixMissingFontListenable,
      builder: (context, child) => SwitchListTile(
        title: const Text('修复字体显示'),
        subtitle: const Text('字体显示不正常可以尝试开启此项，更改后需要重启应用'),
        value: settings.fixMissingFont,
        onChanged: (value) => settings.fixMissingFont = value,
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

    return ListenableBuilder(
      listenable: settings.showGuideListenable,
      builder: (context, child) => SwitchListTile(
        title: const Text('下一次启动应用时显示用户指导'),
        subtitle: const Text('更改后需要重启应用'),
        value: settings.backdropUI
            ? settings.rawShowBackdropGuide
            : settings.rawShowGuide,
        onChanged: (value) {
          if (settings.backdropUI) {
            settings.showBackdropGuide = value;
          } else {
            settings.showGuide = value;
          }
        },
      ),
    );
  }
}

class AdvancedSettingsView extends StatelessWidget {
  const AdvancedSettingsView({super.key});

  @override
  Widget build(BuildContext context) => ColoredSafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('高级设置'),
          ),
          body: ListView(
            children: [
              if (!GetPlatform.isIOS && ImageService.to.hasStoragePermission)
                _SaveImagePath(),
              const _CacheImageCount(),
              const _AddBlueIslandEmoticons(),
              const _ShowPoCookieTag(),
              const _PoCookieColor(),
              const _ShowUserCookieNote(),
              const _ShowUserCookieColor(),
              const _RestoreForumPage(),
              const _ImageDisposeDistance(),
              const _FixedImageDisposeRatio(),
              const _FixMissingFont(),
              const _ShowGuide(),
              const Divider(height: 10.0, thickness: 1.0),
            ],
          ),
        ),
      );
}
