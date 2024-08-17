import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:vaultify/util/theming/controller.dart';

///Buttons
class Buttons {
  ///Current Theme
  static final bool _currentTheme =
      ThemeController.current(context: Get.context!);

  ///Elevated
  static ElevatedButton elevated({
    required String text,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            _currentTheme ? const Color(0xFFFAFAFA) : const Color(0xFF1F2A33),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: !_currentTheme
              ? const Color(0xFFFAFAFA)
              : const Color(0xFF1F2A33),
        ),
      ),
    );
  }
}
