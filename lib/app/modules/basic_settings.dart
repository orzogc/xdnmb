import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../data/services/settings.dart';
import '../utils/theme.dart';
import '../widgets/dialog.dart';
import '../widgets/forum_name.dart';

class _InitialForum extends StatelessWidget {
  const _InitialForum({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ValueListenableBuilder<Box>(
      valueListenable: settings.initialForumListenable,
      builder: (context, value, child) => ListTile(
        title: const Text('应用启动后显示的版块'),
        trailing: TextButton(
          onPressed: () => Get.dialog(SelectForum(onSelect: (forum) {
            settings.initialForum = forum.copy();
            Get.back();
          })),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: ForumName(
              forumId: settings.initialForum.id,
              isTimeline: settings.initialForum.isTimeline,
              textStyle: TextStyle(
                color:
                    Get.isDarkMode ? Colors.white : AppTheme.primaryColorLight,
              ),
              maxLines: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _ShowImage extends StatelessWidget {
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

class _AutoJumpPage extends StatelessWidget {
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
  const _AutoJumpPosition({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ValueListenableBuilder<Box>(
      valueListenable: settings.isJumpToLastBrowsePositionListenable,
      builder: (context, value, child) => ListTile(
        title: Text(
          '自动跳转位置',
          style: TextStyle(
            color: settings.isJumpToLastBrowsePage
                ? null
                : Get.isDarkMode
                    ? AppTheme.primaryColorDark
                    : Colors.grey,
          ),
        ),
        subtitle: const Text('自动跳转页数时跳转到最近浏览的位置'),
        trailing: Switch(
          value: settings.isJumpToLastBrowsePosition,
          onChanged: settings.isJumpToLastBrowsePage
              ? (value) => settings.isJumpToLastBrowsePosition = value
              : null,
        ),
      ),
    );
  }
}

class _AfterPostRefresh extends StatelessWidget {
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

class _EditFeedId extends StatelessWidget {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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
      ),
      child: TextButton(
        onPressed: () => Get.dialog(_EditFeedId()),
        child: const Text('编辑'),
      ),
    );
  }
}

class BasicSettingsController extends GetxController {}

class BasicSettingsBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(BasicSettingsController());
  }
}

class BasicSettingsView extends GetView<BasicSettingsController> {
  const BasicSettingsView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('基本设置'),
        ),
        body: ListView(
          children: const [
            _InitialForum(),
            _ShowImage(),
            _Watermark(),
            _AutoJumpPage(),
            _AutoJumpPosition(),
            _AfterPostRefresh(),
            _FeedId(),
          ],
        ),
      );
}
