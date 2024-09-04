import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/route_manager.dart';
import 'package:sensitive_clipboard/sensitive_clipboard.dart';
import 'package:swipeable_button_view/swipeable_button_view.dart';
import 'package:vaultify/util/models/item.dart';
import 'package:vaultify/util/services/data/remote.dart';
import 'package:vaultify/util/services/encryption/handler.dart';
import 'package:vaultify/util/services/toast/handler.dart';
import 'package:vaultify/util/theming/controller.dart';
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
                        child: ListTile(
                          title: Text(item.name),
                          trailing: IconButton.filled(
                            onPressed: () {
                              //Swipe to Confirm
                              showModalBottomSheet(
                                context: context,
                                showDragHandle: true,
                                builder: (context) {
                                  return SizedBox(
                                    width: double.infinity,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        //Title
                                        const Text(
                                          "Delete Password",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 24.0,
                                          ),
                                        ),

                                        //Subtitle
                                        const Padding(
                                          padding: EdgeInsets.all(20.0),
                                          child: Text(
                                            "This Password will be deleted from all your devices.",
                                            style: TextStyle(fontSize: 14.0),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),

                                        //Swipe to Confirm
                                        Padding(
                                          padding: const EdgeInsets.all(40.0),
                                          child: SwipeableButtonView(
                                            onFinish: () {},
                                            onWaitingProcess: () async {
                                              //Delete Item
                                              await RemoteData.deleteDataByID(
                                                table: "passwords",
                                                id: item.id,
                                              );

                                              //Close Sheet
                                              Get.back();
                                            },
                                            activeColor:
                                                Theme.of(context).cardColor,
                                            buttonWidget: const Icon(
                                              Ionicons.ios_chevron_forward,
                                              color: Colors.black,
                                            ),
                                            buttontextstyle: TextStyle(
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium!
                                                  .color,
                                            ),
                                            buttonText: "Swipe to Confirm",
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            color: Theme.of(context).cardColor,
                            icon: const Icon(Ionicons.ios_trash_outline),
                          ),
                        ),
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
