import 'package:flutter/material.dart';

final ValueNotifier<ThemeMode> appThemeMode = ValueNotifier<ThemeMode>(ThemeMode.system);

void toggleAppTheme({required Brightness currentBrightness}) {
  appThemeMode.value = switch (appThemeMode.value) {
    ThemeMode.light => ThemeMode.dark,
    ThemeMode.dark => ThemeMode.light,
    ThemeMode.system =>
      currentBrightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark,
  };
}
