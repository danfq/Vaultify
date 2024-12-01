import 'dart:async';
import 'package:get/route_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:vaultify/util/models/group.dart';
import 'package:vaultify/util/models/password.dart';
import 'package:vaultify/util/services/account/handler.dart';
import 'package:flutter/material.dart';
import 'package:vaultify/util/widgets/buttons.dart';

class GroupsHandler {
  ///Supabase
  static final _supabase = Supabase.instance.client;

  ///Current User
  static final _currentUserID =
      AccountHandler.currentUser?.id ?? AccountHandler.cachedUser["id"];

  ///Get Group by ID
  static Future<Group> getByID({required String id}) async {
    //Matching Group
    final matGroup =
        (await _supabase.from("groups").select().eq("id", id).limit(1))[0];

    //Parse Group
    final group = Group(
      id: id,
      name: matGroup["name"],
      uid: matGroup["uid"],
    );

    //Return Group
    return group;
  }

  ///Get Password Group
  static Future<Group?> getPasswordGroup({
    required String passwordID,
  }) async {
    //Get Relationship
    final matRel = (await _supabase
        .from("group_passwords")
        .select()
        .eq("password_id", passwordID)
        .limit(1));

    //Check Matching Relationship
    if (matRel.isNotEmpty) {
      //Get Matching Group
      final matGroup = await getByID(id: matRel[0]["group_id"]);

      //Return Group
      return matGroup;
    }

    //Return Null
    return null;
  }

  ///Get All Groups & Respective Passwords
  static Stream<List<Group?>> getAllGroups({
    required Function(List<Group> data) onNewData,
  }) {
    final currentUserID =
        AccountHandler.currentUser?.id ?? AccountHandler.cachedUser["id"];

    if (currentUserID == null) {
      return Stream.value([]);
    }

    return _supabase
        .from("groups")
        .stream(primaryKey: ["id"])
        .eq("uid", currentUserID)
        .asyncMap((groupsData) async {
          if (groupsData.isEmpty) {
            onNewData([]);
            return [];
          }

          final groupsMap = <String, Group>{};

          final groups = groupsData
              .map((json) {
                try {
                  if (json.isEmpty) {
                    return null;
                  }
                  return Group(
                    id: json["id"],
                    name: json["name"],
                    passwords: json["passwords"] ?? [],
                    uid: _currentUserID,
                  );
                } catch (error) {
                  return null;
                }
              })
              .where((group) => group != null)
              .cast<Group>()
              .toList();

          for (var group in groups) {
            groupsMap[group.name] = group;
          }

          // Fetch password data securely from passwords_view
          final groupPasswordsData = await _supabase
              .from("group_passwords")
              .select("group_id, password_id, passwords_view(*)")
              .eq("uid", currentUserID);

          final passwordMap = <String, List<Password>>{};

          for (var relation in groupPasswordsData) {
            final groupId = relation["group_id"] as String?;
            final passwordData = relation["passwords_view"];

            if (groupId != null && passwordData != null) {
              try {
                final password = Password.fromJSON(passwordData);

                if (passwordMap.containsKey(groupId)) {
                  passwordMap[groupId]!.add(password);
                } else {
                  passwordMap[groupId] = [password];
                }
              } catch (error) {
                debugPrint("Error Parsing Password: $error.");
              }
            }
          }

          final updatedGroups = groupsMap.values.map((group) {
            final updatedPasswords = passwordMap[group.id] ?? [];
            return group.copyWith(passwords: updatedPasswords);
          }).toList();

          onNewData(updatedGroups);
          return updatedGroups;
        });
  }

  ///Add Group
  static Future<Group?> addGroup({required String name}) async {
    //Safety Check When Not Logged In
    if (_currentUserID == null) return null;

    //Group
    final group = Group(
      id: const Uuid().v4(),
      name: name,
      uid: _currentUserID,
    );

    //Add Group with Name
    final response = await _supabase.from("groups").insert({
      "id": group.id,
      "name": group.name,
      "uid": group.uid,
    }).select();

    //Return if the group was added successfully
    return response.isNotEmpty ? group : null;
  }

  ///Delete Group
  static Future<bool> deleteGroup({required String groupID}) async {
    //Check if Logged In
    if (_currentUserID == null) return false;

    //Deleted Status
    bool deleted = false;

    // Create a completer to wait for the dialog result
    final Completer<bool> completer = Completer();

    //Confirmation dialog
    Get.defaultDialog(
      title: "Delete Group",
      content: const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          "This Group will be deleted from all your Devices.\n\nAll Passwords within this Group will become Group-less.",
          textAlign: TextAlign.center,
        ),
      ),
      cancel: Buttons.text(
          text: "Cancel",
          onTap: () {
            //Cancelled
            completer.complete(false);
            Get.back();
          }),
      confirm: Buttons.elevated(
        text: "Delete",
        onTap: () async {
          try {
            await _supabase.from("groups").delete().eq("id", groupID).then((_) {
              deleted = true;
            });
          } catch (error) {
            deleted = false;
          }

          //Return Deleted Status
          completer.complete(deleted);
          Get.back();
        },
      ),
    );

    //Wait for Confirmation
    return completer.future;
  }

  static Future<void> deleteAll() async {
    //Delete Passwords
    await _supabase.from("groups").delete().eq("uid", _currentUserID);
  }
}
