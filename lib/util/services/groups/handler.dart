import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:vaultify/util/models/group.dart';
import 'package:vaultify/util/models/password.dart';
import 'package:vaultify/util/services/account/handler.dart';

///Groups Handler
class GroupsHandler {
  ///Supabase
  static final _supabase = Supabase.instance.client;

  ///Add Group
  static Future<bool> addGroup({required String name}) async {
    //Current User ID
    final String? userID =
        AccountHandler.currentUser?.id ?? AccountHandler.cachedUser["id"];

    //Group
    final group = {
      "id": const Uuid().v4(),
      "name": name.trim(),
      "uid": userID,
    };

    //Add Group to Database
    final added =
        (await _supabase.from("groups").insert(group).select()).isNotEmpty;

    //Debug
    print("Group '${name.trim()} | Added: $added'");

    //Return Added Status
    return added;
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
