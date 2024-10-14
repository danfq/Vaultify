import 'package:flutter/material.dart';
import 'package:vaultify/util/models/password.dart';

///Items
class Items {
  ///Password Item
  static Widget password({
    required Password password,
    required VoidCallback onTap,
  }) {
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
          onTap: onTap,
        ),
      ),
    );
  }
}
