import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/route_manager.dart';
import 'package:local_auth/local_auth.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:vaultify/pages/settings/premium/premium.dart';
import 'package:vaultify/util/services/data/local.dart';
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

  ///Bio Lock
  bool bioLock = LocalData.boxData(box: "security")["bio_lock"] ?? false;

  ///Biometric Support
  bool? bioSupport;

  ///Check Biometric Support
  Future<void> checkBioSupport() async {
    //Biometric Support
    final support = await LocalAuthentication().isDeviceSupported();

    //Set Support
    setState(() {
      bioSupport = support;
    });
  }

  @override
  void initState() {
    super.initState();

    //Check Biometric Support
    checkBioSupport();
  }

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

            //Security
            SettingsSection(
              title: const Text("Security"),
              tiles: [
                //Biometric Lock
                SettingsTile.switchTile(
                  enabled: bioSupport ?? false,
                  leading: const Icon(Ionicons.finger_print),
                  initialValue: bioLock,
                  onToggle: (context) {
                    //Update UI
                    setState(() {
                      bioLock = !bioLock;
                    });

                    //Set Bio Lock Status
                    LocalData.updateValue(
                      box: "security",
                      item: "bio_lock",
                      value: bioLock,
                    );
                  },
                  title: const Text("Biometric Lock"),
                ),
              ],
            ),

            //Premium
            SettingsSection(
              title: const Text("Premium"),
              tiles: [
                //Vaultify Premium
                SettingsTile.navigation(
                  leading: const Icon(Ionicons.shield),
                  title: const Text("Vaultify Premium"),
                  onPressed: (context) => Get.to(() => const GetPremium()),
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
