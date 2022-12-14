import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/services/settings.dart';
import 'buttons.dart';
import 'guide.dart';
import 'tab_list.dart';

class _DrawerHeader extends StatelessWidget {
  final double appBarHeight;

  // ignore: unused_element
  const _DrawerHeader({super.key, required this.appBarHeight});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onPrimary;

    final Widget searchButton =
        SearchButton(iconColor: color, afterSearch: Get.back);
    final Widget settingsButton =
        SettingsButton(iconColor: color, onTapPrelude: Get.back);

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
              '霞岛',
              style: (theme.appBarTheme.titleTextStyle ??
                      theme.textTheme.titleLarge)
                  ?.apply(
                color: theme.appBarTheme.foregroundColor ?? color,
              ),
            ),
            const Spacer(),
            SettingsService.shouldShowGuide
                ? const DarkModeGuide(DarkModeButton())
                : const DarkModeButton(),
            SettingsService.shouldShowGuide
                ? SearchGuide(searchButton)
                : searchButton,
            SettingsService.shouldShowGuide
                ? SettingsGuide(settingsButton)
                : settingsButton,
          ],
        ),
      ),
    );
  }
}

class _DrawerBottom extends StatelessWidget {
  // ignore: unused_element
  const _DrawerBottom({super.key});

  @override
  Widget build(BuildContext context) {
    final Widget historyButton = HistoryButton(onTapEnd: Get.back);
    final Widget feedButton = FeedButton(onTapEnd: Get.back);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const SponsorButton(),
          SettingsService.shouldShowGuide
              ? HistoryGuide(historyButton)
              : historyButton,
          SettingsService.shouldShowGuide ? FeedGuide(feedButton) : feedButton,
        ],
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  final double appBarHeight;

  const AppDrawer({super.key, required this.appBarHeight});

  @override
  Widget build(BuildContext context) => Drawer(
        child: Column(
          children: [
            _DrawerHeader(appBarHeight: appBarHeight),
            Expanded(child: TabList(onTapEnd: Get.back)),
            const Divider(height: 10.0, thickness: 1.0),
            const _DrawerBottom(),
          ],
        ),
      );
}
