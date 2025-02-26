import 'dart:io';
import 'package:animated_expandable_fab/expandable_fab/action_button.dart';
import 'package:animated_expandable_fab/expandable_fab/expandable_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/route_manager.dart';
import 'package:vaultify/pages/home/import/import.dart';
import 'package:vaultify/pages/home/lists/groups.dart';
import 'package:vaultify/pages/home/lists/passwords.dart';
import 'package:vaultify/pages/home/new.dart';
import 'package:vaultify/pages/settings/profile/premium.dart';
import 'package:vaultify/pages/settings/settings.dart';
import 'package:vaultify/pages/tools/tools.dart';
import 'package:vaultify/util/services/encryption/handler.dart';
import 'package:vaultify/util/services/groups/handler.dart';
import 'package:vaultify/util/services/passwords/handler.dart';
import 'package:vaultify/util/services/toast/handler.dart';
import 'package:vaultify/util/widgets/buttons.dart';
import 'package:vaultify/util/widgets/input.dart';
import 'package:vaultify/util/widgets/main.dart';

class Vaultify extends StatefulWidget {
  const Vaultify({super.key});

  @override
  State<Vaultify> createState() => _VaultifyState();
}

class _VaultifyState extends State<Vaultify> {
  ///Current Index
  int _navIndex = 0;

  ///Body
  Widget _body() {
    switch (_navIndex) {
      //All Passwords
      case 0:
        return const PasswordsList();

      //Groups
      case 1:
        return const GroupsList();

      //Tools
      case 2:
        return const Tools();

      //Default - None
      default:
        return const SizedBox.shrink();
    }
  }

  ///Private Key
  String _privateKey = "";

  ///Get Private Key
  Future<void> getPrivateKey() async {
    //Private Key
    final privateKey = await EncryptionHandler.privateKey;

    setState(() {
      _privateKey = privateKey ?? "";
    });

    //Check if Private Key is Set
    if (_privateKey.isEmpty) {
      //Set Private Key
      notifyPrivateKeyAbsence();
    }
  }

