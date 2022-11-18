import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:swipeable_page_route/swipeable_page_route.dart';

import '../data/services/settings.dart';

abstract class AppTheme {
  static final Color primaryColorLight = Colors.red.shade300;

  static final Color primaryColorDark = Colors.grey.shade700;

  static final Color colorDark = Colors.blueGrey.shade200;

  static const Color overlayBackgroundColor = Color(0x80303030);

  static const Color buttonOverlayColorLight = Color(0x0a000000);

  static const Color buttonOverlayColorDark = Color(0x0affffff);

  static const Color linkTextColor = Color(0xff0077dd);

  static const Color iconColor = Color(0xff898989);

  static final Color editPostFilledColorLight = Colors.grey.shade200;

  static const Color editPostFilledColorDark = Color(0xff4d4d4d);

  static const Color headerColor = Colors.grey;

  static const TextStyle boldRed =
      TextStyle(color: Colors.red, fontWeight: FontWeight.bold);

  static final ThemeData theme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryColorLight,
    colorScheme: ColorScheme.light(
        primary: primaryColorLight,
        secondary: primaryColorLight,
        onPrimary: Colors.white,
        onSurface: Colors.black,
        onSecondary: Colors.white),
    fontFamily: SettingsService.isFixMissingFont ? 'Noto Sans' : null,
    appBarTheme: AppBarTheme(backgroundColor: primaryColorLight),
    progressIndicatorTheme:
        ProgressIndicatorThemeData(color: primaryColorLight),
    textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
            foregroundColor:
                MaterialStateColor.resolveWith((states) => primaryColorLight),
            overlayColor: _TextButtonDefaultOverlay(buttonOverlayColorLight))),
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
            backgroundColor: ButtonStyleButton.allOrNull(primaryColorLight))),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
            foregroundColor:
                MaterialStateColor.resolveWith((states) => primaryColorLight),
            overlayColor: _TextButtonDefaultOverlay(buttonOverlayColorLight))),
    inputDecorationTheme: InputDecorationTheme(
      focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.primaryColorLight)),
      border: UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.primaryColorLight)),
      floatingLabelStyle: TextStyle(color: AppTheme.primaryColorLight),
    ),
    textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppTheme.primaryColorLight,
        selectionColor: AppTheme.primaryColorLight),
    iconTheme: const IconThemeData(color: iconColor),
    checkboxTheme: CheckboxThemeData(
        fillColor: _CheckboxFillColor(primaryColorLight),
        checkColor: MaterialStateColor.resolveWith((states) => Colors.white)),
    toggleableActiveColor: AppTheme.primaryColorLight,
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: primaryColorLight,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle:
            const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 14.0)),
    indicatorColor: Colors.blue,
    pageTransitionsTheme: PageTransitionsTheme(builders: {
      TargetPlatform.android: SettingsService.isBackdropUI
          ? const SwipeablePageTransitionsBuilder()
          : const ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: SettingsService.isBackdropUI
          ? const SwipeablePageTransitionsBuilder()
          : const CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: SettingsService.isBackdropUI
          ? const SwipeablePageTransitionsBuilder()
          : const CupertinoPageTransitionsBuilder(),
    }),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColorDark,
    colorScheme: ColorScheme.dark(
        primary: primaryColorDark,
        secondary: primaryColorDark,
        onPrimary: colorDark,
        onSurface: colorDark,
        onSecondary: colorDark),
    fontFamily: SettingsService.isFixMissingFont ? 'Noto Sans' : null,
    appBarTheme: AppBarTheme(backgroundColor: primaryColorDark),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: primaryColorDark),
    textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
            foregroundColor:
                MaterialStateColor.resolveWith((states) => Colors.white),
            overlayColor: _TextButtonDefaultOverlay(buttonOverlayColorDark))),
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
            backgroundColor: ButtonStyleButton.allOrNull(primaryColorDark),
            foregroundColor: ButtonStyleButton.allOrNull(colorDark))),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
            foregroundColor:
                MaterialStateColor.resolveWith((states) => colorDark),
            overlayColor: _TextButtonDefaultOverlay(buttonOverlayColorDark))),
    inputDecorationTheme: InputDecorationTheme(
      focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.colorDark)),
      border: UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.colorDark)),
      floatingLabelStyle: TextStyle(color: AppTheme.colorDark),
    ),
    textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Colors.white, selectionColor: Colors.white),
    iconTheme: const IconThemeData(color: iconColor),
    checkboxTheme: CheckboxThemeData(
        fillColor: _CheckboxFillColor(Colors.white),
        checkColor: MaterialStateColor.resolveWith((states) => Colors.black)),
    toggleableActiveColor: AppTheme.primaryColorLight,
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: Colors.grey,
        unselectedItemColor: primaryColorDark,
        selectedLabelStyle:
            const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 14.0)),
    indicatorColor: Colors.white,
    pageTransitionsTheme: PageTransitionsTheme(builders: {
      TargetPlatform.android: SettingsService.isBackdropUI
          ? const SwipeablePageTransitionsBuilder()
          : const ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: SettingsService.isBackdropUI
          ? const SwipeablePageTransitionsBuilder()
          : const CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: SettingsService.isBackdropUI
          ? const SwipeablePageTransitionsBuilder()
          : const CupertinoPageTransitionsBuilder(),
    }),
    textTheme: const TextTheme(
      //headlineLarge: TextStyle(),
      //labelMedium: TextStyle(),
      headline1: TextStyle(),
      headline2: TextStyle(),
      headline3: TextStyle(),
      headline4: TextStyle(),
      headline5: TextStyle(),
      headline6: TextStyle(),
      subtitle1: TextStyle(),
      subtitle2: TextStyle(),
      bodyText1: TextStyle(),
      bodyText2: TextStyle(),
      caption: TextStyle(),
      button: TextStyle(),
      overline: TextStyle(),
    ).apply(displayColor: colorDark, bodyColor: colorDark),
  );

  static Color get specialTextColor =>
      Get.isDarkMode ? AppTheme.colorDark : AppTheme.primaryColorLight;

  static Color get textColor =>
      Get.isDarkMode ? AppTheme.colorDark : Colors.black;

  static Color get highlightColor =>
      Get.isDarkMode ? Colors.white : AppTheme.primaryColorLight;

  static Color get inactiveSettingColor =>
      Get.isDarkMode ? AppTheme.primaryColorDark : Colors.grey;
}

class _TextButtonDefaultOverlay extends MaterialStateProperty<Color?> {
  final Color primary;

  _TextButtonDefaultOverlay(this.primary);

  @override
  Color? resolve(Set<MaterialState> states) {
    if (states.contains(MaterialState.hovered)) {
      return primary.withOpacity(0.04);
    }
    if (states.contains(MaterialState.focused) ||
        states.contains(MaterialState.pressed)) {
      return primary.withOpacity(0.12);
    }
    return null;
  }
}

class _CheckboxFillColor extends MaterialStateProperty<Color?> {
  final Color primary;

  _CheckboxFillColor(this.primary);

  @override
  Color? resolve(Set<MaterialState> states) {
    if (states.contains(MaterialState.disabled)) {
      return Colors.grey.shade400;
    }
    return primary;
  }
}
