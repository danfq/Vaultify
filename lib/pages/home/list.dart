import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/route_manager.dart';
import 'package:sensitive_clipboard/sensitive_clipboard.dart';
import 'package:swipeable_button_view/swipeable_button_view.dart';
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
  /// Passwords (All Items)
  List<Map<String, dynamic>> allPasswords = [];

  /// Filtered Passwords
  ValueNotifier<List<Map>> filteredPasswords = ValueNotifier([]);

  /// Holds the current search query to reapply after new data is received
  String currentQuery = "";

  @override
  void initState() {
    super.initState();
    // Initialize the filtered list to show all passwords initially
    filteredPasswords.value = allPasswords;
  }

  /// Filter Passwords based on `query`
  void _filterPasswords(String query) {
    final parsedQuery = query.toLowerCase().trim();
    currentQuery = parsedQuery; // Store the current query

    if (parsedQuery.isEmpty) {
      filteredPasswords.value = allPasswords;
    } else {
      filteredPasswords.value = allPasswords.where((item) {
        return item["name"].toLowerCase().contains(parsedQuery);
      }).toList();
    }
  }

  /// Show Password Sheet
  Future<void> _showPasswordBottomSheet(
      BuildContext context, PasswordItem item) async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Password Name
              Text(
                item.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24.0,
                ),
              ),

              // Password Value
              Padding(
                padding: const EdgeInsets.all(40.0),
                child: Text(
                  EncryptionHandler.decodeASCII(
                    ascii: item.password,
                  ),
                ),
              ),

              // Copy to Clipboard Button
              Padding(
                padding: const EdgeInsets.all(40.0),
                child: Buttons.elevatedIcon(
                  text: "Copy to Clipboard",
                  icon: Ionicons.ios_copy_outline,
                  onTap: () async {
                    await SensitiveClipboard.copy(
                      EncryptionHandler.decodeASCII(ascii: item.password),
                    );
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

  /// Show Deletion Dialog
  void _showDeleteConfirmation(BuildContext context, PasswordItem item) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SizedBox(
          width: double.infinity,
          child: Column(
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
                  style: TextStyle(fontSize: 14.0),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(40.0),
                child: SwipeableButtonView(
                  onFinish: () {},
                  onWaitingProcess: () async {
                    //Delete Password from Database
                    await RemoteData.deleteDataByID(
                      table: "passwords",
                      id: item.id,
                    );

                    //Local Passwords
                    final List localItems =
                        LocalData.boxData(box: "passwords")["list"] ?? [];

                    //Remove Local Password
                    localItems.removeWhere(
                      (itemData) => itemData["id"] == item.id,
                    );

                    //Update Local Passwords
                    await LocalData.updateValue(
                      box: "passwords",
                      item: "list",
                      value: localItems,
                    );

                    //Close Sheet
                    Get.back();
                  },
                  activeColor: Theme.of(context).cardColor,
                  buttonWidget: const Icon(Ionicons.ios_chevron_forward,
                      color: Colors.black),
                  buttontextstyle: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium!.color,
                  ),
                  buttonText: "Swipe to Confirm",
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: CupertinoSearchTextField(
            placeholder: "Search...",
            onChanged: (query) {
              // Filter Passwords based on query
              _filterPasswords(query);
            },
          ),
        ),

        // Divider
        const Divider(
          indent: 40.0,
          endIndent: 40.0,
          thickness: 0.4,
        ),

        // Passwords List
        Expanded(
          child: StreamBuilder(
            stream: RemoteData.getData(
              table: "passwords_view",
              onNewData: (data) {
                setState(() {
                  allPasswords = data;
                  // Reapply the current search query when new data arrives
                  _filterPasswords(currentQuery);
                });
              },
            ),
            builder: (context, snapshot) {
              return ValueListenableBuilder(
                valueListenable: filteredPasswords,
                builder: (context, passwords, child) {
                  if (passwords.isEmpty) {
                    return const Center(
                      child: Text(
                        "No matching passwords found.",
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: passwords.length,
                    itemBuilder: (context, index) {
                      final item = PasswordItem.fromJSON(passwords[index]);

                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Card(
                          child: InkWell(
                            onTap: () async {
                              // Show Password Bottom Sheet
                              await _showPasswordBottomSheet(context, item);
                            },
                            borderRadius: BorderRadius.circular(14.0),
                            child: ListTile(
                              title: Text(item.name),
                              trailing: IconButton.filled(
                                onPressed: () {
                                  // Show delete confirmation modal
                                  _showDeleteConfirmation(context, item);
                                },
                                color: Theme.of(context).cardColor,
                                icon: const Icon(Ionicons.ios_trash_outline),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
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
