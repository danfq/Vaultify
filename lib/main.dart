import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:vaultify/util/services/main.dart';
import 'package:vaultify/util/theming/themes.dart';

void main() async {
  //Initialize Main Services
  await MainServices.init();

  //Initial Route
  final initialRoute = await MainServices.initialRoute();

  //Run App
  runApp(
    AdaptiveTheme(
      light: Themes.light,
      dark: Themes.dark,
      initial: AdaptiveThemeMode.system,
      builder: (light, dark) {
        return GetMaterialApp(
          theme: light,
          darkTheme: dark,
          home: initialRoute,
        );
      },
    ),
  );
}
