import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/route_manager.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:vaultify/util/theming/controller.dart';
import 'package:vaultify/util/widgets/main.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  ///Current Theme
  bool currentTheme = ThemeController.current(context: Get.context!);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainWidgets.appBar(title: const Text("Settings")),
      body: SafeArea(
        child: SettingsList(
          lightTheme: SettingsThemeData(
            settingsListBackground: Theme.of(context).scaffoldBackgroundColor,
          ),
          darkTheme: SettingsThemeData(
            settingsListBackground: Theme.of(context).scaffoldBackgroundColor,
          ),
          sections: [
            //UI & Visuals
            SettingsSection(
              title: const Text("UI & Visuals"),
              tiles: [
                SettingsTile.switchTile(
                  leading: Icon(
                    currentTheme ? Ionicons.ios_moon : Ionicons.ios_sunny,
                  ),
                  title: const Text("Theme Mode"),
                  initialValue: currentTheme,
                  onToggle: (mode) {
                    ThemeController.setAppearance(context: context, mode: mode);

                    setState(() {
                      currentTheme = mode;
                    });
                  },
                ),
              ],
            ),

            //Team & Licenses
            SettingsSection(
              title: const Text("Team & Licenses"),
              tiles: [
                //Team
                SettingsTile.navigation(
                  leading: const Icon(Ionicons.ios_people),
                  title: const Text("Team"),
                ),

                //Licenses
                SettingsTile.navigation(
                  leading: const Icon(Ionicons.ios_document),
                  title: const Text("Licenses"),
                  onPressed: (context) {
                    Get.to(
                      () => const LicensePage(applicationName: "Vaultify"),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
