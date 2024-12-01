import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/route_manager.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:vaultify/pages/security/import_key.dart';
import 'package:vaultify/pages/settings/profile/info.dart';
import 'package:vaultify/pages/settings/profile/premium.dart';
import 'package:vaultify/pages/settings/team/team.dart';
import 'package:vaultify/util/services/data/local.dart';
import 'package:vaultify/util/services/encryption/handler.dart';
import 'package:vaultify/util/services/toast/handler.dart';
import 'package:vaultify/util/theming/controller.dart';
import 'package:vaultify/util/widgets/buttons.dart';
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

  ///Package Info
  PackageInfo? packageInfo;

  ///Check Biometric Support
  Future<void> checkBioSupport() async {
    //Biometric Support
    final support = await LocalAuthentication().isDeviceSupported();

    //Set Support
    setState(() {
      bioSupport = support;
    });
  }

  ///Set Package Info
  Future<void> setPackageInfo() async {
    //Package Info
    final info = await PackageInfo.fromPlatform();

    //Set Package Info
    packageInfo = info;
  }

  @override
  void initState() {
    super.initState();

    //Check Biometric Support
    checkBioSupport();

    //Set Package Info
    setPackageInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainWidgets.appBar(title: const Text("Settings")),
      body: SafeArea(
        child: SettingsList(
          physics: const BouncingScrollPhysics(),
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

                //Import Private Key
                SettingsTile.navigation(
                  leading: const Icon(Ionicons.ios_key_outline),
                  title: const Text("Import Private Key"),
                  onPressed: (context) => Get.to(
                    () => const ImportKey(),
                  ),
                ),

                //Export Private Key
                SettingsTile.navigation(
                  leading: const Icon(Ionicons.ios_cloud_upload_outline),
                  title: const Text("Export Private Key"),
                  onPressed: (context) {
                    //Show Export Key Dialog
                    Get.defaultDialog(
                      title: "Export Private Key",
                      middleText:
                          "Export your Private Key to a file for backup or transfer.",
                      cancel: Buttons.text(
                        text: "Cancel",
                        onTap: () => Get.back(),
                      ),
                      confirm: Buttons.elevated(
                        text: "Export",
                        onTap: () async {
                          try {
                            //Close Dialog
                            Get.back();

                            //Show Loading Dialog
                            Get.dialog(
                              const Center(
                                child: CircularProgressIndicator(),
                              ),
                              barrierDismissible: false,
                            );

                            //Export Key
                            final exported =
                                await EncryptionHandler.exportKey();

                            //Close Loading Dialog
                            Get.back();

                            //Check if Exported
                            if (!exported) return;

                            //Notify User
                            ToastHandler.toast(
                              message: "Private Key Exported Successfully!",
                            );
                          } catch (e) {
                            //Close Loading Dialog if it's showing
                            if (Get.isDialogOpen ?? false) {
                              Get.back();
                            }

                            //Show Error
                            ToastHandler.toast(
                              message:
                                  "Error exporting Private Key: ${e.toString()}",
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ],
            ),

            //Profile
            SettingsSection(
              title: const Text("Profile"),
              tiles: [
                //Information
                SettingsTile.navigation(
                  leading: const Icon(Ionicons.ios_person),
                  title: const Text("Information"),
                  onPressed: (context) => Get.to(() => const ProfileInfo()),
                ),

                //Vaultify Premium
                SettingsTile.navigation(
                  leading: const Icon(Ionicons.ios_shield),
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
                  onPressed: (context) => Get.to(() => const Team()),
                ),

                //Licenses
                SettingsTile.navigation(
                  leading: const Icon(Ionicons.ios_document),
                  title: const Text("Licenses"),
                  onPressed: (context) {
                    Get.to(
                      () => LicensePage(
                        applicationName: packageInfo?.appName,
                        applicationVersion: packageInfo?.version,
                        applicationIcon: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14.0),
                            child: Image.asset("assets/logo.png", height: 80.0),
                          ),
                        ),
                      ),
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
