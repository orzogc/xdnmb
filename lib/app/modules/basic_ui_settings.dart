import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';

import '../data/services/settings.dart';
import '../utils/theme.dart';
import '../widgets/color.dart';
import '../widgets/dialog.dart';
import '../widgets/listenable.dart';

class _ShowBottomBar extends StatelessWidget {
  // ignore: unused_element
  const _ShowBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;
    final textStyle = Theme.of(context).textTheme.bodyMedium;

    return ListTile(
      title: const Text('底边栏'),
      subtitle: !GetPlatform.isIOS
          ? const Text('底边栏会取代侧边栏，如要使用侧边栏需要取消显示底边栏')
          : const SizedBox.shrink(),
      trailing: ListenableBuilder(
        listenable: Listenable.merge([
          settings.showBottomBarListenable,
          settings.autoHideBottomBarListenable,
        ]),
        builder: (context, child) {
          int n =
              settings.showBottomBar ? (settings.autoHideBottomBar ? 0 : 1) : 2;
          // iOS强制使用底边栏
          if (GetPlatform.isIOS) {
            n = n.clamp(0, 1);
          }

          return DropdownButton<int>(
            value: n,
            alignment: Alignment.centerRight,
            underline: const SizedBox.shrink(),
            icon: const SizedBox.shrink(),
            style: textStyle,
            onChanged: (value) {
              if (value != null) {
                value = value.clamp(0, GetPlatform.isIOS ? 1 : 2);
                switch (value) {
                  case 0:
                    settings.showBottomBar = true;
                    settings.autoHideBottomBar = true;
                    break;
                  case 1:
                    settings.showBottomBar = true;
                    settings.autoHideBottomBar = false;
                    break;
                  case 2:
                    if (!GetPlatform.isIOS) {
                      settings.showBottomBar = false;
                      settings.autoHideBottomBar = false;
                    }
                    break;
                }
              }
            },
            items: [
              const DropdownMenuItem<int>(
                value: 0,
                alignment: Alignment.centerRight,
                child: Text('向下滑动时隐藏'),
              ),
              const DropdownMenuItem<int>(
                value: 1,
                alignment: Alignment.centerRight,
                child: Text('始终显示'),
              ),
              if (!GetPlatform.isIOS)
                const DropdownMenuItem<int>(
                  value: 2,
                  alignment: Alignment.centerRight,
                  child: Text('不显示'),
                ),
            ],
          );
        },
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

    return ListenableBuilder(
      listenable: settings.backdropUIListenable,
      builder: (context, child) => SwitchListTile(
        title: const Text('启用幕布界面'),
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

    return ListenableBuilder(
      listenable: Listenable.merge([
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
                  final ratio = await Get.dialog<double>(NumRangeDialog<double>(
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

    return ListenableBuilder(
      listenable: Listenable.merge([
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
                  final ratio = await Get.dialog<double>(NumRangeDialog<double>(
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

class _AutoHideAppBar extends StatelessWidget {
  // ignore: unused_element
  const _AutoHideAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ListenableBuilder(
      listenable: settings.autoHideAppBarListenable,
      builder: (context, child) => SwitchListTile(
        title: const Text('向下滑动时自动隐藏标题栏'),
        value: settings.autoHideAppBar,
        onChanged: (value) => settings.autoHideAppBar = value,
      ),
    );
  }
}

class _FloatingButton extends StatelessWidget {
  // ignore: unused_element
  const _FloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;
    final textStyle = Theme.of(context).textTheme.bodyMedium;

    return ListenableBuilder(
      listenable: Listenable.merge([
        settings.showBottomBarListenable,
        settings.hideFloatingButtonListenable,
        settings.autoHideFloatingButtonListenable,
      ]),
      builder: (context, child) {
        final int n = settings.hideFloatingButton
            ? 1
            : (settings.autoHideFloatingButton ? 2 : 0);

        late final Widget trailing;
        if (settings.showBottomBar) {
          final style = textStyle?.apply(color: AppTheme.inactiveSettingColor);

          switch (n) {
            case 0:
              trailing = Text('始终显示', style: style);
              break;
            case 1:
              trailing = Text('隐藏', style: style);
              break;
            case 2:
              trailing = Text('向下滑动时隐藏', style: style);
              break;
          }
        } else {
          trailing = DropdownButton<int>(
            value: n,
            alignment: Alignment.centerRight,
            underline: const SizedBox.shrink(),
            icon: const SizedBox.shrink(),
            style: textStyle,
            onChanged: (value) {
              if (value != null) {
                value = value.clamp(0, 2);
                switch (value) {
                  case 0:
                    settings.hideFloatingButton = false;
                    settings.autoHideFloatingButton = false;
                    break;
                  case 1:
                    settings.hideFloatingButton = true;
                    settings.autoHideFloatingButton = false;
                    break;
                  case 2:
                    settings.hideFloatingButton = false;
                    settings.autoHideFloatingButton = true;
                    break;
                }
              }
            },
            items: const [
              DropdownMenuItem<int>(
                value: 0,
                alignment: Alignment.centerRight,
                child: Text('始终显示'),
              ),
              DropdownMenuItem<int>(
                value: 1,
                alignment: Alignment.centerRight,
                child: Text('隐藏'),
              ),
              DropdownMenuItem<int>(
                value: 2,
                alignment: Alignment.centerRight,
                child: Text('向下滑动时隐藏'),
              ),
            ],
          );
        }

        return ListTile(
          title: Text(
            '右下角的悬浮球',
            style: TextStyle(
              color:
                  settings.showBottomBar ? AppTheme.inactiveSettingColor : null,
            ),
          ),
          trailing: trailing,
        );
      },
    );
  }
}

class _DrawerDragRatio extends StatelessWidget {
  // ignore: unused_element
  const _DrawerDragRatio({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ListenableBuilder(
      listenable: settings.drawerEdgeDragWidthRatioListenable,
      builder: (context, child) {
        final textStyle = TextStyle(
            color:
                settings.showBottomBar ? AppTheme.inactiveSettingColor : null);

        return ListTile(
          title: Text('划开侧边栏的范围占屏幕宽度的比例', style: textStyle),
          trailing:
              Text('${settings.drawerEdgeDragWidthRatio}', style: textStyle),
          onTap: !settings.showBottomBar
              ? () async {
                  final ratio = await Get.dialog<double>(NumRangeDialog<double>(
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

    return ListenableBuilder(
      listenable: settings.swipeablePageDragWidthRatioListenable,
      builder: (context, child) {
        final textStyle = TextStyle(
            color: !(settings.showBottomBar || settings.backdropUI)
                ? AppTheme.inactiveSettingColor
                : null);

        return ListTile(
          title: Text('左侧边缘滑动返回上一页的范围占屏幕宽度的比例', style: textStyle),
          trailing:
              Text('${settings.swipeablePageDragWidthRatio}', style: textStyle),
          onTap: (settings.showBottomBar || settings.backdropUI)
              ? () async {
                  final ratio = await Get.dialog<double>(NumRangeDialog<double>(
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

    return ListenableBuilder(
      listenable: Listenable.merge([
        settings.showBottomBarListenable,
        settings.backdropUIListenable,
        settings.compactTabAndForumListListenable,
      ]),
      builder: (context, child) => SwitchListTile(
        title: Text(
          '合并显示标签页列表和版块列表',
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

class _ShowPoCookieTag extends StatelessWidget {
  // ignore: unused_element
  const _ShowPoCookieTag({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ListenableBuilder(
      listenable: settings.showPoCookieTagListenable,
      builder: (context, child) => SwitchListTile(
        title: const Text('串内Po饼干左边显示Po标识'),
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

class _ShowRelativeTime extends StatelessWidget {
  // ignore: unused_element
  const _ShowRelativeTime({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ListenableBuilder(
      listenable: settings.showRelativeTimeListenable,
      builder: (context, child) => SwitchListTile(
        title: const Text('串时间使用相对时间'),
        subtitle: const Text('例如显示“几分钟前”而不是具体的时间'),
        value: settings.showRelativeTime,
        onChanged: (value) => settings.showRelativeTime = value,
      ),
    );
  }
}

class _ShowLatestPostTimeInFeed extends StatelessWidget {
  // ignore: unused_element
  const _ShowLatestPostTimeInFeed({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;
    final textStyle = Theme.of(context).textTheme.bodyMedium;

    return ListTile(
      title: const Text('订阅界面里的串显示最后回复时间'),
      trailing: ListenableBuilder(
        listenable: settings.showLatestPostTimeInFeedListenable,
        builder: (context, child) => DropdownButton<int>(
          value: settings.showLatestPostTimeInFeed,
          alignment: Alignment.centerRight,
          underline: const SizedBox.shrink(),
          icon: const SizedBox.shrink(),
          style: textStyle,
          onChanged: (value) {
            if (value != null) {
              settings.showLatestPostTimeInFeed = value.clamp(0, 2);
            }
          },
          items: const [
            DropdownMenuItem<int>(
              value: 0,
              alignment: Alignment.centerRight,
              child: Text('不显示'),
            ),
            DropdownMenuItem<int>(
              value: 1,
              alignment: Alignment.centerRight,
              child: Text('显示绝对时间'),
            ),
            DropdownMenuItem<int>(
              value: 2,
              alignment: Alignment.centerRight,
              child: Text('显示相对时间'),
            ),
          ],
        ),
      ),
    );
  }
}

class BasicUISettingsView extends StatelessWidget {
  const BasicUISettingsView({super.key});

  @override
  Widget build(BuildContext context) => ColoredSafeArea(
        child: Scaffold(
          appBar: AppBar(title: const Text('界面基本设置')),
          body: ListView(
            children: [
              const _ShowBottomBar(),
              const Divider(height: 10.0, thickness: 1.0),
              const _BackdropUI(),
              const _FrontLayerDragHeightRatio(),
              const _BackLayerDragHeightRatio(),
              const Divider(height: 10.0, thickness: 1.0),
              const _AutoHideAppBar(),
              const _FloatingButton(),
              if (GetPlatform.isMobile) const _DrawerDragRatio(),
              const _PageDragWidthRatio(),
              const _CompactTabAndForumList(),
              const Divider(height: 10.0, thickness: 1.0),
              const _ShowPoCookieTag(),
              const _PoCookieColor(),
              const _ShowUserCookieNote(),
              const _ShowUserCookieColor(),
              const Divider(height: 10.0, thickness: 1.0),
              const _ShowRelativeTime(),
              const _ShowLatestPostTimeInFeed(),
            ],
          ),
        ),
      );
}
