import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';

import '../data/services/settings.dart';
import '../data/services/user.dart';
import '../utils/theme.dart';
import '../widgets/dialog.dart';
import '../widgets/listenable.dart';

class _UseDrawerAndEndDrawer extends StatelessWidget {
  // ignore: unused_element
  const _UseDrawerAndEndDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ListenBuilder(
      listenable: settings.useDrawerAndEndDrawerListenable,
      builder: (context, child) => SwitchListTile(
        title: const Text('使用左右侧边栏'),
        value: settings.useDrawerAndEndDrawer,
        onChanged: (value) => settings.useDrawerAndEndDrawer = value,
      ),
    );
  }
}

class _ShowBottomBar extends StatelessWidget {
  // ignore: unused_element
  const _ShowBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;
    final textStyle = Theme.of(context).textTheme.bodyMedium;

    return ListenBuilder(
      listenable: settings.bottomBarSettingListenable,
      builder: (context, child) => ListTile(
        title: Text(
          '底边栏',
          style: TextStyle(
            color: settings.useDrawerAndEndDrawer
                ? AppTheme.inactiveSettingColor
                : null,
          ),
        ),
        trailing: DropdownButton<int>(
          value: settings.bottomBarSetting,
          alignment: Alignment.centerRight,
          underline: const SizedBox.shrink(),
          icon: const SizedBox.shrink(),
          style: textStyle,
          onChanged: !settings.useDrawerAndEndDrawer
              ? (value) {
                  if (value != null) {
                    settings.bottomBarSetting = value;
                  }
                }
              : null,
          items: const [
            DropdownMenuItem<int>(
              value: 0,
              alignment: Alignment.centerRight,
              child: Text('向下滑动时隐藏'),
            ),
            DropdownMenuItem<int>(
              value: 1,
              alignment: Alignment.centerRight,
              child: Text('始终显示'),
            ),
            DropdownMenuItem<int>(
              value: 2,
              alignment: Alignment.centerRight,
              child: Text('不显示'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EndDrawerContent extends StatelessWidget {
  // ignore: unused_element
  const _EndDrawerContent({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;
    final textStyle = Theme.of(context).textTheme.bodyMedium;

    return ListenBuilder(
      listenable: settings.endDrawerSettingListenable,
      builder: (context, child) => ListTile(
        title: Text(
          '右边侧边栏',
          style: TextStyle(
            color: settings.endDrawerHasOnlyTabAndForumList
                ? AppTheme.inactiveSettingColor
                : null,
          ),
        ),
        trailing: DropdownButton<int>(
          value: settings.endDrawerSetting,
          alignment: Alignment.centerRight,
          underline: const SizedBox.shrink(),
          icon: const SizedBox.shrink(),
          style: textStyle,
          onChanged: !settings.endDrawerHasOnlyTabAndForumList
              ? (value) {
                  if (value != null) {
                    settings.endDrawerSetting = value;
                  }
                }
              : null,
          items: [
            if (!settings.useDrawerAndEndDrawer)
              const DropdownMenuItem<int>(
                value: 0,
                alignment: Alignment.centerRight,
                child: Text('不使用'),
              ),
            const DropdownMenuItem<int>(
              value: 1,
              alignment: Alignment.centerRight,
              child: Text('版块'),
            ),
            const DropdownMenuItem<int>(
              value: 2,
              alignment: Alignment.centerRight,
              child: Text('标签页'),
            ),
            if (!settings.useDrawerAndEndDrawer)
              const DropdownMenuItem<int>(
                value: 3,
                alignment: Alignment.centerRight,
                child: Text('标签页和版块'),
              ),
          ],
        ),
      ),
    );
  }
}

class _AutoHideAppBar extends StatelessWidget {
  // ignore: unused_element
  const _AutoHideAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ListenBuilder(
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

    return ListenBuilder(
      listenable: settings.floatingButtonSettingListenable,
      builder: (context, child) => ListTile(
        title: Text(
          '右下角的悬浮球',
          style: TextStyle(
            color: !settings.hasFloatingButton
                ? AppTheme.inactiveSettingColor
                : null,
          ),
        ),
        trailing: DropdownButton<int>(
          value: settings.floatingButtonSetting,
          alignment: Alignment.centerRight,
          underline: const SizedBox.shrink(),
          icon: const SizedBox.shrink(),
          style: textStyle,
          onChanged: settings.hasFloatingButton
              ? (value) {
                  if (value != null) {
                    settings.floatingButtonSetting = value;
                  }
                }
              : null,
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
        ),
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

    return ListenBuilder(
      listenable: settings.drawerEdgeDragWidthRatioListenable,
      builder: (context, child) {
        final textStyle = TextStyle(
            color: !settings.hasDrawerOrEndDrawerRx
                ? AppTheme.inactiveSettingColor
                : null);

        return ListTile(
          title: Text('划开侧边栏的范围占屏幕宽度的比例', style: textStyle),
          trailing:
              Text('${settings.drawerEdgeDragWidthRatio}', style: textStyle),
          onTap: settings.hasDrawerOrEndDrawerRx
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

    return ListenBuilder(
      listenable: settings.swipeablePageDragWidthRatioListenable,
      builder: (context, child) {
        final textStyle = TextStyle(
            color: !settings.isSwipeablePageRx
                ? AppTheme.inactiveSettingColor
                : null);

        return ListTile(
          title: Text('左侧边缘滑动返回上一页的范围占屏幕宽度的比例', style: textStyle),
          trailing:
              Text('${settings.swipeablePageDragWidthRatio}', style: textStyle),
          onTap: settings.isSwipeablePageRx
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

    return ListenBuilder(
      listenable: Listenable.merge([
        settings.endDrawerSettingListenable,
        settings.compactTabAndForumListListenable,
      ]),
      builder: (context, child) => SwitchListTile(
        title: Text(
          '合并显示标签页列表和版块列表',
          style: TextStyle(
            color: settings.hasDrawerOrEndDrawerRx
                ? AppTheme.inactiveSettingColor
                : null,
          ),
        ),
        value: settings.compactTabAndForumList,
        onChanged: !settings.hasDrawerOrEndDrawerRx
            ? (value) => settings.compactTabAndForumList = value
            : null,
      ),
    );
  }
}

class _TransparentSystemNavigationBar extends StatelessWidget {
  // ignore: unused_element
  const _TransparentSystemNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ListenBuilder(
      listenable: settings.transparentSystemNavigationBarListListenable,
      builder: (context, child) => SwitchListTile(
        title: const Text('系统底部导航栏透明化'),
        subtitle: const Text('更改后需要重启应用'),
        value: settings.transparentSystemNavigationBar,
        onChanged: (value) => settings.transparentSystemNavigationBar = value,
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

    return ListenBuilder(
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

    return ListenBuilder(
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

    return ListenBuilder(
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

    return ListenBuilder(
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

    return ListenBuilder(
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
    final user = UserService.to;
    final textStyle = Theme.of(context).textTheme.bodyMedium;

    return ListenBuilder(
      listenable: Listenable.merge([
        user.feedCookieListenable,
        settings.showLatestPostTimeInFeedListenable,
      ]),
      builder: (context, child) => ListTile(
        title: Text('订阅界面里的串显示最后回复时间',
            style: TextStyle(
                color:
                    user.hasFeedCookie ? AppTheme.inactiveSettingColor : null)),
        trailing: DropdownButton<int>(
          value: !user.hasFeedCookie ? settings.showLatestPostTimeInFeed : 0,
          alignment: Alignment.centerRight,
          underline: const SizedBox.shrink(),
          icon: const SizedBox.shrink(),
          style: textStyle,
          onChanged: !user.hasFeedCookie
              ? (value) {
                  if (value != null) {
                    settings.showLatestPostTimeInFeed = value;
                  }
                }
              : null,
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
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('界面基本设置')),
        body: ListView(
          children: [
            if (!GetPlatform.isIOS) const _UseDrawerAndEndDrawer(),
            const _ShowBottomBar(),
            const _EndDrawerContent(),
            const Divider(height: 10.0, thickness: 1.0),
            const _AutoHideAppBar(),
            const _FloatingButton(),
            if (GetPlatform.isMobile) const _DrawerDragRatio(),
            const _PageDragWidthRatio(),
            const _CompactTabAndForumList(),
            if (SettingsService.isAllowTransparentSystemNavigationBar)
              const _TransparentSystemNavigationBar(),
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
      );
}
