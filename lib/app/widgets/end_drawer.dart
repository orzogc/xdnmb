import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/services/settings.dart';
import '../data/services/xdnmb_client.dart';
import '../routes/routes.dart';
import '../utils/extensions.dart';
import 'buttons.dart';
import 'forum_list.dart';
import 'guide.dart';

class _DrawerHeader extends StatelessWidget {
  final double appBarHeight;

  // ignore: unused_element
  const _DrawerHeader({super.key, required this.appBarHeight});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = SettingsService.to;
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
                  ? settings.showGuide
                      ? ReorderForumsGuide(reorderForums)
                      : reorderForums
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackdropDrawerHeader extends StatelessWidget {
  final double appBarHeight;

  // ignore: unused_element
  const _BackdropDrawerHeader({super.key, required this.appBarHeight});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: appBarHeight + MediaQuery.of(context).padding.top,
      child: DrawerHeader(
        decoration: BoxDecoration(
          color: theme.appBarTheme.backgroundColor ?? theme.colorScheme.primary,
        ),
        margin: null,
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: SizedBox.expand(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '霞岛',
              style: (theme.appBarTheme.titleTextStyle ??
                      theme.textTheme.titleLarge)
                  ?.apply(
                color: theme.appBarTheme.foregroundColor ??
                    theme.colorScheme.onPrimary,
              ),
            ),
          ),
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
    final settings = SettingsService.to;

    return SettingsService.isBackdropUI
        ? Drawer(
            width: 150.0,
            child: Column(
              children: [
                _BackdropDrawerHeader(appBarHeight: appBarHeight),
                ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: [
                    settings.shouldShowGuide
                        ? const DarkModeGuide(DarkModeButton(showLabel: true))
                        : const DarkModeButton(showLabel: true),
                    settings.shouldShowGuide
                        ? const SearchGuide(SearchButton(showLabel: true))
                        : const SearchButton(showLabel: true),
                    settings.shouldShowGuide
                        ? const HistoryGuide(HistoryButton(showLabel: true))
                        : const HistoryButton(showLabel: true),
                    settings.shouldShowGuide
                        ? const FeedGuide(FeedButton(showLabel: true))
                        : const FeedButton(showLabel: true),
                    settings.shouldShowGuide
                        ? const SettingsGuide(SettingsButton(showLabel: true))
                        : const SettingsButton(showLabel: true),
                    const SponsorButton(showIcon: true),
                  ].withSpaceBetween(height: 10.0),
                ),
              ].withSpaceBetween(height: 10.0),
            ),
          )
        : Drawer(
            width: min(width * 0.5, 304),
            child: Column(
              children: [
                _DrawerHeader(appBarHeight: appBarHeight),
                const Expanded(child: ForumList()),
              ],
            ),
          );
  }
}
