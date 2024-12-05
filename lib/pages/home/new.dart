import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:future_progress_dialog/future_progress_dialog.dart';
import 'package:get/route_manager.dart';
import 'package:uuid/uuid.dart';
import 'package:vaultify/util/models/group.dart';
import 'package:vaultify/util/models/password.dart';
import 'package:vaultify/util/services/encryption/handler.dart';
import 'package:vaultify/util/services/groups/handler.dart';
import 'package:vaultify/util/services/passwords/handler.dart';
import 'package:vaultify/util/services/passwords/strength.dart';
import 'package:vaultify/util/services/toast/handler.dart';
import 'package:vaultify/util/widgets/buttons.dart';
import 'package:vaultify/util/widgets/input.dart';
import 'package:vaultify/util/widgets/main.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';

class NewItem extends StatefulWidget {
  const NewItem({super.key, this.password});

  ///Item
  final Password? password;

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

  ///Password
  Password? _password;

  ///Get Groups
  Future<void> _getGroups() async {
    await GroupsHandler.getAllGroups(onNewData: (data) {
      //Set Groups
      setState(() {
        _groups = data;
      });
    }).first;
  }

  ///Get Matching Group for Password
  Future<void> _getMatchingGroup(String? passwordID) async {
    //Matching Group
    final matGroup = await GroupsHandler.getPasswordGroup(
      passwordID: passwordID ?? "",
    );

    //Set Group
    setState(() {
      _selectedGroup = matGroup;
    });
  }

  ///Check Password
  Future<void> _checkPassword() async {
    //Password
    final password = widget.password;

    //Check if Password was Passed On
    if (password != null) {
      //Set Password Data
      setState(() {
        _password = password;
      });

      //Get Matching Group
      await _getMatchingGroup(_password?.id);
    }
  }

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing password data if editing
    if (widget.password != null) {
      _nameController.text = widget.password!.name;
      _passwordController.text = widget.password!.password;
    }

    //Get Groups
    _getGroups();

    //Check Password
    _checkPassword();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainWidgets.appBar(
        title: const Text("Password"),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //Name
            Input(
              controller: _nameController,
              placeholder: _password?.name ?? "Name (e.g. Google)",
            ),

            //Password
            Input(
              controller: _passwordController,
              placeholder: _password?.password ?? "Password",
              isPassword: true,
              onChanged: (value) {
                //Check Strength
                setState(() {});
              },
            ),

            //Strength Indicator
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: PasswordStrengthIndicator(
                strength: StrengthHandler.isStrong(
                  _passwordController.text.trim(),
                ),
              ),
            ),

            //Group Selection
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: CustomDropdown.search(
                decoration: const CustomDropdownDecoration(
                  listItemStyle: TextStyle(color: Colors.black),
                  hintStyle: TextStyle(color: Colors.black),
                  noResultFoundStyle: TextStyle(color: Colors.black),
                  headerStyle: TextStyle(color: Colors.black),
                  searchFieldDecoration: SearchFieldDecoration(
                    prefixIcon: Icon(
                      Ionicons.ios_search_outline,
                      color: Colors.black,
                    ),
                    hintStyle: TextStyle(color: Colors.black),
                    textStyle: TextStyle(color: Colors.black),
                  ),
                ),
                hintText: _selectedGroup?.name ?? "Group",
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

            // If editing existing password, use existing values for empty fields
            if (_password != null) {
              final updatedPassword = Password(
                id: _password!.id,
                name: name.isEmpty ? _password!.name : name,
                password: password.isEmpty ? _password!.password : password,
              );

              //Save Password
              await showDialog(
                context: context,
                builder: (context) {
                  return FutureProgressDialog(
                    PasswordsHandler.updateByID(
                      password: updatedPassword,
                      group: _selectedGroup,
                    ),
                    message: const Text("Saving..."),
                  );
                },
              ).then((success) async {
                if (success ?? false) {
                  ToastHandler.toast(message: "Password Updated!");
                  Get.back(result: updatedPassword);
                } else {
                  ToastHandler.toast(message: "Failed to Update Password");
                }
              });
            } else {
              // Handle new password creation (requires all fields)
              if (name.isNotEmpty && password.isNotEmpty) {
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
                      _selectedGroup != null
                          ? _password == null
                              ? PasswordsHandler.addWithGroup(
                                  password: passwordItem,
                                  groupID: _selectedGroup!.id,
                                )
                              : PasswordsHandler.updateByID(
                                  password: passwordItem,
                                  group: _selectedGroup,
                                )
                          : _password == null
                              ? PasswordsHandler.add(password: passwordItem)
                              : PasswordsHandler.updateByID(
                                  password: passwordItem,
                                ),
                      message: const Text("Saving..."),
                    );
                  },
                ).then((success) async {
                  //Check Success
                  if (success ?? false) {
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
            }
          },
        ),
      ),
    );
  }
}

Future<void> ensureKeyPairExists() async {
  final publicKey = await EncryptionHandler.publicKey;
  final privateKey = await EncryptionHandler.privateKey;

  if (publicKey == null || privateKey == null) {
    // Generate new key pair
    final keyPair = await EncryptionHandler.generateKeyPair();
    await EncryptionHandler.saveKeyPairSecurely(
      publicKey: keyPair['publicKey']!,
      privateKey: keyPair['privateKey']!,
    );
  }
}
