import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/services/settings.dart';
import '../routes/routes.dart';
import '../utils/extensions.dart';

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

  //static const Color cardColorLight = Colors.white;

  //static const Color cardColorDark = Color(0xff424242);

  static const Curve slideCurve = Curves.easeOutQuart;

  static const TextStyle boldRed =
      TextStyle(color: Colors.red, fontWeight: FontWeight.bold);

  static final TextStyle postHeaderTextStyle =
      SettingsService.to.postHeaderTextStyle().apply(color: headerColor);

  static final StrutStyle postHeaderStrutStyle =
      StrutStyle.fromTextStyle(postHeaderTextStyle);

  static final TextStyle postContentTextStyle =
      SettingsService.to.postContentTextStyle();

  static final StrutStyle postContentStrutStyle =
      StrutStyle.fromTextStyle(postContentTextStyle);

  static final TextStyle boldRedPostContentTextStyle =
      SettingsService.to.postContentTextStyle(AppTheme.boldRed);

  static final StrutStyle boldRedPostContentStrutStyle =
      StrutStyle.fromTextStyle(boldRedPostContentTextStyle);

  static final FontWeight postContentBoldFontWeight =
      (postContentTextStyle.fontWeight != null &&
              postContentTextStyle.fontWeight!.toInt() >
                  FontWeight.bold.toInt())
          ? postContentTextStyle.fontWeight!
          : FontWeight.bold;

  static final InputDecorationTheme lightInputDecorationTheme =
      InputDecorationTheme(
    focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: AppTheme.primaryColorLight)),
    border: UnderlineInputBorder(
        borderSide: BorderSide(color: AppTheme.primaryColorLight)),
    floatingLabelStyle: TextStyle(color: AppTheme.primaryColorLight),
  );

  static final InputDecorationTheme darkInputDecorationTheme =
      InputDecorationTheme(
    focusedBorder:
        UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.colorDark)),
    border:
        UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.colorDark)),
    floatingLabelStyle: TextStyle(color: AppTheme.colorDark),
  );

  static final ThemeData theme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryColorLight,
    colorScheme: ColorScheme.light(
        primary: primaryColorLight,
        secondary: primaryColorLight,
        onPrimary: Colors.white,
        onSurface: Colors.black,
        onSecondary: Colors.white),
    fontFamily: SettingsService.isFixMissingFont ? 'Go Noto CJKCore' : null,
    appBarTheme: AppBarTheme(backgroundColor: primaryColorLight),
    progressIndicatorTheme:
        ProgressIndicatorThemeData(color: primaryColorLight),
    textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
            foregroundColor:
                MaterialStateColor.resolveWith((states) => primaryColorLight),
            overlayColor: _ButtonDefaultOverlay(buttonOverlayColorLight))),
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
            backgroundColor: ButtonStyleButton.allOrNull(primaryColorLight))),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
            foregroundColor:
                MaterialStateColor.resolveWith((states) => primaryColorLight),
            overlayColor: _ButtonDefaultOverlay(buttonOverlayColorLight))),
    inputDecorationTheme: lightInputDecorationTheme,
    dropdownMenuTheme:
        DropdownMenuThemeData(inputDecorationTheme: lightInputDecorationTheme),
    textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppTheme.primaryColorLight,
        selectionColor: AppTheme.primaryColorLight),
    iconTheme: const IconThemeData(color: iconColor),
    switchTheme: SwitchThemeData(
        thumbColor: _SwitchColor(AppTheme.primaryColorLight),
        trackColor: _SwitchColor(AppTheme.primaryColorLight.withOpacity(0.5))),
    checkboxTheme: CheckboxThemeData(
        fillColor: _CheckboxFillColor(primaryColorLight),
        checkColor: MaterialStateColor.resolveWith((states) => Colors.white)),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: primaryColorLight,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle:
            const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 14.0)),
    indicatorColor: Colors.blue,
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: AppPageTransitionsBuilder(),
      TargetPlatform.iOS: AppPageTransitionsBuilder(),
      TargetPlatform.macOS: AppPageTransitionsBuilder(),
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
    fontFamily: SettingsService.isFixMissingFont ? 'Go Noto CJKCore' : null,
    appBarTheme: AppBarTheme(backgroundColor: primaryColorDark),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: primaryColorDark),
    textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
            foregroundColor:
                MaterialStateColor.resolveWith((states) => Colors.white),
            overlayColor: _ButtonDefaultOverlay(buttonOverlayColorDark))),
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
            backgroundColor: ButtonStyleButton.allOrNull(primaryColorDark),
            foregroundColor: ButtonStyleButton.allOrNull(colorDark))),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
            foregroundColor:
                MaterialStateColor.resolveWith((states) => colorDark),
            overlayColor: _ButtonDefaultOverlay(buttonOverlayColorDark))),
    inputDecorationTheme: darkInputDecorationTheme,
    dropdownMenuTheme:
        DropdownMenuThemeData(inputDecorationTheme: darkInputDecorationTheme),
    textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Colors.white, selectionColor: Colors.white),
    iconTheme: const IconThemeData(color: iconColor),
    switchTheme: SwitchThemeData(
        thumbColor: _SwitchColor(AppTheme.primaryColorLight),
        trackColor: _SwitchColor(AppTheme.primaryColorLight.withOpacity(0.5))),
    checkboxTheme: CheckboxThemeData(
        fillColor: _CheckboxFillColor(Colors.white),
        checkColor: MaterialStateColor.resolveWith((states) => Colors.black)),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: Colors.grey,
        unselectedItemColor: primaryColorDark,
        selectedLabelStyle:
            const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 14.0)),
    indicatorColor: Colors.white,
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: AppPageTransitionsBuilder(),
      TargetPlatform.iOS: AppPageTransitionsBuilder(),
      TargetPlatform.macOS: AppPageTransitionsBuilder(),
    }),
    textTheme: const TextTheme(
      displayLarge: TextStyle(),
      displayMedium: TextStyle(),
      displaySmall: TextStyle(),
      headlineLarge: TextStyle(),
      headlineMedium: TextStyle(),
      headlineSmall: TextStyle(),
      titleLarge: TextStyle(),
      titleMedium: TextStyle(),
      titleSmall: TextStyle(),
      bodyLarge: TextStyle(),
      bodyMedium: TextStyle(),
      bodySmall: TextStyle(),
      labelLarge: TextStyle(),
      labelMedium: TextStyle(),
      labelSmall: TextStyle(),
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

class _ButtonDefaultOverlay extends MaterialStateProperty<Color?> {
  final Color color;

  _ButtonDefaultOverlay(this.color);

  @override
  Color? resolve(Set<MaterialState> states) {
    if (states.contains(MaterialState.hovered)) {
      return color.withOpacity(0.04);
    }
    if (states.contains(MaterialState.focused) ||
        states.contains(MaterialState.pressed)) {
      return color.withOpacity(0.12);
    }
    return null;
  }
}

class _CheckboxFillColor extends MaterialStateProperty<Color?> {
  final Color color;

  _CheckboxFillColor(this.color);

  @override
  Color? resolve(Set<MaterialState> states) =>
      states.contains(MaterialState.disabled) ? Colors.grey.shade400 : color;
}

class _SwitchColor extends MaterialStateProperty<Color?> {
  final Color color;

  _SwitchColor(this.color);

  @override
  Color? resolve(Set<MaterialState> states) =>
      states.contains(MaterialState.selected) ? color : null;
}
