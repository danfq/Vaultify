import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/route_manager.dart';

///Main Widgets
class MainWidgets {
  ///AppBar
  static PreferredSizeWidget appBar({
    Widget? title,
    bool? allowBack = true,
    bool? centerTitle = true,
    Color? backgroundColor = Colors.transparent,
    Widget? leading,
    VoidCallback? onBack,
    List<Widget>? actions,
  }) {
    //Default Leading
    final defaultLeading = IconButton(
      onPressed: onBack ?? () => Navigator.pop(Get.context!),
      icon: const Icon(Ionicons.ios_chevron_back),
    );

    //Leading Widget
    final finalLeading = leading ?? (allowBack ?? true ? defaultLeading : null);

    //AppBar
    return AppBar(
      title: title,
      automaticallyImplyLeading: allowBack ?? true,
      scrolledUnderElevation: 0.0,
      backgroundColor:
          backgroundColor ?? Theme.of(Get.context!).scaffoldBackgroundColor,
      leading: finalLeading,
      centerTitle: centerTitle,
      actions: actions,
    );
  }

  ///Page Title
  static Widget pageTitle({required String title, double? textSize}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: textSize ?? 24.0,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
