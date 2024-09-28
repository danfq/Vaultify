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

  ///Get All Groups & Respective Passwords
  static Stream<List<Group>> getAllGroups({
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
          debugPrint("Raw groups data: $groupsData");

          if (groupsData.isEmpty) {
            debugPrint("Empty groupsData.");
            onNewData([]);
            return [];
          }

          final groupsMap =
              <String, Group>{}; // Map to store the latest group by name

          final groups = groupsData
              .map((json) {
                try {
                  if (json.isEmpty) {
                    debugPrint("Empty Group Data");
                    return null;
                  }
                  return Group(
                    id: json["id"],
                    name: json["name"],
                    passwords: json["passwords"] ?? [],
                    uid: _currentUserID,
                  );
                } catch (error) {
                  debugPrint("Error Parsing Group: $error.");
                  return null;
                }
              })
              .where((group) => group != null)
              .cast<Group>()
              .toList();

          debugPrint("Parsed groups: $groups");

          for (var group in groups) {
            groupsMap[group.name] = group;
          }

          // Fetch password data securely from passwords_view
          final groupPasswordsData = await _supabase
              .from("group_passwords")
              .select(
                  "group_id, password_id, passwords_view(*)") // Changed to passwords_view
              .eq("uid", currentUserID);

          debugPrint("Raw group passwords data: $groupPasswordsData");

          final passwordMap = <String, List<Password>>{};

          for (var relation in groupPasswordsData) {
            final groupId = relation["group_id"] as String?;
            final passwordData =
                relation["passwords_view"]; // Changed to passwords_view

            if (groupId != null && passwordData != null) {
              try {
                final password =
                    Password.fromJSON(passwordData); // Decoding password

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

          debugPrint("Updated groups: $updatedGroups");

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
}
