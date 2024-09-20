import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vaultify/util/models/password.dart';
import 'package:vaultify/util/services/account/handler.dart';
import 'package:vaultify/util/services/account/premium.dart';
import 'package:vaultify/util/services/data/env.dart';
import 'package:vaultify/util/services/data/remote.dart';

///Passwords Handler
class PasswordsHandler {
  ///Supabase
  static final _supabase = Supabase.instance.client;

  ///Current User
  static final _currentUserID =
      AccountHandler.currentUser?.id ?? AccountHandler.cachedUser["id"];

  ///Max Passwords
  static Future<String> maxPasswords() async {
    //Max Passwords (Environment Variable)
    final maxEnv = EnvVars.get(name: "MAX_ITEMS");

    //Check Premium
    final premium = await PremiumHandler.checkPremium();

    //Return According to Premium
    return premium ? "∞" : maxEnv;
  }

  ///Add Password with Group
  static Future<bool> addWithGroup({
    required Password password,
    required String groupID,
  }) async {
    //Added Status
    bool added = false;

    //Add Password
    final addedPwd = (await _supabase.from("passwords").insert(
      {
        "id": password.id,
        "name": password.name,
        "password": password.password,
        "uid": _currentUserID,
      },
    ).select())
        .isNotEmpty;

    //Add Relationship with Group
    final addedRel = (await _supabase.from("group_passwords").insert({
      "group_id": groupID,
      "password_id": password.id,
      "uid": _currentUserID,
    }).select())
        .isNotEmpty;

    //Check if All is Good
    if (addedPwd && addedRel) {
      added = true;
    }

    //Return Added Status
    return added;
  }

  ///Get All Passwords
  static Future<List<Password>> getAll() async {
    //Passwords
    List<Password> passwords = [];

    //Database Passwords
    final dbPwds =
        await _supabase.from("passwords").select().eq("uid", _currentUserID);

    //Parse Passwords
    for (final dbPwd in dbPwds) {
      //Password
      final password = Password.fromJSON(dbPwd);

      //Add Password to List
      passwords.add(password);
    }

    //Return Passwords
    return passwords;
  }
}
