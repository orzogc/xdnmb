import 'package:flutter/material.dart';

import '../routes/routes.dart';

class UISettingsView extends StatelessWidget {
  const UISettingsView({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
        left: false,
        top: false,
        right: false,
        child: Scaffold(
          appBar: AppBar(title: const Text('界面设置')),
          body: ListView(
            children: const [
              ListTile(
                title: Text('Backdrop设置'),
                onTap: AppRoutes.toBackdropUISettings,
              ),
              ListTile(
                title: Text('串字体设置'),
                onTap: AppRoutes.toPostUISettings,
              ),
            ],
          ),
        ),
      );
}
