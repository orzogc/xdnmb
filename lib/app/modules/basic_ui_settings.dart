import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../data/services/settings.dart';
import '../utils/notify.dart';
import '../utils/theme.dart';
import '../widgets/dialog.dart';
import '../widgets/safe_area.dart';

class _ShowBottomBar extends StatelessWidget {
  // ignore: unused_element
  const _ShowBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ValueListenableBuilder<Box>(
      valueListenable: settings.showBottomBarListenable,
      builder: (context, value, child) => SwitchListTile(
        title: const Text('显示底边栏'),
        subtitle: const Text('更改后需要重启应用'),
        value: settings.showBottomBar,
        onChanged: (value) => settings.showBottomBar = value,
      ),
    );
  }
}

class _AutoHideBottomBar extends StatelessWidget {
  // ignore: unused_element
  const _AutoHideBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return NotifyBuilder(
      animation: Listenable.merge([
        settings.showBottomBarListenable,
        settings.autoHideBottomBarListenable,
      ]),
      builder: (context, child) => SwitchListTile(
        title: Text(
          '向下滑动时自动隐藏底边栏',
          style: TextStyle(
            color:
                !settings.showBottomBar ? AppTheme.inactiveSettingColor : null,
          ),
        ),
        value: settings.autoHideBottomBar,
        onChanged: settings.showBottomBar
            ? (value) => settings.autoHideBottomBar = value
            : null,
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
      builder: (context, value, child) => SwitchListTile(
        title: const Text('启用幕布界面'),
        subtitle: const Text('更改后需要重启应用'),
        value: settings.backdropUI,
        onChanged: (value) => settings.backdropUI = value,
      ),
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
          title: Text('幕布下拉手势范围占屏幕高度的比例（不含标题栏）', style: textStyle),
          trailing:
              Text('${settings.frontLayerDragHeightRatio}', style: textStyle),
          onTap: settings.backdropUI
              ? () async {
                  final ratio = await Get.dialog<double>(DoubleRangeDialog(
                      text: '比例',
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
          title: Text('幕布上拉手势范围占屏幕高度的比例（不含标题栏）', style: textStyle),
          trailing:
              Text('${settings.backLayerDragHeightRatio}', style: textStyle),
          onTap: settings.backdropUI
              ? () async {
                  final ratio = await Get.dialog<double>(DoubleRangeDialog(
                      text: '比例',
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

class _HideFloatingButton extends StatelessWidget {
  // ignore: unused_element
  const _HideFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return NotifyBuilder(
      animation: Listenable.merge([
        settings.showBottomBarListenable,
        settings.hideFloatingButtonListenable,
      ]),
      builder: (context, child) => SwitchListTile(
        title: Text(
          '隐藏右下角的悬浮球',
          style: TextStyle(
            color:
                settings.showBottomBar ? AppTheme.inactiveSettingColor : null,
          ),
        ),
        value: settings.hideFloatingButton,
        onChanged: !settings.showBottomBar
            ? (value) => settings.hideFloatingButton = value
            : null,
      ),
    );
  }
}

class _AutoHideFloatingButton extends StatelessWidget {
  // ignore: unused_element
  const _AutoHideFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return NotifyBuilder(
      animation: Listenable.merge([
        settings.showBottomBarListenable,
        settings.hideFloatingButtonListenable,
        settings.autoHideFloatingButtonListenable,
      ]),
      builder: (context, child) => SwitchListTile(
        title: Text(
          '向下滑动时自动隐藏右下角的悬浮球',
          style: TextStyle(
            color: (settings.showBottomBar || settings.hideFloatingButton)
                ? AppTheme.inactiveSettingColor
                : null,
          ),
        ),
        value: settings.autoHideFloatingButton,
        onChanged: !(settings.showBottomBar || settings.hideFloatingButton)
            ? (value) => settings.autoHideFloatingButton = value
            : null,
      ),
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
      builder: (context, value, child) {
        final textStyle = TextStyle(
            color:
                settings.showBottomBar ? AppTheme.inactiveSettingColor : null);

        return ListTile(
          title: Text('划开侧边栏的范围占屏幕宽度的比例', style: textStyle),
          trailing:
              Text('${settings.drawerEdgeDragWidthRatio}', style: textStyle),
          onTap: !settings.showBottomBar
              ? () async {
                  final ratio = await Get.dialog<double>(DoubleRangeDialog(
                      text: '比例',
                      initialValue: settings.drawerEdgeDragWidthRatio,
                      min: SettingsService.minDrawerEdgeDragWidthRatio,
                      max: SettingsService.maxDrawerEdgeDragWidthRatio));

                  if (ratio != null) {
                    settings.drawerEdgeDragWidthRatio = ratio;
                  }
                }
              : null,
        );
      },
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
            color: !(settings.showBottomBar || settings.backdropUI)
                ? AppTheme.inactiveSettingColor
                : null);

        return ListTile(
          title: Text('左侧边缘滑动返回上一页的范围占屏幕宽度的比例', style: textStyle),
          subtitle: Text('更改后需要重启应用', style: textStyle),
          trailing:
              Text('${settings.swipeablePageDragWidthRatio}', style: textStyle),
          onTap: (settings.showBottomBar || settings.backdropUI)
              ? () async {
                  final ratio = await Get.dialog<double>(DoubleRangeDialog(
                      text: '比例',
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

class _CompactTabAndForumList extends StatelessWidget {
  // ignore: unused_element
  const _CompactTabAndForumList({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return NotifyBuilder(
      animation: Listenable.merge([
        settings.showBottomBarListenable,
        settings.backdropUIListenable,
        settings.compactTabAndForumListListenable,
      ]),
      builder: (context, child) => SwitchListTile(
        title: Text(
          '同时显示标签页列表和版块列表',
          style: TextStyle(
            color: !(settings.showBottomBar || settings.backdropUI)
                ? AppTheme.inactiveSettingColor
                : null,
          ),
        ),
        value: settings.compactTabAndForumList,
        onChanged: (settings.showBottomBar || settings.backdropUI)
            ? (value) => settings.compactTabAndForumList = value
            : null,
      ),
    );
  }
}

// TODO: 自动隐藏AppBar
class BasicUISettingsView extends StatelessWidget {
  const BasicUISettingsView({super.key});

  @override
  Widget build(BuildContext context) => ColoredSafeArea(
        child: Scaffold(
          appBar: AppBar(title: const Text('界面基本设置')),
          body: ListView(
            children: [
              if (!GetPlatform.isIOS) const _ShowBottomBar(),
              const _AutoHideBottomBar(),
              const Divider(height: 10.0, thickness: 1.0),
              const _BackdropUI(),
              const _FrontLayerDragHeightRatio(),
              const _BackLayerDragHeightRatio(),
              const Divider(height: 10.0, thickness: 1.0),
              const _HideFloatingButton(),
              const _AutoHideFloatingButton(),
              if (GetPlatform.isMobile) const _DrawerDragRatio(),
              const _PageDragWidthRatio(),
              const _CompactTabAndForumList(),
            ],
          ),
        ),
      );
}
