import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/route_manager.dart';
import 'package:sensitive_clipboard/sensitive_clipboard.dart';
import 'package:vaultify/pages/home/new.dart';
import 'package:vaultify/util/models/password.dart';
import 'package:vaultify/util/services/data/remote.dart';
import 'package:vaultify/util/services/encryption/handler.dart';
import 'package:vaultify/util/services/toast/handler.dart';
import 'package:vaultify/util/widgets/buttons.dart';

///Items
class Items {
  ///Password Item
  static Widget password({required Password password}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.0),
        ),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
          title: Text(password.name),
          onTap: () => _passwordSheet(password),
        ),
      ),
    );
  }

  ///Password Sheet
  static void _passwordSheet(Password item) {
    showModalBottomSheet(
      showDragHandle: true,
      context: Get.context!,
      builder: (_) => FutureBuilder<String?>(
        future: EncryptionHandler.getKeyPairSecurely().then(
          (keys) => EncryptionHandler.decryptPassword(
            encryptedMessage: item.password,
            privateKey: EncryptionHandler.pemToPrivateKey(
              keys["privateKey"] ?? "",
            ),
          ),
        ),
        builder: (context, snapshot) {
          //Decrypted Password
          final decryptedPassword = snapshot.data;

          //UI
          return SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                //Name & Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    //Name
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        item.name,
                        style: Theme.of(Get.context!).textTheme.titleLarge,
                      ),
                    ),

                    //Actions
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          //Edit Button
                          Buttons.iconFilled(
                            icon: Ionicons.ios_pencil_outline,
                            onTap: () {
                              //Close Bottom Sheet
                              Get.back();

                              //Go to Edit Page
                              Get.to(() => NewItem(password: item));
                            },
                          ),

                          //Spacing
                          const SizedBox(width: 20.0),

                          //Delete Button
                          Buttons.iconFilled(
                            icon: Ionicons.ios_trash_outline,
                            backgroundColor: Colors.red,
                            iconColor: Colors.white,
                            onTap: () {
                              //Close Bottom Sheet
                              Get.back();

                              //Show Deletion Confirmation
                              _showDeleteConfirmation(item);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                //Decrypted Password
                Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: snapshot.connectionState == ConnectionState.waiting
                      ? const CircularProgressIndicator()
                      : Text(decryptedPassword ?? ""),
                ),

                //Copy to Clipboard Button
                Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Buttons.elevatedIcon(
                    text: "Copy to Clipboard",
                    icon: Ionicons.ios_copy_outline,
                    onTap: () async {
                      //Close Bottom Sheet
                      Get.back();

                      //Copy to Clipboard§
                      await SensitiveClipboard.copy(decryptedPassword);

                      //Notify User
                      ToastHandler.toast(message: "Copied!");
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  ///Show Deletion Confirmation
  static void _showDeleteConfirmation(Password item) {
    Get.defaultDialog(
      title: "Delete \"${item.name}?\"",
      middleText: "You won't be able to recover this Password!",
      cancel: Buttons.text(text: "Cancel", onTap: () => Get.back()),
      confirm: Buttons.elevated(
        text: "Delete",
        onTap: () async {
          //Close Dialog
          Get.back();

          //Delete Password
          await RemoteData.deleteDataByID(
            table: "passwords",
            id: item.id,
            isPassword: true,
          );

          //Notify User
          ToastHandler.toast(message: "Password Deleted!");
        },
      ),
    );
  }
}
