import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/route_manager.dart';
import 'package:sensitive_clipboard/sensitive_clipboard.dart';
import 'package:vaultify/util/models/item.dart';
import 'package:vaultify/util/services/data/local.dart';
import 'package:vaultify/util/services/data/remote.dart';
import 'package:vaultify/util/services/encryption/handler.dart';
import 'package:vaultify/util/services/toast/handler.dart';
import 'package:vaultify/util/widgets/buttons.dart';

class ItemsList extends StatefulWidget {
  const ItemsList({super.key});

  @override
  State<ItemsList> createState() => _ItemsListState();
}

class _ItemsListState extends State<ItemsList> {
  ///Passwords
  List<dynamic> passwords = [];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: RemoteData.getData(
        table: "passwords_view",
        onNewData: (data) {
          setState(() {
            passwords = data;
          });
        },
      ),
      builder: (context, snapshot) {
        return passwords.isNotEmpty
            ? ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: passwords.length,
                itemBuilder: (context, index) {
                  final item = PasswordItem.fromJSON(passwords[index]);

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      child: InkWell(
                        onTap: () async {
                          //Show Password Bottom Sheet
                          await showModalBottomSheet(
                            context: context,
                            showDragHandle: true,
                            builder: (context) {
                              return SizedBox(
                                width: double.infinity,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    //Password Name
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24.0,
                                      ),
                                    ),

                                    //Password
                                    Padding(
                                      padding: const EdgeInsets.all(40.0),
                                      child: Text(
                                        EncryptionHandler.decodeASCII(
                                          ascii: item.password,
                                        ),
                                      ),
                                    ),

                                    //Copy To Clipboard
                                    Padding(
                                      padding: const EdgeInsets.all(40.0),
                                      child: Buttons.elevatedIcon(
                                        text: "Copy to Clipboard",
                                        icon: Ionicons.ios_copy_outline,
                                        onTap: () async {
                                          //Copy to Clipboard
                                          await SensitiveClipboard.copy(
                                            EncryptionHandler.decodeASCII(
                                              ascii: item.password,
                                            ),
                                          );

                                          //Close Sheet
                                          Get.back();

                                          //Notify User
                                          ToastHandler.toast(
                                            message: "Copied!",
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        borderRadius: BorderRadius.circular(14.0),
                        child: ListTile(title: Text(item.name)),
                      ),
                    ),
                  );
                },
              )
            : const Center(
                child: Text(
                  "You Have No Passwords\nTap + To Add One",
                  textAlign: TextAlign.center,
                ),
              );
      },
    );
  }
}
