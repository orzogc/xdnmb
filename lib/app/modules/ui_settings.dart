import 'package:flutter/material.dart';

import '../routes/routes.dart';

class UISettingsView extends StatelessWidget {
  const UISettingsView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('界面设置')),
        body: ListView(
          children: const [
            ListTile(
              title: Text('界面基本设置'),
              onTap: AppRoutes.toBasicUISettings,
            ),
            ListTile(
              title: Text('串字体设置'),
              onTap: AppRoutes.toPostUISettings,
            ),
          ],
        ),
      );
}
