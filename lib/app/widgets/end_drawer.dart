import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/services/xdnmb_client.dart';
import '../routes/routes.dart';
import 'forum_list.dart';
import 'guide.dart';

class _DrawerHeader extends StatelessWidget {
  final double appBarHeight;

  // ignore: unused_element
  const _DrawerHeader({super.key, required this.appBarHeight});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final client = XdnmbClientService.to;

    final reorderForums = IconButton(
      onPressed: AppRoutes.toReorderForums,
      icon: Icon(Icons.swap_vert, color: theme.colorScheme.onPrimary),
    );

    return SizedBox(
      height: appBarHeight + MediaQuery.of(context).padding.top,
      child: DrawerHeader(
        decoration: BoxDecoration(
          color: theme.appBarTheme.backgroundColor ?? theme.colorScheme.primary,
        ),
        margin: null,
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Row(
          children: [
            Text(
              '版块',
              style: (theme.appBarTheme.titleTextStyle ??
                      theme.textTheme.titleLarge)
                  ?.apply(
                color: theme.appBarTheme.foregroundColor ??
                    theme.colorScheme.onPrimary,
              ),
            ),
            const Spacer(),
            Obx(
              () => client.isReady.value
                  ? ReorderForumsGuide(reorderForums)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class AppEndDrawer extends StatelessWidget {
  final double width;

  final double appBarHeight;

  const AppEndDrawer(
      {super.key, required this.width, required this.appBarHeight});

  @override
  Widget build(BuildContext context) {
    /* final settings = SettingsService.to;

    final Widget searchButton =
        SearchButton(showLabel: true, afterSearch: Get.back);
    final Widget historyButton =
        HistoryButton(showLabel: true, onTapEnd: Get.back);
    final Widget feedButton = FeedButton(showLabel: true, onTapEnd: Get.back);
    final Widget settingsButton =
        SettingsButton(showLabel: true, onTapPrelude: Get.back); */

    return Drawer(
      width: min(width * 0.5, 304),
      child: Column(
        children: [
          _DrawerHeader(appBarHeight: appBarHeight),
          Expanded(child: ForumList(onTapEnd: Get.back)),
        ],
      ),
    );
  }
}
