import 'dart:io';
import 'package:get/route_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:vaultify/pages/vaultify.dart';

///Tray Handler
class TrayHandler with TrayListener {
  ///Initialize Tray Service
  static Future<void> init() async {
    //Register Tray Listener
    trayManager.addListener(TrayHandler());

    //Set Icon
    await trayManager.setIcon(
      Platform.isWindows ? "assets/tray.ico" : "assets/tray.png",
    );

    //Menu
    final menu = Menu(
      items: [
        //Open App
        MenuItem(
          key: "show_app",
          label: "Open App",
          onClick: (item) => Get.to(() => const Vaultify()),
        ),

        //Separator
        MenuItem.separator(),

        //Quit App
        MenuItem(
          key: "quit_app",
          label: "Quit",
          onClick: (item) => exit(0),
        ),
      ],
    );

    //Set Menu
    await trayManager.setContextMenu(menu);
  }

  @override
  void onTrayIconMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }
}
