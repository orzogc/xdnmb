import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../data/services/settings.dart';
import '../routes/routes.dart';
import '../widgets/dialog.dart';

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
          ListTile(
            title: const Text('管理饼干'),
            onTap: () => Get.toNamed(AppRoutes.userPath),
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
              title: const Text('发送的图片默认附带水印'),
              trailing: Switch(
                value: settings.isWatermark,
                onChanged: (value) => settings.isWatermark = value,
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
          )
        ],
      ),
    );
  }
}
