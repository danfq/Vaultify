import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/route_manager.dart';
import 'package:sensitive_clipboard/sensitive_clipboard.dart';
import 'package:swipeable_button_view/swipeable_button_view.dart';
import 'package:vaultify/util/models/password.dart';
import 'package:vaultify/util/services/anim/handler.dart';
import 'package:vaultify/util/services/data/remote.dart';
import 'package:vaultify/util/services/encryption/handler.dart';
import 'package:vaultify/util/services/toast/handler.dart';
import 'package:vaultify/util/widgets/buttons.dart';
import 'package:vaultify/util/widgets/items.dart';
import 'package:vaultify/util/widgets/main.dart';

class GroupPasswords extends StatefulWidget {
  const GroupPasswords({
    super.key,
    required this.groupName,
    required this.passwords,
  });

  ///Group Name
  final String groupName;

  ///Passwords
  final List<Password> passwords;

  @override
  State<GroupPasswords> createState() => _GroupPasswordsState();
}

class _GroupPasswordsState extends State<GroupPasswords> {
  ///Build Password Tile
  Widget _buildListTile(BuildContext context, Password item, int index) {
    return Items.password(
      password: item,
      onTap: () => _showPasswordBottomSheet(context, item),
    );
  }

  ///Show Password Sheet
  Future<void> _showPasswordBottomSheet(
      BuildContext context, Password item) async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => _passwordSheetContent(item),
    );
  }

  ///Password Sheet Content
  Widget _passwordSheetContent(Password item) {
    //Decoded Password
    final decodedPassword = EncryptionHandler.decodeASCII(ascii: item.password);

    //UI
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24.0),
          ),
          Padding(
            padding: const EdgeInsets.all(40.0),
            child: Text(decodedPassword ?? ""),
          ),
          Padding(
            padding: const EdgeInsets.all(40.0),
            child: Buttons.elevatedIcon(
              text: "Copy to Clipboard",
              icon: Ionicons.ios_copy_outline,
              onTap: () async {
                await SensitiveClipboard.copy(decodedPassword);
                Get.back();
                ToastHandler.toast(message: "Copied!");
              },
            ),
          ),
        ],
      ),
    );
  }

  ///Delete Confirmation
  void _showDeleteConfirmation(BuildContext context, Password item, int index) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => _deleteConfirmationSheet(item, index),
    );
  }

  ///Delete Confirmation Sheet
  Widget _deleteConfirmationSheet(Password item, int index) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "Delete Password",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24.0),
        ),
        const Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            "This Password will be deleted from all your devices.",
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(40.0),
          child: SwipeableButtonView(
            onFinish: () {},
            onWaitingProcess: () async {
              //Delete Item
              await _deletePassword(item, index);

              //Close Sheet
              Get.back();
            },
            activeColor: Theme.of(Get.context!).cardColor,
            buttonWidget: const Icon(
              Ionicons.ios_chevron_forward,
              color: Colors.black,
            ),
            buttonText: "Swipe to Confirm",
            buttontextstyle: Theme.of(Get.context!).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  ///Delete Password
  Future<void> _deletePassword(Password item, int index) async {
    //Delete from Database
    await RemoteData.deleteDataByID(table: "passwords", id: item.id);

    //Delete Local Password
    setState(() {
      widget.passwords.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainWidgets.appBar(
        title: Text(widget.groupName),
      ),
      body: SafeArea(
        child: widget.passwords.isNotEmpty
            ? ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: widget.passwords.length,
                itemBuilder: (context, index) {
                  //Password
                  final password = widget.passwords[index];

                  //UI
                  return _buildListTile(context, password, index);
                },
              )
            : Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimHandler.asset(animation: "empty", reverse: true),
                    const Text("No Passwords"),
                  ],
                ),
              ),
      ),
    );
  }
}
