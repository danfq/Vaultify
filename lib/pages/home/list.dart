import 'package:flutter/material.dart';
import 'package:vaultify/util/models/item.dart';
import 'package:vaultify/util/services/data/local.dart';

class ItemsList extends StatelessWidget {
  const ItemsList({super.key});

  @override
  Widget build(BuildContext context) {
    //Items
    final List items = LocalData.boxData(box: "passwords")["list"] ?? [];

    //UI
    return items.isNotEmpty
        ? ListView.builder(
            itemBuilder: (context, index) {
              //Item
              final item = PasswordItem.fromJSON(items[index]);

              //UI
              return ListTile(title: Text(item.name));
            },
          )
        : const Center(
            child: Text(
              "No Passwords\nAdd One By Tapping +",
              textAlign: TextAlign.center,
            ),
          );
  }
}
