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
    bool? enabled,
  }) {
    return ElevatedButton(
      onPressed: enabled ?? true ? onTap : null,
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

  ///Elevated with Icon
  static ElevatedButton elevatedIcon({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
    bool? enabled,
  }) {
    return ElevatedButton.icon(
      onPressed: enabled ?? true ? onTap : null,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            _currentTheme ? const Color(0xFFFAFAFA) : const Color(0xFF1F2A33),
      ),
      icon: Icon(
        icon,
        color:
            !_currentTheme ? const Color(0xFFFAFAFA) : const Color(0xFF1F2A33),
      ),
      label: Text(
        text,
        style: TextStyle(
          color: !_currentTheme
              ? const Color(0xFFFAFAFA)
              : const Color(0xFF1F2A33),
        ),
      ),
    );
  }

  ///Text Button
  static TextButton text({required String text, required VoidCallback onTap}) {
    return TextButton(
      onPressed: onTap,
      child: Text(text),
    );
  }
}
