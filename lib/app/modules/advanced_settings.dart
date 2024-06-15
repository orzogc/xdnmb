import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/services/image.dart';
import '../data/services/settings.dart';
import '../routes/routes.dart';
import '../utils/image.dart';
import '../utils/toast.dart';
import '../widgets/dialog.dart';
import '../widgets/listenable.dart';

class _SaveImagePath extends StatelessWidget {
  // ignore: unused_element
  const _SaveImagePath({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ListenBuilder(
      listenable: settings.saveImagePathListenable,
      builder: (context, child) => ListTile(
        title: const Text('图片保存位置'),
        subtitle: settings.saveImagePath != null
            ? Text(settings.saveImagePath!)
            : null,
        onTap: () async {
          try {
            final path = await FilePicker.platform.getDirectoryPath(
              // autocorrect: false
              dialogTitle: 'X岛',
              // autocorrect: true
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
  }
}

class _CacheImageCount extends StatelessWidget {
  // ignore: unused_element
  const _CacheImageCount({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ListenBuilder(
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

class _ClearImageCache extends StatelessWidget {
  // ignore: unused_element
  const _ClearImageCache({super.key});

  @override
  Widget build(BuildContext context) => ListTile(
        title: const Text('清除图片缓存'),
        onTap: () async {
          await XdnmbImageCacheManager().emptyCache();
          showToast('清除图片缓存成功');
        },
      );
}

class _FollowPlatformBrightness extends StatelessWidget {
  // ignore: unused_element
  const _FollowPlatformBrightness({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ListenBuilder(
      listenable: settings.followPlatformBrightnessListenable,
      builder: (context, child) => SwitchListTile(
        title: const Text('白天/黑夜模式跟随系统设置'),
        subtitle: const Text('更改后需要重启应用'),
        value: settings.followPlatformBrightness,
        onChanged: (value) => settings.followPlatformBrightness = value,
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

    return ListenBuilder(
      listenable: settings.addBlueIslandEmoticonsListenable,
      builder: (context, child) => SwitchListTile(
        title: const Text('添加蓝岛颜文字'),
        value: settings.addBlueIslandEmoticons,
        onChanged: (value) => settings.addBlueIslandEmoticons = value,
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

    return ListenBuilder(
      listenable: settings.restoreForumPageListenable,
      builder: (context, child) => SwitchListTile(
        title: const Text('恢复标签页时恢复时间线和版块的页数'),
        value: settings.restoreForumPage,
        onChanged: (value) => settings.restoreForumPage = value,
      ),
    );
  }
}

class _AddDeleteFeedInThread extends StatelessWidget {
  // ignore: unused_element
  const _AddDeleteFeedInThread({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ListenBuilder(
      listenable: settings.addDeleteFeedInThreadListenable,
      builder: (context, child) => SwitchListTile(
        title: const Text('串页面右上角菜单增加取消订阅选项'),
        value: settings.addDeleteFeedInThread,
        onChanged: (value) => settings.addDeleteFeedInThread = value,
      ),
    );
  }
}

class _LongPressButtonToOpenNewTab extends StatelessWidget {
  // ignore: unused_element
  const _LongPressButtonToOpenNewTab({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ListenBuilder(
      listenable: settings.longPressButtonToOpenNewTabListenable,
      builder: (context, child) => SwitchListTile(
        title: const Text('长按历史或订阅/标签按钮会在新标签页打开对应页面'),
        value: settings.longPressButtonToOpenNewTab,
        onChanged: (value) => settings.longPressButtonToOpenNewTab = value,
      ),
    );
  }
}

class _MaxPagesEachTab extends StatelessWidget {
  // ignore: unused_element
  const _MaxPagesEachTab({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ListenBuilder(
      listenable: settings.maxPagesEachTabListenable,
      builder: (context, child) => ListTile(
        title: const Text('每个标签页同时保持状态的最多页数'),
        // autocorrect: false
        subtitle: const Text('设置为较小的数值可以改善性能和减少内存占用，0为无限制'),
        // autocorrect: true
        trailing: Text('${settings.maxPagesEachTab}'),
        onTap: () async {
          final n = await Get.dialog<int>(NumRangeDialog<int>(
              text: '页数', initialValue: settings.maxPagesEachTab, min: 0));

          if (n != null) {
            settings.maxPagesEachTab = n;
          }
        },
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

    return ListenBuilder(
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

    return ListenBuilder(
      listenable: settings.fixedImageDisposeRatioListenable,
      builder: (context, child) => ListTile(
        title: const Text('适应模式下移动未缩放的大图导致返回的最小距离占屏幕高度或宽度的比例'),
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

    return ListenBuilder(
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

    return ListenBuilder(
      listenable: settings.showGuideListenable,
      builder: (context, child) => SwitchListTile(
        title: const Text('下一次启动应用时显示用户指导'),
        subtitle: const Text('更改后需要重启应用'),
        value: settings.rawShowGuide,
        onChanged: (value) => settings.showGuide = value,
      ),
    );
  }
}

class AdvancedSettingsView extends StatelessWidget {
  const AdvancedSettingsView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('高级设置'),
        ),
        body: ListView(
          children: [
            const ListTile(
                title: Text('网络设置'), onTap: AppRoutes.toNetworkSettings),
            if (!(GetPlatform.isIOS || GetPlatform.isMacOS) &&
                ImageService.to.hasStoragePermission)
              const _SaveImagePath(),
            const _CacheImageCount(),
            const _ClearImageCache(),
            if (GetPlatform.isMobile || GetPlatform.isMacOS)
              const _FollowPlatformBrightness(),
            const _AddBlueIslandEmoticons(),
            const _RestoreForumPage(),
            const _AddDeleteFeedInThread(),
            const _LongPressButtonToOpenNewTab(),
            const _MaxPagesEachTab(),
            const _ImageDisposeDistance(),
            const _FixedImageDisposeRatio(),
            const _FixMissingFont(),
            const _ShowGuide(),
          ],
        ),
      );
}
