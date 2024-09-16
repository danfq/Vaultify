import 'package:get/route_manager.dart';
import 'package:http/http.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:vaultify/util/models/group.dart';
import 'package:vaultify/util/services/account/handler.dart';
import 'package:flutter/material.dart';
import 'package:vaultify/util/widgets/buttons.dart';

///Groups Handler
class GroupsHandler {
  ///Supabase
  static final _supabase = Supabase.instance.client;

  ///Current User ID
  static final String? userID =
      AccountHandler.currentUser?.id ?? AccountHandler.cachedUser["id"];

  ///Add Group
  static Future<bool> addGroup({required String name}) async {
    //Group
    final group = {
      "id": const Uuid().v4(),
      "name": name.trim(),
      "uid": userID,
    };

    //Add Group to Database
    final added =
        (await _supabase.from("groups").insert(group).select()).isNotEmpty;

    //Return Added Status
    return added;
  }

  ///Delete Group
  static Future<bool> deleteGroup({required String groupID}) async {
    //Deleted State
    bool deleted = false;

    //Confirmation
    await Get.defaultDialog(
      title: "Are you sure?",
      content: const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          "This Group will be deleted from all your Devices.\n\nAll associated Passwords will become Group-less.",
          textAlign: TextAlign.center,
        ),
      ),
      cancel: TextButton(
        onPressed: () {
          deleted = false;
          Get.back();
        },
        child: const Text("Cancel"),
      ),
      confirm: Buttons.elevated(
        text: "Delete",
        onTap: () async {
          //Delete Group from Database
          await _supabase.from("groups").delete().eq("id", groupID);
          await _supabase
              .from("group_passwords")
              .delete()
              .eq("group_id", groupID);

          deleted = true;
          Get.back();
        },
      ),
    );

    //Return Deleted State
    return deleted;
  }

  ///Get All Groups & Corresponding Passwords
  static Stream<List<Group>> getAllGroups({
    required Function(List<Group> data) onNewData,
  }) async* {
    //Groups & Passwords
    List<Group> allGroups = [];

    //Current User ID
    final String? userID =
        AccountHandler.currentUser?.id ?? AccountHandler.cachedUser["id"];

    //All Groups
    final groups =
        await _supabase.from("groups").select().eq("uid", userID ?? "");

    //All Passwords per Group
    final groupPasswords = await _supabase
        .from("group_passwords")
        .select("group_id, password_id, uid, passwords(*)")
        .eq("uid", userID ?? "");

    //Loop Through Groups & Corresponding Passwords
    for (final group in groups) {
      //Group Passwords
      final passwords = groupPasswords
          .where((relation) => relation["group_id"] == group["id"])
          .map((relation) => relation["passwords"])
          .toList();

      //Group
      final groupObj = Group(
        id: group["id"],
        name: group["name"],
        passwords: passwords,
        uid: userID ?? "",
      );

      //Add Group to List
      allGroups.add(groupObj);
    }

    //On New Data
    onNewData(allGroups);

    //Return Groups
    yield allGroups;
  }
}
