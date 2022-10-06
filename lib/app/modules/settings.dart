import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../data/services/settings.dart';
import '../routes/routes.dart';
import '../utils/theme.dart';
import '../widgets/dialog.dart';
import '../widgets/forum_name.dart';

class _EditFeedUuid extends StatelessWidget {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  _EditFeedUuid({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;
    final uuid = settings.feedUuid.obs;
    String? id;

    return InputDialog(
      content: Form(
        key: _formKey,
        child: Obx(
          () => TextFormField(
            key: ValueKey<String>(uuid.value),
            decoration: const InputDecoration(labelText: '订阅ID'),
            autofocus: true,
            initialValue: uuid.value,
            onSaved: (newValue) => id = newValue,
            validator: (value) =>
                (value == null || value.isEmpty) ? '请输入订阅ID' : null,
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => uuid.value = const Uuid().v4(),
          child: const Text('生成UUID'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();

              settings.feedUuid = id!;
              Get.back();
            }
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
}

class SettingsController extends GetxController {}

class SettingsBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(SettingsController());
  }
}

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          const ListTile(
            title: Text('管理饼干'),
            onTap: AppRoutes.toUser,
          ),
          ValueListenableBuilder<Box>(
            valueListenable: settings.initialForumListenable,
            builder: (context, value, child) => ListTile(
              title: const Text('应用启动时显示的板块'),
              trailing: TextButton(
                onPressed: () => Get.dialog(SelectForum(onSelect: (forum) {
                  settings.initialForum = forum.copy();
                  Get.back();
                })),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: forumNameText(
                    context,
                    settings.initialForum.forumName,
                    textStyle: TextStyle(
                        color: Get.isDarkMode
                            ? Colors.white
                            : AppTheme.primaryColorLight),
                    maxLines: 1,
                  ),
                ),
              ),
            ),
          ),
          ValueListenableBuilder<Box>(
            valueListenable: settings.showImageListenable,
            builder: (context, value, child) => ListTile(
              title: const Text('显示图片'),
              trailing: Switch(
                value: settings.showImage,
                onChanged: (value) => settings.showImage = value,
              ),
            ),
          ),
          ValueListenableBuilder<Box>(
            valueListenable: settings.isWatermarkListenable,
            builder: (context, value, child) => ListTile(
              title: const Text('发送图片默认附带水印'),
              trailing: Switch(
                value: settings.isWatermark,
                onChanged: (value) => settings.isWatermark = value,
              ),
            ),
          ),
          ValueListenableBuilder<Box>(
            valueListenable: settings.isJumpToLastBrowsePageListenable,
            builder: (context, value, child) => ListTile(
              title: const Text('打开串时自动跳转到最近浏览的页数'),
              trailing: Switch(
                value: settings.isJumpToLastBrowsePage,
                onChanged: (value) => settings.isJumpToLastBrowsePage = value,
              ),
            ),
          ),
          ValueListenableBuilder<Box>(
            valueListenable: settings.isJumpToLastBrowsePageListenable,
            builder: (context, value, child) => ValueListenableBuilder(
              valueListenable: settings.isJumpToLastBrowsePositionListenable,
              builder: (context, value, child) => ListTile(
                title: Text(
                  '自动跳转页数时滚动到最近浏览的位置',
                  style: TextStyle(
                    color: settings.isJumpToLastBrowsePage
                        ? null
                        : Get.isDarkMode
                            ? Theme.of(context).primaryColor
                            : null,
                  ),
                ),
                trailing: Switch(
                  value: settings.isJumpToLastBrowsePosition,
                  onChanged: settings.isJumpToLastBrowsePage
                      ? (value) => settings.isJumpToLastBrowsePosition = value
                      : null,
                ),
              ),
            ),
          ),
          ValueListenableBuilder<Box>(
            valueListenable: settings.feedUuidListenable,
            builder: (context, value, child) => ListTile(
              title: const Text('订阅ID'),
              subtitle: Text(settings.feedUuid),
              trailing: TextButton(
                onPressed: () => Get.dialog(_EditFeedUuid()),
                child: const Text('编辑'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
