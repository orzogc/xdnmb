import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../data/services/settings.dart';
import '../utils/theme.dart';
import '../widgets/dialog.dart';
import '../widgets/forum_name.dart';

class _RestoreTabs extends StatelessWidget {
  // ignore: unused_element
  const _RestoreTabs({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ValueListenableBuilder<Box>(
      valueListenable: settings.isRestoreTabsListenable,
      builder: (context, value, child) => ListTile(
        title: const Text('应用启动后恢复标签页'),
        trailing: Switch(
          value: settings.isRestoreTabs,
          onChanged: (value) => settings.isRestoreTabs = value,
        ),
      ),
    );
  }
}

class _InitialForum extends StatelessWidget {
  // ignore: unused_element
  const _InitialForum({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ValueListenableBuilder<Box>(
      valueListenable: settings.initialForumListenable,
      builder: (context, value, child) => ListTile(
        title: Text(
          '应用启动后显示的版块',
          style: TextStyle(
            color:
                settings.isRestoreTabs ? AppTheme.inactiveSettingColor : null,
          ),
        ),
        trailing: TextButton(
          onPressed: settings.isRestoreTabs
              ? null
              : () => Get.dialog(
                    SelectForum(
                      onSelect: (forum) {
                        settings.initialForum = forum.copy();
                        Get.back();
                      },
                    ),
                  ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: ForumName(
              forumId: settings.initialForum.id,
              isTimeline: settings.initialForum.isTimeline,
              textStyle: TextStyle(
                  color: settings.isRestoreTabs
                      ? Colors.grey
                      : AppTheme.highlightColor),
              maxLines: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _ShowImage extends StatelessWidget {
  // ignore: unused_element
  const _ShowImage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ValueListenableBuilder<Box>(
      valueListenable: settings.showImageListenable,
      builder: (context, value, child) => ListTile(
        title: const Text('显示图片'),
        trailing: Switch(
          value: settings.showImage,
          onChanged: (value) => settings.showImage = value,
        ),
      ),
    );
  }
}

class _Watermark extends StatelessWidget {
  // ignore: unused_element
  const _Watermark({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ValueListenableBuilder<Box>(
      valueListenable: settings.isWatermarkListenable,
      builder: (context, value, child) => ListTile(
        title: const Text('发送图片默认附带水印'),
        trailing: Switch(
          value: settings.isWatermark,
          onChanged: (value) => settings.isWatermark = value,
        ),
      ),
    );
  }
}

class _HideFloatingButton extends StatelessWidget {
  // ignore: unused_element
  const _HideFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ValueListenableBuilder<Box>(
      valueListenable: settings.hideFloatingButtonListenable,
      builder: (context, value, child) => ListTile(
        title: const Text('隐藏右下角的悬浮球'),
        trailing: Switch(
          value: settings.hideFloatingButton,
          onChanged: (value) => settings.hideFloatingButton = value,
        ),
      ),
    );
  }
}

class _AutoJumpPage extends StatelessWidget {
  // ignore: unused_element
  const _AutoJumpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ValueListenableBuilder<Box>(
      valueListenable: settings.isJumpToLastBrowsePageListenable,
      builder: (context, value, child) => ListTile(
        title: const Text('自动跳转页数'),
        subtitle: const Text('打开串时自动跳转到最近浏览的页数'),
        trailing: Switch(
          value: settings.isJumpToLastBrowsePage,
          onChanged: (value) => settings.isJumpToLastBrowsePage = value,
        ),
      ),
    );
  }
}

class _AutoJumpPosition extends StatelessWidget {
  // ignore: unused_element
  const _AutoJumpPosition({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ValueListenableBuilder<Box>(
      valueListenable: settings.isJumpToLastBrowsePositionListenable,
      builder: (context, value, child) {
        final textStyle = TextStyle(
          color: !settings.isJumpToLastBrowsePage
              ? AppTheme.inactiveSettingColor
              : null,
        );

        return ListTile(
          title: Text('自动跳转位置', style: textStyle),
          subtitle: Text('自动跳转页数时跳转到最近浏览的位置', style: textStyle),
          trailing: Switch(
            value: settings.isJumpToLastBrowsePosition,
            onChanged: settings.isJumpToLastBrowsePage
                ? (value) => settings.isJumpToLastBrowsePosition = value
                : null,
          ),
        );
      },
    );
  }
}

class _AfterPostRefresh extends StatelessWidget {
  // ignore: unused_element
  const _AfterPostRefresh({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ValueListenableBuilder<Box>(
      valueListenable: settings.isAfterPostRefreshListenable,
      builder: (context, value, child) => ListTile(
        title: const Text('发表新串后自动刷新页面'),
        trailing: Switch(
          value: settings.isAfterPostRefresh,
          onChanged: (value) => settings.isAfterPostRefresh = value,
        ),
      ),
    );
  }
}

class _DismissibleTab extends StatelessWidget {
  // ignore: unused_element
  const _DismissibleTab({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ValueListenableBuilder<Box>(
      valueListenable: settings.dismissibleTabListenable,
      builder: (context, value, child) => ListTile(
        title: const Text('在标签页列表中滑动标签可以关闭标签页'),
        trailing: Switch(
          value: settings.dismissibleTab,
          onChanged: ((value) => settings.dismissibleTab = value),
        ),
      ),
    );
  }
}

class _EditFeedId extends StatelessWidget {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // ignore: unused_element
  _EditFeedId({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;
    final feedId = settings.feedId.obs;
    String? id;

    return InputDialog(
      content: Form(
        key: _formKey,
        child: Obx(
          () => TextFormField(
            key: ValueKey<String>(feedId.value),
            decoration: const InputDecoration(labelText: '订阅ID'),
            autofocus: true,
            initialValue: feedId.value,
            onSaved: (newValue) => id = newValue,
            validator: (value) =>
                (value == null || value.isEmpty) ? '请输入订阅ID' : null,
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => feedId.value = const Uuid().v4(),
          child: const Text('生成UUID'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();

              settings.feedId = id!;
              Get.back();
            }
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}

class _FeedId extends StatelessWidget {
  // ignore: unused_element
  const _FeedId({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ValueListenableBuilder<Box>(
      valueListenable: settings.feedIdListenable,
      builder: (context, value, child) => ListTile(
        title: const Text('订阅ID'),
        subtitle: Text(settings.feedId),
        trailing: child,
        onTap: () => Get.dialog(_EditFeedId()),
      ),
      child: TextButton(
        onPressed: () => Get.dialog(_EditFeedId()),
        child: const Text('编辑'),
      ),
    );
  }
}

class BasicSettingsView extends StatelessWidget {
  const BasicSettingsView({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
        left: false,
        top: false,
        right: false,
        child: Scaffold(
          appBar: AppBar(title: const Text('基本设置')),
          body: ListView(
            children: const [
              _RestoreTabs(),
              _InitialForum(),
              _ShowImage(),
              _Watermark(),
              _HideFloatingButton(),
              _AutoJumpPage(),
              _AutoJumpPosition(),
              _AfterPostRefresh(),
              _DismissibleTab(),
              _FeedId(),
            ],
          ),
        ),
      );
}
