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

      //Default - None
      default:
        return Container();
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
          onPressed: () => Get.to(() => const Settings()),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainWidgets.appBar(
        title: const Text("Vaultify"),
        centerTitle: false,
        allowBack: false,
        actions: [
          //Settings
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: IconButton(
              onPressed: () => Get.off(() => const Settings()),
              icon: const Icon(Ionicons.ios_settings_outline),
            ),
          ),
        ],
      ),
      body: SafeArea(child: _body()),
      bottomNavigationBar: MainWidgets.bottomNav(
        navIndex: _navIndex,
        onChanged: (index) {
          setState(() {
            _navIndex = index;
          });
        },
      ),
      floatingActionButton: ExpandableFab(
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
                                final groupName = nameController.text.trim();

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
      ),
    );
  }
}
