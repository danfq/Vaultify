import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:get/route_manager.dart';
import 'package:vaultify/pages/home/list.dart';
import 'package:vaultify/pages/home/new.dart';
import 'package:vaultify/pages/settings/settings.dart';
import 'package:vaultify/util/models/item.dart';
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
          //New Item
          final newItem = await Get.to<PasswordItem?>(() => const NewItem());

          //Check New Item
          if (newItem != null) {
            //Add New Item to List
            setState(() {
              items.add(newItem.toJSON());
            });
          }
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Ionicons.ios_add),
      ),
    );
  }
}