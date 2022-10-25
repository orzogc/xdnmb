import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../data/services/settings.dart';

class _FixMissingFont extends StatelessWidget {
  const _FixMissingFont({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.to;

    return ValueListenableBuilder<Box>(
      valueListenable: settings.fixMissingFontListenable,
      builder: (context, value, child) => ListTile(
        title: const Text('修复字体显示'),
        subtitle: const Text('字体显示不正常可以尝试开启此项，需要重启应用'),
        trailing: Switch(
          value: settings.fixMissingFont,
          onChanged: (value) => settings.fixMissingFont = value,
        ),
      ),
    );
  }
}

class AdvancedSettingsController extends GetxController {}

class AdvancedSettingsBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(AdvancedSettingsBinding());
  }
}

class AdvancedSettingsView extends GetView<AdvancedSettingsController> {
  const AdvancedSettingsView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('高级设置'),
        ),
        body: ListView(
          children: const [
            _FixMissingFont(),
          ],
        ),
      );
}
