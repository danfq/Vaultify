import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:future_progress_dialog/future_progress_dialog.dart';
import 'package:get/route_manager.dart';
import 'package:vaultify/pages/home/lists/groups.dart';
import 'package:vaultify/pages/home/lists/passwords.dart';
import 'package:vaultify/pages/home/new.dart';
import 'package:vaultify/pages/settings/premium/premium.dart';
import 'package:vaultify/pages/settings/settings.dart';
import 'package:vaultify/util/services/account/premium.dart';
import 'package:vaultify/util/services/data/env.dart';
import 'package:vaultify/util/services/data/local.dart';
import 'package:vaultify/util/services/groups/handler.dart';
import 'package:vaultify/util/services/toast/handler.dart';
import 'package:vaultify/util/widgets/buttons.dart';
import 'package:vaultify/util/widgets/input.dart';
import 'package:vaultify/util/widgets/main.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

class Vaultify extends StatefulWidget {
  const Vaultify({super.key});

  @override
  State<Vaultify> createState() => _VaultifyState();
}

class _VaultifyState extends State<Vaultify> {
  ///Items
  final List<Map> _items = LocalData.boxData(box: "passwords")["list"] ?? [];

  ///Current Index
  int _navIndex = 0;

  ///Body
  Widget body() {
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
              onPressed: () => Get.to(() => const Settings()),
              icon: const Icon(Ionicons.ios_settings_outline),
            ),
          ),
        ],
      ),
      body: SafeArea(child: body()),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14.0)),
        child: SalomonBottomBar(
          backgroundColor: Theme.of(context).dialogBackgroundColor,
          selectedItemColor: Theme.of(context).iconTheme.color,
          currentIndex: _navIndex,
          onTap: (index) {
            setState(() {
              _navIndex = index;
            });
          },
          items: [
            SalomonBottomBarItem(
              icon: const Icon(Ionicons.ios_list_outline),
              title: const Text("All Passwords"),
            ),
            SalomonBottomBarItem(
              icon: const Icon(Ionicons.ios_grid_outline),
              title: const Text("Groups"),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navIndex == 0
            ? () async {
                //Premium Status
                final premium = await PremiumHandler.checkPremium();

                //Max Items
                final int maxItems = int.parse(EnvVars.get(name: "MAX_ITEMS"));

                //Check Max Items or Premium (Infinite Items)
                if (_items.length < maxItems || premium) {
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
              }
            : () async {
                //Show New Group Sheet
                await showModalBottomSheet(
                  context: context,
                  showDragHandle: true,
                  builder: (context) {
                    //New Group Name Controller
                    final nameController = TextEditingController();

                    //UI
                    return SizedBox(
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
                                      if (added) {
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
                    );
                  },
                );
              },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Ionicons.ios_add),
      ),
    );
  }
}
