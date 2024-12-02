import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/route_manager.dart';
import 'package:sensitive_clipboard/sensitive_clipboard.dart';
import 'package:swipeable_button_view/swipeable_button_view.dart';
import 'package:vaultify/pages/home/new.dart';
import 'package:vaultify/util/models/password.dart';
import 'package:vaultify/util/services/anim/handler.dart';
import 'package:vaultify/util/services/data/local.dart';
import 'package:vaultify/util/services/data/remote.dart';
import 'package:vaultify/util/services/encryption/handler.dart';
import 'package:vaultify/util/services/toast/handler.dart';
import 'package:vaultify/util/widgets/buttons.dart';
import 'package:vaultify/util/widgets/items.dart';

class PasswordsList extends StatefulWidget {
  const PasswordsList({super.key});

  @override
  State<PasswordsList> createState() => _PasswordsListState();
}

class _PasswordsListState extends State<PasswordsList> {
  ///All Passwords
  List<Map<String, dynamic>> allPasswords =
      LocalData.boxData(box: "passwords")["list"] ?? [];

  ///Filtered Passwords
  ValueNotifier<List<Map>> filteredPasswords = ValueNotifier([]);

  ///Current Query
  String currentQuery = "";

  /// Key for AnimatedList
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    filteredPasswords.value = allPasswords;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_listKey.currentState != null) {
        setState(() {});
      }
    });
  }

  ///Filter Passwords
  void _filterPasswords(String query) {
    currentQuery = query.toLowerCase().trim();
    filteredPasswords.value = currentQuery.isEmpty
        ? allPasswords
        : allPasswords.where((item) {
            return item["name"].toLowerCase().contains(currentQuery);
          }).toList();
  }

  ///Build Password Tile
  Widget _buildListTile(BuildContext context, Password item, int index) {
    return Items.password(
      password: item,
      onTap: () => _showPasswordBottomSheet(context, item, index),
    );
  }

  ///Show Password Sheet
  Future<void> _showPasswordBottomSheet(
    BuildContext context,
    Password item,
    int index,
  ) async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => _passwordSheetContent(item, index),
    );
  }

  ///Password Sheet Content
  Widget _passwordSheetContent(Password item, int index) {
    return FutureBuilder<String>(
      future: Future.wait<dynamic>([
        EncryptionHandler.privateKey,
        Future.value(item.password),
      ]).then((values) async {
        //Private Key
        final privateKey = EncryptionHandler.pemToPrivateKey(values[0]);

        //Encrypted Password
        final encryptedPassword = values[1];

        //Decrypt Password
        return await EncryptionHandler.decryptPassword(
          encryptedMessage: encryptedPassword,
          privateKey: privateKey,
        );
      }),
      builder: (context, snapshot) {
        //Decoded Password
        final decodedPassword = snapshot.data ?? "";

        //UI
        return SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              //Name & Edit & Delete
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    //Name
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24.0,
                      ),
                    ),

                    //Edit & Delete
                    Row(
                      children: [
                        //Edit
                        Buttons.iconFilled(
                          icon: Ionicons.ios_pencil_outline,
                          onTap: () {
                            Get.back();
                            Get.to(
                              () => NewItem(
                                password: Password(
                                  id: item.id,
                                  name: item.name,
                                  password: decodedPassword,
                                ),
                              ),
                            );
                          },
                        ),

                        //Delete
                        Buttons.iconFilled(
                          icon: Ionicons.ios_trash_bin_outline,
                          backgroundColor: Colors.red,
                          onTap: () {
                            //Close Sheet
                            Get.back();

                            //Deletion Confirmation
                            _showDeleteConfirmation(context, item, index);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              //Password
              Padding(
                padding: const EdgeInsets.all(40.0),
                child: Text(decodedPassword),
              ),

              //Copy to Clipboard
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
      },
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
            activeColor: Theme.of(context).cardColor,
            buttonWidget: const Icon(
              Ionicons.ios_chevron_forward,
              color: Colors.black,
            ),
            buttonText: "Swipe to Confirm",
            buttontextstyle: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  ///Delete Password
  Future<void> _deletePassword(Password item, int index) async {
    //Delete from Database
    await RemoteData.deleteDataByID(
      table: "passwords",
      id: item.id,
      isPassword: true,
    );

    //Delete Local Password
    final int removeIndex =
        allPasswords.indexWhere((data) => data["id"] == item.id);
    if (removeIndex >= 0) {
      allPasswords.removeAt(removeIndex);
      filteredPasswords.value = List.from(allPasswords);

      // Animate removal from the AnimatedList using fade
      _listKey.currentState?.removeItem(
        index,
        (context, animation) => FadeTransition(
          opacity: animation,
          child: _buildListTile(context, item, index),
        ),
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: CupertinoSearchTextField(
            placeholder: "Search...",
            onChanged: _filterPasswords,
          ),
        ),
        const Divider(indent: 40.0, endIndent: 40.0, thickness: 0.4),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: RemoteData.getData(
              table: "passwords",
              onNewData: (data) {
                setState(() {
                  allPasswords = data;
                  _filterPasswords(currentQuery);
                });
              },
            ),
            builder: (context, snapshot) {
              // Show empty container while loading
              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }

              return ValueListenableBuilder(
                valueListenable: filteredPasswords,
                builder: (context, passwords, _) {
                  // Show empty animation only if we have data but passwords list is empty
                  if (passwords.isEmpty && allPasswords.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimHandler.asset(
                            animation: "empty",
                            reverse: true,
                          ),
                          const Text(
                            "No Passwords\nAdd One by Tapping +",
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 500),
                    tween: Tween(begin: 1.0, end: 0.0),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 50 * value),
                        child: Opacity(
                          opacity: 1 - value,
                          child: child,
                        ),
                      );
                    },
                    child: AnimatedList(
                      key: _listKey,
                      physics: const BouncingScrollPhysics(),
                      initialItemCount: passwords.length,
                      itemBuilder: (context, index, animation) {
                        if (index >= passwords.length) {
                          return const SizedBox.shrink();
                        }
                        final item = Password.fromJSON(passwords[index]);
                        return FadeTransition(
                          opacity: animation,
                          child: _buildListTile(context, item, index),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
