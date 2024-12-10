import 'dart:io';
import 'package:flutter/cupertino.dart';
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

  ///Bottom Navigation Bar
  static Widget bottomNav({
    required int navIndex,
    required Function(int index) onChanged,
  }) {
    //Android
    if (Platform.isAndroid) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14.0)),
        child: BottomNavigationBar(
          backgroundColor: Theme.of(Get.context!).dialogBackgroundColor,
          selectedItemColor: Theme.of(Get.context!).iconTheme.color,
          currentIndex: navIndex,
          onTap: (index) {
            onChanged(index);
          },
          items: const [
            //Home
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Ionicons.ios_list_outline),
              ),
              label: "All Passwords",
            ),

            //Offline
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Ionicons.ios_grid_outline),
              ),
              label: "Groups",
            ),

            //Generate Password
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Ionicons.ios_lock_open_outline),
              ),
              label: "Generate Password",
            ),
          ],
        ),
      );
    }

    //iOS
    if (Platform.isIOS) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14.0)),
        child: CupertinoTabBar(
          activeColor: Theme.of(Get.context!).iconTheme.color,
          currentIndex: navIndex,
          onTap: (index) {
            onChanged(index);
          },
          height: 60.0,
          items: const [
            //Home
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Ionicons.ios_list_outline),
              ),
              label: "All Passwords",
            ),

            //Offline
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Ionicons.ios_grid_outline),
              ),
              label: "Groups",
            ),

            //Generate Password
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Ionicons.ios_lock_open_outline),
              ),
              label: "Generate Password",
            ),
          ],
        ),
      );
    }

    //Default
    return Container();
  }
}
