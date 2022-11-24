import 'package:flutter/material.dart';

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
    final settings = SettingsService.to;
    final theme = Theme.of(context);
    final color = theme.colorScheme.onPrimary;

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
            settings.shouldShowGuide
                ? const DarkModeGuide(DarkModeButton())
                : const DarkModeButton(),
            settings.shouldShowGuide
                ? SearchGuide(SearchButton(iconColor: color))
                : SearchButton(iconColor: color),
            settings.shouldShowGuide
                ? SettingsGuide(SettingsButton(iconColor: color))
                : SettingsButton(iconColor: color),
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
    final settings = SettingsService.to;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const SponsorButton(),
          settings.shouldShowGuide
              ? const HistoryGuide(HistoryButton())
              : const HistoryButton(),
          settings.shouldShowGuide
              ? const FeedGuide(FeedButton())
              : const FeedButton(),
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
            const Expanded(child: TabList()),
            const Divider(height: 10.0, thickness: 1.0),
            const _DrawerBottom(),
          ],
        ),
      );
}
