import 'package:flutter/material.dart';
import 'package:future_progress_dialog/future_progress_dialog.dart';
import 'package:get/route_manager.dart';
import 'package:uuid/uuid.dart';
import 'package:vaultify/util/models/group.dart';
import 'package:vaultify/util/models/password.dart';
import 'package:vaultify/util/services/account/handler.dart';
import 'package:vaultify/util/services/data/local.dart';
import 'package:vaultify/util/services/data/remote.dart';
import 'package:vaultify/util/services/groups/handler.dart';
import 'package:vaultify/util/services/toast/handler.dart';
import 'package:vaultify/util/widgets/buttons.dart';
import 'package:vaultify/util/widgets/input.dart';
import 'package:vaultify/util/widgets/main.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';

class NewItem extends StatefulWidget {
  const NewItem({super.key});

  @override
  State<NewItem> createState() => _NewItemState();
}

class _NewItemState extends State<NewItem> {
  ///Name Controller
  final TextEditingController _nameController = TextEditingController();

  ///Password Controller
  final TextEditingController _passwordController = TextEditingController();

  ///Groups
  List<Group> _groups = [];

  ///Selected Group
  Group? _selectedGroup;

  ///Get Groups
  Future<void> getGroups() async {
    await GroupsHandler.getAllGroups(onNewData: (data) {}).first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainWidgets.appBar(title: const Text("New Password")),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //Name
            Input(
              controller: _nameController,
              placeholder: "Name (e.g. Google)",
            ),

            //Password
            Input(
              controller: _passwordController,
              placeholder: "Password",
              isPassword: true,
            ),

            //Group Selection
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: CustomDropdown.search(
                hintText: "Group",
                noResultFoundText: "No Groups",
                items: _groups,
                onChanged: (group) {
                  setState(() {
                    _selectedGroup = group;
                  });
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Buttons.elevated(
          text: "Save Password",
          onTap: () async {
            //Name & Password
            final name = _nameController.text.trim();
            final password = _passwordController.text.trim();

            //Check Name, Password & Group
            if (name.isNotEmpty && password.isNotEmpty) {
              //Items
              List items = LocalData.boxData(box: "passwords")["list"] ?? [];

              //Password Item
              final passwordItem = Password(
                id: const Uuid().v4(),
                name: name,
                password: password,
              );

              //Save Password
              await showDialog(
                context: context,
                builder: (context) {
                  return FutureProgressDialog(
                    RemoteData.addData(
                      table: "passwords",
                      data: {
                        "id": passwordItem.id,
                        "name": name,
                        "password": password,
                        "uid": AccountHandler.cachedUser["id"],
                      },
                    ),
                    message: const Text("Saving..."),
                  );
                },
              ).then((success) async {
                //Check Success
                if (success) {
                  //Add Item to List
                  items.add(passwordItem.toJSON());

                  //Update Passwords List
                  await LocalData.updateValue(
                    box: "passwords",
                    item: "list",
                    value: items,
                  );

                  //Notify User
                  ToastHandler.toast(message: "Password Saved!");

                  //Return Home
                  Get.back(result: passwordItem);
                } else {
                  //Notify User
                  ToastHandler.toast(message: "Failed to Save Password");
                }
              });
            } else {
              //Notify User
              ToastHandler.toast(message: "All Fields Are Mandatory");
            }
          },
        ),
      ),
    );
  }
}
