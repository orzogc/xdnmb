import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../data/services/settings.dart';
import '../utils/notify.dart';
import '../utils/theme.dart';
import '../widgets/dialog.dart';

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
          title: Text('上拉手势范围占屏幕高度的比例', style: textStyle),
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

class BackdropUISettingsView extends StatelessWidget {
  const BackdropUISettingsView({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
        left: false,
        top: false,
        right: false,
        child: Scaffold(
          appBar: AppBar(title: const Text('Backdrop设置')),
          body: ListView(
            children: [
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
