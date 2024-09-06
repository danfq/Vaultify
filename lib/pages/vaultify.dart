import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/route_manager.dart';
import 'package:vaultify/pages/home/list.dart';
import 'package:vaultify/pages/home/new.dart';
import 'package:vaultify/pages/settings/premium/premium.dart';
import 'package:vaultify/pages/settings/settings.dart';
import 'package:vaultify/util/models/item.dart';
import 'package:vaultify/util/services/account/premium.dart';
import 'package:vaultify/util/services/data/env.dart';
import 'package:vaultify/util/services/data/local.dart';
import 'package:vaultify/util/widgets/main.dart';

class Vaultify extends StatefulWidget {
  const Vaultify({super.key});

  @override
  State<Vaultify> createState() => _VaultifyState();
}

class _VaultifyState extends State<Vaultify> {
  ///Items
  List items = LocalData.boxData(box: "passwords")["list"] ?? [];

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
      body: const SafeArea(child: ItemsList()),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          //Premium Status
          final premium = await PremiumHandler.checkPremium();

          //Max Items
          final int maxItems = int.parse(EnvVars.get(name: "MAX_ITEMS"));

          //Number of Items
          final List items = LocalData.boxData(box: "passwords")["list"] ?? [];

          //Check Premium
          if (items.length < maxItems) {
            //New Item
            final newItem = await Get.to<PasswordItem?>(() => const NewItem());

            //Check New Item
            if (newItem != null) {
              //Add New Item to List
              setState(() {
                items.add(newItem.toJSON());
              });
            }
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
                child: const Text("Pay"),
              ),
            );
          }
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Ionicons.ios_add),
      ),
    );
  }
}