  ///Notify User of Private Key Absence
  Future<void> notifyPrivateKeyAbsence() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Get.defaultDialog(
        barrierDismissible: false,
        title: "Hi!",
        middleText:
            "It seems like you don't have a Private Key set.\nPlease set it via the Settings.",
        confirm: ElevatedButton(
          onPressed: () {
            //Close Dialog
            Get.back();

            //Open Settings
            Get.to(() => const Settings());
          },
          child: const Text("Open Settings"),
        ),
      );
    });
  }

  @override
  void initState() {
    super.initState();

    //Get Private Key
    getPrivateKey();
  }

  // Add this method to build the drawer
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
            child: const Text(
              "Vaultify",
              style: TextStyle(
                fontSize: 24,
              ),
            ),
          ),

          //Passwords
          ListTile(
            leading: const Icon(Ionicons.ios_lock_closed_outline),
            title: const Text("Passwords"),
            selected: _navIndex == 0,
            onTap: () {
              setState(() {
                _navIndex = 0;
              });

              //Close Drawer
              Get.back();
            },
          ),

          //Groups
          ListTile(
            leading: const Icon(Ionicons.ios_grid_outline),
            title: const Text("Groups"),
            selected: _navIndex == 1,
            onTap: () {
              setState(() {
                _navIndex = 1;
              });

              //Close Drawer
              Get.back();
            },
          ),

          //Generate Password
          ListTile(
            leading: const Icon(Ionicons.ios_lock_closed_outline),
            title: const Text("Generate Password"),
            onTap: () {
              setState(() {
                _navIndex = 2;
              });

              //Close Drawer
              Get.back();
            },
          ),

          //Settings
          ListTile(
            leading: const Icon(Ionicons.ios_settings_outline),
            title: const Text("Settings"),
            onTap: () {
              //Close Drawer
              Get.back();

              //Open Settings
              Get.to(() => const Settings());
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    //Check if Mobile
    final isMobile = Platform.isIOS || Platform.isAndroid;

    //UI
    return Scaffold(
      appBar: MainWidgets.appBar(
        title: const Text("Vaultify"),
        centerTitle: false,
        allowBack: false,
        leading: !isMobile
            ? Builder(
                builder: (context) => Buttons.icon(
                  icon: Ionicons.ios_menu_outline,
                  onTap: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
              )
            : null,
        actions: [
          if (isMobile)
            Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: IconButton(
                onPressed: () => Get.to(() => const Settings()),
                icon: const Icon(Ionicons.ios_settings_outline),
              ),
            ),
        ],
      ),
      drawer: !isMobile ? _buildDrawer() : null,
      body: SafeArea(child: _body()),
      bottomNavigationBar: isMobile
          ? MainWidgets.bottomNav(
              navIndex: _navIndex,
              onChanged: (index) {
                setState(() {
                  _navIndex = index;
                });
              },
            )
          : null,
      floatingActionButton: _navIndex != 2
          ? ExpandableFab(
              distance: 100.0,
              openIcon: const Icon(Ionicons.ios_add, color: Colors.white),
              closeIcon: const Icon(Ionicons.ios_close_outline),
              children: [
                //Import from File
                ActionButton(
                  icon: const Icon(
                    Ionicons.ios_download_outline,
                    color: Colors.white,
                  ),
                  onPressed: () async {
                    await Get.to(() => const ImportFromFile())!.then(
                      (_) => setState(() {}),
                    );
                  },
                ),

                //New Password
                ActionButton(
                  icon: const Icon(
                    Ionicons.ios_lock_closed_outline,
                    color: Colors.white,
                  ),
                  onPressed: () async {
                    //Hit Max Passwords
                    final hitMax = await PasswordsHandler.hitMax();

                    //Check Max Items or Premium (Infinite Items)
                    if (!hitMax) {
                      //New Item
                      Get.to(() => const NewItem());
                    } else {
                      //Notify User
                      await Get.defaultDialog(
                        title: "Oops!",
                        content: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "You've reached the maximum Password limit.\n\nTo unlock an infinite amount, please pay the Premium one-time fee of 5€.",
                          ),
                        ),
                        cancel: TextButton(
                          onPressed: () => Get.back(),
                          child: const Text("Cancel"),
                        ),
                        confirm: ElevatedButton(
                          onPressed: () {
                            Get.back();
                            Get.to(() => const GetPremium());
                          },
                          child: const Text("Get Premium"),
                        ),
                      );
                    }
                  },
                ),

                //New Group
                ActionButton(
                  icon: const Icon(
                    Ionicons.ios_grid_outline,
                    color: Colors.white,
                  ),
                  onPressed: () async {
                    //Show New Group Sheet
                    await showModalBottomSheet(
                      context: context,
                      showDragHandle: true,
                      isScrollControlled: true,
                      builder: (context) {
                        //New Group Name Controller
                        final nameController = TextEditingController();

                        //UI
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                //Title
                                const Text(
                                  "New Group",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24.0,
                                  ),
                                ),

                                //Group Name
                                Input(
                                  controller: nameController,
                                  placeholder: "Group Name",
                                ),

                                //Save Group
                                Padding(
                                  padding: const EdgeInsets.all(40.0),
                                  child: Buttons.elevatedIcon(
                                    text: "Add Group",
                                    icon: Ionicons.ios_add,
                                    onTap: () async {
                                      //Group Name
                                      final groupName =
                                          nameController.text.trim();

                                      //Check Group Name
                                      if (groupName.isNotEmpty) {
                                        //Add Group
                                        await GroupsHandler.addGroup(
                                          name: groupName,
                                        ).then(
                                          (added) {
                                            if (added != null) {
                                              ToastHandler.toast(
                                                message: "'$groupName' Added!",
                                              );
                                            } else {
                                              ToastHandler.toast(
                                                message: "Failed to Add",
                                              );
                                            }
                                          },
                                        );
                                      }

                                      //Close Sheet
                                      Get.back();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            )
          : null,
    );
  }
}
